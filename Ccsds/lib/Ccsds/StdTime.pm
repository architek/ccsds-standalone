package Ccsds::StdTime;

use warnings;
use strict;

=head1 NAME

Ccsds::StdTime - Time code formats of CCSDS Standards

=cut

use Data::ParseBinary;
use DateTime;

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
    my ($day_size,$milli_size,$epoch)=@_;
    # default CCSDS Epoch: 1/1/1958
    $epoch ||= 1958;
    if ($day_size==16 || $day_size==24 &&
        $milli_size==0 || $milli_size==16 || $milli_size==32) 
    { 
        return Struct('Sat_Time', 
                            dayCDS($day_size),
                            UBInt32('Mil'),
                            subMilliCDS($milli_size),
                            Value('OBT',
								sub {
								    my $day_num;
								    if ($day_size == 16) {
								        $day_num=$_->ctx->{'DoE'};
								    } else {
                                    #Calculate out of 24 bits
								        my $k=256**2;
								        map { $day_num+=$k*$_; $k/=256; } @{ $_->ctx->{'bDoE'} };
								    }

                                    #calculate subsecond details
								    my $s=int($_->ctx->{'Mil'}/1000); 
								    my $ms=$_->ctx->{'Mil'}-$s*1000;
								    my $obt = DateTime->new(year=>$epoch)->add(days=>$day_num)->add(seconds=>$s);
                                    return 
                                        ($milli_size==0 ) ? sprintf ("%s.%03d", $obt, $ms) :
                                        ($milli_size==16) ? sprintf ("%s.%03d%03d", $obt, $ms, $_->ctx->{'Mic'}) :
								        sprintf ("%s.%03d%06d", $obt, $ms, $_->ctx->{'Pic'} );
								}
                            )
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
                Value( "OBT", 
                    sub { 
                        my ($s, $k)=(0, 256**($ct-1) );
                        map { $s+=$k*$_; $k/=256; } ( @{ $_->ctx->{"CUC Coarse"} } , @{ $_->ctx->{"CUC Fine"} } );
                        return $s;
                    }
                )
           );
}

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
    ...

    my $obt=$Sat_Time->decode("\x12\x23\x34\x45\x67\x89");
    print "Corresponding OBT is ", $obt->{OBT} , "\n";
    

=head1 DESCRIPTION

 In the Recommendation, four Levels of time code formats can be defined based on the four degrees of interpretability of the code.

 This library allows to decode CUC and CDS formats.
 Currently, PField and self-identified OBT type is not auto-detected, it must be provided by the user if needed
 The decoding to textual time is handle in Value OBT
 This could be replaced by a Data::ParseBinary Adapter to allow Textual->Binary encoding

=head1 STRUCTURES

=head2 CUC

1 to 4 octets of Coarse time, 0 to 3 of Fine time
This allows 136 years and 60ns granularity

    #Sample customization for PROJECT
    #################################

    use Ccsds::StdTime;
    # CUC 48 bits
    our $Sat_Time = CUC(4,2);
    # or CUC 56 bits
    our $Sat_Time = CUC(4,3);

=head2 CDS

16 or 24 bits for DAY, 32 bits for MS of the day, submilliseconds on 0,16 or 32 bits
This code is UTC based and leap second correction has to be made (with perl libraries)
    
    #Sample customization for PROJECT
    #################################

    use Ccsds::StdTime;
    # CDS with DoE on 24 bits and no submilli, default epoch
    our $Sat_Time = CDS(24,0);

    # CDS with DoE on 16 bits and submilli on 16 bits, epoch set to 1/1/2000
    our $Sat_Time = CDS(16,16,2000);

=head1 EXPORTS

=head2 CUC

Given a Coarse and a Fine precision (in bytes) 

Returns a CUC Structure of 3 elements: Coarse, Fine and OBT being the calculated value

The formulae to calcuate this value is the recommended one:

OBT(c,f)= C1*256**(c-1)+C2*256**(c-2)..+Cc*256**0 + F1*256**-1 + F1*256**-2 .. + Ff*256**-f

=head2 CDS

Given a day precision (in bits: 16 or 24 bits. who needs 2**24 ie 45 centuries?) and a sub-millisecond precision (0,16,32 bits) and a year of Epoch (meaning exact epoch is 1st January of this year 0:00 UTC)

Returns a CDS Structure of 4 elements: day from epoch, milliseconds of the day, submillisecond and OBT being the calculated value

To calculate offset to epoch, DateTime is used (which takes care of leap second). 

The subsecond part is simply appended (with 24 bits, no easier solution).

TODO Finish case $milli_size=0 (no 3rd field)

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
