#Sample customization for GIO
#############################
package Ccsds::Custo;
use Ccsds::StdTime;
use Data::ParseBinary;

our $TMSourceSecondaryHeader = Struct('TMSourceSecondaryHeader',  ### 10 bytes
  BitStruct('SecHeadFirstField',                                  #1 byte
    BitField('Spare1',1),
    BitField('PUS Version Number',3),
    Nibble('Spare2')
  ),
  UBInt8('Service Type'),                                         #1 byte
  UBInt8('Service Subtype'),                                      #1 byte
  UBInt8('Destination Id'),                                       #1 byte
  CUC(4,2),                                                       #6 bytes
  Value('Length',10),
);

1;
