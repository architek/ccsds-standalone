use strict;
use warnings;
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

package TMCommon;
use Data::ParseBinary;

our $Sat_Time = Struct('Sat_Time',
	UBInt32('Seconds'),
	UBInt16('SubSeconds'),
	Value('OBT', sub { $_->ctx->{'Seconds'} + $_->ctx->{'SubSeconds'}/65535 } )
);

our $Pid = Enum(BitField('PID',7),
		TIME => 0x0,
                SYS => 0x10,
                AOC => 0x11,
                PF  => 0x12,
                PL  => 0x13,
		PFSUA_STMTC => 0x22,
		PFSUA_TMTC => 0x24,
		PFSUB_STMTC => 0x2A,
		PFSUB_TMTC => 0x2C,
		PLSU_C_Band => 0x32,
		PLSU_PRS => 0x33,
		PLSU_TMTC => 0x34,
		NSGU_S => 0x40,
		NSGU_L => 0x48,
        	_default_ => $DefaultPass
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($Sat_Time $Pid); 

1;

