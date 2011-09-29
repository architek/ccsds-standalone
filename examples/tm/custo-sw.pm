#Sample customization for SW
############################
package Ccsds::Custo;
use Data::ParseBinary;
use Ccsds::StdTime;

our $Sat_Time= CDS(16,16,2000);

our $TMSourceSecondaryHeader = Struct('TMSourceSecondaryHeader',
  Value('Length',12),                                             ### 12 bytes
  BitStruct('SecHeadFirstField',                                  #1 byte
    BitField('Spare1',1), 
    BitField('PUS Version Number',3), 
    Nibble('Spare2')
  ),
  UBInt8('Service Type'),                                         #1 byte
  UBInt8('Service Subtype'),                                      #1 byte
  UBInt8('Sync Status'),                                          #1 byte
  $Sat_Time,                                                      #8 bytes
);

1;
