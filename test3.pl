#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Digest::CRC qw(crc32 crc16 crcccitt crc8);


use TMSourcePacket; 
use TMPrinter; 
#$Data::ParseBinary::print_debug_info=1;

my $buf=();
my $decoded=();

{
local $/=undef;
$buf=<STDIN>;
}

my $scosTM=0;
$scosTM=(exists $ARGV[0]);


if (!$scosTM) {
 #$@ non nul
#Or a normal packet (beginning at TM Version number)
 $buf =~ s/^.....//gm;
 $buf =~ s/ |\n//g;
 
# print "BUF IS <$buf>\n";
# my $bufC=substr $buf,0,-4;
# my $crc = crcccitt($bufC);
# print $crc . "\n";
 

 my $pstring = pack (qq{H*},qq{$buf});
 $decoded=$tmsourcepacket_parser->parse($pstring);

} else {
#Is it a SCOS packet (scos headers+packet)
 $buf =~ s/^..........//gm;
 $buf =~ s/ |\n//g;
 #print "BUF IS <$buf>\n";

 my $pstring = pack (qq{H*},qq{$buf});
 $decoded=$scos_tmsourcepacket_parser->parse($pstring);
}

#print Dumper($decoded);
TMPrint($decoded);
