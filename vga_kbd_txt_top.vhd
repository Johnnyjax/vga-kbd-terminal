library ieee;
use ieee.std_logic_1164.all;
entity vga_kbd_txt_top is
	port(
		-- vga signals
		CLOCK_50 : in std_logic;
		KEY            : in std_logic_vector(3 downto 0);
		SW             : in std_logic_vector(6 downto 0);
		VGA_HS, VGA_VS : out std_logic;	
		VGA_R, VGA_B, VGA_G : out std_logic_vector(2 downto 0);
		
		--kbd signals
		PS2_DAT, PS2_CLK : in std_logic;
		UART_TXD         : out std_logic
	);
end vga_kbd_txt_top;

architecture arch of vga_kbd_txt_top is
	-- vga signals
	signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	signal video_on, pixel_tick : std_logic;
	signal rgb_reg, rgb_next : std_logic_vector(2 downto 0);
	--kbd signals
	signal scan_data, w_data : std_logic_vector(7 downto 0);
	signal kb_not_empty, kb_buf_empty : std_logic;
	signal key_code, ascii_code : std_logic_vector(7 downto 0);
	signal enter_tick : std_logic;
	signal up_tick, down_tick, left_tick, right_tick : std_logic;
	signal bck_spc_tick : std_logic;
begin
	vga_sync_unit : entity work.vga_sync
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					vsync => VGA_VS, hsync => VGA_HS, video_on => video_on,
					p_tick => pixel_tick, pixel_x => pixel_x, pixel_y => pixel_y);
	text_gen_unit : entity work.vga_kbd_txt
		port map(clk => CLOCK_50, reset => not(KEY(0)), btn => not(KEY(2 downto 1)), key_code => ascii_code(6 downto 0),
					video_on => video_on, pixel_x => pixel_x, pixel_y => pixel_y, we => kb_not_empty, enter_tick => enter_tick,
					text_rgb => rgb_next, up_tick => up_tick, down_tick => down_tick, left_tick => left_tick,
					right_tick => right_tick, bck_spc_tick => bck_spc_tick);
	kb_code_unit : entity work.kb_code(arch)
		port map(clk => CLOCK_50, reset => not(KEY(0)), ps2d => PS2_DAT, ps2c => PS2_CLK,
					rd_key_code => kb_not_empty, key_code => key_code, enter_tick => enter_tick,
					kb_buf_empty => kb_buf_empty, up_tick => up_tick, down_tick => down_tick, left_tick => left_tick,
					right_tick => right_tick, bck_spc_tick => bck_spc_tick);
	key2a_unit : entity work.key2ascii(arch)
		port map(key_code => key_code, ascii_code => ascii_code);
	process(CLOCK_50)
	begin
		if(CLOCK_50'event and CLOCK_50 = '1') then
			if(pixel_tick = '1') then
				rgb_reg <= rgb_next;
			end if;
		end if;
	end process;
	kb_not_empty <= not kb_buf_empty;
	VGA_R <= (others => rgb_reg(2));
	VGA_G <= (others => rgb_reg(1));
	VGA_B <= (others => rgb_reg(0));
end arch;
		