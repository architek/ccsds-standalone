#!/usr/bin/perl
$/ = ''; # paragraph reads
while (<>) {
chomp;
#print "Block Detected \n<$_>\n";
$res=qx{echo "$_" | ./test.pl 2>&1};
print $res;
}
