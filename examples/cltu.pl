#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use Ccsds::Utils qw(verify_crc tm_verify_crc);
use Ccsds::TC::Frame qw($Cltu $TCFrame);
use Ccsds::TC::SourcePacket qw($tcsourcepacket);

my $odebug   = 0;
my $odumper  = 0;
my $oshowver = 0;
my $opts     = GetOptions(
    'debug'   => \$odebug,     # do we want debug
    'dumper'  => \$odumper,    # do we want to use tmprint or internal dumper
    'version' => \$oshowver
);

# State machine: Start with State=0
# 0 1 First Segment of TC User Data Unit on one MAP                         State goes from 0 to 1
# 0 0 Continuing Segment of TC User Data Unit on one MAP                    Push data
# 1 0 Last Segment of TC User Data Unit on one MAP                          State goes from 1 to 0, decode packet
# 1 1 No segmentation (one TC User Data Unit or multiple complete packets)  Decode Packet

use constant {
    FIRST => 1,
    CONT  => 0,
    LAST  => 2,
    STAND => 3,
    OUT   => 0,
    IN    => 1
};

sub remove_cbh {
    ( my $idata, my $fl ) = @_;
    my $odata;
    my $offset = 0;

    while ( $fl > 0 ) {
        my $l = 7;
        $l = $fl if ( $fl < 7 );

        $odata .= substr( $idata, $offset, $l * 2 );
        $offset += 16;
        $fl -= 7;
    }

    print "    " . $idata . "\n" if $odebug;
    print "    " . $odata . "\n" if $odebug;
    return $odata;
}

$Data::ParseBinary::print_debug_info = 1 if $odebug;
$/ = '';    # paragraph reads
my $nblocks       = 0;
my $state         = OUT;    # Segment Sequence state is "Outside a packet"
my $segments_data = ();
while (<STDIN>) {
    chomp;
    my $buf = ();
    $nblocks++;
    print "BUF is:\n$_\n" if $odebug;

    #Sanity check on input
    die("There are non ASCII characters in your input\n")
      unless /^[[:ascii:]]*$/;

    my @lines = split(/\n/);

    my $line = ();
    foreach (@lines) {
        next if /^#/;

        #Is everything on one line, without header and spaces
        s/[^[:xdigit:]]//g;
        $buf .= $_;
    }

    if ($odebug) {
      my $cblock=int(length($buf)/2-2-8)/7;
      print "SSSS"
      . "FHFHFHFHFHSH"
      . "╭╮╳╳"
      . "╭╮╭╮╭╮╭╮╭╮╭╮╭╮╳╳" x ($cblock-1) . "T" x 16 . "\n";
      print "$buf\n";

    }
  DECODE:
    my $pstring = pack( qq{H*}, qq{$buf} );

    #Decode the complete CLTU, incl. CBH
    my $cltu = $Cltu->parse($pstring);

    #After this we now have CLTU *data* without CBH
    my $cltu_clean = remove_cbh( substr( $buf, 4 ),
        $cltu->{'TC Frame Header'}->{'Frame Length'} + 1 );

    #We remove this from the output
    $cltu->{'Cltu Data'} = ();
    print Dumper($cltu);

    my $seqf = $cltu->{'Segment Header'}->{'Sequence Flags'};
    #Push segment datas = frameheader+segmentheader
    $segments_data .= substr( $cltu_clean, ( 5 + 1 ) * 2 );
    if ( $state == IN ) {

        #We are in a packet
        die
"Wrong segment, we received Sequence flag $seqf while we expect 0 or 2\n"
          unless ( $seqf == CONT or $seqf == LAST );

        if ( $seqf == LAST ) {
            my $pstring2 = pack( qq{H*}, qq{$segments_data} );
            my $packet = $tcsourcepacket->parse($pstring2);
            print Dumper($packet);
            $segments_data = ();
        }
    }
    else {

        #We are still out of a packet
        die
"Wrong segment, we received Sequence flag $seqf while we expect 1 or 3\n"
          unless ( $seqf == FIRST or $seqf == STAND );
        if ( $seqf == FIRST ) {
            $state = IN;
        }
        else {

            #No segmentation, decode packet
            my $pstring2 = pack( qq{H*}, qq{$segments_data} );
            my $packet = $tcsourcepacket->parse($pstring2);
            print Dumper($packet);
            $segments_data = ();
        }
    }
}
