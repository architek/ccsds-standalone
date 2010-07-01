#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use Ccsds::Utils qw(verify_crc tm_verify_crc);
use Ccsds::TC::Frame
  qw($Cltu $TCFrame);
use Ccsds::TC::SourcePacket
  qw($tcsourcepacket);

my $odebug   = 0;
my $odumper  = 0;
my $oshowver = 0;
my $opts     = GetOptions(
    'debug'   => \$odebug,     # do we want debug
    'dumper'  => \$odumper,    # do we want to use tmprint or internal dumper
    'version' => \$oshowver
);

sub remove_cbh {
  my $odata;
  my $offset=0;
  (my $idata, my $fl) = @_;
  
  while($fl>0) {
    my $l=7;
    $l=$fl if ($fl<7) ;
  
    $odata.=substr($idata,$offset,$l*2);
    $offset+=16;
    $fl-=7;
  }
 
 print "    " . $idata . "\n" if $odebug;
 print  "    " . $odata . "\n" if $odebug;
 return $odata;
}

$Data::ParseBinary::print_debug_info = 1 if $odebug;

$/ = '';                       # paragraph reads
my $nblocks = 0;
while (<STDIN>) {
    chomp;
    my $buf     = ();
    my $pstring = ();
    $nblocks++;
    print "BUF IS <$_>\n" if $odebug;

    #Sanity check on input 
    die("There are non ASCII characters in your input\n") unless /^[[:ascii:]]*$/;

    #If input is simple: no header, no space then proceed to decoding
    $buf = $_, goto DECODE if (/^[[:xdigit:]]*$/);
    my @lines = split(/\n/);

    #Try to remove non ASCII characters as well as
    #The typical addresses on the left
    my $line = ();
    foreach (@lines) {
        next if /^#/;
        #Is everything on one line, without header and spaces
        s/[^[:xdigit:]]//g;
        $buf .= $_
    }
    if ($odebug) {
       print "\n";
       print "SSSS" . "FHFHFHFHFHSH" . "╭╮╳╳" . "╭╮╭╮╭╮╭╮╭╮╭╮╭╮╳╳" x 3 . "\n";
       print "$buf\n" ;
    }
  DECODE:
    $pstring = pack( qq{H*}, qq{$buf} );

    #Decode the complete CLTU, incl. CBH
    my $cltu=$Cltu->parse($pstring);
    #After this we now have CLTU *data* without CBH
    my $cltu_clean=remove_cbh(substr($buf,4),$cltu->{'TC Frame Header'}->{'Frame Length'}+1);
   
#We remove this from the output
    $cltu->{'Cltu Data'}=();
    print Dumper($cltu);

#We currently only handle standalone segment (1 packet not split into several segment)
    return unless $cltu->{'Segment Header'}->{'Sequence Flags'} eq 3; 

#Packet is at start + frameheader+segmentheader
    my $pkt=substr($cltu_clean,(5+1)*2);
    print $pkt if $odebug;
    
    #decode the contained packet
    my $pstring2 = pack( qq{H*}, qq{$pkt} );
    my $packet=$tcsourcepacket->parse($pstring2);

    print Dumper($packet);
}
