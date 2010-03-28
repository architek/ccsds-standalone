#tc 3,131!!!!
#Erreurs sur le service 15:
# - N=0 renvoie que 5 PS
# - HK Format contient N, pas necessaire si fixe
package TMPus;
use strict;
use warnings;
use Data::ParseBinary;
use TMRM;
use TMSgm;
use TMSourcePacket;	# needed for pus time in MTL..

our $pus_AckOk = Struct("AckOk",
	UBInt16("TC Packet Id"),
	UBInt16("TC Packet SC")
);

sub pus_AckKo {
	return Struct("AckKo",
	    UBInt16("TC Packet Id"),
	    UBInt16("TC Packet SC"),
	    UBInt16("FID"),
#Parameters are 32bits (hence /4)
	    Array(sub { ( $_->ctx(2)->{"Packet Header"}->{"Packet Sequence Control"}->{"Source Data Length"}-6)/4},UBInt32("Params"))
        );
}

our $pus_DirMil = Struct("Pus_DirMil",
	UBInt16("Command Word"),
	UBInt16("Milbus Status"),
	UBInt16("Dsize"),
	Array(sub { $_->ctx->{"Dsize"} },UBInt16("MilData") )
);

our $pus_hk_report_definition = Struct("Pus HK Report Definition",
	UBInt8("Sid"),
	UBInt8("Collection Interval"),
	Enum(UBInt8("Status"),
		Disabled => 0,
		Enabled => 1
	),
	UBInt8("NPar"),
	Array(sub { $_->ctx->{"NPar"} },UBInt32("ParamId") )
);

sub pus_Event {
	return Struct("PusEvent",
	    UBInt16("EID"),
#Parameters are 32bits (hence /4)
	    Array(sub { ( $_->ctx(2)->{"Packet Header"}->{"Packet Sequence Control"}->{"Source Data Length"}-2)/4},UBInt32("Params"))
        );
}


our $pus_enabled_events = Struct("Enabled events",
	UBInt16("NEid"),
	Array(sub { $_->ctx->{"NEid"} },UBInt16("Eids") )
);

#TODO Sub SAU: if PID == NSGU_A then return UBInt32 otherwise UBInt8
our $pus_memory_dump = Struct("Memory Dump",
	UBInt16("Memory Id"),
	UBInt32("Start Address"),
	UBInt16("Length"),
	Array(sub { $_->ctx->{"Length"} },UBInt8("Data") )
);

our $pus_memory_chk = Struct("Memory Check",
	UBInt16("Memory Id"),
	UBInt32("Start Address"),
	UBInt16("Length"),
	UBInt16("Crc")
);

our $pus_function_status = Struct("Function Status",
	UBInt8("N"),
	Array(sub { $_->ctx->{"N"}}, 
		Struct ("Function Info",
			UBInt8("Function Id"),
			BitStruct("Status",
				Padding(7),
				Flag("Execution Status"),
			),
			Enum(UBInt8("Function Type"),
				Normal => 0,
				Vital => 1,
				'Potential Hazardous' => 2
			),
			UBInt32("Enabled Timeout")
		)
	)
);

sub pus_sliced {
	return Struct("Sliced",
		UBInt8("Function Id"),
		UBInt8("Nr Current Slice"),
		UBInt8("Total Slice"),
#As sliced are only parseable on a whole when all slices are read, this will not be decoded..
#One example is shown for reading slice 1 of sgm group 47 (list of TM packets defined) but that's just a proof of concept
		Switch("Data",sub { $_->ctx->{'Function Id'} },
			{
				110 => $sgm_read
			},
			default => Array(sub { $_->ctx(2)->{"Packet Header"}->{"Packet Sequence Control"}->{"Source Data Length"}-3},UBInt8("Params"))
		)
	);
}

our $pus_function = Struct("Data",
	UBInt8("Function Id"),
	Switch("Data",sub { $_->ctx->{'Function Id'} },
	{
		103 => $RMLog,
        	_default_ => $DefaultPass
	})
);


#TODO 
#Currently assumes DFH *in TC* is set to 1 (which is always the case for mapid-1 TCs)
our $pus_detailed_schedule = Struct("Detailed Schedule",
	UBInt16("N"),
	Array(sub { $_->ctx->{"N"}},
	   Struct("TC",
	   #FIXME..
		$Data::ParseBinary::FileSystem::TMSourcePacket::Sat_Time,
		UBInt16("Packet ID"),
		UBInt16("Packet Sequence Control"),
		UBInt16("TC Length"),
		UBInt32("Data Field Header"),
		Array(sub { 1+$_->ctx->{"TC Length"}},UBInt8("TC Application Data")),
		UBInt16("TC Packet Error Control")
	   )
	)
);

our $pus_summary_schedule = Struct("Summary Schedule",
	UBInt16("N"),
	Array(sub { $_->ctx->{"N"}},
	   Struct("TC",
	   #FIXME..
		$Data::ParseBinary::FileSystem::TMSourcePacket::Sat_Time,
		BitStruct("Pidb",
			Padding(1),
			$Data::ParseBinary::FileSystem::TMSourcePacket::Pid
		),
		BitStruct("SSCb",
			Padding(2),
			BitField("Source Seq Count",14)
		),
	   )
	)
);

our $pus_command_schedule_status = Struct("Command Schedule Status",
	UBInt8("N"),
	Array(sub { $_->ctx->{"N"}},Struct("Status",
#FIXME
#		BitStruct("Pidb",
#			Padding(1),
#			$Data::ParseBinary::FileSystem::TMSourcePacket::Pid
#		),
		UBInt8("Pid"),
		UBInt8("Status")
	))
);

#TODO Criteria
our $pus_current_monitoring_list= Struct("Current Monitoring List",
	UBInt8("Monitoring Status"),
	UBInt8("Maximum Reporting delay"),
	UBInt8("N"),
	Array(sub { $_->ctx->{"N"}},
		UBInt8("Monitoring Id"),
		UBInt32("ParamId"),
		UBInt32("Validity ParamId"),
		UBInt8("Parameter Monitoring Interval"),
		UBInt8("Rep"),
		UBInt8("Monitoring Status"),
		UBInt8("Check Type"),
		Array(12,UBInt8("Monitoring Criteria"))
	)
);

#TODO Checking status is enum
our $pus_current_monitoring_oo_list= Struct("Current Monitoring OO List",
	UBInt16("N"),
	Array(sub { $_->ctx->{"N"}}, Struct("Limits",
		UBInt32("ParamId"),
		UBInt32("Mask"),
		UBInt32("Parameter Value"),
		UBInt32("Limit crossed"),
		UBInt8("Previous Checking Status"),
		UBInt8("Current Checking Status"),
		$Data::ParseBinary::FileSystem::TMSourcePacket::Sat_Time,
	)
	)
);
our $pus_check_transition= Struct("Check Transition",
	UBInt16("N"),
	Array(sub { $_->ctx->{"N"}},
		UBInt32("ParamId"),
		UBInt32("Mask"),
		UBInt32("Parameter Value"),
		UBInt32("Limit crossed"),
		UBInt8("Previous Checking Status"),
		UBInt8("Current Checking Status"),
		$Data::ParseBinary::FileSystem::TMSourcePacket::Sat_Time,
	)
);

our $pus_enabled_tm_sourcepacket= Struct("Enabled TM sourcepacket",
	UBInt8("N1"),
	Array(sub { $_->ctx->{"N1"}},Struct("TMSourcePacket",
#FIXME		BitStruct("Pidb",
#			Padding(1),
#			$Data::ParseBinary::FileSystem::TMSourcePacket::Pid
#		),
		UBInt8("PID"),
		UBInt8("FStat"),
		UBInt8("N2"),
		Array(sub { $_->ctx->{"N2"}},Struct("Types",
			UBInt8("Type"),
			UBInt8("FStat"),
			UBInt8("N3"),
			Array(sub { $_->ctx->{"N3"}},Struct("SubTypes",
				UBInt8("SubType"),
				UBInt8("FStat")
			))
		))
	))
);

our $pus_enabled_hk= Struct("Enabled HK",
	UBInt8("N1"),
	Array(sub { $_->ctx->{"N1"}},Struct("Pids",
#FIXME		BitStruct("Pidb",
#			Padding(1),
#			$Data::ParseBinary::FileSystem::TMSourcePacket::Pid
#		),
		UBInt8("PID"),
		UBInt8("N2"),
		Array(sub { $_->ctx->{"N2"}},Struct("Sids",
			UBInt8("SID"),
			UBInt8("FStat")
		)),
	))
);

our $pus_enabled_event= Struct("Enabled Events",
	UBInt8("N1"),
	Array(sub { $_->ctx->{"N1"}},
		BitStruct("Pidb",
			Padding(1),
			$Data::ParseBinary::FileSystem::TMSourcePacket::Pid
		),
		UBInt8("N2"),
		Array(sub { $_->ctx->{"N2"}},
			UBInt16("EID"),
			UBInt8("FStat")
		),
	)
);
our $pus_storage_selection_definition= Struct("Storage Selection definition",
	UBInt8("N1"),
	Array(sub { $_->ctx->{"N1"}},Struct("Pids",
#FIXME		BitStruct("Pidb",
#			Padding(1),
#			$Data::ParseBinary::FileSystem::TMSourcePacket::Pid
#		),
		UBInt8("PID"),
		UBInt8("StoreId1"),
		UBInt8("N2"),
		Array(sub { $_->ctx->{"N2"}},Struct("Types",
			UBInt8("Type"),
			UBInt8("StoreId2"),
			UBInt8("N3"),
				Array(sub { $_->ctx->{"N3"}},Struct("SubTypes",
					UBInt8("SubType"),
					UBInt8("StoreId3")
				))
		))
	))
);

our $pus_packet_store_catalogue= Struct("Packet Store Catalogue",
	UBInt8("N"),
	Array(sub { $_->ctx->{"N"}},Struct("Stores",
		UBInt8("StoreId"),
		UBInt32("Storage Time1"),
		UBInt32("Storage Time2"),
		UBInt8("Percentage filled"),
		Padding(9)
	))
);
our $pus_hk_format= Struct("HK Format",
	UBInt8("N"),
	Array(sub {$_->ctx->{'N'}},Struct("Format",
		UBInt8("StoreId"),
		BitStruct("BufferPolb",
			Padding(7),
			BitField("Buffer Policy",1)
		),
		UBInt32("Number of Bytes")
	))
);


our $pus_sid_storage_selection_definition= Struct("Sid Storage Selection definition",
	UBInt8("N1"),
	Array(sub { $_->ctx->{"N1"}},Struct("Pids",
		UBInt8("PID"),
#		BitStruct("Pidb",
#			Padding(1),
#			$Data::ParseBinary::FileSystem::TMSourcePacket::Pid
#		),
		UBInt8("N2"),
		Array(sub { $_->ctx->{"N2"}},Struct("Sids",
			UBInt16("SID"),
			UBInt8("StoreId")
		)),
	))
);

our $pus_OBCP_list= Struct("OBCP List",
	UBInt8("NProc"),
	Array(sub { $_->ctx->{"NProc"}},
		UBInt8("ProcedureId"),
		UBInt8("Status"),
		UBInt8("Position")
	)
);

our $pus_OBCP_dump = Struct("OBCP dump",
	UBInt8("Procedure Id"),
	UBInt8("Procedure Steps"),
	Array(sub { $_->ctx->{"Procedure Steps"}},
	   UBInt8("Procedure Step"),
	   UBInt16("Delay"),
	   Struct("Tc",
	   #FIXME..
		$Data::ParseBinary::FileSystem::TMSourcePacket::Sat_Time,
		UBInt16("Packet ID"),
		UBInt16("Packet Sequence Control"),
		UBInt16("TC Length"),
		UBInt32("Data Field Header"),
		Array(sub { 1+$_->ctx->{"TC Length"}},UBInt8("TC Application Data")),
		UBInt16("TC Packet Error Control")
	   )
	)
);

#Only mapid 1 are allowed, meaning DFH is always true
our $pus_event_detection_list= Struct("Event detection List",
	UBInt8("N"),
	Array(sub { $_->ctx->{"N"}},
	   Struct("TC",
		UBInt8("PID"),
		UBInt16("EID"),
		UBInt8("Action Status"),
		UBInt16("Packet ID"),
		UBInt16("Packet Sequence Control"),
		UBInt16("TC Length"),
#		UBInt32("Data Field Header"),
		UBInt8(undef),
		UBInt8("Service Type"),
		UBInt8("Service SubType"),
		UBInt8(undef),

		Array(sub { 1+$_->ctx->{"TC Length"} - 6},UBInt8("TC Application Data")),
		UBInt16("TC Packet Error Control")
	   )
   	)
);

sub pus_parameter_report {
	return Struct("Parameter Report",
		UBInt8("NPar"),
		Array(sub { $_->ctx(2)->{"Packet Header"}->{"Packet Sequence Control"}->{"Source Data Length"}-1},UBInt32("Params"))
	);
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($pus_AckOk $pus_DirMil $pus_hk_report_definition $pus_enabled_events $pus_memory_dump $pus_memory_dump $pus_memory_chk $pus_function_status $pus_function pus_AckKo pus_Event pus_sliced $pus_detailed_schedule $pus_summary_schedule $pus_command_schedule_status $pus_current_monitoring_list  $pus_current_monitoring_oo_list $pus_check_transition $pus_enabled_tm_sourcepacket $pus_enabled_hk $pus_enabled_event $pus_storage_selection_definition $pus_packet_store_catalogue $pus_hk_format $pus_sid_storage_selection_definition $pus_OBCP_list $pus_OBCP_dump $pus_event_detection_list pus_parameter_report);

1;

