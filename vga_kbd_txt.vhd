library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_kbd_txt is
	port(
		clk, reset : in std_logic;
		btn : in std_logic_vector(1 downto 0);
		key_code : in std_logic_vector(6 downto 0);
		video_on : in std_logic;
		pixel_x, pixel_y : in std_logic_vector(9 downto 0);
		enter_tick : in std_logic;
		up_tick, down_tick , left_tick, right_tick : in std_logic;
		bck_spc_tick : in std_logic;
	   we : in std_logic;
		text_rgb : out std_logic_vector(2 downto 0)
	);
end vga_kbd_txt;

architecture arch of vga_kbd_txt is
	signal char_addr : std_logic_vector(6 downto 0);
	signal rom_addr : std_logic_vector(10 downto 0);
	signal row_addr : std_logic_vector(3 downto 0);
	signal bit_addr : unsigned(2 downto 0);
	signal font_word : std_logic_vector(7 downto 0);
	signal font_bit : std_logic;
	
	
	signal addr_r, addr_w : std_logic_vector(11 downto 0);
	signal din, dout : std_logic_vector(6 downto 0);
	
	constant MAX_X : integer := 80;
	constant MAX_Y : integer := 30;
	signal we_wth_bck : std_logic;
	signal cur_x_reg, cur_x_next : unsigned(6 downto 0);
	signal cur_y_reg, cur_y_next : unsigned(4 downto 0);
	signal move_x_tick, move_y_tick : std_logic;
	signal cursor_on : std_logic;
	signal pix_x1_reg, pix_y1_reg : unsigned(9 downto 0);
	signal pix_x2_reg, pix_y2_reg : unsigned(9 downto 0);
	
	signal bck_spc : std_logic;
	signal font_rgb, font_rev_rgb : std_logic_vector(2 downto 0);
begin
	debounce_unit0 : entity work.debounce
		port map(clk => clk, reset => reset, sw => btn(0),
					db_level => open, db_tick => move_x_tick);
	debounce_unit1 : entity work.debounce
		port map(clk => clk, reset => reset, sw => btn(1),
					db_level => open, db_tick => move_y_tick);
	font_unit : entity work.font_rom
		port map(clk => clk, addr => rom_addr, data => font_word);
	video_ram : entity work.altera_dual_port_ram_sync
		generic map(ADDR_WIDTH => 12, DATA_WIDTH => 7)
		port map(clk => clk, we => we_wth_bck,
					addr_a => addr_w, addr_b => addr_r,
					din_a => din, dout_a => open, dout_b => dout);
	process(clk)
	begin	
		if(clk'event and clk = '1') then
			cur_x_reg <= cur_x_next;
			cur_y_reg <= cur_y_next;
			pix_x1_reg <= unsigned(pixel_x);
			pix_x2_reg <= pix_x1_reg;
			pix_y1_reg <= unsigned(pixel_y);
			pix_y2_reg <= pix_y1_reg;
			bck_spc <= bck_spc_tick;
		end if;
	end process;
	we_wth_bck <= we or bck_spc;
	addr_w <= std_logic_vector(cur_y_reg & cur_x_reg);
	din <= (others => '0') when bck_spc = '1' else
				key_code;
	
	addr_r <= pixel_y(8 downto 4) & pixel_x(9 downto 3);
	char_addr <= dout;
	row_addr <= pixel_y(3 downto 0);
	rom_addr <= char_addr & row_addr;
	bit_addr <= pix_x2_reg(2 downto 0);
	font_bit <= font_word(to_integer(not bit_addr));
	cur_x_next <= 
			(others => '0') when ((we = '1' or right_tick = '1') and 
										cur_x_reg = MAX_X-1) or enter_tick = '1' or
										(cur_x_reg = 0 and cur_y_reg = 0 and bck_spc_tick = '1')else
			cur_x_reg + 1 when we = '1' or right_tick = '1' else
			"1001111" when ((left_tick = '1' or bck_spc_tick = '1') and cur_x_reg = 0)  else
			cur_x_reg - 1 when left_tick = '1' or bck_spc_tick = '1' else
			cur_x_reg;
	cur_y_next <= 
		(others => '0') when (down_tick = '1' and 
									cur_y_reg = MAX_Y-1) or (cur_x_reg = 0 and cur_y_reg = 0 and bck_spc_tick = '1') else
		"11101" when up_tick = '1' and cur_y_reg = 0 else
		cur_y_reg + 1 when enter_tick = '1' or down_tick = '1' or (we = '1' and cur_x_reg = MAX_X -1) else
		cur_y_reg - 1 when up_tick = '1' or (bck_spc_tick = '1' and cur_x_reg = 0) else
		cur_y_reg;
	font_rgb <= "000" when font_bit = '1' else "111";
	font_rev_rgb <= "000" when font_bit = '1' else "010";
	cursor_on <= '1' when pix_y2_reg(8 downto 4) = cur_y_reg and pix_y2_reg(3 downto 0) >= "1110" and
								 pix_x2_reg(9 downto 3) = cur_x_reg else
					 '0';
	process(video_on, cursor_on, font_rgb, font_rev_rgb)
	begin
		if video_on = '0' then
			text_rgb <= "000";
		else
			if cursor_on = '1' then
				text_rgb <= font_rev_rgb;
			else
				text_rgb <= font_rgb;
			end if;
		end if;
	end process;
end arch;