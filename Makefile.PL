use inc::Module::Install;

name 'Ccsds';
all_from 'lib/Ccsds.pm';
author q{Laurent KISLAIRE <teebeenator@gmail.com>};
license 'perl';

build_requires 'Test::More';
requires 'Data::ParseBinary' => '0';
requires 'Digest::CRC'       => '0';
requires 'DateTime'          => '0';
requires 'Try::Tiny'         => '0';

test =>
  { TESTS => q[t/00-load.t t/pod.t t/01-crc.t t/02-decode.t] };

auto_install;

WriteAll;

