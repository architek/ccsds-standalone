#!/usr/bin/perl -w
#      Example of plugins
#===============================================================================

use strict;

#my %ssc = ();

my $lognamec = $logname;
my $lognames = $logname;
$lognamec |= "log_client";
$lognames |= "log_server";
open my $fc, ">", "${lognamec}_${host}_$port.ccs";
open my $fs, ">", "${lognames}_$PORT.ccs";

# Logs packets
my $m_log = sub {
    my ( $data, $FILE ) = @_;
    syswrite( $FILE, $data ) if $mdebug;
    return $data;
};

# Dump packets
my $m_dump = sub {
    my ( $data, undef ) = @_;
    #Decoding
    my $decoded = tmsourcepacket($data);

    #Print the packet
    print Dumper $decoded ;
    return $data;
}

# Modify packets on the fly
my $m_correct_packets_to_client = sub {
    my ( $data, undef ) = @_;
    my $decoded = tmsourcepacket($data);
    #Get important fields
    my $f_header = $decoded->{'TM Source Packet'}->{'Packet Header'}; my $f_data   = $decoded->{'TM Source Packet'}->{'Packet Data Field'};
    my $f_pec    = \$f_data->{'Packet Error Control'}; my $f_dfh    = $f_header->{'Packet Id'}->{'DFH Flag'};
    my $f_pid    = $f_header->{'Packet Id'}->{'Apid'}->{'PID'};
    #Get rest of fields
    my $f_sec_header = $f_data->{'TMSourceSecondaryHeader'};
    my $f_pus_t      = $f_sec_header->{'Service Type'}; my $f_pus_st     = $f_sec_header->{'Service SubType'};

#    my $f_pus_time   = $f_sec_header->{'Sat_Time'};
#    my $f_pus_version =
#      $f_sec_header->{'SecHeadFirstField'}->{'PUS Version Number'};
#    my $f_packet_length =
#      \$f_header->{'Packet Sequence Control'}->{'Packet Length'};
#    my $f_data_length =
#      $f_header->{'Packet Sequence Control'}->{'Source Data Length'};
#    my $f_data_ssc =
#      $f_header->{'Packet Sequence Control'}->{'Source Seq Count'};

    #SSC check
    #FIXME ssc depends on f_pid or f_apid?
#    my $delta_ssc = $f_data_ssc - $ssc{$f_pid};
#   print
"Possible reboot: ssc gap of $delta_ssc (from $ssc{$f_pid} to $f_data_ssc ) for $f_pid\n" unless ($delta_ssc%0xFFFF == 1);
#   $ssc{$f_pid} = $f_data_ssc;

    #Correct some broken traffic
    if ( $f_pid == 6 and $f_pus_t == 3 and $f_pus_st == 25 ) {
        $$f_packet_length += 2;
    }
    $data = $tmsourcepacket->build($decoded);
    #recalculate crc
    substr( $data, -2 ) = pack( 'H*', calc_crc( substr( $data, 0, -2 ) ) );
    
    #extra check check crc again
    warn "Wrong Crc on rebuild" unless tm_verify_crc_bin $data;
    return $data;
};

