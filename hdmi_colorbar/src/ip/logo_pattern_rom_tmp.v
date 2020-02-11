//Copyright (C)2014-2019 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.2.02Beta
//Part Number: GW1N-LV1QN48C6/I5
//Created Time: Mon Feb 10 05:35:32 2020

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    logo_pattern_rom your_instance_name(
        .dout(dout_o), //output [0:0] dout
        .clk(clk_i), //input clk
        .oce(oce_i), //input oce
        .ce(ce_i), //input ce
        .reset(reset_i), //input reset
        .ad(ad_i) //input [15:0] ad
    );

//--------Copy end-------------------
