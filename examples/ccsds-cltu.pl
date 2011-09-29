#!/usr/bin/perl
#This script is an example of decoding CLTU to TC packets using TC::File

use strict;
use warnings;
use Ccsds::Utils;
use Ccsds::TC::File;

my $config = { debug => 0 };
die "You need to provide a logfile" unless $ARGV[0];

my $nf = read_frames( $ARGV[0], $config );
print "Read $nf frames\n";
