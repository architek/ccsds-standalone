#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use TMSourcePacket; 
use TMPrinter; 
#$Data::ParseBinary::print_debug_info=1;

my $ibuf=();

{
local $/=undef;
$ibuf=<STDIN>;
}

eval {
 $my $buf=$ibuf;
#Is it a SCOS packet (scos headers+packet)
 $buf =~ s/^..........//gm;
 $buf =~ s/ |\n//g;
 #print "BUF IS <$buf>\n";

 my $pstring = pack (qq{H*},qq{$buf});
 my $decoded=$scos_tmsourcepacket_parser->parse($pstring);
} or do {
 #$@ non nul
#Or a normal packet (beginning at TM Version number)
 $my $buf=$ibuf;
 $buf =~ s/^...//gm;
 $buf =~ s/ |\n//g;
 #print "BUF IS <$buf>\n";

 my $pstring = pack (qq{H*},qq{$buf});
 my $decoded=$tmsourcepacket_parser->parse($pstring);
}


#print Dumper($decoded);
TMPrint($decoded);
