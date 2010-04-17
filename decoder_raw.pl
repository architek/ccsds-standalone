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

#TODO integrate CRC as MAGIC in TMSourcePacket and loop on parsers

sub verify_crc {
	(my $crc_in,my $data)=@_;
  	$crc_in =~ tr/A-F/a-f/;
 	my $sdata=pack("H*",$data);
	my $crc=crcccitt("$sdata");
	print "Calculated Crc:" . sprintf("%x",$crc) . "\n" if $mdebug;
	return $crc eq $crc_in;
}

sub tm_verify_crc {
	print "Included Crc:" . substr($_[0],-4) . "\n" if $mdebug;
	(my $data, my $crc_in) =(substr($_[0] , 0, -4), hex substr ($_[0],-4));
	return verify_crc($crc_in,$data);
}

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
