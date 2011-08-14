use warnings;
use strict;
use Test::More tests=>2;
use Data::Dumper;
use FindBin ();
use lib "$FindBin::Bin";

#Reference data to check against
#This also sets a default customization
my $datas="t/ref1.pm";
plan skip_all => "You need reference datas in $datas" unless ( -f $datas ) ;
use ref1;

use Ccsds;
use Ccsds::TM::SourcePacket qw($TMSourcePacket $TMSourcePacketHeader $TMSourceSecondaryHeader $ScosTMSourcePacket);
use Fcntl ':mode';

my ( $tmp , $b_tmp);
$b_tmp = pack( 'H*' , $ref1::tmp );

#Packets
eval { $tmp = $TMSourcePacket->parse( $b_tmp ); };
ok ( %$tmp ~~ %$ref1::r_tmp );

#Header
eval { $tmp = $TMSourcePacketHeader->parse( $b_tmp ); };
ok ( %$tmp ~~ %$ref1::r_tmph );

done_testing($2);
diag( "Testing Ccsds Decoding $Ccsds::VERSION, Perl $], $^X" );
