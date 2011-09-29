#Sample customization for S3
#############################
package Ccsds::Custo;
use Data::ParseBinary;

our $has_crc=Value('Has Crc', 
    sub { 
      ( $_->ctx->{'Packet Header'}->{'Packet Id'}->{'Apid'} != 2047 &&
        $_->ctx->{'Packet Header'}->{'Packet Id'}->{'Apid'} != 29 
      ) ? 1 : 0 ;
    } 
);

1;
