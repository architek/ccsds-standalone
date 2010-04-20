use strict;
use warnings;
#<<'#';
#    Copyright (C) 2010  Laurent Kislaire, teebeenator@gmail.com
#
#    This program is free software: you can redistribute it and or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package TMSourcePacket;
use Data::ParseBinary;

use TMCommon;
use TMPus;
use TMRM;

#TODO
#sub are not needed by compilator!


my $Apid = BitStruct('Apid',
	$Pid,
	Nibble('Pcat')
);

my $TMSourceSecondaryHeader = Struct('TMSourceSecondaryHeader',
	BitStruct('SecHeadFirstField',
	  BitField('Spare1',1),
	  BitField('TM Source Packet PUS Version Number',3),
	  Nibble('Spare2')
  ),
	UBInt8('Service Type'),
	UBInt8('Service Subtype'),
	UBInt8('Destination Id'),
	$Sat_Time,
);


our $tmsourcepacket_parser = Struct('TM Source Packet',
    Struct('Packet Header',
        BitStruct('Packet Id',
	        BitField('Version Number',3),
       	  BitField('Type',1),
	        Flag('DFH Flag'),
	        $Apid
        ),
        BitStruct('Packet Sequence Control',
	        BitField('Segmentation Flags',2),
	        BitField('Source Seq Count',14),
	        UBInt16('Packet Length'),
	        Value('Source Data Length', sub { $_->ctx->{'Packet Length'} +1 -2 - 10*$_->ctx(1)->{'Packet Id'}->{'DFH Flag'} } ),
        )
    ),

    Struct('Packet Data Field',
	If ( sub { $_->ctx(1)->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'} }, Struct('Data Field',
	     $TMSourceSecondaryHeader,
	     Switch('PusData', sub { join(',',$_->ctx->{TMSourceSecondaryHeader}->{'Service Type'},$_->ctx->{TMSourceSecondaryHeader}->{'Service Subtype'})},
            {
		'1,1'   => $pus_AckOk,
		'1,7'   => $pus_AckOk,
		'1,2'   => pus_AckKo,
		'1,8'   => pus_AckKo,
		'2,129' => $pus_DirMil,
		'3,10'  => $pus_hk_report_definition, # TODO check SID 1..32, check 0<=Npar<=55
		'3,12'  => $pus_hk_report_definition, # TODO check SID 33.64, same
    '3,25'  => $pus_hk,
    '3,25'  => $pus_hk,
		'5,1'   => pus_Event,
		'5,2'   => pus_Event,
		'5,3'   => pus_Event,
		'5,4'   => pus_Event,
		'5,132' => $pus_enabled_events,
		'6,6'   => $pus_memory_dump,
		'6,10'  => $pus_memory_chk,
		'8,133' => $pus_function_status,
		'8,140' => $pus_function,
		'8,141' => pus_sliced,
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
		'128,3' => pus_parameter_report
	    },
	    default => $DefaultPass,
	    ),
        )),
        If ( sub { ! $_->ctx(1)->{'Packet Header'}->{'Packet Id'}->{'DFH Flag'}}, Struct('Time Packet',
	#No DFH
	 $Sat_Time,
	  UBInt8('Status'),
        )),
	UBInt16('Packet Error Control'),
    )
);

our $scos_tmsourcepacket_parser= Struct('Scos TM Source Packet',
	Array(20,UBInt8(undef)),
	$tmsourcepacket_parser
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($tmsourcepacket_parser $scos_tmsourcepacket_parser);

1;

