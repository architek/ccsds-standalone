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

package TMSgm;
use strict;
use warnings;
use Data::ParseBinary;

our $sgm_read = Struct ('SGM_Slice',
	UBInt16('LengthTotal'),
	UBInt32('SGMId'),
	UBInt32('Group'),
	Switch('Data',sub { $_->ctx->{'Group'} },
		{
			47 => Struct('Group 47',
				UBInt32('Offset'),
				UBInt32('Length2'),
				UBInt32('Validity'),
				UBInt32('CrcGroup'),
				UBInt32('NumberItems'),
				Array(sub { $_->ctx->{'NumberItems'}},
				  Struct('HK',
					UBInt32('Sid'),
					UBInt32('Enabled'),
					UBInt32('CollInt'),
					UBInt32('NPara'),
					UBInt32('ParaList')
				  )
				)
			      ),
			46 => Struct('Group 46',
				UBInt32('Offset'),
				UBInt32('Length2'),
				UBInt32('Validity'),
				UBInt32('CrcGroup'),

				UBInt32('Coarse OBT'),
				UBInt32('SubSeconds OBT'),
				UBInt32('ASW Start Counter'),
				UBInt32('Last SC Mode'),
				UBInt32('FDIR Level 2'),
				UBInt32('Last Active PM'),
				UBInt32('PM Configuration'),
			      )
		},
		default => $DefaultPass,
	)
);


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($sgm_read);

1;
