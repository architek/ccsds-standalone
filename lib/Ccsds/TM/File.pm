package Ccsds::TM::File;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::File - Set of utilities to work on CCSDS TM Files

=cut

use Ccsds::Utils qw(tm_verify_crc CcsdsDump hdump);
use Ccsds::TM::Frame qw($TMFrame);
use Ccsds::TM::SourcePacket qw($TMSourcePacket $TMSourcePacketHeader $TMSourceSecondaryHeader);
use Data::Dumper;


sub dbg {
    my ( $class, $mess, $config ) = @_;
    if ( $config->{output}->{$class} ) {
        $config->{coderefs_output}->($mess) if $config->{coderefs_output};
        warn "$mess";
    }
    return;
}

my $g_pkt_len;
my $g_pkt_apid;
my $g_pkt_is_idle;

my $idle_frames;
my $idle_packets;

sub _decode_pkt_head {
    my ($data) = @_;

    my $pkt_head   = $TMSourcePacketHeader->parse($data);
    $g_pkt_len     = $pkt_head->{'Packet Sequence Control'}->{'Packet Length'} + 1 + $pkt_head->{Length};
    $g_pkt_apid    = $pkt_head->{'Packet Id'}->{'vApid'};
    $g_pkt_is_idle = $g_pkt_apid == 0b11111111111 ? 1 : 0;
    return $g_pkt_len;
}

sub _decode_pkt {
    my ($data,$config) = @_;
    
    my $pkt         = $TMSourcePacket->parse($data);
    my $pkt_head    = $pkt->{'Packet Header'};
    $g_pkt_len     = $pkt_head->{'Packet Sequence Control'}->{'Packet Length'} + 1 + $pkt_head->{Length};
    $g_pkt_apid    = $pkt_head->{'Packet Id'}->{'vApid'};
    $g_pkt_is_idle = $g_pkt_apid == 0b11111111111 ? 1 : 0;

    #Verify CRC
    if ( $pkt->{'Has Crc'} && !tm_verify_crc( unpack 'H*', substr( $data, 0, $g_pkt_len ) ) ) {
#        warn "CRC of following packet does not match";
        #dbg "W", "CRC of following source packet does not match\n", $config;
        #dbg "debug", unpack( 'H*', $data ) . "\n", $config;
    }

    #Stop if not interested in idle packets
    return if $g_pkt_is_idle && !$idle_packets;

    #Execute coderefs. Pass decoded packet and raw packet, based on the ccsds length (datafield length-1)
    for ( @{ $config->{coderefs_packet} } ) {
        my $pkt_data = substr( $data, 0, $g_pkt_len );
        $_->( $pkt,$pkt_data);
    }
    return;
}

sub read_record {
    my ( $fin, $config ) = @_;
    my $raw;
    if ( read( $fin, $raw, $config->{record_len} ) != $config->{record_len} ) {
        warn "Incomplete record";
        return 0;
    }

    #If sync, check
    if ( $config->{has_sync}
        and substr( $raw, $config->{offset_data} - 4, 4 ) ne "\x1a\xcf\xfc\x1d" )
    {
        warn "Record does not contain a SYNC, reading next record";
        return 0;
    }
    return $raw;
}

sub read_frames {
    my ( $filename, $config ) = @_;

    my $frame_nr = 0;
    my $vc       = 0;
    my @packet_vcid = ("") x 128;    # VC 0..127
    my $skip;
    my $sec;
    my $offset;

    $g_pkt_len=undef;
    my $TMSourcePacketHeaderLength=$config->{TMSourcePacketHeaderLength}; 

    #Show warnings if user defined a warning subref
    $config->{output}->{W} = 1;

    #Remove buffering - This slows down a lot the process but helps to correlate errors to normal output
    local $| = 1 if $config->{output}->{debug};

    $idle_frames=$config->{idle_frames}; $idle_packets=$config->{idle_packets};

    open my $fin, "<", $filename or die "can not open $filename";
    binmode $fin;
    
    if ( exists $config->{skip} ) {
        $skip = $config->{skip};
        seek($fin,$skip* $config->{record_len},0);
    }

  FRAME_DECODE:
    while ( !eof $fin ) {
        
        my $raw;

        #Extract frame from record
        next FRAME_DECODE unless $raw = read_record( $fin, $config );
        my $rec_head = substr $raw, 0, $config->{offset_data} - 4;
        $raw = substr $raw, $config->{offset_data}, $config->{frame_len};

        #Parse frame
        my $tmframe        = $TMFrame->parse($raw);
        my $tmframe_header = $tmframe->{'TM Frame Header'};
        my $fhp            = $tmframe_header->{'First Header Pointer'};

        #if we reached the number of frames and we end up on a packet boundary, stop
        return $frame_nr if defined $config->{frame_nr} and $frame_nr >= $config->{frame_nr} and $fhp != 0b11111111111;

        #if we were requested to skip frames, skip until next packet boundary (or OID frame)
        if ( defined $skip ) {
            next FRAME_DECODE if $fhp == 0b11111111111;
            $skip = undef;
        }

#Process frames
        $frame_nr++;
        
        if ( exists $tmframe_header->{'Sync Flag'} and $tmframe_header->{'Sync Flag'} ne '0' ) {
            warn "First Header Pointer undefined for frame $frame_nr!";
            next FRAME_DECODE;
        }

#Skip OID frames
        next FRAME_DECODE if $fhp == 0b11111111110 && !$idle_frames;

        #Execute coderefs
        $_->( $tmframe, $raw, $rec_head ) for @{ $config->{coderefs_frame} };
        next FRAME_DECODE if $fhp == 0b11111111110;
        
        #Remove Prefix: Primary header and Secondary if there
        $sec = $tmframe_header->{'Sec Header'} if exists $tmframe_header->{'Sec Header'};
        $offset = $tmframe_header->{Length};
        $offset += $tmframe->{'TM Frame Secondary Header'}->{'Sec Header Length'} + 1
          if $sec;
        $raw = substr $raw, $offset;
        
        #Remove Suffix: CLCW 
        $raw = substr( $raw, 0, -4 ) if exists $tmframe->{CLCW};

#Start Packet assembly on frame data
        $vc = $tmframe_header->{'Virtual Channel Id'};

        #Frame does not finish packet, append and go to next frame
        if ($fhp == 0b11111111111) {
            $packet_vcid[$vc] .= $raw;
            next FRAME_DECODE;
        }

        #There is a packet beginning in this frame, finalize current
        if (length($packet_vcid[$vc])) { 
            $packet_vcid[$vc] .= substr $raw, 0, $fhp; 
            if (length($packet_vcid[$vc]) >= $TMSourcePacketHeaderLength) {
                _decode_pkt_head($packet_vcid[$vc]);
                #Idle packets normally terminate a VC stream
                if ($g_pkt_is_idle) {
                    $packet_vcid[$vc]="";
                    next FRAME_DECODE 
                }
                if (length($packet_vcid[$vc]) >= $g_pkt_len) {
                    _decode_pkt( substr($packet_vcid[$vc],0,$g_pkt_len) , $config); 
                }
            }
        }

        #Begin decoding following packets
        $raw = substr $raw, $fhp;
        $packet_vcid[$vc]="";
      
        my $cont;
        do {
            $cont=0;
            #Do we have a full packet header
            if ( length($raw) >= $TMSourcePacketHeaderLength ) {
                _decode_pkt_head($raw);
                #Idle packets normally terminate a VC stream
                if ($g_pkt_is_idle) {
                    $packet_vcid[$vc]="";
                    next FRAME_DECODE 
                }
                #Do we have the full packet
                if (length($raw) >= $g_pkt_len) {
                    #Yes, decode packet
                    _decode_pkt( substr($raw,0,$g_pkt_len) , $config); 
                    substr( $raw, 0, $g_pkt_len , '') ;
                    $cont=1;
                    #Go on decoding packets
                }
            }
            #Not complete header or packet, push for following frames
        } while ($cont);
        $packet_vcid[$vc]= $raw;
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
     idle_frames => 0,      #Show idle frames
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
