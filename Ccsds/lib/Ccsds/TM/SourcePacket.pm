package Ccsds::TM::SourcePacket;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::SourcePacket - Decoding Ccsds TM SourcePackets!

=cut

use Data::ParseBinary;

use Ccsds::Common;
use Ccsds::StdTime;
use Ccsds::TM::Pus;
use Ccsds::TM::RM;

our $TMSourceSecondaryHeader = 
 $Ccsds::Custo::TMSourceSecondaryHeader || Struct('TMSourceSecondaryHeader',   ### 12 bytes
  Value('Length',12),
  BitStruct('SecHeadFirstField',                                  #1 byte
    BitField('Spare1',1),
    BitField('PUS Version Number',3),
    Nibble('Spare2')
  ),
  UBInt8('Service Type'),                                         #1 byte
  UBInt8('Service Subtype'),                                      #1 byte
  UBInt8('Destination Id'),                                       #1 byte
  $Ccsds::Custo::Sat_Time || CUC(4,3),                            #7 bytes
  UBInt8('Time Quality'),                                         #1 byte
);

#Exported in case for detecting non data packets: time, idle
our $TMSourcePacketHeader=
  Struct('Packet Header',                                                       ### 6 bytes
        BitStruct('Packet Id',                                    #5+11 bits
          BitField('Version Number',3),
          BitField('Type',1),
          Flag('DFH Flag'),
          BitField('Apid',11),
        ),
        BitStruct('Packet Sequence Control',                      #16+16 bits
          BitField('Segmentation Flags',2),
          BitField('Source Seq Count',14),
          UBInt16('Packet Length'),
        )
);

sub source_data_length {
    my $sdl;
    $sdl= $_->ctx(1)->{'Packet Header'}->{'Packet Sequence Control'}->{'Packet Length'} +1 -2 ;
    if ( $_->ctx(1)->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'} ) {
        $sdl -= $_->ctx->{'TMSourceSecondaryHeader'}->{'Length'} ;
    }
    return $sdl;
}

#TODO Time Packet
our $TMSourcePacket = Struct('TM Source Packet',

  $TMSourcePacketHeader,
  Struct('Packet Data Field',
      If ( sub { $_->ctx(1)->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'} },
          $TMSourceSecondaryHeader,
      ),
      Array(\&source_data_length,UBInt8('Source Data')),
      UBInt16('Packet Error Control'),          #Can be optionnal
  ),
);

our $ScosTMSourcePacket = Struct('Scos TM Source Packet',
  Array(20,UBInt8('Scos Header')),
  $TMSourcePacket
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($TMSourcePacket $TMSourcePacketHeader $TMSourceSecondaryHeader $ScosTMSourcePacket);

=head1 SYNOPSIS

Quick summary of what the module does.

    use Ccsds::TM::SourcePacket;

    $input=<STDIN>;
    die("There are non ASCII characters in your input\n") unless /^[[:ascii:]]*$/;
    #convert input to binary
    $pstring = pack( qq{H*}, qq{$input} );
    print "Warning: The CRC is incorrect, decoding anyway\n" unless ( tm_verify_crc $buf) ;

    my $foo = Ccsds::TM::SourcePacket::$TMSourcePacket->parse($pstring);
    ...

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::TM::SourcePacket


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Ccsds::TM::SourcePacket
