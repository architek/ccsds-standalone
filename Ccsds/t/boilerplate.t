#!perl -T

use strict;
use warnings;
use Test::More tests => 14;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - Great new Ccsds encoder&decoder lib/,
        'boilerplate description'     => qr/This module allows to decode and encode most of ccsds structures/,
        'stub function definition'    => qr/function[12]/,
    );
}

TODO: {
  local $TODO = "Need to replace the boilerplate text";

  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );

  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

  module_boilerplate_ok('lib/Ccsds.pm');
  module_boilerplate_ok('lib/Ccsds/Common.pm');
  module_boilerplate_ok('lib/Ccsds/Utils.pm');
  module_boilerplate_ok('lib/Ccsds/StdTime.pm');
  module_boilerplate_ok('lib/Ccsds/TM/Frame.pm');
  module_boilerplate_ok('lib/Ccsds/TM/SourcePacket.pm');
  module_boilerplate_ok('lib/Ccsds/TM/Printer.pm');
  module_boilerplate_ok('lib/Ccsds/TM/Pus.pm');
  module_boilerplate_ok('lib/Ccsds/TM/RM.pm');
  module_boilerplate_ok('lib/Ccsds/TC/Frame.pm');
  module_boilerplate_ok('lib/Ccsds/TC/SourcePacket.pm');
  module_boilerplate_ok('lib/Ccsds/TC/Printer.pm');

}

