#!/usr/bin/perl
use strict;
use warnings;
$|++;

use Ccsds::TM::File3 qw/read_frames3/;
use Parallel::ForkManager;
use Sys::CPU;
use Data::Dumper;
use Convert::Binary::C;

my $filename = $ARGV[0] ;
my $n_cores  = Sys::CPU::cpu_count();
my $n_parts  = $n_cores * 3;
my ( $nf, $np ) = ( 0, 0 );
my ($id,$vc,%dist_vc,$slice);
my $PERCENTAGE=5;

my $config = {
    output => {
        debug => 0,    #internal debug
        data  => 0,    #dump content of protocol units
    },
    record_len      => 4 + 1912 + 128,
    offset_data     => 4,
    frame_len       => 1912,
    TMSourcePacketHeaderLength => 6,

    has_sync        => 1,
#    idle_frames => 1,
#    idle_packets => 1,

#    coderefs_packet => [ \&main::scos_tm_decode, ],
    coderefs_packet=>[ \&main::scos_tm_decode, ],
    coderefs_output => \&main::output_decoder,
    coderefs_frame=>[\&main::extract_tmfe_record],
};


sub ww {
    my $d=`date`;
    chomp $d;
    print "$d : ", shift, "\n";
}

sub scos_tm_decode {

    my ( $pkt_hdr, $pkt_data_field_hdr ) = @_;
    $np++;

}

sub extract_tmfe_record {
    my ( $frame_hdr ) = @_;
    $vc = $frame_hdr->{master_channel_id}{vcid};
    $dist_vc{$id}->{$vc}->{n}++;
    $nf++;
    if ( $nf % int( $slice * $PERCENTAGE / 100 ) == 0 ) {
        ww "$id: Progress : ". int( 100 * $nf / $slice ). "%";
    }
}

#Split number of records into n_cores
sub conf_par {
    my $sz = -s $filename;
    $slice = $sz / $config->{record_len};
    print "Detected $sz bytes, $slice blocks\n";
    $slice = 1 + int( $slice / $n_parts );
    print "Slicing in $n_parts of $slice frames\n";
    return $slice;
}

print "Using $n_cores cores\n";
my $pm = new Parallel::ForkManager($n_cores);

my $steps = conf_par;
$config->{frame_nr} = $steps;

my $c=prep_struct();

ww "Start";
for ( 0 .. $n_parts - 1 ) {
    $pm->start and next;
    $id = $_ + 1 . "/" . $n_parts;
    my $p = int( 100 * $_ / $n_parts );
    ww "New thread $id ($p%)";

    $dist_vc{$id}->{stat}->{from} = $config->{skip} = $_ * $steps;
    $dist_vc{$id}->{stat}->{to} = $dist_vc{$id}->{stat}->{from} + $steps;

    Ccsds::TM::File::read_frames3( $filename, $config ,$c);

    print "-" x 80, "\n", "Thread $id, from frame ",
      $config->{skip},     ", nframes=",
      $config->{frame_nr}, ":\n";
    ww Dumper( \%dist_vc );
    ww "$np non_idle packets\n";

    $pm->finish;    # Terminates the child process
}

$pm->wait_all_children;
ww "End";

sub prep_struct {
    my $c = Convert::Binary::C->new;
    $c->Define(qw( __USE_POSIX __USE_ISOC99=1 ));
    $c->configure( UnsignedChars => 1, UnsignedBitfields => 1, ByteOrder => 'BigEndian' );

    $c->parse(<<'CCODE');
  struct frame_hdr { 
      struct {
          int version:2;
          int scid:8;
          int vcid:6;
      } master_channel_id;
      char vcfc[3];
      struct {
          int rp:1; 
          int rsvd:7;
      } signalling_field;
      unsigned short fhec;
  };
 
  struct frame_data_field_hdr {
      int spare:5;
      int fhp:11;
  };

  struct pkt_hdr {
      int version:3;
      int type:1;
      int sechdr:1;
      int spare:2;
      int vcm:1;
      int rsvd:1;
      int wn:2;
      int dn:1;
      int bn:4;
      int sf:2;
      int seqn:14;
      short pkt_df_length;
  };

  struct pkt_data_field_hdr {
      int sc_coarse;
      char sc_fine[3];
      int tcv:12;
      int msi:1;
      int pps:1;
      int sos:10;
      short cs;
  };
CCODE

    $c;
}
