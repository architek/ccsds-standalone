package Data::ParseBinary::Network::Ccsds::Common;

use warnings;
use strict;

=head1 NAME

Data::ParseBinary::Network::Ccsds::Common - The great new Data::ParseBinary::Network::Ccsds::Common!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.3';

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

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::ParseBinary::Network::Ccsds::Common;

    my $foo = Data::ParseBinary::Network::Ccsds::Common->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::ParseBinary::Network::Ccsds::Common


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-ParseBinary-Network-Ccsds>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-ParseBinary-Network-Ccsds>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-ParseBinary-Network-Ccsds>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-ParseBinary-Network-Ccsds/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Data::ParseBinary::Network::Ccsds::Common
