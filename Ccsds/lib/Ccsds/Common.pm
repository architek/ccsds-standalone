package Ccsds::Common;

use warnings;
use strict;

=head1 NAME

Ccsds::Common - Common Structures to CCSDS Standards

=cut

our $VERSION = '1.7';

use Data::ParseBinary;

#CUC
our $Sat_Time = Struct( 'Sat_Time',
    UBInt8('C1'),
    UBInt8('C2'),
    UBInt8('C3'),
    UBInt8('F1'),
    UBInt8('F2'),
    UBInt8('F3'),
    Value(              
        'OBT', sub { 
        $_->ctx->{'C1'}*256**3  +
        $_->ctx->{'C2'}*256**2  +
        $_->ctx->{'C3'}*256     +
        $_->ctx->{'F1'}*256**-1 +
        $_->ctx->{'F2'}*256**-2 +
        $_->ctx->{'F3'}*256**-3 
        }
    )
);

our $Pid = Enum(
    BitField( 'PID', 7 ),
      TIME        => 0x0,
      _default_   => $DefaultPass
);

our $Apid = BitStruct('Apid',
  $Pid,
  Nibble('Pcat')
);


require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw($Sat_Time $Pid $Apid);

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::Common


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Ccsds::Common
