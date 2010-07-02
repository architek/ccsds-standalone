package Ccsds::Utils;

use warnings;
use strict;

=head1 NAME

Ccsds::Utils - Set of utilities to work with CCSDS Standards

=cut

our $VERSION = '1.6';

use Digest::CRC qw(crcccitt);

#Takes input as binary!
sub calc_crc {

    return crcccitt(shift);

}

#Takes input as hex ascii representation
sub verify_crc {

    ( my $crc_in, my $data ) = @_;

    my $sdata = pack( "H*", $data );
    my $crc = calc_crc $sdata;

    print 'Calculated Crc:' . sprintf( '%x', $crc ) . "\n" if $::odebug;

    return lc $crc eq lc $crc_in;

}

#Takes input as hex ascii representation, no space
sub tm_verify_crc {

    print 'Included Crc:' . substr( $_[0], -4 ) . "\n" if $::odebug;

    #split string into data,crc
    ( my $data, my $crc_in ) =
      ( substr( $_[0], 0, -4 ), hex substr( $_[0], -4 ) );

    return verify_crc( $crc_in, $data );
}

#Patch 16bit-crc included in the binary stream
sub patch_crc {

  my $data=shift;

  substr( $$data, -2 ) = pack( 'H4', calc_crc( substr( $$data, 0, -2 ) ) );

}

#Takes input as binary!
sub tm_verify_crc_bin {

    return tm_verify_crc unpack( 'A*', shift );

}

#Removes EB90, CBH 1 bit correction code, TAIL
#Takes input as hex ascii representation of a CLTU (EB90,CBH..,TAIL)
sub decode_cltu_data {
    my $odata;
    my $offset = 4;                 # Skip EB90
    my $cbh_len= 7;
    ( my $idata, my $fl ) = @_;     # Ascii data , Included frame TOTAL length
    while ( $fl > 0 ) {
        my $l = $cbh_len;
        $l = $fl if ( $fl < $cbh_len );
        $odata .= substr( $idata, $offset, $l * 2 );
        $offset += 2*($cbh_len+1);
        $fl -= $cbh_len;
    }
    print "Data after CBH decoding :\n    $odata\n" if $::odebug;
    return $odata;
}



require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(calc_crc verify_crc tm_verify_crc tm_verify_crc_bin calc_crc patch_crc decode_cltu_data);

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::Utils


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Ccsds::Utils
