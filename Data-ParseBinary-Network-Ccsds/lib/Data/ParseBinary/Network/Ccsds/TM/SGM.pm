package Data::ParseBinary::Network::Ccsds::TM::SGM;

use warnings;
use strict;

=head1 NAME

Data::ParseBinary::Network::Ccsds::TM::SGM - The great new Data::ParseBinary::Network::Ccsds::TM::SGM!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.00';

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
		default => $DefaultPass,
	)
);


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($sgm_read);

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::ParseBinary::Network::Ccsds::TM::SGM;

    my $foo = Data::ParseBinary::Network::Ccsds::TM::SGM->new();
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

    perldoc Data::ParseBinary::Network::Ccsds::TM::SGM


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

1; # End of Data::ParseBinary::Network::Ccsds::TM::SGM
