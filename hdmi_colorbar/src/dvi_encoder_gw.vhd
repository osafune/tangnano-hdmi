-- ===================================================================
-- TITLE : DVI Transmitter (for GW1N LVCMOS33D)
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2005/10/12 -> 2005/10/13
--
--     UPDATE : 2014/10/12 MAX10 support
--            : 2018/05/13 License update
--            : 2020/02/09 GW1N modify
--
--     Github : https://github.com/osafune/misc_hdl_module
--
-- ===================================================================

-- The MIT License (MIT)
-- Copyright (c) 2005-2020 J-7SYSTEM WORKS LIMITED.
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


----------------------------------------------------------------------
--  TMDS encoder
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity dvi_encoder_tmds_submodule is
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;

		de_in		: in  std_logic;
		c1_in		: in  std_logic;
		c0_in		: in  std_logic;

		d_in		: in  std_logic_vector(7 downto 0);

		q_out		: out std_logic_vector(9 downto 0)
	);
end dvi_encoder_tmds_submodule;

architecture RTL of dvi_encoder_tmds_submodule is
	signal cnt		: integer range -8 to 8;

	signal qm_reg	: std_logic_vector(8 downto 0);
	signal de_reg	: std_logic;
	signal c_reg	: std_logic_vector(1 downto 0);
	signal qout_reg	: std_logic_vector(9 downto 0);

	-- バイト中のビット１の個数をカウント --
	function number1s(D:std_logic_vector(7 downto 0)) return integer is
		variable i,num	: integer;
	begin
		num := 0;

		for i in 0 to 7 loop
			if (D(i) = '1') then
				num := num + 1;
			end if;
		end loop;

		return num;
	end;

	-- バイト中のビット０の個数をカウント --
	function number0s(D:std_logic_vector(7 downto 0)) return integer is
		variable i,num	: integer;
	begin
		num := 0;

		for i in 0 to 7 loop
			if (D(i) = '0') then
				num := num + 1;
			end if;
		end loop;

		return num;
	end;

	-- XORエンコード --
	function encode1(D:std_logic_vector(7 downto 0)) return std_logic_vector is
		variable i		: integer;
		variable q_m	: std_logic_vector(8 downto 0);
	begin
		q_m(0) := D(0);

		for i in 1 to 7 loop
			q_m(i) := q_m(i - 1) xor D(i);
		end loop;

		q_m(8) := '1';

		return q_m;

	end;

	-- XNORエンコード --
	function encode0(D:std_logic_vector(7 downto 0)) return std_logic_vector is
		variable i		: integer;
		variable q_m	: std_logic_vector(8 downto 0);
	begin
		q_m(0) := D(0);

		for i in 1 to 7 loop
			q_m(i) := not(q_m(i - 1) xor D(i));
		end loop;

		q_m(8) := '0';

		return q_m;

	end;

begin

	-- 入力信号をラッチ --

	process (clk, reset) begin
		if (reset = '1') then
			de_reg <= '0';
			c_reg <= "00";

		elsif rising_edge(clk) then
			de_reg <= de_in;
			c_reg <= c1_in & c0_in;

			if (number1s(d_in) > 4 or (number1s(d_in) = 4 and d_in(0) = '0')) then
				qm_reg <= encode0(d_in);
			else
				qm_reg <= encode1(d_in);
			end if;

		end if;
	end process;


	-- データをTMDSにエンコード --

	process (clk, reset) begin
		if (reset = '1') then
			cnt <= 0;

		elsif rising_edge(clk) then
			if (de_reg = '1') then
				if (cnt = 0 or (number1s(qm_reg(7 downto 0)) = number0s(qm_reg(7 downto 0)))) then
					qout_reg(9) <= not qm_reg(8);
					qout_reg(8) <= qm_reg(8);

					if (qm_reg(8) = '0') then
						qout_reg(7 downto 0) <= not qm_reg(7 downto 0);
						cnt <= cnt + (number0s(qm_reg(7 downto 0)) - number1s(qm_reg(7 downto 0)));
					else
						qout_reg(7 downto 0) <= qm_reg(7 downto 0);
						cnt <= cnt + (number1s(qm_reg(7 downto 0)) - number0s(qm_reg(7 downto 0)));
					end if;

				else
					if ((cnt > 0 and number1s(qm_reg(7 downto 0)) > number0s(qm_reg(7 downto 0)))
							or (cnt < 0 and number0s(qm_reg(7 downto 0)) > number1s(qm_reg(7 downto 0)))) then
						qout_reg(9) <= '1';
						qout_reg(8) <= qm_reg(8);
						qout_reg(7 downto 0) <= not qm_reg(7 downto 0);

						if (qm_reg(8)='0') then
							cnt <= cnt + (number0s(qm_reg(7 downto 0)) - number1s(qm_reg(7 downto 0)));
						else
							cnt <= cnt + (number0s(qm_reg(7 downto 0)) - number1s(qm_reg(7 downto 0))) + 2;
						end if;

					else
						qout_reg(9) <= '0';
						qout_reg(8) <= qm_reg(8);
						qout_reg(7 downto 0) <= qm_reg(7 downto 0);

						if (qm_reg(8)='1') then
							cnt <= cnt + (number1s(qm_reg(7 downto 0)) - number0s(qm_reg(7 downto 0)));
						else
							cnt <= cnt + (number1s(qm_reg(7 downto 0)) - number0s(qm_reg(7 downto 0))) - 2;
						end if;

					end if;
				end if;

			else
				cnt <= 0;
				case c_reg is
				when "01" =>
					qout_reg <= "0010101011";
				when "10" =>
					qout_reg <= "0101010100";
				when "11" =>
					qout_reg <= "1010101011";
				when others =>
					qout_reg <= "1101010100";
				end case;

			end if;

		end if;
	end process;

	q_out <= qout_reg;


end RTL;



----------------------------------------------------------------------
-- top module
----------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity dvi_encoder_gw is
	generic(
		CLOCK_IODELAY_VALUE	: integer := 0;
		DATA0_IODELAY_VALUE	: integer := 0;
		DATA1_IODELAY_VALUE	: integer := 0;
		DATA2_IODELAY_VALUE	: integer := 0
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;		-- Rise edge drive clock
		clk_x5		: in  std_logic;		-- Transmitter clock (It synchronizes with clk)

		vga_r		: in  std_logic_vector(7 downto 0);
		vga_g		: in  std_logic_vector(7 downto 0);
		vga_b		: in  std_logic_vector(7 downto 0);
		vga_de		: in  std_logic;
		vga_hsync	: in  std_logic;
		vga_vsync	: in  std_logic;

		data0_p		: out std_logic;
		data1_p		: out std_logic;
		data2_p		: out std_logic;
		clock_p		: out std_logic
	);
end dvi_encoder_gw;

architecture RTL of dvi_encoder_gw is
	signal q_blu_sig	: std_logic_vector(9 downto 0);
	signal q_grn_sig	: std_logic_vector(9 downto 0);
	signal q_red_sig	: std_logic_vector(9 downto 0);

	component dvi_encoder_tmds_submodule is
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;

		de_in		: in  std_logic;
		c1_in		: in  std_logic;
		c0_in		: in  std_logic;

		d_in		: in  std_logic_vector(7 downto 0);

		q_out		: out std_logic_vector(9 downto 0)
	);
	end component;

	component OSER10 is
	GENERIC (
		GSREN : string := "false";
		LSREN : string := "true"
	);
	PORT (
		D0 : in std_logic;
		D1 : in std_logic;
		D2 : in std_logic;
		D3 : in std_logic;
		D4 : in std_logic;
		D5 : in std_logic;
		D6 : in std_logic;
		D7 : in std_logic;
		D8 : in std_logic;
		D9 : in std_logic;
		PCLK : in std_logic;
		RESET : in std_logic;
		FCLK : in std_logic;
		Q : OUT std_logic
	);
	end component;
	signal clock_ser_sig	: std_logic;
	signal data0_ser_sig	: std_logic;
	signal data1_ser_sig	: std_logic;
	signal data2_ser_sig	: std_logic;

	component IODELAY is
	GENERIC (
		C_STATIC_DLY : integer := 0
	);
	PORT (
		DI : IN std_logic;
		SDTAP : IN std_logic;
		SETN : IN std_logic;
		VALUE : IN std_logic;
		DO : OUT std_logic;
		DF : OUT std_logic
	);
	end component;


begin

	-- TMDSデータエンコード --

	u_enc_r : dvi_encoder_tmds_submodule
	port map (
		reset	=> reset,
		clk		=> clk,
		de_in	=> vga_de,
		c1_in	=> '0',
		c0_in	=> '0',
		d_in	=> vga_r,
		q_out	=> q_red_sig
	);

	u_enc_g : dvi_encoder_tmds_submodule
	port map (
		reset	=> reset,
		clk		=> clk,
		de_in	=> vga_de,
		c1_in	=> '0',
		c0_in	=> '0',
		d_in	=> vga_g,
		q_out	=> q_grn_sig
	);

	u_enc_b : dvi_encoder_tmds_submodule
	port map (
		reset	=> reset,
		clk		=> clk,
		de_in	=> vga_de,
		c1_in	=> vga_vsync,
		c0_in	=> vga_hsync,
		d_in	=> vga_b,
		q_out	=> q_blu_sig
	);


	-- シリアライザ --

	u_ser_clk : OSER10
	port map (
		RESET	=> reset,
		PCLK	=> clk,
		FCLK	=> clk_x5,
		D0		=> '1',
		D1		=> '1',
		D2		=> '1',
		D3		=> '1',
		D4		=> '1',
		D5		=> '0',
		D6		=> '0',
		D7		=> '0',
		D8		=> '0',
		D9		=> '0',
		Q		=> clock_ser_sig
	);

	u_ser_dat0 : OSER10
	port map (
		RESET	=> reset,
		PCLK	=> clk,
		FCLK	=> clk_x5,
		D0		=> q_blu_sig(0),
		D1		=> q_blu_sig(1),
		D2		=> q_blu_sig(2),
		D3		=> q_blu_sig(3),
		D4		=> q_blu_sig(4),
		D5		=> q_blu_sig(5),
		D6		=> q_blu_sig(6),
		D7		=> q_blu_sig(7),
		D8		=> q_blu_sig(8),
		D9		=> q_blu_sig(9),
		Q		=> data0_ser_sig
	);

	u_ser_dat1 : OSER10
	port map (
		RESET	=> reset,
		PCLK	=> clk,
		FCLK	=> clk_x5,
		D0		=> q_grn_sig(0),
		D1		=> q_grn_sig(1),
		D2		=> q_grn_sig(2),
		D3		=> q_grn_sig(3),
		D4		=> q_grn_sig(4),
		D5		=> q_grn_sig(5),
		D6		=> q_grn_sig(6),
		D7		=> q_grn_sig(7),
		D8		=> q_grn_sig(8),
		D9		=> q_grn_sig(9),
		Q		=> data1_ser_sig
	);

	u_ser_dat2 : OSER10
	port map (
		RESET	=> reset,
		PCLK	=> clk,
		FCLK	=> clk_x5,
		D0		=> q_red_sig(0),
		D1		=> q_red_sig(1),
		D2		=> q_red_sig(2),
		D3		=> q_red_sig(3),
		D4		=> q_red_sig(4),
		D5		=> q_red_sig(5),
		D6		=> q_red_sig(6),
		D7		=> q_red_sig(7),
		D8		=> q_red_sig(8),
		D9		=> q_red_sig(9),
		Q		=> data2_ser_sig
	);


	-- IOディレイタップ --

	u_iod_clk : IODELAY
	generic map (
		C_STATIC_DLY	=> CLOCK_IODELAY_VALUE
	)
	port map (
		DI		=> clock_ser_sig,
		DO		=> clock_p,
		SDTAP	=> '0',
		SETN	=> '0',
		VALUE	=> '0'
	);

	u_iod_dat0 : IODELAY
	generic map (
		C_STATIC_DLY	=> DATA0_IODELAY_VALUE
	)
	port map (
		DI		=> data0_ser_sig,
		DO		=> data0_p,
		SDTAP	=> '0',
		SETN	=> '0',
		VALUE	=> '0'
	);

	u_iod_dat1 : IODELAY
	generic map (
		C_STATIC_DLY	=> DATA1_IODELAY_VALUE
	)
	port map (
		DI		=> data1_ser_sig,
		DO		=> data1_p,
		SDTAP	=> '0',
		SETN	=> '0',
		VALUE	=> '0'
	);

	u_iod_dat2 : IODELAY
	generic map (
		C_STATIC_DLY	=> DATA2_IODELAY_VALUE
	)
	port map (
		DI		=> data2_ser_sig,
		DO		=> data2_p,
		SDTAP	=> '0',
		SETN	=> '0',
		VALUE	=> '0'
	);



end RTL;
