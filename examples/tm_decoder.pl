#!/usr/bin/perl
use strict;
use warnings;

#Simplest example
#Take as input a packet log and decodes it, wether Scos TM or normal TM

use Getopt::Long;
use Data::Dumper;
use Ccsds qw($VERSION);
use Ccsds::Utils qw(verify_crc tm_verify_crc);
use Ccsds::TM::SourcePacket
  qw($TMSourcePacket $ScosTMSourcePacket);
use Ccsds::TM::Printer qw(TMPrint);

#Fields to convert in hex if dumper is used
my @tohex = ('Packet Error Control');

our $odebug   = 0;             
my $odumper  = 0;
my $oshowver = 0;

my $opts     = GetOptions(
    'debug'   => \$odebug,     # do we want debug
    'dumper'  => \$odumper,    # do we want to use tmprint or internal dumper
    'version' => \$oshowver
);

die "Using lib version $VERSION\n" if $oshowver;
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

    #Sanity check on input 
    die("There are non ASCII characters in your input\n") unless /^[[:ascii:]]*$/;

    #If input is simple: no header, no space then proceed to decoding
    $buf = $_, goto DECODE if (/^[[:xdigit:]]*$/);
    my @lines = split(/\n/);

    #Try to remove non ASCII characters as well as
    #The typical addresses on the left
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


  DECODE:
    $pstring = pack( qq{H*}, qq{$buf} );

    #first lets try on real tmsourcepacket
    if ( tm_verify_crc $buf) {
        $decoded = $TMSourcePacket->parse($pstring);
    }
    elsif ( tm_verify_crc substr $buf, 40 ) {

        #now lets try on scosheader+tmsourcepacket
        $decoded = $ScosTmSourcePacket->parse($pstring);
    }
    else {

        #Decode anyway
        print "Warning, Crc seems wrong!\n";
        $decoded = $TMSourcePacket->parse($pstring);
    }

    if ($odumper) {
        #Change fields to hex in the Dumper output
        my $dumper = Dumper($decoded);
        foreach (@tohex) {
           $dumper =~ m/$_.*=>\s([[:alnum:]]*),/;
           my $hv = sprintf( "%#x", $1 );
           $dumper =~ s/$1/$hv/;
           }
        print $dumper;
    }
    else {
        TMPrint($decoded);
    }

    print "/>\n";
}
