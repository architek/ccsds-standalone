#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Digest::CRC qw(crcccitt);


use TMSourcePacket qw($tmsourcepacket_parser $scos_tmsourcepacket_parser); 
use TMPrinter; 

my $mdebug=0;
my $nblocks=0;
$mdebug=1 if exists $ARGV[0];

$Data::ParseBinary::print_debug_info=1 if exists $ARGV[0];

while (1) {
  my $raw=();
  my $decoded=();
  my $pstring=();
  die @_ if (sysread(STDIN,$raw,6)!=6);
  my $length=1+hex unpack("H*",substr $raw,4,6);
  die @_ if (sysread(STDIN,$raw,$length,6)!=$length);
  my $buf=unpack("H*",$raw);
  $nblocks++;
  
  print "Buffer :$buf\n";
  #first lets try on real tmsourcepacket 
  if (tm_verify_crc $buf) {
        $decoded=$tmsourcepacket_parser->parse($raw);
  } else {
	print "Buffer is not SourcePacket:$buf";
  }
  print "/" . "-" x 100 . "\n";
  print Dumper($decoded);
  #TMPrint($decoded);
  print "\\" . "-" x 100 . "\n";
  print "\n";
}
