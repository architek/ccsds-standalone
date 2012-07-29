package Ccsds::TM::File;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::File - Set of utilities to work on CCSDS TM Files

=cut

use Ccsds::Utils qw(tm_verify_crc CcsdsDump hdump);
use Ccsds::TM::Frame qw($TMFrame);
use Ccsds::TM::SourcePacket qw($TMSourcePacket $TMSourcePacketHeader $TMSourceSecondaryHeader);
use Try::Tiny;

sub dbg { my ($class,$mess,$config) = @_;
    if ($config->{output}->{$class}) {
        $config->{coderefs_output}->($mess) if $config->{coderefs_output};
        warn "$mess";
    }
}

#Given a data field binary stream, tries to decode exactly one packet.
#If a packet is found, return its length or 0 if no valid/complete packet (wrt to length and datas)
#Crc Check: if crc of non idle packet is incorrect, display error message
sub _try_decode_pkt {
    my ( $data, $config ) = @_;
    my ( $pkt_len, $is_idle, $apid, $tmpacket, $tmpacketh, $catch );

    #Header
    try {
        $catch = 0;
        $tmpacketh = $TMSourcePacketHeader->parse($data);
    }
    catch {
        #Possible only on short reads
        #dbg "W" ,"Undecoded Packet Header",$config;
        $catch = 1;
    };
    return 0 if $catch;

    $apid     = $tmpacketh->{'Packet Id'}->{'vApid'};
    $is_idle  = $apid == 0b11111111111 ? 1 : 0;
    $pkt_len  = $tmpacketh->{'Packet Sequence Control'}->{'Packet Length'} + 1 + 6;
    return $pkt_len if $is_idle and !$config->{idle_packets};
    return 0 if $pkt_len > length($data);

    dbg "data", CcsdsDump($tmpacketh), $config if $config->{idle_packets} or !$is_idle ;

    #Packet
    try {
        $catch=0;
        $tmpacket = $TMSourcePacket->parse($data);
    }
    catch {
        #This should not happen as we have enough bytes
        #
        $catch = 1;
    };
    return 0 if $catch;

    dbg "data", CcsdsDump( $tmpacket, $config->{ascii}) , $config
       if $config->{idle_packets} or !$is_idle ;

    #We got a complete packet, verify CRC
    if ( $tmpacket->{'Has Crc'} and
        !tm_verify_crc( unpack 'H*', substr( $data, 0, $pkt_len ) ) )
    {
        dbg "W","CRC of following source packet does not match\n",$config ;
        dbg "debug", unpack( 'H*', $data ) . "\n", $config;
    }

    #Execute coderefs. Pass decoded packet and raw packet, based on the ccsds length (datafield length-1)
    for ( @{ $config->{coderefs_packet} } ) {
        my $pkt = substr( $data, 0, $pkt_len );
        $_->( $tmpacket, $pkt );
    }

    return $pkt_len;
}

sub read_frames {
    my ( $filename, $config ) = @_;

    my $frame_nr = 0;
    my $vc;
    my $pkt_len;
    my @packet_vcid = ("") x 8;    # VC 0..7

    #Show warnings if user defined a warning subref
    $config->{output}->{W}=1;

#Remove buffering - This slows down a lot the process but helps to correlate errors to normal output
    $| = 1 if $config->{output}->{debug} ;

    open my $fin, "<", $filename or die "can not open $filename";
    binmode $fin;

  FRAME_DECODE:
    while ( !eof $fin ) {
        my $raw;

        # Read a record
        if ( read( $fin, $raw, $config->{record_len} ) != $config->{record_len} ) {
            dbg "W","Fatal: Not a full frame record of " . $config->{record_len} . "\n", $config;
            return -1;
        }
        #If sync, check
        if ($config->{has_sync}) {
            if ( substr( $raw, $config->{offset_data} - 4 , 4 ) ne "\x1a\xcf\xfc\x1d" ) {
                dbg "W","Record does not contain a SYNC, reading next record\n", $config;
                next FRAME_DECODE;
            }
        }

        $frame_nr++;

        #Extract frame from record
        my $rec_head = substr $raw, 0, $config->{offset_data} - 4;
        $raw = substr $raw, $config->{offset_data}, $config->{frame_len};

        #Parse frame
        my $tmframe = $TMFrame->parse($raw);

        #Execute coderefs
        $_->( $tmframe, $raw, $rec_head ) for @{ $config->{coderefs_frame} };

        #Remove CLCW
        $raw = substr($raw, 0, -4) if exists $tmframe->{CLCW};

        if ( exists $tmframe->{'TM Frame Header'}->{'Sync Flag'} and $tmframe->{'TM Frame Header'}->{'Sync Flag'} ne '0' ) {
            dbg "W","First Header Pointer undefined for frame $frame_nr!\n", $config;
            next;
        }

        my $tmframe_header = $tmframe->{'TM Frame Header'};
        my $fhp            = $tmframe_header->{'First Header Pointer'};

        my $sec;        # Secondary header present ?
        $sec  = $tmframe_header->{'Sec Header'} if exists $tmframe_header->{'Sec Header'};
        
        $vc = $tmframe_header->{'Virtual Channel Id'};
        if ( $fhp == 0b11111111110 ) {
            dbg "data","Frame $frame_nr is an OID Transfer Frame\n",$config;
            next;
        }
        dbg "data", CcsdsDump($tmframe_header) , $config;
        dbg "debug", "Fhp:$fhp\n" , $config;
        dbg "data" , "Frame:" . unpack( 'H*', substr( $raw, 0, 6 ) ) . "|" . unpack( 'H*', substr( $raw, 6 ) ) . "|" . "\n", $config;

        #Remove Primary header and Secondary if there
        my $offset = $tmframe->{'TM Frame Header'}->{Length};
        $offset += $tmframe->{'TM Frame Secondary Header'}->{'Sec Header Length'} + 1
          if $sec;
        $raw = substr $raw, $offset;

        if ( length $packet_vcid[$vc] ) {

            #Finish previous packet
            if ( $fhp == 0b11111111111 ) {

#we don't have another packet that begins. this one might end now or on a next frame
                dbg "debug", "We have pending data and current frame has no data header\n",$config;
                $packet_vcid[$vc] .= $raw;
                next;
            }
            else {

                #stop at the next packet
                dbg "debug", "We have pending data and current frame has a data header\n", $config;
                my $raw_packet = $packet_vcid[$vc] . substr $raw, 0, $fhp;
                dbg "debug", "After appending all packets slice, we have a packet of length ". length $raw_packet . "\n", $config;
                if ( !_try_decode_pkt( $raw_packet, $config ) ) {
                    dbg "W","Corrupted packet - using FHP to resync\n", $config;
                    dbg "debug", "old data were:" . unpack( 'H*', $packet_vcid[$vc] ). "\nComplete concatenated data:". unpack( 'H*', $raw_packet ) . "\n", $config;
                }
            }
        }

# We have no data remaining, fetch next packet pointed to by First Header Pointer
        $raw = substr $raw, $fhp;
        $packet_vcid[$vc] = "";
        do {
            if ( ( $pkt_len = _try_decode_pkt( $raw, $config ) ) == 0 ) {

#We got an incomplete packet, not yet the full packet.. store it. rem: try catch error is in $_
                $packet_vcid[$vc] = $raw;
                dbg "debug", "cut data:". unpack( 'H*', $packet_vcid[$vc] ).
                             " length is ". length( $packet_vcid[$vc] ) . "\n", $config;
                next FRAME_DECODE;
            }

            #go forward in the frame to the next packet
            dbg "debug","Removing Length " . $pkt_len . " bytes: ". unpack( 'H*', substr $raw, 0, $pkt_len ) . "\n", $config;
            substr($raw,0,$pkt_len)='';
            dbg "debug", "Remains  <". unpack( 'H*', $raw ). ">" . "\n" , $config;
        } while length $raw;
    }

#End of file, try to decode last packet that has split on the previous frame(s) and until the last byte of this frame
    if ( length $packet_vcid[$vc] ) {
        if ( !_try_decode_pkt( $packet_vcid[$vc], $config ) ) {
            dbg "W", "Last packet corrupt and can't resync as there is no more frame\n", $config;
        }
    }
    close $fin;
    return $frame_nr;
}

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(read_frames);

=head1 SYNOPSIS

This module allows to read a binary file containing blocks. Each block contains one TM Frame.
Frames are decoded and so are included packets. First Header Pointer is used to find packets, detect incoherency and resynchronise if needed.

The module expects a filename and a configuration describing:
    - Format of the blocks and frames: size of blocks, offset in the block where the frame begins and size of frame.
    - Code references for frames: After each decoded frame, a list of subs can be called
    - Code references for packets: After each decoded packet, a list of subs can be called

 sub frame_print_header {
  my ($frame) = @_;
  print "New frame:\n";
  CcsdsDump($frame);
 }

 sub packet_print_header {
  my ($packet) = @_;
  print "New packet:\n";
  CcsdsDump($frame);
 }

 #Define format of file. Note: Frame Length is redundant with info in the frame.
 my $config={
     record_len => 32+4+1115+160,     # Size of each records, here we have a record header of 32 bytes and sync and reedsolomon
     offset_data => 32+4,       # Offset of the frame in this record (after the sync marker)
     frame_len => 1115,      # Frame length, without Sync and without Reed Solomon Encoding Tail and FEC if any
     debug => 2,             # Parser debugger 0: quiet, 1: print headers, 2: print full CADU, 3: Self Debug, 4:DataParseBinary Debug
     verbose => 1,
     has_sync  => 1,
     ascii => 1,             #hex and ascii output of packet data
     idle_packets => 0,      #Show idle packets
 #Callbacks to execute at each frame
     #coderefs_frame =>  [ \&frame_print_header ],
 #Callbacks to execute at each packet
     coderefs_packet => [ \&_0rotate_packets , \&apid_dist , \&ssc_gapCheck ],
 };
 
 my $nf;

 #Call the loop which will go through the complete file
 $nf = read_frames($ARGV[0], $config);

 print "Read $nf frames\n";


A full example is given in the script frame2packet.pl

=head1 EXPORTS

=head2 read_frames()

 Given a file name of X blocks containing frames, return number of frames read from the file or -1 on incomplete read.
 After each decoded frame,  call a list of plugin passed in $config.
 After each decoded packet, call a list of plugin passed in $config.

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::TM::File


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Ccsds::TM::File
