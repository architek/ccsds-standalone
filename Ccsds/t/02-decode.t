use warnings;
use strict;
use Test::More tests=>2;
use Data::Dumper;
use FindBin ();
use lib "$FindBin::Bin";

#Reference data to check against - This also sets a default customization
use ref1;

use Ccsds;
use Ccsds::TM::SourcePacket qw($TMSourcePacket $TMSourcePacketHeader $TMSourceSecondaryHeader $ScosTMSourcePacket);
use Fcntl ':mode';

my ( $tmp , $b_tmp);
$b_tmp = pack( 'H*' , $ref1::tmp );

#Header
eval { $tmp = $TMSourcePacketHeader->parse( $b_tmp ); };
is_deeply (   $tmp , $ref1::r_tmph , "Packet Header decoding");

#Packet
eval { $tmp = $TMSourcePacket->parse( $b_tmp ); };
print Dumper($tmp);
is_deeply (   $tmp , $ref1::r_tmp  , "Packet decoding" );

done_testing($2);
diag( "Testing Ccsds Decoding $Ccsds::VERSION, Perl $], $^X" );
