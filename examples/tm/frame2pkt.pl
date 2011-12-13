#!/usr/bin/perl
use strict;
use warnings;

#######################
# Shows how to use read_frames and plugins
# It goes through a frame file and outputs included packets
# For each packet or frame, a plugin can be registered
# It will be called with the structure as first element
#######################

BEGIN { require "custo-s3.pm"; }    # customize for S3
use Ccsds::Utils qw/CcsdsDump/;
use Ccsds::TM::File qw/read_frames/;
use Data::Dumper;

#List of "plugins"

#Sub to count distribution on apid
#########
my %n_apid;

sub apid_dist {
    my ($packet) = @_;
    my $apid = $packet->{'Packet Header'}->{'Packet Id'}->{'Apid'};
    ++$n_apid{$apid};
}

#Sub to store last n packets
#_0_ to be called first
my $l_packets = [];

sub _0rotate_packets {
    push @$l_packets, $_[0];
    shift @$l_packets if 10 <= @$l_packets;
}

#Sub to check for SSC Gap
#########
my %ssc_apid;

sub ssc_gapCheck {
    my ($packet) = @_;
    my $apid = $packet->{'Packet Header'}->{'Packet Id'}->{'Apid'};
    my $is_idle = $apid == 0b11111111111 ? 1 : 0;
    my $tmpacketh = $packet->{'Packet Header'};
    if ( !$is_idle ) {
        my $ssc = $tmpacketh->{'Packet Sequence Control'}->{'Source Seq Count'};
        if ( defined $ssc_apid{$apid}
            && ( ( $ssc - $ssc_apid{$apid} ) & 16383 ) != 1 )
        {
            warn "SSC Gap from $ssc_apid{$apid} to $ssc for Apid $apid\n";

            #            print Dumper($l_packets) , "\n" ;
        }
        $ssc_apid{$apid} = $ssc;
    }
}

#A simple frame printer
#########
my $n = 0;

sub frame_print_header {
    my ($tmframe) = @_;
    printf "-- Frame %08d " . "-" x 80 . "\n", ++$n unless ( $n % 100 );
    $tmframe->{'Data'} = [];
    print CcsdsDump($tmframe);
}

#Define format of file.
#Note:Frame Length is redundant with info in the frame.
my $config = {
    record_len  => 32 + 4 + 1115 + 160,    # Size of each records
    offset_data => 32 +
      4,    # Offset of the frame in this record (after the sync marker)
    frame_len => 1115
    , # Frame length, without Sync and without Reed Solomon Encoding Tail and FEC if any
    debug => 2
    , # Parser debugger 0: quiet, 1: print headers, 2: print full CADU, 3: Self Debug, 4:DataParseBinary Debug
      #verbose => 1,
    has_sync     => 1,    #If file has syncro markers, use them
    ascii        => 1,    #hex and ascii output of packet data
    idle_packets => 0,    #Show idle packets

    #Callbacks to execute at each frame
    #coderefs_frame =>  [ \&frame_print_header ],
    #Callbacks to execute at each packet
    coderefs_packet => [ \&_0rotate_packets, \&apid_dist, \&ssc_gapCheck ],
};

my $nf;
$nf = read_frames( $ARGV[0], $config );
print "Read $nf frames\n";

print "APID Distribution:\n", Dumper( \%n_apid );
