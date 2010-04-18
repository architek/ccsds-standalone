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

$/ = ''; # paragraph reads
while (<STDIN>) {
  chomp;
  my $buf=();
  my $decoded=();
  my $pstring=();
  $nblocks++;
  
  print "BUF IS <$_>\n" if $mdebug;
  my @lines=split(/\n/);

  #Remove the typical addresses on the left
  my $line=(); 
  foreach (@lines) {
	next if /^#/;
	s/^[[:xdigit:]]+[^[:xdigit:]]+(.+)$/$1/;
#split /[\s:]+/, "00000:61 38 AA 4B B4 F8 00 00 96 01", 2 )[1]
 	$line=$1;
	$line =~ s/ //g;
	$buf=$buf.$line;
  }
  print "BUF IS <$buf>\n" if $mdebug;

  $pstring = pack (qq{H*},qq{$buf});

  #first lets try on real tmsourcepacket 
  if (tm_verify_crc $buf) {
	$decoded=$tmsourcepacket_parser->parse($pstring);
  } 
  elsif (tm_verify_crc substr $buf,40) {
  #now lets try on scosheader+tmsourcepacket
	$decoded=$scos_tmsourcepacket_parser->parse($pstring);
  } else {
  #not recognized
  	die("Crc check failed at block $nblocks, neither a correct TMSourcepacket nor a correct ScosHeader+TMSourcePacket"); 
  } 

#  print "/" . "-" x 100 . "\n";
#  print Dumper($decoded);
  TMPrint($decoded);
#  print "\\" . "-" x 100 . "\n";
  print "\n";
}
