package Ccsds::TC::SourcePacket;

use warnings;
use strict;

=head1 NAME

Ccsds::TC::SourcePacket - Decoding/Encoding of TC Source Packets

=cut

use Data::ParseBinary;

use Ccsds::Common;

#TODO Customization (does CCSDS allows custo of this header? Probably for example encryption header)
our $TCSourceSecondaryHeader = Struct('TCSourceSecondaryHeader',       #32 bits
  BitStruct('SecHeadFirstField',
    BitField('Spare1',1),
    BitField('PUS Version Number',3),
    Nibble('TC Ack Flags')
  ),
  UBInt8('Service Type'),
  UBInt8('Service Subtype'),
  UBInt8('Source Id'),
);

#TODO Source Data Length depends on customization
our $TCPacketHeader = Struct('Packet Header',
  BitStruct('Packet Id',
    BitField('Version Number',3),
    BitField('Type',1),
    Flag('DFH Flag'),
    $Apid
  ),
  BitStruct('Packet Sequence Control',
    BitField('Segmentation Flags',2),
    BitField('Source Seq Count',14),
    UBInt16('Packet Length'),
    Value('Source Data Length', sub { $_->ctx->{'Packet Length'} +1 -2 - 4*$_->ctx(1)->{'Packet Id'}->{'DFH Flag'} } ),
  )
);

our $TCSourcePacket= Struct('TC Source Packet',
  $TCPacketHeader,
  Struct('Packet Data Field',
    If ( sub { $_->ctx(1)->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'}}, 
            $TCSourceSecondaryHeader,
      ),
    Array(sub { $_->ctx(1)->{'Packet Header'}->{'Packet Sequence Control'}->{'Source Data Length'} }, UBInt8('TC Data')),
    UBInt16('Packet Error Control'),
  )
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($TCSourcePacket $TCPacketHeader $TCSourceSecondaryHeader);

=head1 SYNOPSIS

This part allows to decode/encode TC Source Packets, with or without TC Source Secondary Header.

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Ccsds::TC::SourcePacket
