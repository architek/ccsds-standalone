#tc 3,131!!!!
package TMRM;
use strict;
use warnings;
use Data::ParseBinary;


# • Time stamp
# • Conditioned alarms leading to reconfiguration
# • Status inputs at the start of pattern matching
# • Matched PAP index
# • Selected attempt index

our $RMLogEntry = Struct("RMLogEntry",
	UBInt8("TSS1"), 
	UBInt8("TSS2"),
	UBInt8("TS1"), 
	UBInt8("TS2"),
	UBInt8("TS3"), 
	UBInt8("TS4"),
	
	UBInt8("CA1"),
	UBInt8("CA2"),
	BitStruct("CA3b",
		Padding(2),
		BitField("CA3",6)
	),

	UBInt8("Sts1"), 
	UBInt8("Sts2"),
	UBInt8("Sts3"),
	UBInt8("Sts4"),

	UBInt8("Pattern No"),

	UBInt8("AtIdx1"),
	BitStruct("AtIdxb",
		Padding(6),
		BitField("AtIdx2",2),
	),
	Value("TimeStamp", sub { $_->ctx->{"TS1"}+$_->ctx->{"TS2"}*256+$_->ctx->{"TS3"}*65536+$_->ctx->{"TS4"}*256*65536+ ($_->ctx->{"TSS1"}+$_->ctx->{"TSS2"}*256)/65535 }),
	Value("Conditioned Alarm", sub { $_->ctx->{"CA1"}+$_->ctx->{"CA2"}*256+$_->ctx->{"CA3b"}->{"CA3"}*65536 }),
	Value("Status Input", sub { $_->ctx->{"Sts1"}+$_->ctx->{"Sts2"}*256+$_->ctx->{"Sts3"}*65536+$_->ctx->{"Sts4"}*256*65536 }),
	Value("Attempt index", sub { $_->ctx->{"AtIdx1"}+$_->ctx->{"AtIdxb"}->{"AtIdx2"}*256 })
);

our $RMLog = Struct("RMLog",
#	Enum(UBInt8("RMId"),
#		RM_A=>0,
#		RM_B=>1
#	),
	UBInt16(undef),
	UBInt32("Pointer"),
	Array(16, $RMLogEntry)
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($RMLogEntry $RMLog);

1;

