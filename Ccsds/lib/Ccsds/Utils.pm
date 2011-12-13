package Ccsds::Utils;

use warnings;
use strict;

=head1 NAME

Ccsds::Utils - Set of utilities to work with CCSDS Standards

=cut

use Digest::CRC qw(crcccitt);
use Data::Dumper;

sub calc_crc {
    return crcccitt(shift);
}

sub verify_crc {
    ( my $crc_in, my $data ) = @_;

    my $sdata = pack( "H*", $data );
    my $crc = calc_crc $sdata;
    printf "Given Crc:%x\nCalculated Crc:%x\n", $crc_in, $crc if $::odebug;
    return $crc eq $crc_in;
}

sub tm_verify_crc {

    #split string into data,crc
    ( my $data, my $crc_in ) =
      ( substr( $_[0], 0, -4 ), hex substr( $_[0], -4 ) );

    return verify_crc( $crc_in, $data );
}

sub tm_verify_crc_bin {
    return tm_verify_crc unpack( 'A*', shift );
}

#Patch 16bit-crc included in the binary stream
sub patch_crc {
    substr( ${ $_[0] }, -2 ) =
      pack( 'n', calc_crc( substr( ${ $_[0] }, 0, -2 ) ) );
}

#Takes input as hex ascii representation of a CLTU (EB90,CBH..,TAIL)
#Removes EB90, CBH 1 bit correction code, TAIL
sub rs_deinterleaver {
    my ( $cbh_len, $idata, $fl ) =
      @_;    # Ascii data , Included frame TOTAL length
    my ( $odata, $l );
    my $offset = 0;
    while ( $fl > 0 ) {
        $l = $cbh_len;
        $l = $fl if ( $fl < $cbh_len );
        $odata .= substr( $idata, $offset, $l * 2 );
        $offset += 2 * ( $cbh_len + 1 );
        $fl -= $cbh_len;
    }
    print "Data after CBH decoding :\n    $odata\n" if $::odebug;
    return $odata;
}

#Takes input as CLTU (EB90,CBH..,TAIL)
#Removes EB90, CBH 1 bit correction code, TAIL
sub rs_deintbin {
    my ( $cbh_len, $idata, $fl ) =
      @_;    # Ascii data , Included frame TOTAL length
    my ( $ret, $l );
    my $offset = 0;
    while ( $fl > 0 ) {
        $l = $cbh_len;
        $l = $fl if ( $fl < $cbh_len );
        $ret .= substr( $idata, $offset, $l );
        $offset += $cbh_len + 1;
        $fl -= $cbh_len;
    }
    print "Data after CBH decoding :\n    ", unpack( "H*", $ret ), "\n"
      if $::odebug;
    return $ret;
}

#Hex dumper for long data arrays
#Each line of data is 64 bytes.
#arg0: hex bin stream to dump
#arg1: 1 for ascii
sub hdump {
    my $offset = 0;
    my ( @array, $format, $res );
    my $ascii = $_[1] // 0;
    foreach
      my $data ( unpack( "a64" x ( length( $_[0] ) / 64 ) . "a*", $_[0] ) )
    {
        my $len = length($data);
        if ( $len == 64 ) {
            @array = unpack( 'N16', $data );
            $format = "0x%04x (%05d)   " . "%08x " x 16 . " %s\n";
        }
        else {
            @array = unpack( 'C*', $data );
            $_ = sprintf "%2.2x", $_ for @array;
            push( @array, '  ' ) while $len++ < 64;
            $format = "0x%04x (%05d)" . "   " . "%s%s%s%s " x 16 . " %s\n";
        }
        if ($ascii) {
            $data =~ tr/\0-\37\177-\377/./;
        }
        else { $data = ""; }
        $res .= sprintf( $format, $offset, $offset, @array, $data );
        $offset += 64;
    }
    chomp $res;
    return $res;
}

#Detect hash by its keys and return known order and if not, alphabetical
#This is used as key ordering for hashes when printing Ccsds structures using Data::Dumper
#TODO TCs
sub get_orders {
    my ($hash)=@_;
    my $orders= [ 
#TM Packet
['Packet Header','Has Crc', 'Packet Data Field'],      #Packet
 [ "Packet Id", "Packet Sequence Control" ],   # PacketHeader
  [ "Version Number","Type","DFH Flag","vApid","Apid" ], #PacketId
   [ "PID","Pcat"], #Apid
  [ "Segmentation Flags","Source Seq Count","Packet Length" ], # Packet Sequence Control
 ['TMSourceSecondaryHeader','Source Data','Packet Error Control'], # Packet Data Field
  [ 'Length', 'SecHeadFirstField',  'Service Type','Service Subtype', 'Destination Id', 'Sat_Time', 'Time Quality'],  # S3
  [ 'Length', 'SecHeadFirstField',  'Service Type','Service Subtype', 'Destination Id', 'Sat_Time' ],  # GIO
  [ 'Length', 'SecHeadFirstField',  'Service Type','Service Subtype',                   'Sat_Time', 'Sync Status' ],  # SW
   [ 'Spare1','PUS Version Number','Spare2' ],    # SecHead First Field

#TM Frame
['TM Frame Header','TM Frame Secondary Header',	'Data', 'CLCW'], # Frame
 ['Version Number Frame', 'SpaceCraftId', 'Virtual Channel Id', 'Operation Flag','Master Channel Frame Count','Virtual Channel Frame Count', 
 'Sec Header', 'Sync Flag','Packet Order Flag','Segment Length Id','First Header Pointer' ],   #FrameHeader
 ['Sec Header Version', 'Sec Header Length','Data'],       # FrameSecHeader

 ['OBT','DoE','Mil','Mic'],           #CDS time with Microseconds
 ['OBT','DoE','Mil','Pic'],           #CDS time with Picoseconds
 ['OBT','bDoE','Mil','Mic'],          #CDS time with Microseconds and day of Epoch on 24bits
 ['OBT','bDoE','Mil','Pic'],          #CDS time with Picoseconds and day of Epoch on 24bits
 ['OBT','CUC Coarse','CUC Fine'],     #CUC
 ['OBT','Seconds','SubSeconds'],      #Equivalent of CUC
];
    for (@$orders) {
        my %a=map { $_ => 1 } @$_;    # generate a hash from the array reference
        return $_ if (%a ~~ %$hash);  # return array if keys match the given hash
    }
    warn "Sorting alphabetical keys:", join (',', keys %$hash ) , ".\n";
    return [ (sort keys %$hash) ];
}

#Debug dumper to print out Ccsds structures. It uses get_orders() to print keys in order
#Some array fields are printed using a pretty hex dumper with ascii decoding
#TODO TCs
sub CcsdsDump {
    my ( $decoded, $ascii ) = @_;

    #Fields to convert in hex in dumper output
    my @tohex = qw{ 'Packet Error Control' 'CLCW' };
    my $dumper;

#Dumper printout of source data is not usable.
#Overwrite "Source Data" array by its corresponding scalar. It is converted to ascii for Data::Dumper
    {
        local $decoded->{'Packet Data Field'}->{'Source Data'} = unpack( 'H*',
            pack( 'C*', @{ $decoded->{'Packet Data Field'}->{'Source Data'} } )
          )
          if ( exists( $decoded->{'Packet Data Field'} )
            && exists( $decoded->{'Packet Data Field'}->{'Source Data'} ) );
        local $decoded->{'Data'} =
          unpack( 'H*', pack( 'C*', @{ $decoded->{Data} } ) )
          if ( exists( $decoded->{'TM Frame Header'} )
            && exists( $decoded->{Data} ) );   #frames normally always have data

        #Dump using a basic keys ordering
        $Data::Dumper::Sortkeys = \&get_orders;
        $dumper                 = Dumper($decoded);
        $Data::Dumper::Sortkeys = undef;

        #Change some fields to their hex representation
        foreach (@tohex) {
            $dumper =~ m/$_.*=>\s([[:alnum:]]*),?/;
            next unless ( defined $1 and $1 ne "undef" and $1 ne "" );
            my $hv = sprintf( "%#x", $1 );
            $dumper =~ s/$1/$hv/;
        }

        #Convert Source Data Scalar to hexdumper
        $dumper =~
s/'Source Data' => '([^']*)'/"'Source Data' =>\n".hdump(pack('H*',$1),$ascii)/e;
        $dumper =~
          s/'Data' => '([^']*)'/"'Data' =>\n".hdump(pack('H*',$1),$ascii)/e;
    }

    return $dumper;
}

#Deep search of keys in *hashes* structures
sub deep_hsearch {
    my ( $ref, $key ) = @_;
    while ( my ( $k, $v ) = each %$ref ) {
        return deepsearch( $v, $key ) if ref $v eq "HASH";
        return $v if $k eq $key;
    }
    return;
}

sub is_idle {
    my ($tm) = @_;
    return ( exists( $tm->{'Packet Header'} )
          && $tm->{'Packet Header'}->{'Packet Id'}->{vApid} == 2047 ) ? 1 : 0;
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT =
  qw(calc_crc verify_crc tm_verify_crc tm_verify_crc_bin patch_crc rs_deinterleaver rs_deintbin CcsdsDump is_idle hdump);

=head1 SYNOPSIS

This module includes simple helper for working with Ccsds standards:
    - CRC Handling : CRC calculation, inline verification and inline patching
    - RS de-interleaver
    - HexDumper to print nicely long datas in hex representation
    - Debugger output for any structures that prints the hash given in argument, keys being sorted.

=head1 EXPORTS

=head2 calc_crc()

Takes input as binary, gives out calculated CRC CCITT

=head2 verify_crc()

Takes input as hex ascii representation
Returns 1 if OK, 0 otherwise

=head2 tm_verify_crc()

Takes input as hex ascii representation, no space
Returns 1 if OK, 0 otherwise

=head2 tm_verify_crc_bin()

Takes input as binary

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
