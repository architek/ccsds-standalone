package Ccsds::Common;

use warnings;
use strict;

=head1 NAME

Ccsds::Common - Common Structures to CCSDS Standards

=cut

our $VERSION = '1.7';

use Data::ParseBinary;

our $Sat_Time = Struct( 'Sat_Time',
    UBInt32('Seconds'),
    UBInt16('SubSeconds'),
    Value(
        'OBT', sub { $_->ctx->{'Seconds'} + $_->ctx->{'SubSeconds'} / 65535 }
    )
);

our $Pid = Enum(
    BitField( 'PID', 7 ),
      TIME        => 0x0,
      SYS         => 0x10,
      AOC         => 0x11,
      PF          => 0x12,
      PL          => 0x13,
      PFSUA_STMTC => 0x22,
      PFSUA_TMTC  => 0x24,
      PFSUB_STMTC => 0x2A,
      PFSUB_TMTC  => 0x2C,
      PLSU_C_Band => 0x32,
      PLSU_PRS    => 0x33,
      PLSU_TMTC   => 0x34,
      NSGU_S      => 0x40,
      NSGU_L      => 0x48,
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
