#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use Ccsds::Utils qw(tm_verify_crc);

use Ccsds::TM::SourcePacket qw($tmsourcepacket);
use Ccsds::TC::SourcePacket qw($tcsourcepacket);

use Ccsds::TM::Printer qw(TMPrint $VERSION);
use Ccsds::TC::Printer qw(TCPrint );

my @tohex = ('Packet Error Control');

our $odebug   = 0;             
my  $odumper  = 0;
my  $oshowver = 0;

my  $opts     = GetOptions(
    'debug'   => \$odebug,     # do we want debug
    'dumper'  => \$odumper,    # do we want to use tmprint or internal dumper
    'version' => \$oshowver
);

die "Version $VERSION\n" if $oshowver;
$Data::ParseBinary::print_debug_info = 1 if $odebug;

$|++;                          # autoflush stdout

my ( $nblocks, $nblocks_error, $is_tm) ;
while (<STDIN>) {
    next if /^\s+$/;
    chomp;

    my ($decoded, $pstring);
#print "Block " , ++$nblocks, "\n" if $odebug;
    print "Block " , ++$nblocks, "\n" ;
    
    #Sanity check on input 
    die("There are non ASCII characters in your input\n") unless /^[[:ascii:]]*$/;

    #Remove extra chars ( left adress part "XXXX : data" ) unless there are only hex digits
    s/^[[:xdigit:]]+[^[:xdigit:]]+(.+)$/$1/ unless (/^[[:xdigit:]]*$/);
    s/\s//g;

    print "BUF IS <$_>\n" if $odebug;
    $pstring = pack( qq{H*}, qq{$_} );

    #Decode potential tm
    if ( tm_verify_crc $_) {
        eval q( $decoded = $tmsourcepacket->parse($pstring) );
        if ($@) {
          $nblocks_error++;
          print "TM ERROR : Undecoded TM? (But Crc is correct)\n$@\n";
          next;
        }
        $is_tm=1;
    }
    else {
        #Decode tc
        eval q( $decoded = $tcsourcepacket->parse($pstring) );
        if ($@) {
          $nblocks_error++;
          print "TC ERROR : Undecoded TC?\n$@\n";
          next;
        }
        $is_tm=0;
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
        if ($is_tm) {
          TMPrint($decoded)
        } else { 
          TCPrint($decoded);
        }
    }

    print "/>\n";
}
print "Total TMTC Decoded: $nblocks, Total TMTC in error : $nblocks_error\n" if $odebug;
