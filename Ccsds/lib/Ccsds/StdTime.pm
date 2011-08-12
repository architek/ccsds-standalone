package Ccsds::StdTime;

use warnings;
use strict;

=head1 NAME

Ccsds::StdTime - Time code formats of CCSDS Standards

=cut

use Data::ParseBinary;

#The decoding to textual time is handle in Value OBT
#This could be replaced by a special adpater. TODO

sub dayCDS {
    my ($day_size)=@_;
    return $day_size==16 ? 
            UBInt16('DoE'):               # 16 bits
            Array( 3, UBInt8('bDoE') );   # 24 bits
}

sub subMilliCDS {
    my ($milli_size)=@_;
    return $milli_size==16 ?
            UBInt16('Mic'):
            UBInt32('Pic');
}

my $p_Field= BitStruct('P-Field',
    Flag('Extension'),
    BitField('Time Code Id',3),
    BitField('Detail Bits',4),
);

sub CDS {
    my ($day_size,$milli_size)=@_;
    if ($day_size==16 || $day_size==24 &&
        $milli_size==0 || $milli_size==16 || $milli_size==32) 
    { 
        return Struct('Sat_Time', 
                            dayCDS($day_size),
                            UBInt32('Mil'),
                            subMilliCDS($milli_size),
                    );
    } else { 
        die "Values $day_size and $milli_size not allowed for CDS form of CCSDS standard"; 
        return undef;
    }
}

sub CUC {
    my ($ct,$ft)=@_;
    return Struct('Sat_Time', 
                Array( $ct, UBInt8("CUC Coarse") ),
                Array( $ft, UBInt8("CUC Fine") ),
           );
}

#sub cds2utc {
#    my $mil=$cds->{'Mil'}/Size;
#    print "OBT: ", $obt . "." . $cds->{'Mic'} ,"\n"; 
#    my $obt = DateTime->new(year=>2000)->add(days=>$cds->{'DoE'})->add(seconds=>$cds->{'Mil'}/(1000));
#    print "OBT: ", $obt . "." . $cds->{'Mic'} ,"\n"; 
#}

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(CDS CUC $p_Field);

=head1 SYNOPSIS

    BEGIN {
        use Ccsds::StdTime;
        our $Sat_Time=CUC(4,2);
    }

    use Ccsds::TM::SourcePacket qw($TMSourcePacket $TMSourcePacketHeader $TMSourceSecondaryHeader);
    $TMSourcePacket->decode($data);

=head1 DESCRIPTION

In the Recommendation, four Levels of time code formats can be defined based on the four degrees of interpretability of the code.

This library allows to decode CUC and CDS formats.
Currently, PField and self-identified OBT type is not auto-detected, it must be provided by the user if needed

=head1 Standard structures

=head3 CUC

1 to 4 octets of Coarse time, 0 to 3 of Fine time
This allows 136 years and 60ns granularity

    #Sample customization for PROJECT
    #################################

    use Ccsds::StdTime;
    # CUC 48 bits
    our $Sat_Time = CUC(4,2);
    # or CUC 56 bits
    our $Sat_Time = CUC(4,3);

=head3 CDS

16 or 24 bits for DAY, 32 bits for MS of the day, submilliseconds on 0,16 or 32 bits
This code is UTC based and leap second correction has to be made (with perl libraries)
    
    #Sample customization for PROJECT
    #################################

    use Ccsds::StdTime;
    # CDS with DoE on 24 bits and no submilli
    our $Sat_Time = CDS(24,0);

    # CDS with DoE on 16 bits and submilli on 16 bits
    our $Sat_Time = CDS(16,16);
    my $cds = $decoded->{'Sat_Time'};
    use DateTime;
    my $obt = DateTime->new(year=>2000)->add(days=>$cds->{'DoE'})->add(seconds=>$cds->{'Mil'}/(65535*1000));
    print "OBT: ", $obt . "." . $cds->{'Mic'} ,"\n";


=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::StdTime


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Ccsds::StdTime
