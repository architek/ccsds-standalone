use inc::Module::Install;

name     'Data-ParseBinary-Network-Ccsds';
all_from 'lib/Data/ParseBinary/Network/Ccsds.pm';
author   q{Laurent KISLAIRE <teebeenator@gmail.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

