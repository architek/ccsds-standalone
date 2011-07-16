package Ccsds::TM::Printer;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::Printer - Simple printer for decoding CCSDS TM Source Packets

=cut

use Switch;
use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 3;

sub TMPrint {

  my ($tm) = shift;
  
  my $Src_Packet=$tm;
  if (exists $tm->{'TM Source Packet'}) {
  # Then $tm is a scos packet, and we go directly to the TM Packet
    $Src_Packet=$tm->{'TM Source Packet'};
  }
  my $Pkt_Data=$Src_Packet->{'Packet Data Field'}->{'Data Field'};
  my $Pus_Header=$Pkt_Data->{'TMSourceSecondaryHeader'};
  
  my $OBT=${$Pus_Header->{'Sat_Time'}}{'OBT'};
  my $Pus_Type=$Pus_Header->{'Service Type'};
  my $Pus_SubType=$Pus_Header->{'Service Subtype'};
  
  my $Pus_Data=$Pkt_Data->{'PusData'};

  if (defined(my $Time_Packet=$Src_Packet->{'Packet Data Field'}->{'Time Packet'})) {
    print "TM Time ", Dumper($Time_Packet);
    return;
  }
  print "TM PUS($Pus_Type,$Pus_SubType)\t";
  printf "OBT=%10.3f\t", $OBT;
  switch ( join(',',$Pus_Type,$Pus_SubType) ){
    case /3,10|3,12/ {
      my $SID=$Pus_Data->{'Sid'};
      my $Col=$Pus_Data->{'Collection Interval'};
      my $Status=$Pus_Data->{'Status'};
      my $NPar=$Pus_Data->{'NPar'};
      my $Params=$Pus_Data->{'ParamId'};
      print "HK/Diag Report Definition  Sid=$SID  ColInt=$Col  Status=$Status  NPar=$NPar\n";
       print "Params=\n" . Dumper($Params) if ($NPar);
    }
    case '5,132' {
      my $NEid=$Pus_Data->{'NEid'};
      my $Eids=$Pus_Data->{'Eids'};
      #$Data::Dumper::Indent = 2;
       print "Enabled Events  NEids=$NEid\n";
      print "EIDs=\n" . Dumper($Eids) if ($NEid);
    }
    case '6,6' {
      my $MemId=$Pus_Data->{'Memory Id'};
      my $StartAddress=$Pus_Data->{'Start Address'};
      my $Length=$Pus_Data->{'Length'};
      my $dta=$Pus_Data->{'Data'};
      print "Memory Id:$MemId  StartAddress:" . sprintf('%08x',$StartAddress) . "  Length: $Length Data:\n";
      my $l=32;
      for(my $i=0;$i<$Length;$i+=$l){
        my $j=$i+$l-1; $j=$Length-1 if ($j>$Length-1);
        print sprintf('%08x : ',$i). join(' ',  map { sprintf '%02X',$_} @$dta[$i..$j]) . "\n";  
      }
    }
    case '8,140' {
      my $FID=$Pus_Data->{'Function Id'};
      print "Function ID=$FID  ";  
      my $Function_Data=$Pus_Data->{'Data'};
      switch ($FID) {
         case 103 {
          my $Ptr=$Function_Data->{'Pointer'};
          my $Entry=$Function_Data->{'RMLogEntry'};
          print "RM Log  Pointer:$Ptr\n";
          my $i=0;
          for(;(my $cTimeStamp=(my $cEntry=$$Entry[$i])->{'TimeStamp'})!=0;$i++) {
            print '-' x 48 ."\n              Entry $i at ". sprintf('%07f',$cTimeStamp)."s          \n".'-' x 48 . "\n";
            my $cSts=$cEntry->{'Status Input'};
            my $cCond=$cEntry->{'Conditioned Alarm'};
            my $cAtmp=$cEntry->{'Attempt index'};
            my $cPat=$cEntry->{'Pattern No'};

            my @mkeys_s=('au', 'auRed', 'tmEnc', 'pmAct', 'wd', 'rm', 'rmRed', 'buttrRed', 
                'pmBit1', 'sdram', 'pmA', 'pmB', 'pmBit0', 'eeprom');
            my $sts_print='';
            foreach my $mkey_s (@mkeys_s) {     # We print either " +XX" or the same number of spaces
              $sts_print.=($cEntry->{$mkey_s})?' +PMBact':' +PMAact',next if ($mkey_s eq 'pmAct');
              $sts_print.=($cEntry->{$mkey_s})?" +$mkey_s":' ' x (2+length($mkey_s));
            }

            my @mkeys_c=( 'WDA', 'WDB', 'EPA', 'EPB', 'BatA', 'BatB', 'Thr', 'SunLoss', 
                  'TempCtl', 'PMAhw', 'PMAall', 'PMAuv', 'PMAsw', 'PMBhw', 'PMBall', 
                  'PMBuv', 'PMBsw', 'SelPM', 'Sep1', 'Sep2', 'Sep3', 'WDen');
            my $cond_print='';
            foreach my $mkey_c (@mkeys_c) {
              $cond_print.=($cEntry->{$mkey_c})?' +SelPMB':' +SelPMA',next if ($mkey_c eq 'SelPM');
              $cond_print.=" +$mkey_c" if $cEntry->{$mkey_c};
            }

            print 'Pattern No        :      '. sprintf('%04d',$cPat) . "\n";
            print 'Status Input      :0x'. sprintf('%08x',$cSts) . " $sts_print\n";
            print 'Conditionned Alarm:  0x'. sprintf('%06x',$cCond) . " $cond_print\n";
            print 'Attempt Index     :  '. sprintf('%8d',$cAtmp) . "\n";
          }
          print '-' x 48 . "\n" if ($i);
        }
        else { print "Undecoded Function\n" . Dumper($Function_Data); }
      }
    }
    case '8,141' {
      my $FID=$Pus_Data->{'Function Id'};
      my $NrCurSlice=$Pus_Data->{'Nr Current Slice'};
      my $TotSlice=$Pus_Data->{'Total Slice'};
      my $Length=$Pus_Data->{'Length'};
      print "Sliced Function Report : Function ID=$FID  Slice:$NrCurSlice/$TotSlice Length of Datas:$Length\n";
      my $dta=$Pus_Data->{'Data'};
      if ($FID==152) {
        print Dumper($dta);
      } else {
      for(my $i=0;$i<$Length;$i+=32){
        my $j=$i+31; $j=$Length-1 if ($j>$Length-1);
        print sprintf('%08x : ',$i). join(' ',  map { sprintf '%02X',$_} @$dta[$i..$j]) . "\n";  
      }
      }
    }
    case '11,19' {
      my $N=$Pus_Data->{'N'};
      print "NParam=$N\n";
      for(my $i=0;$i<$N;$i++) {
        my $cSts=$Pus_Data->{'Status'}->[$i];
        my $PID=$cSts->{'Pidb'}->{'PID'};
        my $Status=$cSts->{'Status'};
        print sprintf('%12s',$PID)."  Status=$Status\n";
      }
    }
    case '12,11' {
      my $N=$Pus_Data->{'N'};
      print "NParam=$N\n";
      for(my $i=0;$i<$N;$i++) {
#TODO        my $cLimit=$$Pus_Data->
        my $ParamId=$Pus_Data->{'ParamId'};
        my $Mask=$Pus_Data->{'Mask'};
        my $ParamValue=$Pus_Data->{'Parameter Value'};
        my $LimCrossed=$Pus_Data->{'Limit crossed'};
        my $PrevCheckSts=$Pus_Data->{'Previous Checking Status'};
        my $CurCheckSts=$Pus_Data->{'Current Checking Status'};
        my $Time=${$Pus_Data->{'Sat_Time'}}{'OBT'};
        print "ParamId=$ParamId  Mask=$Mask  Param Value=$ParamValue  Limit crossed=$LimCrossed  Previous Chk Status=$PrevCheckSts  Current Chk Status=$CurCheckSts  OBT=$OBT\n";
      }
    }
    case '14,4' {
      my $N1=$Pus_Data->{'N1'};
      print "Number of TM Source(N1)=$N1\n";
      for(my $i=0;$i<$N1;$i++) {
        my $cTM=$Pus_Data->{'TMSourcePacket'}->[$i];
        my $PID=$cTM->{'Pidb'}->{'PID'};
        my $FStat=$cTM->{'FStat'};
        my $N2=$cTM->{'N2'};
        print sprintf('%12s',$PID)."  FStat=$FStat  Number of Type(N2)=$N2\n";
        for(my $j=0;$j<$N2;$j++) {
          my $cLType=$cTM->{'Types'}->[$j];
          my $Type=$cLType->{'Type'};
          my $TFStat=$cLType->{'FStat'};
          my $N3=$cLType->{'N3'};
          print "\tType=$Type  FStat=$TFStat  Number of SubType(N3)=$N3\n";
          for(my $k=0;$k<$N3;$k++) {
            my $cLSubType=$cLType->{'SubTypes'}->[$k];
            my $SubType=$cLSubType->{'SubType'};
            my $STFStat=$cLSubType->{'FStat'};
            print "\t\tSubType=$SubType  FStat=$STFStat \n";
          }
        }
      }
    }
    case '14,8' {
      my $N1=$Pus_Data->{'N1'};
      print "Number of Pids(N1)=$N1\n";
      for(my $i=0;$i<$N1;$i++) {
        my $cPid=$Pus_Data->{'Pids'}->[$i];
        my $PID=$cPid->{'Pidb'}->{'PID'};
        my $N2=$cPid->{'N2'};
        print sprintf('%12s',$PID)."  Number of Sids(N2)=$N2\n";
        for(my $j=0;$j<$N2;$j++) {
          my $cSid=$cPid->{'Sids'}->[$j];
          my $SID=$cSid->{'SID'};
          my $FStat=$cSid->{'FStat'};
          print "\t\tSID=$SID  FStat=$FStat\n";
        }
      }
    }
    case '15,6' {
      my $N1=$Pus_Data->{'N1'};
      print "Number of Pids(N1)=$N1\n";
      for(my $i=0;$i<$N1;$i++) {
        my $cTM=$Pus_Data->{'Pids'}->[$i];
        my $PID=$cTM->{'Pidb'}->{'PID'};
        my $StoreId1=$cTM->{'StoreId1'};
        my $N2=$cTM->{'N2'};
        print sprintf('%12s',$PID)."  StoreId1=$StoreId1  Number of Type(N2)=$N2\n";
        for(my $j=0;$j<$N2;$j++) {
          my $cLType=$cTM->{'Types'}->[$j];
          my $Type=$cLType->{'Type'};
          my $StoreId2=$cLType->{'StoreId2'};
          my $N3=$cLType->{'N3'};
          print "\t\tType=$Type  StoreId2=$StoreId2  Number of SubType(N3)=$N3\n";
          for(my $k=0;$k<$N3;$k++) {
            my $cLSubType=$cLType->{'SubTypes'}->[$k];
            my $SubType=$cLSubType->{'SubType'};
            my $StoreId3=$cLSubType->{'StoreId3'};
            print "\t\t\t   SubType=$SubType  StoreId3=$StoreId3 \n";
          }
        }
      }
      
    }
    case '15,13' {
      my $N=$Pus_Data->{'N'};
      print "Number of Stores=$N\n";
      for(my $i=0;$i<$N;$i++) {
        my $cStore=$Pus_Data->{'Stores'}->[$i];
        my $cStoreId=$cStore->{'StoreId'};
        my $cStoreTime1=$cStore->{'Storage Time1'};
        my $cStoreTime2=$cStore->{'Storage Time2'};
        my $cPercent=$cStore->{'Percentage filled'};
        print "StoreId $cStoreId  Time:[${cStoreTime1}s .. ${cStoreTime2}s]  Filled: $cPercent%\n";
      }
    }
    case '19,7' {
      my $N=$Pus_Data->{'N'};
      print "NParam=$N\n";
      $Data::Dumper::Indent = 2;
      for(my $i=0;$i<$N;$i++) {
        my $TC=$Pus_Data->{'TC'}->[$i];
        my $PID=$TC->{'Pidb'}->{'PID'};
        my $EID=$TC->{'EID'};
        my $ActSts=$TC->{'Action Status'};
        my $Ccs_TC=$TC->{'Tc'};
        my $TCSecH=$Ccs_TC->{'TCSourceSecondaryHeader'};
        my $TCType=$TCSecH->{'Service Type'};
        my $TCSubType=$TCSecH->{'Service Subtype'};
        print "PID=$PID  EID=$EID  Action Status=$ActSts\n";
        print "TC PUS($TCType,$TCSubType)  Data:\n" . Dumper($TC->{'Tc'}->{'TC Application Data'});
      }
    }
    else { print "Undecoded Type/SubType\n" . Dumper($Pus_Data); }
  }
#  print "\n";
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(TMPrint);

=head1 SYNOPSIS

Quick summary of what the module does.

    use Ccsds::TM::Printer;

    my $decoded = Ccsds::TM::$tmsourcepacket->parse($pstring);
    Ccsds::TM::TMPrint($decoded);

    ...

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::TM::Printer


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Ccsds::TM::Printer
