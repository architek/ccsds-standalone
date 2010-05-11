package Data::ParseBinary::Network::Ccsds::Utils;

use warnings;
use strict;

=head1 NAME

Data::ParseBinary::Network::Ccsds::Utils - The great new Data::ParseBinary::Network::Ccsds::Utils!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '1.02';

use Digest::CRC qw(crcccitt);

#Takes input as hex ascii representation
#Takes input as binary!
sub calc_crc {
    return crcccitt(shift);
}

sub verify_crc {
    ( my $crc_in, my $data ) = @_;
    $crc_in = lc $crc_in;
    my $sdata = pack( "H*", $data );
    my $crc = calc_crc $sdata;
    print 'Calculated Crc:' . sprintf( '%x', $crc ) . "\n" if $::mdebug;
    return $crc eq $crc_in;
}

sub tm_verify_crc {
    print 'Included Crc:' . substr( $_[0], -4 ) . "\n" if $::mdebug;

    #split string into data,crc
    ( my $data, my $crc_in ) =
      ( substr( $_[0], 0, -4 ), hex substr( $_[0], -4 ) );
    return verify_crc( $crc_in, $data );
}

sub tm_verify_crc_bin {
    return tm_verify_crc unpack( 'A*', shift );
}

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(calc_crc verify_crc tm_verify_crc tm_verify_crc_bin calc_crc);

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::ParseBinary::Network::Ccsds::Utils;

    my $foo = Data::ParseBinary::Network::Ccsds::Utils->new();
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

    perldoc Data::ParseBinary::Network::Ccsds::Utils


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

1;    # End of Data::ParseBinary::Network::Ccsds::Utils
