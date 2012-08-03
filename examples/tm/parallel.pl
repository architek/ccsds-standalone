#!/usr/bin/perl
use strict;
use warnings;

BEGIN { require "Custo.pm" }
use Ccsds 2.7;
use Ccsds::TM::File;
use Sys::CPU;
use Parallel::ForkManager;
use Data::Dumper;

my ( $nf, $np ) = ( 0, 0 );
my $id;
my %dist_vc;

my $filename = $ARGV[0];
my $n_cores  = Sys::CPU::cpu_count();

sub output_decoder {
    my ($mess) = @_;
    #    printf "t=%.2fs \t WARNING: $mess\n", $bench_time;
}

sub scos_tm_decode {
    my ( $tm, $raw ) = @_;
    $np++;
}

sub extract_tmfe_record {
    my $frame = shift;
    my $tfh   = $frame->{'TM Frame Header'};
    my $vc    = $tfh->{'Virtual Channel Id'};
    $dist_vc{$id}->{$vc}++;
}

#Split number of records into n_cores
sub conf_par {
    my $sz    = -s $filename;
    my $slice = $sz / $Ccsds::Custo::config_tm->{record_len};
    print "Detected $slice blocks\n";

    $slice = 1 + int( $slice / $n_cores );

    print "Slicing in $slice frames\n";
    $slice;
}

print "Using $n_cores cores\n";
my $pm = new Parallel::ForkManager($n_cores);

my $steps = conf_par;
$Ccsds::Custo::config_tm->{frame_nr} = $steps;

for ( 0 .. $n_cores - 1 ) {
    $pm->start and next;
    $id = $_;
    print "New thread $id\n";
    $Ccsds::Custo::config_tm->{skip} = $_ * $steps;
    $nf = Ccsds::TM::File::read_frames( $filename, $Ccsds::Custo::config_tm );

    print "-" x 80, "\n", "Thread $id, from frame ",
      $Ccsds::Custo::config_tm->{skip},     ", nframes=",
      $Ccsds::Custo::config_tm->{frame_nr}, ":\n";
    print Dumper( \%dist_vc );
    print "$np non_idle packets\n";

    $pm->finish;    # Terminates the child process
}
$pm->wait_all_children;
