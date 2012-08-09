#!/usr/bin/perl
use strict;
use warnings;
$|++;

BEGIN { require "Custo-projectX.pm" }
use Ccsds 2.8;
use Ccsds::TM::File;
use Parallel::ForkManager;
use Sys::CPU;
use Data::Dumper;

my $filename = $ARGV[0] ;
my $n_cores  = Sys::CPU::cpu_count();
my $n_parts  = $n_cores * 3;
my ( $nf, $np ) = ( 0, 0 );
my ($id,$vc,%dist_vc,$slice);
my $PERCENTAGE=5;

sub ww {
    my $d=`date`;
    chomp $d;
    print "$d : ", shift, "\n";
}

sub callback_tm_packet {
    my ( $tm, $raw ) = @_;
    my $apid = $tm->{'Packet Header'}{'Packet Id'}{'vApid'};
    $dist_vc{$id}{"VC $vc"}{"APID $apid"}{n}++;
    $np++;
}

sub callback_tm_frame {
    my ( $frame ) = @_;
    my $tfh = $frame->{'TM Frame Header'};
    $vc = $tfh->{'Virtual Channel Id'};
    $dist_vc{$id}{"VC $vc"}{"n frames"}++;
    $nf++;
    if ( $nf % int( $slice * $PERCENTAGE / 100 ) == 0 ) {
        ww "$id: Progress : ". int( 100 * $nf / $slice ). "%";
    }
}

#Split number of records into n_cores
sub conf_par {
    my $sz = -s $filename;
    $slice = $sz / $Ccsds::Custo::config_tm->{record_len};
    print "Detected $sz bytes, $slice blocks\n";
    $slice = 1 + int( $slice / $n_parts );
    print "Slicing in $n_parts of $slice frames\n";
    return $slice;
}

print "Using $n_cores cores\n";
my $pm = new Parallel::ForkManager($n_cores);

my $steps = conf_par;
$Ccsds::Custo::config_tm->{frame_nr} = $steps;

ww "Start";
for ( 0 .. $n_parts - 1 ) {
    $pm->start and next;
    $id = $_ + 1 . "/" . $n_parts;
    my $p = int( 100 * $_ / $n_parts );
    ww "New thread $id ($p%)";

    $dist_vc{$id}->{stat}{from} = $Ccsds::Custo::config_tm->{skip} = $_ * $steps;
    $dist_vc{$id}->{stat}{to} = $dist_vc{$id}->{stat}{from} + $steps;

    Ccsds::TM::File::read_frames2( $filename, $Ccsds::Custo::config_tm );

    print "-" x 80, "\n", "Thread $id, from frame ",
      $Ccsds::Custo::config_tm->{skip},     ", nframes=",
      $Ccsds::Custo::config_tm->{frame_nr}, ":\n";
    ww Dumper( \%dist_vc );
    ww "$np non_idle packets\n";

    $pm->finish;    # Terminates the child process
}

$pm->wait_all_children;
ww "End";
