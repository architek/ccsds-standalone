#!perl -T

use Test::More tests => 5;
# 1 : compare crc with reference crc results from ccsds documents

use Ccsds;
use Ccsds::Utils qw(calc_crc verify_crc tm_verify_crc tm_verify_crc_bin patch_crc);

my $input="\x06\x00\x0c\xf0\x00\x04\x00\x55\x88\x73\xc9\x00\x00\x05\x21";
my $h_input=unpack('H*',$input);    # Ascii representation
my $e_crc=0x75FB;
my $be_crc=pack('n',$e_crc);        # Big Endian packed

is(   calc_crc( $input ) , $e_crc , "calc_crc($h_input) == " . unpack('H*',$be_crc)  );
ok(   verify_crc( $e_crc , $h_input ) , "verify_crc()"   );
ok(   tm_verify_crc( uc $h_input . lc unpack('H*',$be_crc) ) , "tm_verify_crc()"    );
#FIXME
ok(   tm_verify_crc_bin( $h_input . unpack('H*', $be_crc) ) , "tm_verify_crc_bin()"   );

my $input2=$input . "\xDE\xAD";
is(   unpack('H*', substr( patch_crc(\$input2),-2)) , unpack('H*',$e_crc), "patch_crc()"   );

diag( "Testing Crc Utils for Ccsds $Ccsds::VERSION, Perl $], $^X" );
