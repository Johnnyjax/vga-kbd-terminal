library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity kb_code is
	generic(W_SIZE : integer := 2);
	port(
		clk, reset : in std_logic;
		ps2d, ps2c : in std_logic;
		rd_key_code : in std_logic;
		key_code : out std_logic_vector(7 downto 0);
		enter_tick : out std_logic;
		up_tick, down_tick , left_tick, right_tick : out std_logic;
		bck_spc_tick : out std_logic;
		kb_buf_empty : out std_logic
	);
end kb_code;

architecture arch of kb_code is
	constant BRK : std_logic_vector(7 downto 0) := "11110000";
	constant ENTER : std_logic_vector(7 downto 0) := "01011010";
	constant BCKSPC : std_logic_vector(7 downto 0) := "01100110";
	constant UP_KEY : std_logic_vector(7 downto 0) := "01110101";
	constant DOWN_KEY: std_logic_vector(7 downto 0) := "01110010";
	constant LEFT_KEY : std_logic_vector(7 downto 0) := "01101011";
	constant RIGHT_KEY: std_logic_vector(7 downto 0) := "01110100";
	type statetype is(init, typematic, wait_brk, get_code, waste_cycle);
	signal state_reg, state_next : statetype;
	signal scan_out, w_data : std_logic_vector(7 downto 0);
	signal compare_reg, compare_next : std_logic_vector(7 downto 0);
	signal scan_done_tick, got_code_tick : std_logic;
begin
	ps2_rx_unit : entity work.ps2_rx(arch)
		port map(clk => clk, reset => reset, rx_en => '1',
					ps2d => ps2d, ps2c => ps2c,
					rx_done_tick => scan_done_tick,
					dout => scan_out);
	fifo_key_unit : entity work.fifo(arch)
		generic map(B => 8, W => W_SIZE)
		port map(clk => clk, reset => reset, rd => rd_key_code,
					wr => got_code_tick, w_data => scan_out,
					empty => kb_buf_empty, full => open, 
					r_data => key_code);
	process(clk, reset)
	begin
		if reset = '1' then
			state_reg <= wait_brk;
			compare_reg <= (others => '0');
		elsif(clk'event and clk = '1') then
			state_reg <= state_next;
			compare_reg <= compare_next;
		end if;
	end process;
	
	process(state_reg, scan_done_tick, compare_reg, scan_out)
	begin
		got_code_tick <= '0';
		state_next <= state_reg;
		compare_next <= compare_reg;
		enter_tick <= '0';
		up_tick <= '0';
		down_tick <= '0';
		left_tick <= '0';
		right_tick <= '0';
		bck_spc_tick <= '0';
		case state_reg is 
			when init => 
				if scan_done_tick = '1' then
					if scan_out = BRK then
						state_next <= get_code;
					else
						compare_next <= scan_out;
						state_next <= wait_brk;
					end if;
				end if;
			when wait_brk =>
				if scan_done_tick = '1' then
					if scan_out = compare_reg then
						if scan_out = ENTER then
							enter_tick <= '1';
						elsif scan_out = BCKSPC then
							bck_spc_tick <= '1';
						else
							got_code_tick <= '1';
						end if;
						state_next <= typematic;
					elsif compare_reg = "11100000" then
						if scan_out = UP_KEY then
							up_tick <= '1';
							state_next <= init;
						elsif scan_out = DOWN_KEY then
							down_tick <= '1';
							state_next <= init;
						elsif scan_out = LEFT_KEY then
							left_tick <= '1';
							state_next <= init;
						elsif scan_out = RIGHT_KEY then
							right_tick <= '1';
							state_next <= init;
						elsif scan_out = BRK then
							state_next <= waste_cycle;
						end if;
					elsif scan_out = BRK then
						state_next <= get_code;
					else
						state_next <= init;
					end if;
				end if;
			when typematic =>
				if scan_done_tick = '1' then
					if scan_out /= BRK then
						if scan_out = ENTER then
							enter_tick <= '1';
						elsif scan_out = BCKSPC then
							bck_spc_tick <= '1';
						else
							got_code_tick <= '1';
						end if;
					else
						state_next <= waste_cycle;
					end if;
				end if;
			when waste_cycle =>
				if scan_done_tick = '1' then
					state_next <= init;
				end if;
			when get_code =>
				if scan_done_tick = '1' then
					if scan_out = ENTER then
						enter_tick <= '1';
					elsif scan_out = BCKSPC then
						bck_spc_tick <= '1';
					else
						got_code_tick <= '1';
					end if;
					state_next <= init;
				end if;
		end case;
	end process;
end arch;