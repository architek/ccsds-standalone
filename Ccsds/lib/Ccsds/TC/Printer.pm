package Ccsds::TC::Printer;

use warnings;
use strict;

=head1 NAME

Ccsds::TC::Printer - Simple printer for decoding CCSDS TC Structures

=cut

our $VERSION = '1.6';

use Switch;
use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 3;

# Takes CLTU (EB90,CBH...,TAIL) Ascii representation as input
sub CltuPrint {

  my ($cltu_buff) = shift;
  my $cblock=int(length($cltu_buff)/2-2-8)/7;
  print "SSSS"                           # StartSequence
  . "FHFHFHFHFHSH"                       # Frame and Segment Headers
  . "╭╮╳╳"                               # Show ClodeBlocks locations
  . "╭╮╭╮╭╮╭╮╭╮╭╮╭╮╳╳" x ($cblock-1) 
  . "T" x 16 . "\n";                     # Tail

  print "$cltu_buff\n";
  
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(CltuPrint $VERSION);

=head1 SYNOPSIS

Quick summary of what the module does.

    use Ccsds::TC::Printer;

    CltuPrint($cltu_ascii);

    ...

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::TM::Printer


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Ccsds::TM::Printer
