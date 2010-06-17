package Ccsds;

use warnings;
use strict;

=head1 NAME

Ccsds - Module used to decode or encode CCSDS TC/TM

=cut

our $VERSION = '1.4';


=head1 SYNOPSIS

This library allows decoding as well as encoding of CCSDS stream defined in the PSS/ECSS standards from European Space Agency

Here is an example of using the library:

    use Ccsds;

    #Decode binary input as CCSDS TM Source Packet
    my $tm         = $tmsourcepacket->parse($input);

    my $header     = $tm->{'Packet Header'};
    my $dataf      = $tm->{'Packet Data Field'};
    my $data       = $dataf->{'Data Field'};
    my $pid        = $header->{'Packet Id'}->{'Apid'}->{'PID'};
    my $sec_header = $data->{'TMSourceSecondaryHeader'};
    my $pus_data   = $data->{'PusData'};
    my $pus_t      = $sec_header->{'Service Type'};
    my $pus_st     = $sec_header->{'Service Subtype'};

    my $ref_length = \$f_header->{'Packet Sequence Control'}->{'Packet Length'};

    #Correct packet_length for some broken traffic
    if ( $pid == 6 and $pus_t == 3 and $pus_st == 25 ) {
        $$ref_length_packet_length += 2;
    }

    #Rebuild Telemetry
    $data = $tmsourcepacket->build($decoded);
    patch_crc(\$data);
    
    ...

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Ccsds
