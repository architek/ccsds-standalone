#!/usr/bin/perl
use strict;
use warnings;

BEGIN { require "custo-s3.pm"; }
use Ccsds::Utils "CcsdsDump";
use Ccsds::TM::File "read_frames";

# defaults to print all packets
my $code = $ARGV[1] || "1";

#This plugin print ccsds structures if code in $code evals to true
#ex: my $code=q/$tm->{'Packet Header'}->{'Packet Id'}->{'Apid'}==29/;
sub filter_print {
    my ($tm) = @_;
    print CcsdsDump($tm) if eval $code;
}

my $config = {
    record_len      => 32 + 4 + 1115 + 160,
    offset_data     => 32 + 4,
    frame_len       => 1115,
    debug           => 0,
    has_sync        => 1,
    ascii           => 1,
    idle_packets    => 0,
    coderefs_frame  => [ \&filter_print ],
    coderefs_packet => [ \&filter_print ],
};

my $nf = read_frames( $ARGV[0], $config );
print "Read $nf frames\n";
