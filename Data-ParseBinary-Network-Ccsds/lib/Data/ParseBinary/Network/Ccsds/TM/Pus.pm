package Data::ParseBinary::Network::Ccsds::TM::Pus;

use warnings;
use strict;

=head1 NAME

Data::ParseBinary::Network::Ccsds::TM::Pus - Collection for parsing PUS specific

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.2';

use Data::ParseBinary;
use Data::ParseBinary::Network::Ccsds::Common;
use Data::ParseBinary::Network::Ccsds::TM::RM;
use Data::ParseBinary::Network::Ccsds::TM::SGM;
use Data::ParseBinary::Network::Ccsds::TC::SourcePacket;   

our $pus_AckOk = Struct('AckOk',
  UBInt16('TC Packet Id'),
  UBInt16('TC Packet SC')
);

our $pus_AckKo = Struct('AckKo',
  UBInt16('TC Packet Id'),
  UBInt16('TC Packet SC'),
  UBInt16('FID'),
#Parameters are 32bits (hence /4)
  Array(sub { ( $_->ctx(3)->{'Packet Header'}->{'Packet Sequence Control'}->{'Source Data Length'}-6)/4},UBInt32('Params'))
);

our $pus_DirMil = Struct('Pus_DirMil',
  UBInt16('Command Word'),
  UBInt16('Milbus Status'),
  UBInt16('Dsize'),
  Array(sub { $_->ctx->{'Dsize'} },UBInt16('MilData') )
);

our $pus_hk = Struct('Pus HK/Diag',
  UBInt8('SID'),
  Array(sub { $_->ctx(3)->{'Packet Header'}->{'Packet Sequence Control'}->{'Source Data Length'}-1}, UBInt8('Data'))
);

our $pus_hk_report_definition = Struct('Pus HK Report Definition',
  UBInt8('Sid'),
  UBInt8('Collection Interval'),
  Enum(UBInt8('Status'),
  	Disabled => 0,
  	Enabled  => 1
  ),
  UBInt8('NPar'),
  Array(sub { $_->ctx->{'NPar'} },UBInt32('ParamId') )
);

our $pus_Event = Struct('PusEvent',
  UBInt16('EID'),
#Parameters are 32bits (hence /4)
  Array(sub { ( $_->ctx(3)->{'Packet Header'}->{'Packet Sequence Control'}->{'Source Data Length'}-2)/4},UBInt32('Params'))
);

our $pus_enabled_events = Struct('Enabled events',
  UBInt16('NEid'),
  Array(sub { $_->ctx->{'NEid'} },UBInt16('Eids') )
);

#TODO Sub SAU: if PID == NSGU_A then return UBInt32 otherwise UBInt8
our $pus_memory_dump = Struct('Memory Dump',
  UBInt16('Memory Id'),
  UBInt32('Start Address'),
  UBInt16('Length'),
  Array(sub { $_->ctx->{'Length'} },UBInt8('Data') )
);

our $pus_memory_chk = Struct('Memory Check',
  UBInt16('Memory Id'),
  UBInt32('Start Address'),
  UBInt16('Length'),
  UBInt16('Crc')
);

our $pus_function_status = Struct('Function Status',
  UBInt8('N'),
  Array(sub { $_->ctx->{'N'}}, 
  	Struct ('Function Info',
  		UBInt8('Function Id'),
  		BitStruct('Status',
  			Padding(7),
  			Flag('Execution Status'),
  		),
  		Enum(UBInt8('Function Type'),
  			Normal                => 0,
  			Vital                 => 1,
  			'Potential Hazardous' => 2
  		),
  		UBInt32('Enabled Timeout')
  	)
  )
);

our $sw_error_log = Struct('SW Error Log',
  UBInt16('SErr_Count'),
  Array(sub { $_->ctx->{'SErr_Count'}}, 
    Struct('Errors',
      UBInt32('SERR_LOG_SW_ERR_TIMESTAMP_S'),
      UBInt16('SERR_LOG_SW_ERR_TIMESTAMP_SUBS'),
      Value('Time',sub { $_->ctx->{'SERR_LOG_SW_ERR_TIMESTAMP_S'}+$_->ctx->{'SERR_LOG_SW_ERR_TIMESTAMP_SUBS'}/65535 }),
      String('SERR_LOG_SW_ERR_FILE_NAME',14),
      UBInt32('SERR_LOG_SW_ERR_TASK_NAME'),
      UBInt32('SERR_LOG_SW_ERR_FILE_LINE'),
      Array(3,UBInt32('SERR_LOG_SW_ERR_USER_DATA')),
      Array(8,UBInt32('SERR_LOG_SW_ERR_CALL_TRACE')),
  	),
  ),
);

our $pus_sliced = Struct('Sliced',
  UBInt8('Function Id'),
  UBInt8('Nr Current Slice'),
  UBInt8('Total Slice'),
  Value('Length',sub { $_->ctx(3)->{'Packet Header'}->{'Packet Sequence Control'}->{'Source Data Length'}-3}),
  Switch('Data',sub { $_->ctx->{'Function Id'} },
   {
    110   => $sgm_read,
    152   => $sw_error_log,
   },
  default => Array(sub{$_->ctx->{'Length'}},UBInt8('Params'))
  )
);

our $pus_function = Struct('Data',
  UBInt8('Function Id'),
  Switch('Data',sub { $_->ctx->{'Function Id'} },
   {
  	103   => $RMLog
   },
  default => $DefaultPass
  )
);


our $pus_detailed_schedule = Struct('Detailed Schedule',
  UBInt16('N'),
  Array(sub { $_->ctx->{'N'}},
     Struct('Tc',
          $TCPacketHeader,
          $TCSourceSecondaryHeader,
          Array(sub {$_->ctx->{'Packet Header'}->{'Packet Sequence Control'}->{'Source Data Length'}}, UBInt8('TC Application Data')),
          UBInt16('Packet Error Control'),
     )
  )
);

our $pus_summary_schedule = Struct('Summary Schedule',
  UBInt16('N'),
  Array(sub { $_->ctx->{'N'}},
    Struct('TC',
      $Sat_Time,
      BitStruct('Pidb',
        Padding(1),
        $Pid
      ),
      BitStruct('SSCb',
        Padding(2),
        BitField('Source Seq Count',14)
      ),
     )
  )
);

our $pus_command_schedule_status = Struct('Command Schedule Status',
  UBInt8('N'),
  Array(sub { $_->ctx->{'N'}},
    Struct('Status',
  	  BitStruct('Pidb',
  		  Padding(1),
  		  $Pid
  	  ),
      Enum(UBInt8('Status'),
        Disabled => 0,
        Enabled  => 1
      ),
    )
  )
);

my $mon_criteria_lim = Struct('Monitoring Criteria on Limits',
    UBInt32('Low Limit'),
    UBInt16('EID_l'),
    UBInt32('High Limit'),
    UBInt16('EID_h')
);
my $mon_criteria_exp = Struct('Monitoring Criteria on Expected',
    UBInt32('Mask'),
#Filler
  	Padding(2),
    UBInt32('Expected Value'),
    UBInt16('EID')
);


our $pus_current_monitoring_list= Struct('Current Monitoring List',
  UBInt8('Monitoring Status'),
  UBInt8('Maximum Reporting delay'),
  UBInt8('N'),
  Array(sub { $_->ctx->{'N'}}, Struct('Monitorings',
  	UBInt8('Monitoring Id'),
  	UBInt32('ParamId'),
  	UBInt32('Validity ParamId'),
  	UBInt8('Parameter Monitoring Interval'),
  	UBInt8('Rep'),
  	UBInt8('Monitoring Status'),
  	UBInt8('Check Type'),
  	Switch('Check Type',sub { $_->ctx->{'Check Type'} },
  		{
  			0    => $mon_criteria_exp,
        1    => $mon_criteria_lim,
  		},
     default => $DefaultPass
  	)

  ))
);

#TODO Checking status is enum
our $pus_current_monitoring_oo_list= Struct('Current Monitoring OO List',
  UBInt16('N'),
  Array(sub { $_->ctx->{'N'}}, Struct('Limits',
  	UBInt32('ParamId'),
  	UBInt32('Mask'),
  	UBInt32('Parameter Value'),
  	UBInt32('Limit crossed'),
  	UBInt8('Previous Checking Status'),
  	UBInt8('Current Checking Status'),
  	$Sat_Time,
  )
  )
);

our $pus_check_transition= Struct('Check Transition',
  UBInt16('N'),
  Array(sub { $_->ctx->{'N'}}, Struct('Limits',
  	UBInt32('ParamId'),
  	UBInt32('Mask'),
  	UBInt32('Parameter Value'),
  	UBInt32('Limit crossed'),
  	UBInt8('Previous Checking Status'),
  	UBInt8('Current Checking Status'),
  	$Sat_Time,
  ))
);

our $pus_enabled_tm_sourcepacket= Struct('Enabled TM sourcepacket',
  UBInt8('N1'),
  Array(sub { $_->ctx->{'N1'}},Struct('TMSourcePacket',
  	BitStruct('Pidb',
  		Padding(1),
  		$Pid
  	),
  	UBInt8('FStat'),
  	UBInt8('N2'),
  	Array(sub { $_->ctx->{'N2'}},Struct('Types',
  		UBInt8('Type'),
  		UBInt8('FStat'),
  		UBInt8('N3'),
  		Array(sub { $_->ctx->{'N3'}},Struct('SubTypes',
  			UBInt8('SubType'),
  			UBInt8('FStat')
  		))
  	))
  ))
);

our $pus_enabled_hk= Struct('Enabled HK',
  UBInt8('N1'),
  Array(sub { $_->ctx->{'N1'}},Struct('Pids',
  	BitStruct('Pidb',
  		Padding(1),
  		$Pid
  	),
  	UBInt8('N2'),
  	Array(sub { $_->ctx->{'N2'}},Struct('Sids',
  		UBInt8('SID'),
  		UBInt8('FStat')
  	)),
  ))
);

our $pus_enabled_event= Struct('Enabled Events',
  UBInt8('N1'),
  Array(sub { $_->ctx->{'N1'}},Struct('Pids',
  	BitStruct('Pidb',
  		Padding(1),
  		$Pid
  	),
  	UBInt8('N2'),
  	Array(sub { $_->ctx->{'N2'}}, Struct('Eids',
  		UBInt16('EID'),
  		UBInt8('FStat')
  	)),
  )),
);
our $pus_storage_selection_definition= Struct('Storage Selection definition',
  UBInt8('N1'),
  Array(sub { $_->ctx->{'N1'}},Struct('Pids',
  	BitStruct('Pidb',
  		Padding(1),
  		$Pid
  	),
  	UBInt8('StoreId1'),
  	UBInt8('N2'),
  	Array(sub { $_->ctx->{'N2'}},Struct('Types',
  		UBInt8('Type'),
  		UBInt8('StoreId2'),
  		UBInt8('N3'),
  			Array(sub { $_->ctx->{'N3'}},Struct('SubTypes',
  				UBInt8('SubType'),
  				UBInt8('StoreId3')
  			))
  	))
  ))
);

our $pus_packet_store_catalogue= Struct('Packet Store Catalogue',
  UBInt8('N'),
  Array(sub { $_->ctx->{'N'}},Struct('Stores',
  	UBInt8('StoreId'),
  	UBInt32('Storage Time1'),
  	UBInt32('Storage Time2'),
  	UBInt8('Percentage filled'),
  	Padding(9)
  ))
);
our $pus_hk_format= Struct('HK Format',
  UBInt8('N'),
  Array(sub {$_->ctx->{'N'}},Struct('Format',
  	UBInt8('StoreId'),
  	BitStruct('BufferPolb',
  		Padding(7),
  		BitField('Buffer Policy',1)
  	),
  	UBInt32('Number of Bytes')
  ))
);


our $pus_sid_storage_selection_definition= Struct('Sid Storage Selection definition',
  UBInt8('N1'),
  Array(sub { $_->ctx->{'N1'}},Struct('Pids',
  	BitStruct('Pidb',
  		Padding(1),
  		$Pid
  	),
  	UBInt8('N2'),
  	Array(sub { $_->ctx->{'N2'}},Struct('Sids',
  		UBInt16('SID'),
  		UBInt8('StoreId')
  	)),
  ))
);

our $pus_OBCP_list= Struct('OBCP List',
  UBInt8('NProc'),
  Array(sub { $_->ctx->{'NProc'}}, Struct('Procedures',
  	UBInt8('ProcedureId'),
  	UBInt8('Status'),
  	UBInt8('Position')
  ))
);

our $pus_OBCP_dump = Struct('OBCP dump',
  UBInt8('Procedure Id'),
  UBInt8('Procedure Steps'),
  Array(sub { $_->ctx->{'Procedure Steps'}},Struct('Steps',
     UBInt8('Procedure Step'),
     UBInt16('Delay'),
     $tcsourcepacket
  ))
);

#Only mapid 1 are allowed, meaning DFH is always true
our $pus_event_detection_list= Struct('Event detection List',
  UBInt8('N'),
  Array(sub { $_->ctx->{'N'}},
     Struct('TC',
  	   BitStruct('Pidb',
  		   Padding(1),
  		   $Pid
  	   ),
  	   UBInt16('EID'),
  	   UBInt8('Action Status'),
       Struct('Tc',
         $TCPacketHeader,
         $TCSourceSecondaryHeader,
         Array(sub { $_->ctx->{'Packet Header'}->{'Packet Sequence Control'}->{'Source Data Length'}}, UBInt8('TC Application Data')),
         UBInt16('Packet Error Control'),
       )
   	)
  ),
);

our $pus_parameter_report = Struct('Parameter Report',
  	UBInt8('NPar'),
  	Array(sub { $_->ctx(3)->{'Packet Header'}->{'Packet Sequence Control'}->{'Source Data Length'}-1},UBInt8('Params'))
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    $pus_AckOk 
    $pus_DirMil 
    $pus_hk 
    $pus_hk_report_definition 
    $pus_enabled_events 
    $pus_memory_dump 
    $pus_memory_dump 
    $pus_memory_chk 
    $pus_function_status 
    $pus_function 
    $pus_AckKo 
    $pus_Event 
    $pus_sliced 
    $pus_detailed_schedule 
    $pus_summary_schedule 
    $pus_command_schedule_status 
    $pus_current_monitoring_list  
    $pus_current_monitoring_oo_list 
    $pus_check_transition 
    $pus_enabled_tm_sourcepacket 
    $pus_enabled_hk 
    $pus_enabled_event 
    $pus_storage_selection_definition 
    $pus_packet_store_catalogue 
    $pus_hk_format 
    $pus_sid_storage_selection_definition 
    $pus_OBCP_list 
    $pus_OBCP_dump 
    $pus_event_detection_list 
    $pus_parameter_report
);

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Data::ParseBinary::Network::Ccsds::TM::Pus;

    my $foo = Data::ParseBinary::Network::Ccsds::TM::Pus->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2    $pus_AckOk 
=cut
=head2    $pus_DirMil 
=cut
=head2    $pus_hk 
=cut
=head2    $pus_hk_report_definition 
=cut
=head2    $pus_enabled_events 
=cut
=head2    $pus_memory_dump 
=cut
=head2    $pus_memory_dump 
=cut
=head2    $pus_memory_chk 
=cut
=head2    $pus_function_status 
=cut
=head2    $pus_function 
=cut
=head2    $pus_AckKo 
=cut
=head2    $pus_Event 
=cut
=head2    $pus_sliced 
=cut
=head2    $pus_detailed_schedule 
=cut
=head2    $pus_summary_schedule 
=cut
=head2    $pus_command_schedule_status 
=cut
=head2    $pus_current_monitoring_list  
=cut
=head2    $pus_current_monitoring_oo_list 
=cut
=head2    $pus_check_transition 
=cut
=head2    $pus_enabled_tm_sourcepacket 
=cut
=head2    $pus_enabled_hk 
=cut
=head2    $pus_enabled_event 
=cut
=head2    $pus_storage_selection_definition 
=cut
=head2    $pus_packet_store_catalogue 
=cut
=head2    $pus_hk_format 
=cut
=head2    $pus_sid_storage_selection_definition 
=cut
=head2    $pus_OBCP_list 
=cut
=head2    $pus_OBCP_dump 
=cut
=head2    $pus_event_detection_list 
=cut
=head2    $pus_parameter_report
=cut

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::ParseBinary::Network::Ccsds::TM::Pus


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-ParseBinary-Network-Ccsds>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-ParseBinary-Network-Ccsds>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-ParseBinary-Network-Ccsds>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-ParseBinary-Network-Ccsds/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Laurent KISLAIRE.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::ParseBinary::Network::Ccsds::TM::Pus
