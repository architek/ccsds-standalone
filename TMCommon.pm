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

