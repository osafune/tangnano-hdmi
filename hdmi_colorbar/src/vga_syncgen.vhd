-- ===================================================================
-- TITLE : VGA Sync Generator
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2010/12/10 -> 2010/12/27
--
--     UPDATE : 2012/02/21 add pixelena signal(for ATM0430D5)
--            : 2013/07/29 add colorbar generator
--            : 2018/05/13 delete dither
--
--     Github : https://github.com/osafune/misc_hdl_module
--
-- ===================================================================

-- The MIT License (MIT)
-- Copyright (c) 2010-2018 J-7SYSTEM WORKS LIMITED.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity vga_syncgen is
	generic (
		H_TOTAL		: integer := 800;	-- VGA(640x480) / 25.175MHz
		H_SYNC		: integer := 96;
		H_BACKP		: integer := 48;
		H_ACTIVE	: integer := 640;
		V_TOTAL		: integer := 525;
		V_SYNC		: integer := 2;
		V_BACKP		: integer := 33;
		V_ACTIVE	: integer := 480

--		H_TOTAL		: integer := 525;	-- ATM0430D5(480x272) / 9.0MHz
--		H_SYNC		: integer := 40;
--		H_BACKP		: integer := 0;
--		H_ACTIVE	: integer := 480;
--		V_TOTAL		: integer := 288;
--		V_SYNC		: integer := 3;
--		V_BACKP		: integer := 0;
--		V_ACTIVE	: integer := 272

--		H_TOTAL		: integer := 953;	-- RasPi 5inch HDMI Display(800x480) / 30.0MHz
--		H_SYNC		: integer := 48;
--		H_BACKP		: integer := 40;
--		H_ACTIVE	: integer := 800;
--		V_TOTAL		: integer := 525;
--		V_SYNC		: integer := 3;
--		V_BACKP		: integer := 29;
--		V_ACTIVE	: integer := 480
	);
	port (
		reset		: in  std_logic;		-- active high
		video_clk	: in  std_logic;		-- typ 25.175MHz

		scan_ena	: in  std_logic := '0';	-- framebuff scan enable
		framestart	: out std_logic;
		linestart	: out std_logic;
		pixelena	: out std_logic;		-- pixel readout active

		hsync		: out std_logic;
		vsync		: out std_logic;
		hblank		: out std_logic;
		vblank		: out std_logic;
		dotenable	: out std_logic;
		cb_rout		: out std_logic_vector(7 downto 0);		-- colorbar pixeldata
		cb_gout		: out std_logic_vector(7 downto 0);
		cb_bout		: out std_logic_vector(7 downto 0)
	);
end vga_syncgen;

architecture RTL of vga_syncgen is
	signal hcount	: integer range 0 to H_TOTAL-1;
	signal vcount	: integer range 0 to V_TOTAL-1;

	signal scan_in_reg	: std_logic;
	signal scanena_reg	: std_logic;
	signal frame_reg	: std_logic;
	signal line_reg		: std_logic;
	signal hsync_reg	: std_logic;
	signal vsync_reg	: std_logic;
	signal hblank_reg	: std_logic;
	signal vblank_reg	: std_logic;


	constant CB_LEFTBAND	: integer := H_SYNC + H_BACKP + H_ACTIVE/8 - 1;
	constant CB_75WHITE		: integer := H_SYNC + H_BACKP + H_ACTIVE/8 + (H_ACTIVE*3*1)/28 - 1;
	constant CB_75YELLOW	: integer := H_SYNC + H_BACKP + H_ACTIVE/8 + (H_ACTIVE*3*2)/28 - 1;
	constant CB_75CYAN		: integer := H_SYNC + H_BACKP + H_ACTIVE/8 + (H_ACTIVE*3*3)/28 - 1;
	constant CB_75GREEN		: integer := H_SYNC + H_BACKP + H_ACTIVE/8 + (H_ACTIVE*3*4)/28 - 1;
	constant CB_75MAGENTA	: integer := H_SYNC + H_BACKP + H_ACTIVE/8 + (H_ACTIVE*3*5)/28 - 1;
	constant CB_75RED		: integer := H_SYNC + H_BACKP + H_ACTIVE/8 + (H_ACTIVE*3*6)/28 - 1;
	constant CB_75BLUE		: integer := H_SYNC + H_BACKP + H_ACTIVE/8 + (H_ACTIVE*3*7)/28 - 1;
	constant CB_RIGHTBAND	: integer := H_SYNC + H_BACKP + H_ACTIVE - 1;
	constant CB_NORMAL_V	: integer := V_SYNC + V_BACKP + (V_ACTIVE*7)/12 - 1;
	constant CB_GRAY_V		: integer := V_SYNC + V_BACKP + (V_ACTIVE*8)/12 - 1;
	constant CB_WLAMP_V		: integer := V_SYNC + V_BACKP + (V_ACTIVE*9)/12 - 1;
	constant CB_RLAMP_V		: integer := V_SYNC + V_BACKP + (V_ACTIVE*10)/12 - 1;
	constant CB_GLAMP_V		: integer := V_SYNC + V_BACKP + (V_ACTIVE*11)/12 - 1;
	constant CB_BLAMP_V		: integer := V_SYNC + V_BACKP + V_ACTIVE - 1;
	constant CB_LAMPSTEP	: integer := (255*256)/(H_ACTIVE*3/4);

	type STATE_CB_AREA is (LEFTBAND1, WHITE, YELLOW, CYAN, GREEN, MAGENTA, RED, BLUE, RIGHTBAND1,
							LEFTBAND2, FULLWHITE, GRAY, RIGHTBAND2,
							LEFTBAND3, WHITELAMP, RIGHTBAND3,
							LEFTBAND4, REDLAMP, RIGHTBAND4,
							LEFTBAND5, GREENLAMP, RIGHTBAND5,
							LEFTBAND6, BLUELAMP, RIGHTBAND6);
	signal areastate : STATE_CB_AREA;
	signal lampcount	: integer range 0 to 255*256;
	signal cblamp_sig	: std_logic_vector(15 downto 0);
	signal cb_rout_reg	: std_logic_vector(7 downto 0);
	signal cb_gout_reg	: std_logic_vector(7 downto 0);
	signal cb_bout_reg	: std_logic_vector(7 downto 0);

begin

	-- ビデオ同期信号生成 

	framestart <= frame_reg;	-- 必ずレジスタ出力 
	linestart  <= line_reg;		-- 必ずレジスタ出力 
	pixelena   <= scanena_reg when (hblank_reg = '0' and vblank_reg = '0') else '0';

	hsync  <= hsync_reg;
	vsync  <= vsync_reg;
	hblank <= hblank_reg;
	vblank <= vblank_reg;
	dotenable <= (not hblank_reg) and (not vblank_reg);

	process (video_clk, reset) begin
		if (reset = '1') then
			hcount <= H_TOTAL-1;
			vcount <= V_TOTAL-1;

			scan_in_reg <= '0';
			scanena_reg <= '0';
			frame_reg   <= '0';
			line_reg    <= '0';
			hsync_reg   <= '0';
			vsync_reg   <= '0';
			hblank_reg  <= '1';
			vblank_reg  <= '1';

		elsif(video_clk'event and video_clk='1') then
			scan_in_reg <= scan_ena;

			if (hcount = 0 and vcount = 0) then
				scanena_reg <= scan_in_reg;
			end if;


			if (hcount = H_TOTAL-1) then
				hcount <= 0;
			else
				hcount <= hcount + 1;
			end if;

			if (hcount = H_TOTAL-1) then
				hsync_reg <= '1';
			elsif (hcount = H_SYNC-1) then
				hsync_reg <= '0';
			end if;

			if (hcount = H_SYNC + H_BACKP-1) then
				hblank_reg <= '0';
			elsif (hcount = H_SYNC + H_BACKP + H_ACTIVE-1) then
				hblank_reg <= '1';
			end if;


			if (hcount = H_SYNC + H_BACKP + H_ACTIVE-1) then
				if (vcount = V_TOTAL-1) then
					vcount <= 0;
				else
					vcount <= vcount + 1;
				end if;

				if (vcount = V_TOTAL-1) then
					vsync_reg <= '1';
				elsif (vcount = V_SYNC-1) then
					vsync_reg <= '0';
				end if;

				if (vcount = V_SYNC + V_BACKP-1) then
					vblank_reg <= '0';
				elsif (vcount = V_SYNC + V_BACKP + V_ACTIVE-1) then
					vblank_reg <= '1';
				end if;
			end if;


			if (hcount = H_TOTAL-1) then
				if (vcount = 0) then
					frame_reg <= '1';
				else
					frame_reg <= '0';
				end if;

				if (vblank_reg = '0') then
					line_reg <= scanena_reg;
				else
					line_reg <= '0';
				end if;
			elsif (hcount = H_SYNC-1) then
				frame_reg <= '0';
				line_reg  <= '0';
			end if;

		end if;
	end process;


	-- カラーバー信号生成 

	cb_rout <= cb_rout_reg when(hblank_reg = '0' and vblank_reg = '0') else X"00";
	cb_gout <= cb_gout_reg when(hblank_reg = '0' and vblank_reg = '0') else X"00";
	cb_bout <= cb_bout_reg when(hblank_reg = '0' and vblank_reg = '0') else X"00";

	cblamp_sig <= conv_std_logic_vector(lampcount, 16);

	process (video_clk, reset) begin
		if (reset = '1') then
			areastate <= LEFTBAND1;
			lampcount <= 0;
			cb_rout_reg <= X"66";	-- 40% WHITE
			cb_gout_reg <= X"66";
			cb_bout_reg <= X"66";

		elsif(video_clk'event and video_clk='1') then

			if (hcount = CB_LEFTBAND-1) then
				lampcount <= 0;
			else
				lampcount <= lampcount + CB_LAMPSTEP;
			end if;

			case areastate is
			when LEFTBAND1 =>
				if (hcount = CB_LEFTBAND) then
					areastate <= WHITE;
					cb_rout_reg <= X"C0";	-- 75% WHITE
					cb_gout_reg <= X"C0";
					cb_bout_reg <= X"C0";
				end if;

			when WHITE =>
				if (hcount = CB_75WHITE) then
					areastate <= YELLOW;
					cb_rout_reg <= X"C0";	-- 75% YELLOW
					cb_gout_reg <= X"C0";
					cb_bout_reg <= X"00";
				end if;

			when YELLOW =>
				if (hcount = CB_75YELLOW) then
					areastate <= CYAN;
					cb_rout_reg <= X"00";	-- 75% CYAN
					cb_gout_reg <= X"C0";
					cb_bout_reg <= X"C0";
				end if;

			when CYAN =>
				if (hcount = CB_75CYAN) then
					areastate <= GREEN;
					cb_rout_reg <= X"00";	-- 75% GREEN
					cb_gout_reg <= X"C0";
					cb_bout_reg <= X"00";
				end if;

			when GREEN =>
				if (hcount = CB_75GREEN) then
					areastate <= MAGENTA;
					cb_rout_reg <= X"C0";	-- 75% MAGENTA
					cb_gout_reg <= X"00";
					cb_bout_reg <= X"C0";
				end if;

			when MAGENTA =>
				if (hcount = CB_75MAGENTA) then
					areastate <= RED;
					cb_rout_reg <= X"C0";	-- 75% RED
					cb_gout_reg <= X"00";
					cb_bout_reg <= X"00";
				end if;

			when RED =>
				if (hcount = CB_75RED) then
					areastate <= BLUE;
					cb_rout_reg <= X"00";	-- 75% BLUE
					cb_gout_reg <= X"00";
					cb_bout_reg <= X"C0";
				end if;

			when BLUE =>
				if (hcount = CB_75BLUE) then
					areastate <= RIGHTBAND1;
					cb_rout_reg <= X"66";	-- 40% WHITE
					cb_gout_reg <= X"66";
					cb_bout_reg <= X"66";
				end if;

			when RIGHTBAND1 =>
				if (hcount = CB_RIGHTBAND) then
					if (vcount = CB_NORMAL_V) then
						areastate <= LEFTBAND2;
						cb_rout_reg <= X"00";	-- 100% CYAN
						cb_gout_reg <= X"FF";
						cb_bout_reg <= X"FF";
					else
						areastate <= LEFTBAND1;
--						cb_rout_reg <= X"66";	-- 40% WHITE
--						cb_gout_reg <= X"66";
--						cb_bout_reg <= X"66";
					end if;
				end if;


			when LEFTBAND2 =>
				if (hcount = CB_LEFTBAND) then
					areastate <= FULLWHITE;
					cb_rout_reg <= X"FF";	-- 100% WHITE
					cb_gout_reg <= X"FF";
					cb_bout_reg <= X"FF";
				end if;

			when FULLWHITE =>
				if (hcount = CB_75WHITE) then
					areastate <= GRAY;
					cb_rout_reg <= X"C0";	-- 75% WHITE
					cb_gout_reg <= X"C0";
					cb_bout_reg <= X"C0";
				end if;

			when GRAY =>
				if (hcount = CB_75BLUE) then
					areastate <= RIGHTBAND2;
					cb_rout_reg <= X"00";	-- 100% BLUE
					cb_gout_reg <= X"00";
					cb_bout_reg <= X"FF";
				end if;

			when RIGHTBAND2 =>
				if (hcount = CB_RIGHTBAND) then
					if (vcount = CB_GRAY_V) then
						areastate <= LEFTBAND3;
						cb_rout_reg <= X"FF";	-- 100% YELLOW
						cb_gout_reg <= X"FF";
						cb_bout_reg <= X"00";
					else
						areastate <= LEFTBAND2;
						cb_rout_reg <= X"00";	-- 100% CYAN
						cb_gout_reg <= X"FF";
						cb_bout_reg <= X"FF";
					end if;
				end if;


			when LEFTBAND3 =>
				if (hcount = CB_LEFTBAND) then
					areastate <= WHITELAMP;
					cb_rout_reg <= X"00";	-- BLACK
					cb_gout_reg <= X"00";
					cb_bout_reg <= X"00";
				end if;

			when WHITELAMP =>
				if (hcount = CB_75BLUE) then
					areastate <= RIGHTBAND3;
					cb_rout_reg <= X"FF";	-- 100% RED
					cb_gout_reg <= X"00";
					cb_bout_reg <= X"00";
				else
					cb_rout_reg <= cblamp_sig(15 downto 8);	-- WHITE LAMP
					cb_gout_reg <= cblamp_sig(15 downto 8);
					cb_bout_reg <= cblamp_sig(15 downto 8);
				end if;

			when RIGHTBAND3 =>
				if (hcount = CB_RIGHTBAND) then
					if (vcount = CB_WLAMP_V) then
						areastate <= LEFTBAND4;
						cb_rout_reg <= X"26";	-- 15% WHITE
						cb_gout_reg <= X"26";
						cb_bout_reg <= X"26";
					else
						areastate <= LEFTBAND3;
						cb_rout_reg <= X"FF";	-- 100% YELLOW
						cb_gout_reg <= X"FF";
						cb_bout_reg <= X"00";
					end if;
				end if;


			when LEFTBAND4 =>
				if (hcount = CB_LEFTBAND) then
					areastate <= REDLAMP;
					cb_rout_reg <= X"00";	-- BLACK
					cb_gout_reg <= X"00";
					cb_bout_reg <= X"00";
				end if;

			when REDLAMP =>
				if (hcount = CB_75BLUE) then
					areastate <= RIGHTBAND4;
					cb_rout_reg <= X"26";	-- 15% WHITE
					cb_gout_reg <= X"26";
					cb_bout_reg <= X"26";
				else
					cb_rout_reg <= cblamp_sig(15 downto 8);	-- RED LAMP
--					cb_gout_reg <= X"00";
--					cb_bout_reg <= X"00";
				end if;

			when RIGHTBAND4 =>
				if (hcount = CB_RIGHTBAND) then
					if (vcount = CB_RLAMP_V) then
						areastate <= LEFTBAND5;
					else
						areastate <= LEFTBAND4;
					end if;

--					cb_rout_reg <= X"26";	-- 15% WHITE
--					cb_gout_reg <= X"26";
--					cb_bout_reg <= X"26";
				end if;


			when LEFTBAND5 =>
				if (hcount = CB_LEFTBAND) then
					areastate <= GREENLAMP;
					cb_rout_reg <= X"00";	-- BLACK
					cb_gout_reg <= X"00";
					cb_bout_reg <= X"00";
				end if;

			when GREENLAMP =>
				if (hcount = CB_75BLUE) then
					areastate <= RIGHTBAND5;
					cb_rout_reg <= X"26";	-- 15% WHITE
					cb_gout_reg <= X"26";
					cb_bout_reg <= X"26";
				else
--					cb_rout_reg <= X"00";
					cb_gout_reg <= cblamp_sig(15 downto 8);	-- GREEN LAMP
--					cb_bout_reg <= X"00";
				end if;

			when RIGHTBAND5 =>
				if (hcount = CB_RIGHTBAND) then
					if (vcount = CB_GLAMP_V) then
						areastate <= LEFTBAND6;
					else
						areastate <= LEFTBAND5;
					end if;

--					cb_rout_reg <= X"26";	-- 15% WHITE
--					cb_gout_reg <= X"26";
--					cb_bout_reg <= X"26";
				end if;


			when LEFTBAND6 =>
				if (hcount = CB_LEFTBAND) then
					areastate <= BLUELAMP;
					cb_rout_reg <= X"00";	-- BLACK
					cb_gout_reg <= X"00";
					cb_bout_reg <= X"00";
				end if;

			when BLUELAMP =>
				if (hcount = CB_75BLUE) then
					areastate <= RIGHTBAND6;
					cb_rout_reg <= X"26";	-- 15% WHITE
					cb_gout_reg <= X"26";
					cb_bout_reg <= X"26";
				else
--					cb_rout_reg <= X"00";
--					cb_gout_reg <= X"00";
					cb_bout_reg <= cblamp_sig(15 downto 8);	-- BLUE LAMP
				end if;

			when RIGHTBAND6 =>
				if (hcount = CB_RIGHTBAND) then
					if (vcount = CB_BLAMP_V) then
						areastate <= LEFTBAND1;
						cb_rout_reg <= X"66";	-- 40% WHITE
						cb_gout_reg <= X"66";
						cb_bout_reg <= X"66";
					else
						areastate <= LEFTBAND6;
--						cb_rout_reg <= X"26";	-- 15% WHITE
--						cb_gout_reg <= X"26";
--						cb_bout_reg <= X"26";
					end if;
				end if;

			end case;

		end if;
	end process;


end RTL;
