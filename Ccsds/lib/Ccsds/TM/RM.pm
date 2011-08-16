package Ccsds::TM::RM;

use warnings;
use strict;

=head1 NAME

Ccsds::TM::RM - CROME2 RM Log decoding

=cut

use Data::ParseBinary;

# • Time stamp
# • Conditioned alarms leading to reconfiguration
# • Status inputs at the start of pattern matching
# • Matched PAP index
# • Selected attempt index

our $RMLogEntry = Struct('RMLogEntry',
  UBInt8('TSS1'), 
  UBInt8('TSS2'),
  UBInt8('TS1'), 
  UBInt8('TS2'),
  UBInt8('TS3'), 
  UBInt8('TS4'),
  
  UBInt8('CA1'),
  UBInt8('CA2'),
  BitStruct('CA3b',
    Padding(2),
    BitField('CA3',6)
  ),

  UBInt8('Sts1'), 
  UBInt8('Sts2'),
  UBInt8('Sts3'),
  UBInt8('Sts4'),

  UBInt8('Pattern No'),

  UBInt8('AtIdx1'),
  BitStruct('AtIdxb',
  	Padding(6),
  	BitField('AtIdx2',2),
  ),
  Value('TimeStamp', sub { $_->ctx->{'TS1'}+$_->ctx->{'TS2'}<<8+$_->ctx->{'TS3'}<<16+$_->ctx->{'TS4'}<<24+ ($_->ctx->{'TSS1'}+$_->ctx->{'TSS2'}<<8)/65535 }),
  Value('Conditioned Alarm', sub { $_->ctx->{'CA1'}+$_->ctx->{'CA2'}<<8+$_->ctx->{'CA3b'}->{'CA3'}<<16 }),
  Value('Status Input', sub { $_->ctx->{'Sts1'}+$_->ctx->{'Sts2'}<<8+$_->ctx->{'Sts3'}<<16+$_->ctx->{'Sts4'}<<24 }),
  Value('Attempt index', sub { $_->ctx->{'AtIdx1'}+$_->ctx->{'AtIdxb'}->{'AtIdx2'}<<8 }),

  Value('WDA',     sub {  $_->ctx->{'Conditioned Alarm'}&1 }),
  Value('WDB',     sub { ($_->ctx->{'Conditioned Alarm'}&1<<1)>>1}),
  Value('EPA',     sub { ($_->ctx->{'Conditioned Alarm'}&1<<2)>>2}),
  Value('EPB',     sub { ($_->ctx->{'Conditioned Alarm'}&1<<3)>>3}),
  Value('BatA',    sub { ($_->ctx->{'Conditioned Alarm'}&1<<4)>>4 }),
  Value('BatB',    sub { ($_->ctx->{'Conditioned Alarm'}&1<<5)>>5 }),
  Value('Thr',     sub { ($_->ctx->{'Conditioned Alarm'}&1<<6)>>6 }),
  Value('SunLoss', sub { ($_->ctx->{'Conditioned Alarm'}&1<<7)>>7 }),
  Value('TempCtl', sub { ($_->ctx->{'Conditioned Alarm'}&1<<8)>>8 }),
  Value('PMAhw',   sub { ($_->ctx->{'Conditioned Alarm'}&1<<9)>>9 }),
  Value('PMAall',  sub { ($_->ctx->{'Conditioned Alarm'}&1<<10)>>10 }),
  Value('PMAuv',   sub { ($_->ctx->{'Conditioned Alarm'}&1<<11)>>11 }),
  Value('PMAsw',   sub { ($_->ctx->{'Conditioned Alarm'}&1<<12)>>12 }),
  Value('PMBhw',   sub { ($_->ctx->{'Conditioned Alarm'}&1<<13)>>13 }),
  Value('PMBall',  sub { ($_->ctx->{'Conditioned Alarm'}&1<<14)>>14 }),
  Value('PMBuv',   sub { ($_->ctx->{'Conditioned Alarm'}&1<<15)>>15 }),
  Value('PMBsw',   sub { ($_->ctx->{'Conditioned Alarm'}&1<<16)>>16 }),
  Value('SelPM',   sub { ($_->ctx->{'Conditioned Alarm'}&1<<17)>>17 }),
  Value('Sep1',    sub { ($_->ctx->{'Conditioned Alarm'}&1<<18)>>18 }),
  Value('Sep2',    sub { ($_->ctx->{'Conditioned Alarm'}&1<<19)>>19 }),
  Value('Sep3',    sub { ($_->ctx->{'Conditioned Alarm'}&1<<20)>>20 }),
  Value('WDen',    sub { ($_->ctx->{'Conditioned Alarm'}&1<<21)>>21 }),

  Value('au',      sub {  $_->ctx->{'Status Input'}&1 }),
  Value('auRed',   sub { ($_->ctx->{'Status Input'}&1<<1)>>1 }),
  Value('tmEnc',   sub { ($_->ctx->{'Status Input'}&1<<2)>>2 }),
  Value('pmAct',   sub { ($_->ctx->{'Status Input'}&1<<3)>>3 }),
  Value('wd',      sub { ($_->ctx->{'Status Input'}&1<<4)>>4 }),
  Value('rm',      sub { ($_->ctx->{'Status Input'}&1<<5)>>5 }),
  Value('rmRed',   sub { ($_->ctx->{'Status Input'}&1<<6)>>6 }),
  Value('buttrRed',sub { ($_->ctx->{'Status Input'}&1<<7)>>7 }),
  Value('pmBit1',  sub { ($_->ctx->{'Status Input'}&1<<8)>>8 }),
  Value('sdram',   sub { ($_->ctx->{'Status Input'}&1<<9)>>9 }),

  Value('pmA',     sub { ($_->ctx->{'Status Input'}&1<<11)>>11 }),
  Value('pmB',     sub { ($_->ctx->{'Status Input'}&1<<12)>>12 }),
  Value('pmBit0',  sub { ($_->ctx->{'Status Input'}&1<<13)>>13 }),

  Value('eeprom',  sub { ($_->ctx->{'Status Input'}&1<<19)>>19 }),
);

our $RMLog = Struct('RMLog',
  UBInt32('Pointer'),
  Array(16, $RMLogEntry)
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($RMLogEntry $RMLog);

=head1 SYNOPSIS

 Decodes an CROME2 RM Log.
 This module is complete for one Sat Mission. 
 For other Mission, one needs to check and adapt the format of an RM Log.
 Thus, the calls to this module are removed from higher level decoding.

=head1 AUTHOR

Laurent KISLAIRE, C<< <teebeenator at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-parsebinary-network-ccsds at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ParseBinary-Network-Ccsds>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=cut

1; # End of Ccsds::TM::RM
