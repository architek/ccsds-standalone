# NAME

Ccsds - Module used to decode or encode CCSDS TC/TM

[![Build Status](https://secure.travis-ci.org/architek/ccsds-standalone.png?branch=master)](http://travis-ci.org/architek/ccsds-standalone)

# SYNOPSIS

This library allows decoding and encoding of CCSDS stream defined in the PSS/ECSS standards.
The current module Ccsds.pm only exports $VERSION which can be retried to know the version of the library. 

    use Ccsds::Utils qw(tm_verify_crc);
    use Ccsds::TM::Frame qw($TMFrame);
    use Ccsds::TM::SourcePacket qw($TMSourcePacket $TMSourcePacketHeader $TMSourceSecondaryHeader) ;
    use Data::Dumper;

    #Decode binary input as CCSDS TM Source Packet
    my $tm         = $TMSourcePacket->parse($input);

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
    $data = $TMSourcePacket->build($decoded);
    patch_crc(\$data);
    

    ...

# AUTHOR

Laurent KISLAIRE, `<teebeenator at gmail.com>`

# BUGS

Please report any bugs or feature requests to `teebeenator at gmail.com`

# SUPPORT

You can find documentation for this module in the manpage or with the perldoc command.

    man Ccsds
    perldoc Ccsds

https://github.com/architek/ccsds-standalone/wiki


# LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.




