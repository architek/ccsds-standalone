use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::ParseBinary::Network::Ccsds',
    AUTHOR              => q{Laurent KISLAIRE <teebeenator@gmail.com>},
    VERSION_FROM        => 'lib/Data/ParseBinary/Network/Ccsds.pm',
    ABSTRACT_FROM       => 'lib/Data/ParseBinary/Network/Ccsds.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-ParseBinary-Network-Ccsds-*' },
);
