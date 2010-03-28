package TMCommon;
use strict;
use warnings;
use Data::ParseBinary;

our $Sat_Time = Struct("Sat_Time",
	UBInt32("Seconds"),
	UBInt16("SubSeconds"),
	Value("OBT", sub { $_->ctx->{"Seconds"} + $_->ctx->{"SubSeconds"}/65535 } )
);

our $Pid = Enum(BitField("PID",7),
                SYS => 0x10,
                AOC => 0x11,
                PF  => 0x12,
                PL  => 0x13,
        	_default_ => $DefaultPass
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($Sat_Time $Pid); 

1;

