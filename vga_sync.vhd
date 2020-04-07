library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
	port(
		clk, reset : in std_logic;
		hsync, vsync : out std_logic;
		video_on, p_tick : out std_logic;
		pixel_x, pixel_y : out std_logic_vector(9 downto 0)
	);
end vga_sync;

architecture arch of vga_sync is
	constant HD : integer:= 640;
	constant HF : integer:= 4;
	constant HB : integer:= 60;
	constant HR : integer:= 96;
	constant VD : integer:= 480;
	constant VF : integer:= 10;
	constant VB : integer:= 33;
	constant VR : integer:= 2;
	
	signal mod2_reg, mod2_next : std_logic;
	signal v_count_reg, v_count_next : unsigned(9 downto 0);
	signal h_count_reg, h_count_next : unsigned(9 downto 0);
	signal v_sync_reg, h_sync_reg : std_logic;
	signal v_sync_next, h_sync_next : std_logic;
	signal h_end, v_end, pixel_tick : std_logic;
begin
	process(clk, reset)
	begin
		if reset = '1' then
			mod2_reg <= '0';
			v_count_reg <= (others => '0');
			h_count_reg <= (others => '0');
			v_sync_reg <= '0';
			h_sync_reg <= '0';
		elsif (clk'event and clk = '1') then
			mod2_reg <= mod2_next;
			v_count_reg <= v_count_next;
			h_count_reg <= h_count_next;
			v_sync_reg <= v_sync_next;
			h_sync_reg <= h_sync_next;
		end if;
	end process;
	--mod 2 circuit to generate 25 mhz enable tick;
	mod2_next <= not mod2_reg;
	-- 25 mhz pixel tick
	pixel_tick <= '1' when mod2_reg = '1' else '0';
	h_end <= -- end of horizontal counter
		'1' when h_count_reg = (HD+HF+HB+HR-1) else
		'0';
	v_end <= 
		'1' when v_count_reg = (VD+VF+VB+VR-1) else
		'0';
	process(h_count_reg, h_end, pixel_tick)
	begin
		if pixel_tick = '1' then
			if h_end = '1' then
				h_count_next <= (others => '0');
			else
				h_count_next <= (h_count_reg + 1);
			end if;
		else
			h_count_next <= h_count_reg;
		end if;
	end process;
	
	process(v_count_reg, h_end, v_end, pixel_tick)
	begin
		if pixel_tick = '1' and h_end = '1' then
			if v_end = '1' then
				v_count_next <= (others => '0');
			else
				v_count_next <= (v_count_reg + 1);
			end if;
		else
			v_count_next <= v_count_reg;
		end if;
	end process;
	
	h_sync_next <= 
		'0' when (h_count_reg >= (HD+HF))
				and (h_count_reg <= (HD+HF+HR-1)) else
		'1';
	v_sync_next <= 
		'0' when (v_count_reg >= (VD+VF))
			 and (v_count_reg <= (VD+VF+VR-1)) else
		'1';
	video_on <= 
		'1' when (h_count_reg<HD) and (v_count_reg < VD) else
		'0';
	hsync <= h_sync_reg;
	vsync <= v_sync_reg;
	pixel_x <= std_logic_vector(h_count_reg);
	pixel_y <= std_logic_vector(v_count_reg);
	p_tick <= pixel_tick;
end arch;