package Ccsds::TM::SourcePacket;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::SourcePacket - Decoding Ccsds TM SourcePackets!

=cut

our $VERSION = '1.5';

use Data::ParseBinary;

use Ccsds::Common;
use Ccsds::TM::Pus;
use Ccsds::TM::RM;

my $TMSourceSecondaryHeader = Struct('TMSourceSecondaryHeader',   ### 10 bytes
  BitStruct('SecHeadFirstField',                                  #1 byte
    BitField('Spare1',1),
    BitField('PUS Version Number',3),
    Nibble('Spare2')
  ),
  UBInt8('Service Type'),                                         #1 byte
  UBInt8('Service Subtype'),                                      #1 byte
  UBInt8('Destination Id'),                                       #1 byte
  $Sat_Time                                                       #6 bytes
);


our $tmsourcepacket = Struct('TM Source Packet',
  Struct('Packet Header',                                         ### 6 bytes
        BitStruct('Packet Id',                                    #5+11 bits
          BitField('Version Number',3),
          BitField('Type',1),
          Flag('DFH Flag'),
          $Apid
        ),
        BitStruct('Packet Sequence Control',                      #16+16 bits
          BitField('Segmentation Flags',2),
          BitField('Source Seq Count',14),
          UBInt16('Packet Length'),
          Value('Source Data Length', sub { $_->ctx->{'Packet Length'} +1 -2 - 10*$_->ctx(1)->{'Packet Id'}->{'DFH Flag'} } ),
        )
    ),

  Struct('Packet Data Field',
    If ( sub { $_->ctx(1)->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'} }, 
      Struct('Data Field',
            $TMSourceSecondaryHeader,                             ### 10 bytes
            Switch('PusData', sub {  join(',', $_->ctx->{TMSourceSecondaryHeader}->{'Service Type'},$_->ctx->{TMSourceSecondaryHeader}->{'Service Subtype'})},
            {
                '1,1'   => $pus_AckOk,
                '1,7'   => $pus_AckOk,
                '1,2'   => $pus_AckKo,
                '1,8'   => $pus_AckKo,
                '2,129' => $pus_DirMil,
                '3,10'  => $pus_hk_report_definition, 
                '3,12'  => $pus_hk_report_definition, 
                '3,25'  => $pus_hk,
                '3,26'  => $pus_hk,
                '5,1'   => $pus_Event,
                '5,2'   => $pus_Event,
                '5,3'   => $pus_Event,
                '5,4'   => $pus_Event,
                '5,132' => $pus_enabled_events,
                '6,6'   => $pus_memory_dump,
                '6,10'  => $pus_memory_chk,
                '8,133' => $pus_function_status,
                '8,140' => $pus_function,
                '8,141' => $pus_sliced,
                '11,10' => $pus_detailed_schedule,
                '11,13' => $pus_summary_schedule,
                '11,19' => $pus_command_schedule_status,
                '12,9'  => $pus_current_monitoring_list,
                '12,11' => $pus_current_monitoring_oo_list,
                '12,12' => $pus_check_transition,
                '14,4'  => $pus_enabled_tm_sourcepacket,
                '14,8'  => $pus_enabled_hk,
                '14,12' => $pus_enabled_hk,
                '14,16' => $pus_enabled_event,
                '15,6'  => $pus_storage_selection_definition,
                '15,13' => $pus_packet_store_catalogue,
                '15,130'=> $pus_hk_format,
                '15,136'=> $pus_sid_storage_selection_definition,
                '18,9'  => $pus_OBCP_list,
                '18,131'=> $pus_OBCP_dump,
                '19,7'  => $pus_event_detection_list,
                '128,3' => $pus_parameter_report
            },
                default => $DefaultPass,
            ),
      )
    ),
    If ( sub { ! $_->ctx(1)->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'}}, 
      Struct('Time Packet',
        #No DFH
            $Sat_Time,
            UBInt8('Status'),
      )
    ),
    UBInt16('Packet Error Control'),
   )
);

our $scos_tmsourcepacket = Struct('Scos TM Source Packet',
  Array(20,UBInt8('Scos Header')),
  $tmsourcepacket
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($tmsourcepacket $scos_tmsourcepacket);

=head1 SYNOPSIS

Quick summary of what the module does.

    use Ccsds::TM::SourcePacket;

    $input=<STDIN>;
    die("There are non ASCII characters in your input\n") unless /^[[:ascii:]]*$/;
    #convert input to binary
    $pstring = pack( qq{H*}, qq{$input} );
    print "Warning: The CRC is incorrect, decoding anyway\n" unless ( tm_verify_crc $buf) ;

    my $foo = Ccsds::TM::SourcePacket::$tmsourcepacket->parse($pstring);
    ...

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ccsds::TM::SourcePacket


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Ccsds::TM::SourcePacket
