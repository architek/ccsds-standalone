use inc::Module::Install;

name     'Ccsds';
all_from 'lib/Ccsds.pm';
author   q{Laurent KISLAIRE <teebeenator@gmail.com>};
license  'perl';

build_requires 'Test::More';
requires 'Data::ParseBinary'  => '0.27';
requires 'Digest::CRC'        => '0.14';

auto_install;

WriteAll;

