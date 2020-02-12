// ===================================================================
// TITLE : Logo Overlay
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

module logo_overlay #(
	parameter	VIEW_X_SIZE		= 640,
	parameter	VIEW_Y_SIZE		= 480
) (
	output wire			test_frame_begin,
	output wire			test_line_begin,
	output wire			test_line_end,
	output wire [8:0]	test_addr_y,
	output wire [9:0]	test_addr_x,
	output wire			test_rom_q,
	output wire			test_logopix_ena,


	input wire			clock,
	input wire			reset,
	input wire [23:0]	logo_color,
	input wire			logo_move,

	input wire			vsync_in,
	input wire			hsync_in,
	input wire			de_in,
	input wire [23:0]	pixel_in,

	output wire			vsync_out,
	output wire			hsync_out,
	output wire			de_out,
	output wire [23:0]	pixel_out
);


/* ===== Internal nodes ====================== */

	localparam		LOGO_X_SIZE = 256;
	localparam		LOGO_Y_SIZE = 148;
	localparam		POS_BEGIN_X = 0 + 1;
	localparam		POS_BEGIN_Y = 0 + 1;
	localparam		POS_END_X = (VIEW_X_SIZE-1) - LOGO_X_SIZE - 1;
	localparam		POS_END_Y = (VIEW_Y_SIZE-1) - LOGO_Y_SIZE - 1;


	reg  [1:0]		delay_hs_reg, delay_vs_reg, delay_de_reg;
	reg  [23:0]		delay_pix0_reg;
	wire			frame_begin_sig, line_begin_sig, line_end_sig, dot_active_sig;

	reg  [8:0]		pos_x_reg;
	reg  [9:0]		pos_y_reg;
	reg				vec_x_reg, vec_y_reg;
	wire [8:0]		logo_sy_sig;
	wire [9:0]		logo_sx_sig;

	wire [23:0]		logo_pixel_sig;
	reg  [8:0]		y_count_reg;
	reg  [9:0]		x_count_reg;
	reg				y_enable_reg, x_enable_reg;
	wire			logopix_ena_sig;
	reg  [23:0]		pix_out_reg;

	wire [8:0]		addr_y_sig;
	wire [9:0]		addr_x_sig;
	wire			pattern_q_sig;


/* ===== Module description ============== */

	assign test_frame_begin = frame_begin_sig;
	assign test_line_begin = line_begin_sig;
	assign test_line_end = line_end_sig;
	assign test_addr_y = addr_y_sig;
	assign test_addr_x = addr_x_sig;
	assign test_rom_q = pattern_q_sig;
	assign test_logopix_ena = logopix_ena_sig;


	// ----- Sync signal delay -----

	always @(posedge clock or posedge reset) begin
		if (reset) begin
			delay_vs_reg <= 2'b00;
			delay_hs_reg <= 2'b00;
			delay_de_reg <= 2'b00;
			delay_pix0_reg <= 24'h000000;
		end
		else begin
			delay_vs_reg <= {delay_vs_reg[0], ~vsync_in};
			delay_hs_reg <= {delay_hs_reg[0], ~hsync_in};
			delay_de_reg <= {delay_de_reg[0], de_in};

			delay_pix0_reg <= pixel_in;
		end
	end

	assign frame_begin_sig = (delay_vs_reg[1:0] == 2'b01);
	assign line_begin_sig = (delay_hs_reg[1:0] == 2'b01);
	assign line_end_sig = (delay_de_reg[1:0] == 2'b10);
	assign dot_active_sig = (de_in == 1'b1);

	assign logo_pixel_sig = logo_color;



	// ----- Logo position -----

	always @(posedge clock or posedge reset) begin
		if (reset) begin
			pos_x_reg <= 1'd0;
			pos_y_reg <= 1'd0;
			vec_x_reg <= 1'b1;
			vec_y_reg <= 1'b1;
		end
		else begin
			if (frame_begin_sig && logo_move) begin
				if (vec_x_reg) begin
					pos_x_reg <= pos_x_reg + 1'd1;

					if (pos_x_reg == POS_END_X[9:0]) begin
						vec_x_reg <= 1'b0;
					end
				end
				else begin
					pos_x_reg <= pos_x_reg - 1'd1;

					if (pos_x_reg == POS_BEGIN_X[9:0]) begin
						vec_x_reg <= 1'b1;
					end
				end

				if (vec_y_reg) begin
					pos_y_reg <= pos_y_reg + 1'd1;

					if (pos_y_reg == POS_END_Y[8:0]) begin
						vec_y_reg <= 1'b0;
					end
				end
				else begin
					pos_y_reg <= pos_y_reg - 1'd1;

					if (pos_y_reg == POS_BEGIN_Y[8:0]) begin
						vec_y_reg <= 1'b1;
					end
				end
			end
		end
	end

	assign logo_sy_sig = pos_y_reg;
	assign logo_sx_sig = pos_x_reg;



	// ----- Overlay control -----

	always @(posedge clock or posedge reset) begin
		if (reset) begin
			y_count_reg <= 1'd0;
			x_count_reg <= 1'd0;
			y_enable_reg <= 1'b0;
			x_enable_reg <= 1'b0;
			pix_out_reg <= 24'h000000;
		end
		else begin

			if (frame_begin_sig) begin
				y_count_reg <= 1'd0;
			end
			else if (line_end_sig) begin
				y_count_reg <= y_count_reg + 1'd1;
			end

			if (line_begin_sig) begin
				x_count_reg <= 1'd0;
			end
			else if (dot_active_sig) begin
				x_count_reg <= x_count_reg + 1'd1;
			end

			if (line_begin_sig) begin
				if (y_count_reg == logo_sy_sig) begin
					y_enable_reg <= 1'b1;
				end
				else if (y_count_reg == logo_sy_sig + LOGO_Y_SIZE[8:0]) begin
					y_enable_reg <= 1'b0;
				end
			end
			else if (frame_begin_sig) begin
				y_enable_reg <= 1'b0;
			end

			if (dot_active_sig) begin
				if (x_count_reg == logo_sx_sig) begin
					x_enable_reg <= 1'b1;
				end
				else if (x_count_reg == logo_sx_sig + LOGO_X_SIZE[9:0]) begin
					x_enable_reg <= 1'b0;
				end
			end
			else begin
				x_enable_reg <= 1'b0;
			end


			if (logopix_ena_sig) begin
				pix_out_reg <= logo_pixel_sig;
			end
			else begin
				pix_out_reg <= delay_pix0_reg;
			end
		end
	end



	// ----- Pattern rom -----

	assign addr_y_sig = y_count_reg - logo_sy_sig;
	assign addr_x_sig = x_count_reg - logo_sx_sig;

	logo_pattern_rom
	u_rom (
		.reset	(reset),
		.clk	(clock),
		.ce		(1'b1),
		.oce	(1'b1),
		.ad		({addr_y_sig[7:0], addr_x_sig[7:0]}),
		.dout	(pattern_q_sig)
    );

	assign logopix_ena_sig = y_enable_reg & x_enable_reg & pattern_q_sig;



	// ----- Signal output -----

	assign vsync_out = ~delay_vs_reg[1];
	assign hsync_out = ~delay_hs_reg[1];
	assign de_out = delay_de_reg[1];

	assign pixel_out = pix_out_reg;



endmodule
