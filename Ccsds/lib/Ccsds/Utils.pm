package Ccsds::Utils;

use warnings;
use strict;

=head1 NAME

Ccsds::Utils - Set of utilities to work with CCSDS Standards

=cut

use Digest::CRC qw(crcccitt);
use Data::Dumper; 

#Takes input as binary, gives out calculated CRC CCITT
sub calc_crc {

    return crcccitt(shift);

}

#Takes input as hex ascii representation
#Returns 1 if OK, 0 otherwise
sub verify_crc {

    ( my $crc_in, my $data ) = @_;

    my $sdata = pack( "H*", $data );
    my $crc = calc_crc $sdata;

    print 'Given Crc:' . sprintf( '%x', $crc_in ) . "\n" if $::odebug;
    print 'Calculated Crc:' . sprintf( '%x', $crc ) . "\n" if $::odebug;

    return $crc eq $crc_in;

}

#Takes input as hex ascii representation, no space
#Returns 1 if OK, 0 otherwise
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

  substr( $$data, -2 ) = pack( 'n', calc_crc( substr( $$data, 0, -2 ) ) );

}

#Takes input as binary!
sub tm_verify_crc_bin {

    return tm_verify_crc unpack( 'A*', shift );

}

#Removes EB90, CBH 1 bit correction code, TAIL
#Takes input as hex ascii representation of a CLTU (EB90,CBH..,TAIL)
sub rs_deinterleaver {
    my $cbh_len= shift;
    ( my $idata, my $fl ) = @_;     # Ascii data , Included frame TOTAL length
    my $odata;
    my $offset = 0;
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

#hex dumper for long data arrays
sub hdump {
    my $offset = 0;
    my(@array,$format,$res);
    foreach my $data (unpack("a64"x(length($_[0])/64)."a*",$_[0])) {
        my $len = length($data);
        if ($len == 64) {
            @array = unpack('N16', $data);
            $format="0x%04x (%05d)   " . "%08x " x 16 . " %s\n";
        } else {
            @array = unpack('C*', $data);
            $_ = sprintf "%2.2x", $_ for @array;
            push(@array, '  ') while $len++ < 64;
            $format="0x%04x (%05d)" .
               "   " . "%s%s%s%s " x 16 . " %s\n";
        } 
        $data ="";
        #$data =~ tr/\0-\37\177-\377/./; #Uncomment to show ascii
        $res .= sprintf($format,$offset,$offset,@array,$data);
        $offset += 64;
    }
    chomp $res;
    return $res;
}

#detect hash by its keys and return known order or alphabetical
sub get_orders {
    my ($hash)=@_;
    my $orders= [ 
#TM Packet
['Packet Header','Packet Data Field'],      #Packet
 [ "Packet Id", "Packet Sequence Control" ],   # PacketHeader
  [ "Version Number","Type","DFH Flag","Apid" ], #PacketId
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

 ['OBT','DoE','Mil','Mic'],           #CDS time
 ['OBT','DoE','Mil','Pic'],           #CDS time
 ['OBT','bDoE','Mil','Mic'],          #CDS time
 ['OBT','bDoE','Mil','Pic'],          #CDS time
 ['OBT','CUC Coarse','CUC Fine'],     #CUC
 ['OBT','Seconds','SubSeconds'],      #GIO Legacy
];
    for (@$orders) {
        my %a=map { $_ => 1 } @$_;    # generate a hash from the array reference
        return $_ if (%a ~~ %$hash);  # return array if keys match the hash
    }
    print "Sorting alphabetical keys:", join (',', keys %$hash ) , ".\n";
    return [ (sort keys %$hash) ];
}
#Fields to convert in hex if dumper is used
my @tohex = ('Packet Error Control');

sub CcsdsDump {
    my ($decoded)=@_;
    my $srcdata;
    
    #Change "Source Data" array to binary scalar. It is converted to ascii for Data::Dumper.
    if ( exists ($decoded->{'Packet Data Field'}) && exists ( $decoded->{'Packet Data Field'}->{'Source Data'} ) ) {
        $srcdata = unpack('H*',pack( 'C*' , @{ $decoded->{'Packet Data Field'}->{'Source Data'} } ) );
        $decoded->{'Packet Data Field'}->{'Source Data'} = $srcdata;
    }

    #Do a basic ordering for debug output
    $Data::Dumper::Sortkeys=\&get_orders;

    #Dump
    my $dumper = Dumper($decoded);

    #Do hex representation
    foreach (@tohex) { 
        $dumper =~ m/$_.*=>\s([[:alnum:]]*),?/; 
        next unless defined $1;
        my $hv = sprintf( "%#x", $1 ); 
        $dumper =~ s/$1/$hv/; 
    }

    #Convert Source Data Scalar to hexdumper
    $dumper =~ s/'Source Data' => '([^']*)'/"'Source Data' =>\n".hdump(pack('H*',$1))/e;

    return $dumper;
}

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(calc_crc verify_crc tm_verify_crc tm_verify_crc_bin patch_crc rs_deinterleaver CcsdsDump);

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
