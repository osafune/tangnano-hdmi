//Copyright (C)2014-2020 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.2.02 Beta
//Created Time: 2020-02-11 00:12:51
create_clock -name tx_clock -period 7.937 -waveform {0 3.969} [get_nets {tx_clock_sig}]
create_clock -name tmds_clock -period 39.683 -waveform {0 19.841} [get_ports {TMDS_CLOCK}]
create_clock -name video_clock -period 39.683 -waveform {0 19.841} [get_nets {vclock_sig}]
create_clock -name CLOCK_24M -period 41.666 -waveform {0 20.833} [get_ports {XTAL_IN}]
set_output_delay -clock tmds_clock 0.5 [get_ports {TMDS_DATA0 TMDS_DATA1 TMDS_DATA2}]
report_timing -setup -from_clock [get_clocks {tx_clock}] -to_clock [get_clocks {tx_clock}] -max_paths 10
