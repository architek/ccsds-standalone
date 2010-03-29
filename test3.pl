#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Digest::CRC qw(crcccitt);


use TMSourcePacket; 
use TMPrinter; 
#$Data::ParseBinary::print_debug_info=1;

sub verify_crc {
	(my $data, my $crc_in) =(substr($_[0] , 0, -4), hex substr ($_[0],-4));
 	my $sdata=pack("H*",$data);
	my $crc=crcccitt("$sdata");
	return $crc eq $crc_in;
}

my $buf=();
my $decoded=();

{
local $/=undef;
$buf=<STDIN>;
}

my $scosTM=(exists $ARGV[0]);

if (!$scosTM) {
#Normal packet (beginning at TM Version number)
 $buf =~ s/^.....//gm;
 $buf =~ s/ |\n//g;
 die("Wrong Crc") unless verify_crc $buf;
# print "BUF IS <$buf>\n";

 my $pstring = pack (qq{H*},qq{$buf});
 $decoded=$tmsourcepacket_parser->parse($pstring);

} else {
#Is it a SCOS packet (scos headers+packet)
 $buf =~ s/^..........//gm;
 $buf =~ s/ |\n//g;
 #print "BUF IS <$buf>\n";
 die("Wrong Crc") unless verify_crc substr $buf,40;

 my $pstring = pack (qq{H*},qq{$buf});
 $decoded=$scos_tmsourcepacket_parser->parse($pstring);
}

#print Dumper($decoded);
TMPrint($decoded);
