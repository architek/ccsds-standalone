#!/usr/bin/perl
use strict;
use warnings;

# This shows the use of callbacks called for each decoded packet and frame
# command line arguments are:
# filename code_to_eval_for_frames code_to_eval_for_packets
# the following lines will not print any frame detail, and print only packets with apid equals to 29
# ccsds-filt.pl tmframes.bin "return 0" "$tm->{'Packet header'}->{'Packet Id'}->{Apid}==29"

BEGIN { require "custo.pm" }
use Ccsds::Utils    "CcsdsDump";
use Ccsds::TM::File "read_frames";

#Callback that evaluates the perl code passed as command line argument, struct is available in $tm
#Addtional feature: If eval returns true, it will then display a pretty dump of variable $tm to stdout
#ex: "$tm->{'Packet Header'}->{'Packet Id'}->{'Apid'}==29"  would filter and print packets of apid 29
sub eval_sub {
    my ($code)=@_;
    return sub {
        my ($struct) = @_;
        print CcsdsDump($struct) if eval $code;
    }
}

my $config = {
    record_len      => 32 + 4 + 1115 + 160,             # File contains 32 bytes block header, Sync, Frame, ReedSolomon
    offset_data     => 32 + 4,                          # The frame starts there then
    frame_len       => 1115,                            # Size
    debug           => 0,                               # 
    has_sync        => 1,                               # Use Sync Marker to resync when garbage
    ascii           => 1,                               # Display ascii 
    idle_packets    => 0,
    coderefs_frame  => [ eval_sub( $ARGV[1]||1 ) ],     # defaults to a true eval
    coderefs_packet => [ eval_sub( $ARGV[2]||1 ) ],     # to dump structures
};

my $nf = read_frames( $ARGV[0], $config );
print "Read $nf frames\n";
