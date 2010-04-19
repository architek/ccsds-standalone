#!/usr/bin/perl
use strict;
use warnings;

package CCSDS_Common;

use Digest::CRC qw(crcccitt);

sub verify_crc {
	(my $crc_in,my $data)=@_;
  $crc_in = lc $crc_in ;
 	my $sdata=pack("H*",$data);
	my $crc=crcccitt("$sdata");
	print 'Calculated Crc:' . sprintf('%x',$crc) . "\n" if $::mdebug;
	return $crc eq $crc_in;
}

sub tm_verify_crc {
	print 'Included Crc:' . substr($_[0],-4) . "\n" if $::mdebug;
#split string into data,crc
	(my $data, my $crc_in) =(substr($_[0] , 0, -4), hex substr ($_[0],-4));
	return verify_crc($crc_in,$data);
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(verify_crc tm_verify_crc);

1;

