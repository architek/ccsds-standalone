#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Digest::CRC qw(crcccitt);


use TMSourcePacket qw($tmsourcepacket_parser $scos_tmsourcepacket_parser); 
use TMPrinter; 
#$Data::ParseBinary::print_debug_info=1;

#TODO integrate CRC as MAGIC in TMSourcePacket and loop on parsers

#TODO change this to get correct parameters
sub verify_crc {
#	(my $crc_in,my $data)=@_;
	(my $data, my $crc_in) =(substr($_[0] , 0, -4), hex substr ($_[0],-4));
 	my $sdata=pack("H*",$data);
	my $crc=crcccitt("$sdata");
	return $crc eq $crc_in;
}

my $buf=();
my $decoded=();
my $pstring=();

#Remove the typical addresses on the left
my $line=(); 
while (<STDIN>) {
	s/^[[:xdigit:]]+[^[:xdigit:]]+(.+)$/$1/;
#split /[\s:]+/, "00000:61 38 AA 4B B4 F8 00 00 96 01", 2 )[1]
 	$line=$1;
	$line =~ s/ //g;
	$buf=$buf.$line;
}
#print "BUF IS <$buf>\n";

$pstring = pack (qq{H*},qq{$buf});

#first lets try on real tmsourcepacket 
if (verify_crc $buf) {
	$decoded=$tmsourcepacket_parser->parse($pstring);
} 
elsif (verify_crc substr $buf,40) {
#now lets try on scosheader+tmsourcepacket
	$decoded=$scos_tmsourcepacket_parser->parse($pstring);
} else {
#not recognized
die("Crc check failed, neither a correct TMSourcepacket nor a correct ScosHeader+TMSourcePacket"); 
} 

#print Dumper($decoded);
TMPrint($decoded);
