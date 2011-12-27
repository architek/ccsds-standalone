package Ccsds::TC::File;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::File - Set of utilities to work on CCSDS TC Files

=cut

use Data::Dumper;
use Ccsds::TC::Printer qw(TCPrint CltuPrint);
use Ccsds::TC::Frame;
use Ccsds::TC::SourcePacket qw($TCSourcePacket);
use Ccsds::Utils qw(rs_deintbin);

use constant {
    FIRST             => 1,    # For segment state machine
    CONT              => 0,    #
    LAST              => 2,    #
    STAND             => 3,    #
    OUT               => 0,    #
    IN                => 1,    #
    FRAMEHEADER_LEN   => 5,    # Header lengths  for packet extraction
    SEGMENTHEADER_LEN => 1     #
};

#This contains data found before EB90
my $rec_head;

sub read_frames {
    my ( $filename, $config ) = @_;
    $config->{debug} = 0 unless exists $config->{debug};

#$Data::ParseBinary::print_debug_info = 1 if $odebug;
#Remove buffering - This slows down a lot the process but helps to correlate errors to normal output
    $| = 1 if $config->{debug} >= 3;

    my $nr            = 0;
    my $state         = OUT;    # Segment Sequence state is "Outside a packet"
    my $segments_data = ();
    open my $fin, "<", $filename or die "can not open $filename";
    binmode $fin;

    while ( !eof $fin ) {
        my ( $headbuf, $buf );

        last if search( $fin, 2 ) < 0;

        #Read Sync + TC Frame Header
        if ( read( $fin, $headbuf, 2 + 5 ) != 7 ) {
            warn "Fatal: Not a full header\n";
            return -1;
        }
        my $fh = $TCFrameHeader->parse( substr( $headbuf, 2 ) );
        my $remain = $fh->{'Cltu Length'};

        #print "Frame length " , $fh->{'Frame Length'} , "\n";
        if ( read( $fin, $buf, $remain ) != $remain ) {
            warn "Fatal: Not a full frame\n";
            return -1;
        }
        $buf = $headbuf . $buf;

        #Decode the complete CLTU, incl. CBH
        my $cltu = $Cltu->parse($buf);
        substr( $buf, 0, 2 ) = "";    # Remove EB90h

        #Print decoded cltu, but not the still undecoded part
        $cltu->{'Cltu Data'} = ();
        my $mapid   = $cltu->{'Segment Header'}->{'MapId'};
        my $bypass  = $cltu->{'TC Frame Header'}->{'ByPass'};
        my $Scid    = $cltu->{'TC Frame Header'}->{'SpaceCraftId'};
        my $Vcid    = $cltu->{'TC Frame Header'}->{'Virtual Channel Id'};
        my $FLength = $cltu->{'TC Frame Header'}->{'Frame Length'};
        print
"Decoded Frame and included Segment: MapId=$mapid, Bypass=$bypass, Scid=$Scid, Vcid=$Vcid, Frame Length=$FLength\n"
          if $config->{debug};

        my $cltu_data =
          rs_deintbin( 7, $buf,
            $cltu->{'TC Frame Header'}->{'Frame Length'} + 1 )
          ;    #We use BCH Length 7

        #we now have CLTU *data* , BCH removed
        $_->( $cltu, $cltu_data, $rec_head ) for @{ $config->{coderefs_cltu} };

        #State Machine for Segment handling
        my $seqf = $cltu->{'Segment Header'}->{'Sequence Flags'};

        #Push segment datas = frameheader+segmentheader
        $segments_data .=
          substr( $cltu_data, FRAMEHEADER_LEN + SEGMENTHEADER_LEN );
        if ( $state == IN ) {

            #We are in a packet
            die
"Wrong segment, we received Sequence flag $seqf while we expect 0 or 2\n"
              unless ( $seqf == CONT or $seqf == LAST );
            next if ( $seqf == CONT );
            $state = OUT;
        }
        elsif ( $state == OUT ) {
            die
"Wrong segment, we received Sequence flag $seqf while we expect 1 or 3\n"
              unless ( $seqf == FIRST or $seqf == STAND );
            if ( $seqf == FIRST ) {
                $state = IN;
                next;
            }
        }

     #This is a STANDalone segment or LAST segment, decode the overall TC packet
        my $tcpacket = $TCSourcePacket->parse($segments_data);
        $nr++;

        $_->( $tcpacket, $segments_data ) for @{ $config->{coderefs_packet} };
        $segments_data = ();

    }
    return $nr;
}

sub search {
    use Fcntl "SEEK_CUR";
    my ( $file, $offset ) = @_;
    my $raw;
    my $bytes = 0;

    #Keep TMTCFE headers
    $rec_head = "";
    while ( !eof $file ) {
        last unless read( $file, $raw, 2 ) == 2;
        if ( $raw eq "\xeb\x90" ) {
            seek( $file, -$offset, SEEK_CUR );
            return $bytes;
        }
        $rec_head .= substr $raw, 0, 1;
        seek( $file, -1, SEEK_CUR );
        $bytes++;
    }
    return -1;    #eof hit
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

    perldoc Ccsds::TC::File


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Ccsds::TC::File
