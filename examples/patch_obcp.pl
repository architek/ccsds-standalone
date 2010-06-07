#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use Data::ParseBinary::Network::Ccsds::Utils qw(verify_crc tm_verify_crc patch_crc);
use Data::ParseBinary::Network::Ccsds::TM::SourcePacket
  qw($tmsourcepacket $scos_tmsourcepacket);
use Data::ParseBinary::Network::Ccsds::TM::Printer qw(TMPrint $VERSION);
use Data::ParseBinary::Network::Ccsds::TC::SourcePacket qw($tcsourcepacket);

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
        $decoded = $tmsourcepacket->parse($pstring);
    }
    elsif ( tm_verify_crc substr $buf, 40 ) {

        #now lets try on scosheader+tmsourcepacket
        $decoded = $scos_tmsourcepacket->parse($pstring);
    }
    else {

        #Decode anyway
        print "Warning, Crc seems wrong!\n";
        $decoded = $tmsourcepacket->parse($pstring);
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
#        TMPrint($decoded);
    }

    #Get important fields
    my $header = $decoded->{'Packet Header'};
    my $dataf  = $decoded->{'Packet Data Field'};
    my $data   = $dataf->{'Data Field'};
    #Return if packet contain no data (time packet,..)

    #Get rest of fields
    my $pid        = $header->{'Packet Id'}->{'Apid'}->{'PID'};
    my $sec_header = $data->{'TMSourceSecondaryHeader'};
    my $pus_data   = $data->{'PusData'};
    my $pus_t      = $sec_header->{'Service Type'};
    my $pus_st     = $sec_header->{'Service Subtype'};

    print "$pus_t, $pus_st\n";

    #Modify service 18 subservice 131 ( pus_OBCP_dump )
    if ( join( ',', $pus_t, $pus_st ) eq '18,131' ) {
        my $proc_Id = $pus_data->{'Procedure Id'};
        my $N       = $pus_data->{'Procedure Steps'};

        for ( my $i = 0 ; $i < $N ; $i++ ) {

            my $cStep  = $pus_data->{'Steps'}->[$i];
            my $cStepN = $cStep->{'Procedure Step'};

            print "Parsing step $cStepN of Procedure Id: $proc_Id\n";
            my $cDelay  = $cStep->{'Delay'};
            my $Tc      = $cStep->{'TC Source Packet'};
            my $Tc_Data = $Tc->{'Packet Data Field'}->{'TC Data'};

            if (
                   $Tc_Data->[0] == 37
                && $Tc_Data->[1] == 0
                && $Tc_Data->[2] == 192
              )
            {
#                print "Old TC:" , @$Tc_Data , "\n";

                print " HLC in OBCP Found:\n Delay: $cDelay\n";

                #Modify TC included
                $Tc_Data->[3]--;           # Patch HLC Number
                                           #Rebuild TC
                my $mTC = $tcsourcepacket->build($Tc);
                patch_crc(\$mTC);

                print " New TC:", unpack( 'H*', $mTC ), "\n";
            }
        }
    }




    print "/>\n";
}
