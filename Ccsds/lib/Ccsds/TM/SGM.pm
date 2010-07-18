package Ccsds::TM::SGM;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::SGM - GAL Specific lib for decoding TTR SGM. Only 2 items are decoded.

=cut

our $VERSION = '1.7';

use Data::ParseBinary;

our $sgm_read = Struct ('SGM_Slice',
	UBInt16('LengthTotal'),
	UBInt32('SGMId'),
	UBInt32('Group'),
	Switch('Data',sub { $_->ctx->{'Group'} },
		{
			47 => Struct('Group 47',
				UBInt32('Offset'),
				UBInt32('Length2'),
				UBInt32('Validity'),
				UBInt32('CrcGroup'),
				UBInt32('NumberItems'),
				Array(sub { $_->ctx->{'NumberItems'}},
				  Struct('HK',
					UBInt32('Sid'),
					UBInt32('Enabled'),
					UBInt32('CollInt'),
					UBInt32('NPara'),
					UBInt32('ParaList')
				  )
				)
			      ),
			46 => Struct('Group 46',
				UBInt32('Offset'),
				UBInt32('Length2'),
				UBInt32('Validity'),
				UBInt32('CrcGroup'),

				UBInt32('Coarse OBT'),
				UBInt32('SubSeconds OBT'),
				UBInt32('ASW Start Counter'),
				UBInt32('Last SC Mode'),
				UBInt32('FDIR Level 2'),
				UBInt32('Last Active PM'),
				UBInt32('PM Configuration'),
			      )
		},
		_default_ => $DefaultPass,
	)
);


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($sgm_read);

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::TM::SGM


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Ccsds::TM::SGM
