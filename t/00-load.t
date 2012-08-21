#!perl -T

use Test::More tests => 11;

BEGIN {
    use_ok( 'Ccsds' ) || print "Bail out!  ";
    use_ok( 'Ccsds::Common' ) || print "Bail out!  ";
    use_ok( 'Ccsds::Utils' ) || print "Bail out!  ";
    use_ok( 'Ccsds::StdTime' ) || print "Bail out!  ";
    use_ok( 'Ccsds::TM::File' ) || print "Bail out!  ";
    use_ok( 'Ccsds::TM::Frame' ) || print "Bail out!  ";
    use_ok( 'Ccsds::TM::SourcePacket' ) || print "Bail out!  ";
    use_ok( 'Ccsds::TC::SourcePacket' ) || print "Bail out!  ";
    use_ok( 'Ccsds::TC::Frame' ) || print "Bail out!  ";
    use_ok( 'Ccsds::TC::Printer' ) || print "Bail out!  ";
    use_ok( 'Ccsds::TC::File' ) || print "Bail out!  ";
}

diag( "Testing Ccsds Library loading $Ccsds::VERSION, Perl $], $^X" );
