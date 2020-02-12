//Copyright (C)2014-2020 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.2.02 Beta
//Created Time: 2020-02-13 01:06:33
create_clock -name video_clock -period 39.683 -waveform {0 15.873} [get_nets {vclock_sig}]
create_clock -name CLOCK_24M -period 41.666 -waveform {0 20.833} [get_ports {XTAL_IN}]
report_timing -setup -from_clock [get_clocks {tx_clock}] -to_clock [get_clocks {tx_clock}] -max_paths 10 -max_common_paths 1
