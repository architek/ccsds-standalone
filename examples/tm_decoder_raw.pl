#!/usr/bin/perl
use strict;
use warnings;

#Take as input a binary log of contiguous packets and decodes included TM Source Packets.

use Data::Dumper;
use Ccsds::Utils qw(verify_crc tm_verify_crc);
use Ccsds::TM::SourcePacket qw($TMSourcePacket);
use Ccsds::TM::Printer;

my $mdebug = 0;
$mdebug                              = 1 if exists $ARGV[0];
$Data::ParseBinary::print_debug_info = 1 if exists $ARGV[0];

while (1) {
    my $raw     = ();
    my $decoded = ();
    my $pstring = ();
    die @_ if ( sysread( STDIN, $raw, 6 ) != 6 );
    my $length = 1 + hex unpack( 'H*', substr $raw, 4, 6 );
    die @_ if ( sysread( STDIN, $raw, $length, 6 ) != $length );
    my $buf = unpack( 'H*', $raw );

    print "Buffer :$buf\n";

    $decoded = $TMSourcePacket->parse($raw);
    
    print '/' . '-' x 100 . "\n";
    print Dumper($decoded);

    #TMPrint($decoded);
    print '\\' . '-' x 100 . "\n";
    print "\n";
}
