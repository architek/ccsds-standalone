package Ccsds::TM::Frame;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::Frame - Decoding/Encoding of TM Frame

=cut

use Data::ParseBinary;

our $TMFrameHeader= BitStruct('TM Frame Header', #6 bytes
    BitField('Version Number Frame',2),         #16 bits
    BitField('SpaceCraftId',10),
    BitField('Virtual Channel Id',3),           
    BitField('Operation Flag',1),                 
    UBInt8('Master Channel Frame Count'),       #1 byte
    UBInt8('Virtual Channel Frame Count'),      #1 byte
    BitField('Sec Header',1),                   #16 bits
    BitField('Sync Flag',1),
    BitField('Packet Order Flag',1),
    BitField('Segment Length Id',2),
    BitField('First Header Pointer',11), 
);

my $TMFrameSecondaryHeader = BitStruct('TM Frame Secondary Header',
    BitField('Sec Header Version',2),
    BitField('Sec Header Length',6),
    Array(sub { $_->ctx->{'Sec Header Length'}-1 }, UBInt8('Data'))
);

#TODO if Operation Flag is 0, no CLCW 
#TODO Decode CLCW
#TODO allow customization for FEC
our $TMFrame= Struct('TMFrame',
    $TMFrameHeader,
    If ( sub { $_->ctx->{'TM Frame Header'}->{'Sec Header'}}, 
	$TMFrameSecondaryHeader
    ),
    Array(1105,UBInt8('Data')),
    UBInt32('CLCW'),   
    #UBInt16('FEC')
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($TMFrameHeader $TMFrame);

=head1 SYNOPSIS

This part allows to work with TM Frames. One can decode these structures or encode TMs to binary.
Encoding can be used to build scripted TM generators (simulators, ..) or to act as a gateway to forward TMTC.

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
