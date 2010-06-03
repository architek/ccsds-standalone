#!/usr/bin/perl -w
#      Example of plugins
#===============================================================================

use strict;

# Modify packets on the fly
my $m_patch_obcp_hlc_number = sub {
    my ( $rdata, undef ) = @_;
    
    my $data=$rdata;
    my $decoded = tmsourcepacket($data);
    #Get important fields
    my $f_header = $decoded->{'TM Source Packet'}->{'Packet Header'}; 
    my $f_dfh    = $f_header->{'Packet Id'}->{'DFH Flag'};
    my $f_dataf  = $decoded->{'TM Source Packet'}->{'Packet Data Field'};
    my $f_data   = $f_dataf->{'Data Field'};
    return $rdata if defined $f_data->{'Time Packet'};

    #Get rest of fields
    my $f_pid        = $f_header->{'Packet Id'}->{'Apid'}->{'PID'};
    my $f_sec_header = $f_data->{'TMSourceSecondaryHeader'};
    my $f_pus_data   = $f_data->{'PusData'};
    my $f_pus_t      = $f_sec_header->{'Service Type'}; 
    my $f_pus_st     = $f_sec_header->{'Service SubType'};

    #Modify one data of service 18 subservice 131 ( pus_OBCP_dump ) 
    if ( $f_pus_t == 18 and $f_pus_st == 131 ) {
       my $proc_Id= $f_pus_data->{'Procedure Id'};
       my $N = $f_pus_data->{'Procedure Steps'};
       for(my $i=0;$i<$N;$i++) {
        my $cStep=$f_pus_data->{'Steps'}->[$i];
        my $cStepN=$cStep->{'Procedure Step'};
        print "Parsing step $cStepN of Procedure Id: $proc_Id\n";
        my $N = $f_pus_data->{'Procedure Steps'};
        my $cDelay=$cStep->{'Delay'};
        my $Tc=$cStep->{'Tc'};
        my $Tc_Data=$Tc->{'TC Application Data'};
        if ( $Tc_Data->[0]==8 &&
             $Tc_Data->[1]==1 &&
             $Tc_Data->[2]==37 &&   # Send HLC
             $Tc_Data->[3]==192 &&  # HLC_1
           ) {
             $Tc_Data->[4]++;       # Patch HLC Number
             #Rebuild TC
             my $mTC=$tcsourcepacket->build($Tc);
             substr( $mTC, -2 ) = pack( 'H*', calc_crc( substr( $mTC, 0, -2 ) ) );
             
             print "HLC in OBCP Found:\n"
             print "Procedure Id: $proc_Id\n";
             print "Procedure Step: $cStepN\n";
             print "Delay: $cDelay\n";
             print "New TC:" , unpack('H*',$mTC) , "\n";
        }
       }
    }

    return $rdata;
};

