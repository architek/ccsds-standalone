#!perl -T

use Test::More tests => 8;

BEGIN {
    use_ok( 'Data::ParseBinary::Network::Ccsds' ) || print "Bail out!
";
    use_ok( 'Data::ParseBinary::Network::Ccsds::TM::SourcePacket' ) || print "Bail out!
";
    use_ok( 'Data::ParseBinary::Network::Ccsds::TM::Printer' ) || print "Bail out!
";
    use_ok( 'Data::ParseBinary::Network::Ccsds::Common' ) || print "Bail out!
";
    use_ok( 'Data::ParseBinary::Network::Ccsds::TM::Pus' ) || print "Bail out!
";
    use_ok( 'Data::ParseBinary::Network::Ccsds::TM::RM' ) || print "Bail out!
";
    use_ok( 'Data::ParseBinary::Network::Ccsds::TM::SGM' ) || print "Bail out!
";
    use_ok( 'Data::ParseBinary::Network::Ccsds::Utils' ) || print "Bail out!
";
}

diag( "Testing Data::ParseBinary::Network::Ccsds $Data::ParseBinary::Network::Ccsds::VERSION, Perl $], $^X" );
