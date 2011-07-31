package Ccsds::TC::Frame;

use warnings;
use strict;

=head1 NAME

Ccsds::TC::Frame - Decoding/Encoding of TC Frame

=cut

use Data::ParseBinary;

my $TCFrameHeader= BitStruct('TC Frame Header',
    BitField('Version Number Frame',2),         #16 bits
    BitField('ByPass',1),
    BitField('Control Command Flag',1),
    BitField('Spare',2),
    BitField('SpaceCraftId',10),
    BitField('Virtual Channel Id',6),           #16 bits
    BitField('Frame Length',10), 
    UBInt8('Frame Sequence Number'),            #8 bits
);

our $TCFrame= Struct('TCFrame',
    $TCFrameHeader, 
    Array(sub { $_->ctx->{'TC Frame Header'}->{'Frame Length'} }, UBInt8('TC Frame Data')),
    UBInt16('Frame Error Control'),
);

my $TCSegmentHeader = BitStruct('Segment Header',
      BitField('Sequence Flags',2),
      BitField('MapId',6),
);

our $Cltu= Struct('Cltu',
    Magic("\xEB\x90"),
    $TCFrameHeader,
    $TCSegmentHeader,
#Length of the CLTU = 10 + ((Total length of the Frames + 6) / 7) * 8
    Value('Cltu Length', sub { 10 + int( ($_->ctx->{'TC Frame Header'}->{'Frame Length'} +1 + 6 )/7)*8 }),
    
    Array(sub { $_->ctx->{'Cltu Length'} - 2 - 5 - 1 }, UBInt8('Cltu Data')),

);


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($TCFrame $Cltu);

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

1; # End of Ccsds::TC::Frame.pm
