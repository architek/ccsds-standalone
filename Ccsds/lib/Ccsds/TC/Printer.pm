package Ccsds::TC::Printer;

use warnings;
use strict;

=head1 NAME

Ccsds::TC::Printer - Simple printer for CCSDS TC Source Packets and CLTUs

=cut

use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 3;

#TODO : depends on CBH parameters
sub CltuPrint {

  my $cblock=int(length(shift)/2-2-8)/7;
  print "SSSS"                           # StartSequence
  . "FHFHFHFHFHSH"                       # Frame and Segment Headers
  . "╭╮╳╳"                               # Show ClodeBlocks locations
  . "╭╮╭╮╭╮╭╮╭╮╭╮╭╮╳╳" x ($cblock-1) 
  . "T" x 16 . "\n";                     # Tail
  print "$_\n";

}

sub TCPrint {

  my ($Src_Packet) = shift;
  my $DFH=$Src_Packet->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'};
  my $Packet_Length=$Src_Packet->{'Packet Header'}->{'Packet Sequence Control'}->{'Packet Length'};
  my $Pus_Data=$Src_Packet->{'Packet Data Field'}->{'TC Data'};
  if ( $DFH ) {
    my $Pus_SecHeader=$Src_Packet->{'Packet Data Field'}->{'TCSourceSecondaryHeader'};
    my $Pus_Type=$Pus_SecHeader->{'Service Type'};
    my $Pus_SubType=$Pus_SecHeader->{'Service Subtype'};
    print "TC PUS($Pus_Type,$Pus_SubType) Length: $Packet_Length \n";
  }
  else {
    print "TC with no Secondary Header (CPD, HPC, ..) Length: $Packet_Length \n";
  }

#Print datas, if any
  print Dumper($Pus_Data) if (defined($Pus_Data)) ;
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(TCPrint CltuPrint);

=head1 SYNOPSIS

This module is used to print TCs including CLTU and PUS TC 

    use Ccsds::TC::Printer;

    CltuPrint($cltu_ascii);
    ...

    my $decoded = Ccsds::TC::$TCSourcePacket->parse($pstring);
    Ccsds::TC::TCPrint($decoded);

    ...

=head1 EXPORTS

=head2 CltuPrint()

Takes CLTU (EB90,CBH...,TAIL) Ascii representation as input

=head2 TCPrint()

Simple printer for TC and PUS content

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::TC::Printer


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Ccsds::TC::Printer
