// ===================================================================
// TITLE : RGB-Lampy
//
//     DESIGN : s.osafune@j7system.jp (J-7SYSTEM WORKS LIMITED)
//     DATE   : 2019/11/07
//
//     UPDATE : 2020/02/11
// ===================================================================
//
// The MIT License (MIT)
// Copyright (c) 2019-2020 J-7SYSTEM WORKS LIMITED.
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

module rgb_lampy (
	input wire			clock,
	input wire			reset,

	output wire [7:0]	r_value,
	output wire [7:0]	g_value,
	output wire [7:0]	b_value,

	output wire			pwm_red,
	output wire			pwm_green,
	output wire			pwm_blue
);


/* ===== Internal nodes ====================== */

	reg  [26:0]		count_reg;
	wire			pwm_enable_sig;
	wire [7:0]		pwm_count_sig, pwm_value_sig;
	wire [2:0]		phase_sig;
	wire [7:0]		r_value_sig, g_value_sig, b_value_sig;
	reg				r_out_reg, g_out_reg, b_out_reg;



/* ===== Module description ============== */

	assign pwm_enable_sig = (count_reg[6:0] == 0);
	assign pwm_count_sig = count_reg[14:7];
	assign pwm_value_sig = count_reg[23:16];
	assign phase_sig = count_reg[26:24];

	assign r_value_sig =
				(phase_sig == 3'd4 || phase_sig == 3'd5)? 8'd0 :
				(phase_sig == 3'd1 || phase_sig == 3'd2)? 8'd255 :
				(phase_sig == 3'd0)? pwm_value_sig : ~pwm_value_sig;

	assign g_value_sig =
				(phase_sig == 3'd2 || phase_sig == 3'd3)? 8'd0 :
				(phase_sig == 3'd0 || phase_sig == 3'd5)? 8'd255 :
				(phase_sig == 3'd4)? pwm_value_sig : ~pwm_value_sig;

	assign b_value_sig =
				(phase_sig == 3'd0 || phase_sig == 3'd1)? 8'd0 :
				(phase_sig == 3'd3 || phase_sig == 3'd4)? 8'd255 :
				(phase_sig == 3'd2)? pwm_value_sig : ~pwm_value_sig;


	always @(posedge clock or posedge reset) begin
		if (reset) begin
			count_reg <= 1'd0;

			r_out_reg <= 1'b0;
			g_out_reg <= 1'b0;
			b_out_reg <= 1'b0;

		end
		else begin
			if (count_reg == 27'h5ffffff) begin
				count_reg <= 1'd0;
			end
			else begin
				count_reg <= count_reg + 1'd1;
			end

			if (pwm_enable_sig) begin
				if (pwm_count_sig == 0 && r_value_sig != 0) begin
					r_out_reg <= 1'b1;
				end
				else if (pwm_count_sig == r_value_sig) begin
					r_out_reg <= 1'b0;
				end

				if (pwm_count_sig == 0 && g_value_sig != 0) begin
					g_out_reg <= 1'b1;
				end
				else if (pwm_count_sig == g_value_sig) begin
					g_out_reg <= 1'b0;
				end

				if (pwm_count_sig == 0 && b_value_sig != 0) begin
					b_out_reg <= 1'b1;
				end
				else if (pwm_count_sig == b_value_sig) begin
					b_out_reg <= 1'b0;
				end
			end

		end
	end

	assign r_value = r_value_sig;
	assign g_value = g_value_sig;
	assign b_value = b_value_sig;

	assign pwm_red = r_out_reg;
	assign pwm_green = g_out_reg;
	assign pwm_blue = b_out_reg;



endmodule
