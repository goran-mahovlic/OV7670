----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Module Name: top_level - Behavioral 
-- Description: Top level module of the Zedboard OV7670 design
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_level is
    Port ( clk100          : in  STD_LOGIC;
           SW1            : in  STD_LOGIC;
           SW2            : in  STD_LOGIC;
           SW3            : in  STD_LOGIC;
			  SW4            : in  STD_LOGIC;
           config_finished : out STD_LOGIC;
           vga_hsync : out  STD_LOGIC;
           vga_vsync : out  STD_LOGIC;
           vga_r     : out  STD_LOGIC_vector(2 downto 0);
           vga_g     : out  STD_LOGIC_vector(2 downto 0);
           vga_b     : out  STD_LOGIC_vector(1 downto 0);
           ov7670_pclk  : in  STD_LOGIC;
           ov7670_xclk  : out STD_LOGIC;
           ov7670_vsync : in  STD_LOGIC;
           ov7670_href  : in  STD_LOGIC;
           ov7670_data  : in  STD_LOGIC_vector(7 downto 0);
           ov7670_sioc  : out STD_LOGIC;
           ov7670_siod  : inout STD_LOGIC;
           ov7670_pwdn  : out STD_LOGIC;
           ov7670_reset : out STD_LOGIC;
			  channel1_p : out STD_LOGIC;
			  channel1_n : out STD_LOGIC;
			  channel2_p : out STD_LOGIC;
		     channel2_n : out STD_LOGIC;
 		     channel3_p : out STD_LOGIC;
		     channel3_n : out STD_LOGIC;
		     clock_p : out STD_LOGIC;
		     clock_n : out STD_LOGIC
           );
end top_level;

architecture Behavioral of top_level is

	COMPONENT video_lvds
	PORT(
		DotClock : IN std_logic;
		HSync : IN std_logic;
		VSync : IN std_logic;
		DataEnable : IN std_logic;
		Red : in std_logic_vector(5 downto 0);
		Green : in std_logic_vector(5 downto 0);
		Blue : in std_logic_vector(5 downto 0);
		channel1_p : OUT std_logic;
		channel1_n : OUT std_logic;
		channel2_p : OUT std_logic;
		channel2_n : OUT std_logic;
		channel3_p : OUT std_logic;
		channel3_n : OUT std_logic;
		clock_p : OUT std_logic;
		clock_n : OUT std_logic
		);
	END COMPONENT;


	COMPONENT VGA
	PORT(
		CLK25 : IN std_logic;    
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		Hsync : OUT std_logic;
		Vsync : OUT std_logic;
		Nblank : OUT std_logic;      
		clkout : OUT std_logic;
		activeArea : OUT std_logic;
		Nsync : OUT std_logic
		);
	END COMPONENT;

	COMPONENT ov7670_controller
	PORT(
		clk : IN std_logic;
		resend : IN std_logic;    
		siod : INOUT std_logic;      
		config_finished : OUT std_logic;
		sioc : OUT std_logic;
		reset : OUT std_logic;
		pwdn : OUT std_logic;
		xclk : OUT std_logic
		);
	END COMPONENT;

	COMPONENT edge_enhance
	PORT(
				Edge_clk            : in STD_LOGIC;
            enable_feature : in std_logic;
            in_blank  : in std_logic;
            in_hsync  : in std_logic;
            in_vsync  : in std_logic;
            in_red    : in std_logic_vector(7 downto 0);
            in_green  : in std_logic_vector(7 downto 0);
            in_blue   : in std_logic_vector(7 downto 0);
            out_blank : out std_logic;
            out_hsync : out std_logic;
            out_vsync : out std_logic;
            out_red   : out std_logic_vector(7 downto 0);
            out_green : out std_logic_vector(7 downto 0);
            out_blue  : out std_logic_vector(7 downto 0)
		);
	END COMPONENT;

	COMPONENT debounce
	PORT(
		clk : IN std_logic;
		i : IN std_logic;          
		o : OUT std_logic
		);
	END COMPONENT;

	COMPONENT frame_buffer
	PORT(
		data : IN std_logic_vector(11 downto 0);
		rdaddress : IN std_logic_vector(14 downto 0);
		rdclock : IN std_logic;
		wraddress : IN std_logic_vector(14 downto 0);
		wrclock : IN std_logic;
		wren : IN std_logic;          
		q : OUT std_logic_vector(11 downto 0)
		);
	END COMPONENT;

	COMPONENT ov7670_capture
	PORT(
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		pclk : IN std_logic;
		vsync : IN std_logic;
		href : IN std_logic;
		d : IN std_logic_vector(7 downto 0);          
		addr : OUT std_logic_vector(14 downto 0);
		dout : OUT std_logic_vector(11 downto 0);
		we : OUT std_logic
		);
	END COMPONENT;

	COMPONENT RGB
	PORT(
		Din : IN std_logic_vector(11 downto 0);
		Nblank : IN std_logic;          
		R : OUT std_logic_vector(7 downto 0);
		G : OUT std_logic_vector(7 downto 0);
		B : OUT std_logic_vector(7 downto 0)
		);
	END COMPONENT;

	component inst_vga_pll_numato
	port (
		CLK100       : in  std_logic;
		CLK50_camera : out std_logic;
		CLK25_vga    : out std_logic;
		CLK60_LVDS   : out std_logic
		);
	end component;
	
	COMPONENT vga_pll
	PORT(
		inclk0 : IN std_logic;          
		c0 : OUT std_logic;
		c1 : OUT std_logic
		);
	END COMPONENT;

	COMPONENT Address_Generator
	PORT(
		CLK25       : IN  std_logic;
      rez_160x120 : IN std_logic;
      rez_320x240 : IN std_logic;
		enable      : IN  std_logic;       
      vsync       : in  STD_LOGIC;
		address     : OUT std_logic_vector(14 downto 0)
		);
	END COMPONENT;



   signal clk_camera : std_logic;
   signal clk_vga    : std_logic;
	signal clk_lvds   : std_logic;
   signal wren       : std_logic;
   signal resend     : std_logic;
   signal nBlank     : std_logic;
   signal vSync      : std_logic;
   signal nSync      : std_logic;
   
   signal wraddress  : std_logic_vector(14 downto 0);
   signal wrdata     : std_logic_vector(11 downto 0);
   
   signal rdaddress  : std_logic_vector(14 downto 0);
   signal rddata     : std_logic_vector(11 downto 0);
   signal red,green,blue : std_logic_vector(7 downto 0);
   signal activeArea : std_logic;
   
   signal rez_160x120 : std_logic;
   signal rez_320x240 : std_logic;
	signal Enc_enable_feature : std_logic;
   signal Enc_in_blank  : std_logic;
   signal Enc_in_hsync  : std_logic;
   signal Enc_in_vsync  : std_logic;
   signal Enc_out_blank  : std_logic;
   signal Enc_out_hsync  : std_logic;
   signal Enc_out_vsync  : std_logic;
   signal Enc_out_red    : std_logic_vector(7 downto 0);
   signal Enc_out_green  : std_logic_vector(7 downto 0);
   signal Enc_out_blue   : std_logic_vector(7 downto 0);
   signal Enc_in_red    : std_logic_vector(7 downto 0);
   signal Enc_in_green  : std_logic_vector(7 downto 0);
   signal Enc_in_blue   : std_logic_vector(7 downto 0);
	signal invertActiveArea : std_logic;
	signal lvds_DataEnable :  std_logic;
	signal red_lvds_in : std_logic_vector(5 downto 0);
	signal green_lvds_in : std_logic_vector(5 downto 0);
	signal blue_lvds_in : std_logic_vector(5 downto 0);
	signal hsync_lvds_in : std_logic;
	signal vsync_lvds_in : std_logic;	
	
begin
   Enc_in_red <= red(7 downto 0);
   Enc_in_green <= green(7 downto 0);
   Enc_in_blue <= blue(7 downto 0);
	vga_r  <= Enc_out_red(7 downto 5);
	vga_g <= Enc_out_green(7 downto 5);
	vga_b <= Enc_out_blue(7 downto 6);
	vga_hsync <= Enc_out_hsync;
	vga_vsync <= Enc_out_vsync;
	red_lvds_in <= Enc_out_red(7 downto 2);
	green_lvds_in <= Enc_out_green(7 downto 2);
	blue_lvds_in <= Enc_out_blue(7 downto 2);
	hsync_lvds_in <= Enc_out_hsync;
	vsync_lvds_in <= Enc_out_hsync;
   Enc_in_blank <= not ActiveArea;
	lvds_DataEnable <= ActiveArea;
   rez_160x120 <= SW1;
   rez_320x240 <= SW3;
   Enc_enable_feature <= SW4;
-- For the Nexys2  
--	Inst_vga_pll: vga_pll PORT MAP(
--		inclk0 => clk50,
--		c0 => clk_camera,
--		c1 => clk_vga
--	);

inst_vga_pll : inst_vga_pll_numato
  port map
   ( CLK100 => CLK100,
     CLK50_camera => CLK_camera,
     CLK25_vga => CLK_vga,
	  CLK60_LVDS => clk_lvds
	  );

vsync <=  Vsync; 
vsync <=  Enc_in_vsync;

	Inst_VGA: VGA PORT MAP(
		CLK25      => clk_vga,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		clkout     => open,
		Hsync      => Enc_in_hsync,
		Vsync      => Enc_in_vsync,
		Nblank     => nBlank,
		Nsync      => nsync,
      activeArea => activeArea
	);

	Inst_debounce: debounce PORT MAP(
		clk => clk_vga,
		i   => SW2,
		o   => resend
	);

	Inst_ov7670_controller: ov7670_controller PORT MAP(
		clk             => clk_camera,
		resend          => resend,
		config_finished => config_finished,
		sioc            => ov7670_sioc,
		siod            => ov7670_siod,
		reset           => ov7670_reset,
		pwdn            => ov7670_pwdn,
		xclk            => ov7670_xclk
	);

	Inst_frame_buffer: frame_buffer PORT MAP(
		rdaddress => rdaddress,
		rdclock   => clk_vga,
		q         => rddata,
      
		wrclock   => ov7670_pclk,
		wraddress => wraddress(14 downto 0),
		data      => wrdata,
		wren      => wren
	);
   
	Inst_ov7670_capture: ov7670_capture PORT MAP(
		pclk  => ov7670_pclk,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		vsync => ov7670_vsync,
		href  => ov7670_href,
		d     => ov7670_data,
		addr  => wraddress,
		dout  => wrdata,
		we    => wren
	);

	Inst_RGB: RGB PORT MAP(
		Din => rddata,
		Nblank => activeArea,
		R => red,
		G => green,
		B => blue
	);

	Inst_Address_Generator: Address_Generator PORT MAP(
		CLK25 => clk_vga,
      rez_160x120 => rez_160x120,
      rez_320x240 => rez_320x240,
		enable => activeArea,
      vsync  => vsync,
		address => rdaddress
	);
	Inst_edge_enhance: edge_enhance PORT MAP(
		Edge_clk  =>  clk_vga,	
      in_blank  => Enc_in_blank,
      enable_feature => Enc_enable_feature,    
      in_hsync => Enc_in_hsync,
      in_vsync => Enc_in_vsync,
      in_red => Enc_in_red,
      in_green => Enc_in_green,
      in_blue => Enc_in_blue,
		out_red => Enc_out_red,
		out_green => Enc_out_green,
		out_blue => Enc_out_blue,
      out_hsync => Enc_out_hsync,
      out_vsync => Enc_out_vsync
	);
	
 Inst_video_lvds: video_lvds PORT MAP(
 		DotClock => clk_lvds,
		HSync => hsync_lvds_in,
		VSync => vsync_lvds_in,
		DataEnable=> lvds_DataEnable,
		Red => red_lvds_in,
		Green => green_lvds_in,
		Blue => blue_lvds_in,
		channel1_p => channel1_p,
		channel1_n => channel1_n,
		channel2_p => channel2_p,
		channel2_n => channel2_n,
		channel3_p => channel3_p,
		channel3_n => channel3_n,
		clock_p => clock_p,
		clock_n => clock_n	
	);
	
end Behavioral;
