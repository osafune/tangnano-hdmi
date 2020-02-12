//Copyright (C)2014-2019 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.2.02Beta
//Part Number: GW1N-LV1QN48C6/I5
//Created Time: Thu Feb 13 01:04:23 2020

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    pll_tmds_vga your_instance_name(
        .clkout(clkout_o), //output clkout
        .lock(lock_o), //output lock
        .clkoutd(clkoutd_o), //output clkoutd
        .reset(reset_i), //input reset
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
