<<'#';
    Copyright (C) 2010  Laurent Kislaire, teebeenator@gmail.com

    This program is free software: you can redistribute it and or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package TMRM;
use strict;
use warnings;
use Data::ParseBinary;

#TODO Decode bitfields

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

