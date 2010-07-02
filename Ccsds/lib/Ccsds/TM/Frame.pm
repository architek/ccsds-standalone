package Ccsds::TM::Frame;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::Frame - Decoding/Encoding of TM Frame

=cut

our $VERSION = '1.6';

use Data::ParseBinary;

my $TMFrameHeader= BitStruct('TM Frame Header',
    BitField('Version Number Frame',2),         #16 bits
    BitField('SpaceCraftId',10),
    BitField('Virtual Channel Id',3),           
    BitField('Operation Flag',1),
    UBInt8('Master Channel Frame Count'),
    UBInt8('Virtual Channel Frame Count'),
    BitField('Sec Header',1),
    BitField('Sync Flag',1),
    BitField('Packet Order Flag',1),
    BitField('Segment Length Id',2),
    BitField('First Header Pointer',10), 
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($TMFrameHeader);

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

1; # End of Ccsds::TM::Frame.pm
