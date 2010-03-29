#!/usr/bin/perl
$/ = ''; # paragraph reads
while (<>) {
chomp;
#print "Block Detected \n<$_>\n";
$res=qx{echo "$_" | ./test3.pl 2>&1};
print $res;
}
