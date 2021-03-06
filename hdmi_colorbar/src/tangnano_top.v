// ===================================================================
// TITLE : Tang-NANO top module (HDMI output sample)
//
//     DESIGN : s.osafune@j7system.jp (J-7SYSTEM WORKS LIMITED)
//     DATE   : 2020/02/12
// ===================================================================
//
// The MIT License (MIT)
// Copyright (c) 2020 J-7SYSTEM WORKS LIMITED.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

`default_nettype none

module tangnano_top (
	input wire			XTAL_IN,
	input wire	[1:0]	KEY_n,

//	output wire			FPGA_TXD,
//	input wire			FPGA_RXD,

	output wire			LED_R_n,
	output wire			LED_G_n,
	output wire			LED_B_n,

	output wire			PSRAM_CE_n,
	output wire			PSRAM_SCK,
	inout wire	[3:0]	PSRAM_SIO,

//	output wire			LCD_DCLK,
//	output wire			LCD_HSYNC_n,
//	output wire			LCD_VSYNC_n,
//	output wire			LCD_DE,
//	output wire	[4:0]	LCD_R,
//	output wire	[5:0]	LCD_G,
//	output wire	[4:0]	LCD_B,

	output wire			TMDS_CLOCK,		// differential LVCMOS33
	output wire			TMDS_DATA0,		// differential LVCMOS33
	output wire			TMDS_DATA1,		// differential LVCMOS33
	output wire			TMDS_DATA2,		// differential LVCMOS33

	output wire			PIO
);


/* ===== Internal nodes ====================== */

	wire		vclock_x5_sig, pll_locked_sig;
	reg [4:0]	vclk_reg;
	reg			vclk_out_reg;
	wire		vclock_sig		/* synthesis syn_keep = 1 */;
	wire		tx_clock_sig	/* synthesis syn_keep = 1 */;
	wire		reset_sig;

	wire		led_r_sig, led_g_sig, led_b_sig;
	reg [1:0]	key1_reg;
	wire [23:0]	lampy_color_sig, logo_color_sig;
	wire		logo_move_sig;

	wire		vsync_sig, hsync_sig, de_sig;
	wire [7:0]	cb_r_sig, cb_g_sig, cb_b_sig;
	wire		vs_out_sig, hs_out_sig, de_out_sig;
	wire [23:0]	pix_out_sig;



/* ===== Module description ============== */

	assign PSRAM_CE_n = 1'b1;
	assign PSRAM_SCK = 1'b0;
	assign PSRAM_SIO = 4'bzzzz;



	// ----- Clock and Reset signal generate -----

	pll_tmds_vga
	u_pll (
		.reset		(~KEY_n[0]),		// PLL reset
		.clkin		(XTAL_IN),			// input 24.0MHz
		.clkoutd	(vclock_x5_sig),	// TMDS tx clock (126.0MHz)
		.lock		(pll_locked_sig)
	);

	always @(posedge vclock_x5_sig or negedge pll_locked_sig) begin
		if (!pll_locked_sig) begin
			vclk_reg <= 5'b11000;
		end
		else begin
			vclk_reg <= {vclk_reg[3:0], vclk_reg[4]};
		end
	end

	always @(posedge vclock_x5_sig) begin
		vclk_out_reg <= vclk_reg[4];
	end

	BUFG
	u_vclk (
		.I	(vclk_out_reg),
		.O	(vclock_sig)				// Assign to Global Clock Buffer
	);

	assign tx_clock_sig = vclock_x5_sig;
	assign reset_sig = ~pll_locked_sig;



	// ----- On-board LED control -----

	rgb_lampy
	u0 (
		.reset		(reset_sig),
		.clock		(vclock_sig),
		.r_value	(lampy_color_sig[23:16]),
		.g_value	(lampy_color_sig[15:8]),
		.b_value	(lampy_color_sig[7:0]),
		.pwm_red	(led_r_sig),
		.pwm_green	(led_g_sig),
		.pwm_blue	(led_b_sig)
	);

	assign {LED_R_n, LED_G_n, LED_B_n} = ~{led_r_sig, led_g_sig, led_b_sig};

/*
//	タクタイルスイッチを押すとたまにPLLにリセットがかかる（電源ラインのノイズ？）

	always @(posedge vclock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			key1_reg <= 2'b00;
		end
		else begin
			key1_reg <= {key1_reg[0], ~KEY_n[1]};
		end
	end

	assign logo_move_sig = ~key1_reg[1];
	assign logo_color_sig = (key1_reg[1])? lampy_color_sig : 24'hffffff;
*/
	assign logo_move_sig = 1'b1;
	assign logo_color_sig = 24'hffffff;



	// ----- Video signal module -----

	vga_syncgen #(
		.H_TOTAL	(800),				// VGA(640x480,60Hz) / 25.2MHz
		.H_SYNC		(96),
		.H_BACKP	(48),
		.H_ACTIVE	(640),
		.V_TOTAL	(525),
		.V_SYNC		(2),
		.V_BACKP	(33),
		.V_ACTIVE	(480)
	)
	u1 (
		.reset		(reset_sig),
		.video_clk	(vclock_sig),
		.vsync		(vsync_sig),
		.hsync		(hsync_sig),
		.dotenable	(de_sig),
		.cb_rout	(cb_r_sig),
		.cb_gout	(cb_g_sig),
		.cb_bout	(cb_b_sig)
	);

	logo_overlay #(
		.VIEW_X_SIZE	(640),
		.VIEW_Y_SIZE	(480)
	)
	u2 (
		.reset		(reset_sig),
		.clock		(vclock_sig),
		.logo_color	(logo_color_sig),
		.logo_move	(logo_move_sig),
		.vsync_in	(vsync_sig),
		.hsync_in	(hsync_sig),
		.de_in		(de_sig),
		.pixel_in	({cb_r_sig, cb_g_sig, cb_b_sig}),
		.vsync_out	(vs_out_sig),
		.hsync_out	(hs_out_sig),
		.de_out		(de_out_sig),
		.pixel_out	(pix_out_sig)
	);



	// ----- HDMI output module -----

	dvi_encoder_gw #(
		.CLOCK_IODELAY_VALUE	(54),	// These value is adjusted by measuring the actual machine.
		.DATA0_IODELAY_VALUE	(0),
		.DATA1_IODELAY_VALUE	(5),
		.DATA2_IODELAY_VALUE	(42)
	)
	u3 (
		.reset		(reset_sig),
		.clk		(vclock_sig),
		.clk_x5		(tx_clock_sig),
		.vga_r		(pix_out_sig[23:16]),
		.vga_g		(pix_out_sig[15:8]),
		.vga_b		(pix_out_sig[7:0]),
		.vga_de		(de_out_sig),
		.vga_hsync	(hs_out_sig),
		.vga_vsync	(vs_out_sig),

		.clock_p	(TMDS_CLOCK),
		.data0_p	(TMDS_DATA0),
		.data1_p	(TMDS_DATA1),
		.data2_p	(TMDS_DATA2)
	);



endmodule
