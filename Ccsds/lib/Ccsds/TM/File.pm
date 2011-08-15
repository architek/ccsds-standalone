package Ccsds::TM::File;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::File - Set of utilities to work on CCSDS TM Files

=cut

use Ccsds::Utils qw(tm_verify_crc CcsdsDump);
use Ccsds::TM::Frame qw($TMFrame);
use Ccsds::TM::SourcePacket qw($TMSourcePacket $TMSourcePacketHeader $TMSourceSecondaryHeader) ;
use Try::Tiny;

my $glob_pkt_len;  #shared so that frame decoder knows about packet len FIXME

#Input:   Frame data field binary stream 
#Outputs: 0 if a valid packet (wrt to length and datas) was found
#         1 if no packet was found
#         glob_pkt_len <- size of last decoded packet
#Crc Check: if not idle and crc was incorrect, display error message
#
sub try_decode_pkt {
    my ($data,$config) = @_ ;
    my ($is_idle,$apid,$tmpacket,$tmpacketh,$ko);
    $ko = 0;
    
    try { 
    #   \{
        $tmpacketh = $TMSourcePacketHeader->parse($data); 
        print CcsdsDump( $tmpacketh ) if $config->{debug};
        $apid = $tmpacketh->{'Packet Id'}->{'Apid'};
        $is_idle = $apid == 0b11111111111? 1:0; 
        $glob_pkt_len = $tmpacketh->{'Packet Sequence Control'} ->{'Packet Length'} + 1 + 6;

        $tmpacket = $TMSourcePacket->parse( $data );
        if ( $config->{debug} >= 2 ) {
#            $tmpacket->{'Packet Data Field'}->{'Data Field'}->{'Source Data'} = undef unless $config->{print_source_data};
            print CcsdsDump( $tmpacket ) ;
        }
    } catch { 
        print "Undecoded packet\n" if $config->{debug} >= 3;
        $ko = 1;
    };
    return 1 if $ko;
    print "Decoded packet\n" if $config->{debug} >= 3;
    #Execute coderefs
    $_->($tmpacket) for @{ $config->{coderefs_packet} };
    #We got a complete packet, verify CRC
    if ( ! $is_idle  && ! tm_verify_crc( unpack 'H*',substr ( $data, 0, $glob_pkt_len ) ) ) { 
        warn "CRC of packet does not match\n" ; 
        print unpack('H*', $data) , "\n" if $config->{debug} >= 3; 
    }
    return 0;
}

#Return number of frames read or -1 on incomplete read
sub read_frames {
    my ($filename,$config)=@_; 

    my $frame_nr = 0;
    my $vc;
    my @packet_vcid = ("")x8;                               # VC 1..7

    #Remove buffering - This slows down a lot the process but allows to correlate errors to normal output
    $| = 0;
    $| = 1 if  $config->{debug} >= 3;

#Verbose debug, to be done in caller app
#    $Data::ParseBinary::print_debug_info = 1 if $config->{debug} >=4 ;

    open my $fin, "<", $filename or die "can not open $filename"; 
    binmode $fin;

	FRAME_DECODE:
	while(! eof $fin) {
	    my $raw;
	    
	    #Read record
	    # Read a record
	    if ( read( $fin, $raw, $config->{record_len}) != $config->{record_len} ) {
            warn "Fatal: Not a full frame record of " . $config->{record_len} . " bytes\n" ;
            return -1;
        }

        $frame_nr++;
        #Extract frame from record
        $raw=substr $raw , $config->{offset_data} , $config->{frame_len};
        #Parse frame
	    my $tmframe = $TMFrame->parse( $raw );
        #Execute coderefs
        $_->($tmframe) for @{ $config->{coderefs_frame} };
	    #Remove CLCW
	    $raw = substr $raw,0,-4;
	
	    if ( $tmframe->{'TM Frame Header'}->{'Sync Flag'} ne '0' ) {
	        warn "First Header Pointer undefined!\n";
	        next;
	    }
	
	    my $tmframe_header = $tmframe->{'TM Frame Header'};
	    my $fhp            = $tmframe_header->{'First Header Pointer'};
	    my $sec            = $tmframe_header->{'Sec Header'};
	    $vc                = $tmframe_header->{'Virtual Channel Id'};
	    if ( $fhp == 0b11111111110 ) {
	        print "OID Transfer Frame\n" if $config->{debug}>=2;
	        next;
	    }
	    print CcsdsDump($tmframe_header) if $config->{debug};
	    print "Fhp:$fhp," if $config->{debug}>=2;
	    print "Frame:" 
	      . unpack( 'H*', substr( $raw, 0, 6 ) ) . "|"
	      . unpack( 'H*', substr( $raw, 6 )) . "|\n"
	      if $config->{debug}>=2;
	
	    #Remove Primary header and Secondary if there
	    my $offset = 6;    
	    $offset += $tmframe->{'TM Frame Secondary Header'}->{'Sec Header Length'} +1 if ($sec);
	    $raw = substr $raw,$offset;
	
	    if ( length $packet_vcid[$vc] ) {
	        #Finish previous packet
	        if ( $fhp == 0b11111111111 ) {
	            #we don't have another packet that begins. this one might end now or on a next frame
	            print "We have pending data and current frame has no data header\n" if $config->{debug} >= 3;
	            $packet_vcid[$vc] .= $raw;
	            next;
	        } else {
	            #stop at the next packet
	            print "We have pending data and current frame has a data header\n" if $config->{debug} >= 3;
	            my $raw_packet=$packet_vcid[$vc] . substr $raw,0,$fhp ;
	            print "After appending all packets slice, we have a packet of length ", length $raw_packet  , "\n" if $config->{debug} >= 3;
	            if ( try_decode_pkt ( $raw_packet , $config) ) {
	                warn "Corrupted packet - using FHP to resync\n"; 
	                if ( $config->{debug} >= 3 ) { 
	                    print "old data were:",unpack('H*', $packet_vcid[$vc]) , "\n"; 
	                    print "complete concatenated data:" , unpack('H*',$raw_packet) , "\n";
	                }
	            }
	        }
	    }
	    # We have no data remaining, fetch next packet pointed to by First Header Pointer
	    $raw = substr $raw, $fhp;
	    $packet_vcid[$vc] = "";
	    do { 
	        if ( try_decode_pkt ( $raw , $config) ) { 
		        #We got an incomplete packet, not yet the full packet.. store it. rem: try catch error is in $_
		        $packet_vcid[$vc] = $raw;
		        print "cut data:",unpack('H*', $packet_vcid[$vc]) , 
		              " length is ", length($packet_vcid[$vc]), "\n" if $config->{debug} >= 3;
		        next FRAME_DECODE;
		    }
		    #go forward in the frame to the next packet
		    print "Removing " , unpack('H*',substr $raw,0,$glob_pkt_len ) , "\n" if $config->{debug} >= 3;
		    $raw = substr $raw, $glob_pkt_len;
		    print "Remains  " , unpack('H*',$raw), "\n" if $config->{debug} >= 3;
	    } while length $raw;
	}
	#End of file, try to decode last packet that has split on the previous frame(s) and until the last byte of this frame
	if ( length $packet_vcid[$vc] ) {
	    if ( try_decode_pkt ( $packet_vcid[$vc] , $config ) ) {
	        warn "Last packet corrupt and can't resync as there is no more frame\n";
	    }
	}
    return $frame_nr;
}


require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(read_frames);

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

1;    # End of Ccsds::Utils
