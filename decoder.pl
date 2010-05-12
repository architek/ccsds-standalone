#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use Data::ParseBinary::Network::Ccsds::Utils qw(verify_crc tm_verify_crc);
use Data::ParseBinary::Network::Ccsds::TM::SourcePacket
  qw($tmsourcepacket $scos_tmsourcepacket);
use Data::ParseBinary::Network::Ccsds::TM::Printer qw(TMPrint $VERSION);

#Fields to convert in hex if dumper is used
my @tohex = ('Packet Error Control');

my $odebug   = 0;
my $odumper  = 0;
my $oshowver = 0;
my $opts     = GetOptions(
    'debug'   => \$odebug,     # do we want debug
    'dumper'  => \$odumper,    # do we want to use tmprint or internal dumper
    'version' => \$oshowver
);

die "Version $VERSION\n" if $oshowver;
$Data::ParseBinary::print_debug_info = 1 if $odebug;

$/ = '';                       # paragraph reads
my $nblocks = 0;
while (<STDIN>) {
    chomp;
    my $buf     = ();
    my $decoded = ();
    my $pstring = ();
    $nblocks++;
    print "BUF IS <$_>\n" if $odebug;

    #We only take ascii here
    die("What you gave looks binary to me..\n") unless /^[[:ascii:]]*$/;

    #Nothing to do if input is simple: no header, no space
    $buf = $_, goto DECODE if (/^[[:xdigit:]]*$/);
    my @lines = split(/\n/);

    #Remove the typical addresses on the left
    my $line = ();
    foreach (@lines) {
        next if /^#/;

        #Is everything on one line, without header and spaces
        s/^[[:xdigit:]]+[^[:xdigit:]]+(.+)$/$1/;
        $line = $1;
        $line =~ s/ //g;
        $buf .= $line;
    }
    print "BUF IS <$buf>\n" if $odebug;

    # DECODING starts here
  DECODE:
    $pstring = pack( qq{H*}, qq{$buf} );

    #first lets try on real tmsourcepacket
    if ( tm_verify_crc $buf) {
        $decoded = $tmsourcepacket->parse($pstring);
    }
    elsif ( tm_verify_crc substr $buf, 40 ) {

        #now lets try on scosheader+tmsourcepacket
        $decoded = $scos_tmsourcepacket->parse($pstring);
    }
    else {

        #try without crc, good luck
        print "Warning, Crc seems wrong!\n";
        $decoded = $tmsourcepacket->parse($pstring);
    }

    #Change fields to hex
    my $dumper = Dumper($decoded);
    foreach (@tohex) {
        $dumper =~ m/$_.*=>\s([[:alnum:]]*),/;
        my $hv = sprintf( "%#x", $1 );
        $dumper =~ s/$1/$hv/;
    }

    #  print '/' . '-' x 100 . "\n";
    if ($odumper) {
        print $dumper;
    }
    else {
        TMPrint($decoded);
    }

    #  print '\\' . '-' x 100 . "\n";
    print "/>\n";
    print "\n";
}
