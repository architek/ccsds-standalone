#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use Ccsds::Utils qw(decode_cltu_data);
use Ccsds::TC::Printer qw(TCPrint CltuPrint $VERSION);
use Ccsds::TC::Frame qw($Cltu $TCFrame);
use Ccsds::TC::SourcePacket qw($TCSourcePacket);

our $odebug   = 0;
my $odumper  = 0;
my $oshowver = 0;
my $opts     = GetOptions(
    'debug'   => \$odebug,     # do we want debug
    'dumper'  => \$odumper,    # do we want to use tmprint or internal dumper
    'version' => \$oshowver
);

use constant {
    FIRST => 1,              # For segment state machine
    CONT  => 0,              #
    LAST  => 2,              #
    STAND => 3,              #
    OUT   => 0,              #
    IN    => 1,              #
    FRAMEHEADER_LEN => 5,    # Header lengths  for packet extraction
    SEGMENTHEADER_LEN => 1   #
};

die "Version $VERSION\n" if $oshowver;

$Data::ParseBinary::print_debug_info = 1 if $odebug;
$/ = '';    # paragraph reads
$|++;       # autoflush stdout

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

        #Keep only digits ( no adress on the left is allowed! )
        s/[^[:xdigit:]]//g;
        $buf .= $_;
    }
    
  DECODE:

    CltuPrint($buf) if ($odebug);
    my $pstring = pack( qq{H*}, qq{$buf} );

#Decode the complete CLTU, incl. CBH
    my $cltu = $Cltu->parse($pstring);

#Print decoded cltu, but not the still undecoded part
    $cltu->{'Cltu Data'} = ();
    if ($odumper) {
      print Dumper($cltu) 
    } else {
      my $mapid  = $cltu->{'Segment Header'}->{'MapId'};
      my $bypass = $cltu->{'TC Frame Header'}->{'ByPass'};
      my $Scid   = $cltu->{'TC Frame Header'}->{'SpaceCraftId'};
      my $Vcid   = $cltu->{'TC Frame Header'}->{'Virtual Channel Id'};
      my $FLength= $cltu->{'TC Frame Header'}->{'Frame Length'};
      print "Decoded Frame and included Segment: MapId=$mapid, Bypass=$bypass, Scid=$Scid, Vcid=$Vcid, Frame Length=$FLength\n";
    }
    
    $buf =~s/....//;  # Remove EB90h 
    my $cltu_data = rs_deinterleaver( 7, $buf, $cltu->{'TC Frame Header'}->{'Frame Length'} + 1 ); #We use BCH Length 7
#we now have CLTU *data* , BCH removed


#State Machine for Segment handling
    my $seqf = $cltu->{'Segment Header'}->{'Sequence Flags'};
#Push segment datas = frameheader+segmentheader
    $segments_data .= substr( $cltu_data, ( FRAMEHEADER_LEN + SEGMENTHEADER_LEN ) * 2 ); 
    if ( $state == IN ) {

        #We are in a packet
        die
"Wrong segment, we received Sequence flag $seqf while we expect 0 or 2\n"
          unless ( $seqf == CONT or $seqf == LAST );
        next if ( $seqf == CONT );
        $state=OUT;
    } elsif ( $state == OUT ) {
        die
"Wrong segment, we received Sequence flag $seqf while we expect 1 or 3\n"
          unless ( $seqf == FIRST or $seqf == STAND );
        if ( $seqf == FIRST ) {
            $state = IN;
            next;
        }
    }

    #This is a STANDalone segment or LAST segment, decode the overall TC packet
    my $pstring2 = pack( qq{H*}, qq{$segments_data} );
    my $packet = $TCSourcePacket->parse($pstring2);

    if ($odumper) {
      print Dumper($packet);
    } else {
      print " ";
      TCPrint($packet);
    }
    $segments_data = ();

}
