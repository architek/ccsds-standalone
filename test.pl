#!/usr/bin/perl
use Data::Dumper;
use TMSourcePacket; 
use TMPrinter; 
use strict;
#$Data::ParseBinary::print_debug_info=1;

my $buf=();

{
local $/=undef;
$buf=<STDIN>;
}

$buf =~ s/^.....//gm;
$buf =~ s/ |\n//g;

#print "BUF IS <$buf>\n";
my $pstring = pack (qq{H*},qq{$buf});
my $decoded=$tmsourcepacket_parser->parse($pstring);
#print Dumper($decoded);
TMPrint($decoded);
