package TMSgm;
use strict;
use warnings;
use Data::ParseBinary;

our $sgm_read = Struct ("SGM_Slice",
	UBInt16("LengthTotal"),
	UBInt32("SGMId"),
	UBInt32("Group"),
	Switch("Data",sub { $_->ctx->{'Group'} },
		{
			47 => Struct("Group 47",
				UBInt32("Offset"),
				UBInt32("Length2"),
				UBInt32("Validity"),
				UBInt32("CrcGroup"),
				UBInt32("NumberItems"),
				Array(sub { $_->ctx->{"NumberItems"}},
				  Struct("HK",
					UBInt32("Sid"),
					UBInt32("Enabled"),
					UBInt32("CollInt"),
					UBInt32("NPara"),
					UBInt32("ParaList")
				  )
				)
			      )
		},
		default => $DefaultPass,
	)
);


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($sgm_read);

1;
