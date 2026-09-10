library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MouseDisplay is
port (
   pixel_clk: in std_logic;
   xpos     : in std_logic_vector(11 downto 0);
   ypos     : in std_logic_vector(11 downto 0);
   hcount   : in std_logic_vector(11 downto 0);
   vcount   : in std_logic_vector(11 downto 0);
   enable_mouse_display_out : out std_logic;
   red_out  : out std_logic_vector(3 downto 0);
   green_out: out std_logic_vector(3 downto 0);
   blue_out : out std_logic_vector(3 downto 0)
);
attribute rom_extract : string;
attribute rom_extract of MouseDisplay: entity is "yes";
attribute rom_style : string;
attribute rom_style of MouseDisplay: entity is "distributed";
end MouseDisplay;

architecture Behavioral of MouseDisplay is

type displayrom is array(0 to 255) of std_logic_vector(1 downto 0);
constant mouserom: displayrom := (
"00","00","11","11","11","11","11","11","11","11","11","11","11","11","11","11",
"00","01","00","11","11","11","11","11","11","11","11","11","11","11","11","11",
"00","01","01","00","11","11","11","11","11","11","11","11","11","11","11","11",
"00","01","01","01","00","11","11","11","11","11","11","11","11","11","11","11",
"00","01","01","01","01","00","11","11","11","11","11","11","11","11","11","11",
"00","01","01","01","01","01","00","11","11","11","11","11","11","11","11","11",
"00","01","01","01","01","01","01","00","11","11","11","11","11","11","11","11",
"00","01","01","01","01","01","01","01","00","11","11","11","11","11","11","11",
"00","01","01","01","01","01","00","00","00","00","11","11","11","11","11","11",
"00","01","01","01","01","01","00","11","11","11","11","11","11","11","11","11",
"00","01","00","00","01","01","00","11","11","11","11","11","11","11","11","11",
"00","00","11","11","00","01","01","00","11","11","11","11","11","11","11","11",
"00","11","11","11","00","01","01","00","11","11","11","11","11","11","11","11",
"11","11","11","11","11","00","01","01","00","11","11","11","11","11","11","11",
"11","11","11","11","11","00","01","01","00","11","11","11","11","11","11","11",
"11","11","11","11","11","11","00","00","11","11","11","11","11","11","11","11"
);

constant OFFSET: std_logic_vector(4 downto 0) := "10000";
signal mousepixel: std_logic_vector(1 downto 0) := (others => '0');
signal enable_mouse_display: std_logic := '0';
signal xdiff: std_logic_vector(3 downto 0) := (others => '0');
signal ydiff: std_logic_vector(3 downto 0) := (others => '0');

begin

   x_diff: process(hcount, xpos)
   variable temp_diff: std_logic_vector(11 downto 0) := (others => '0');
   begin
         temp_diff := hcount - xpos;
         xdiff <= temp_diff(3 downto 0);
   end process x_diff;

   y_diff: process(vcount, xpos)
   variable temp_diff: std_logic_vector(11 downto 0) := (others => '0');
   begin
         temp_diff := vcount - ypos;
         ydiff <= temp_diff(3 downto 0);
   end process y_diff;

   mousepixel <= mouserom(conv_integer(ydiff & xdiff)) when rising_edge(pixel_clk);

   enable_mouse: process(pixel_clk, hcount, vcount, xpos, ypos)
   begin
      if(rising_edge(pixel_clk)) then
         if(hcount >= xpos + X"001" and hcount < (xpos + OFFSET - X"001") and
            vcount >= ypos and vcount < (ypos + OFFSET)) and
            (mousepixel = "00" or mousepixel = "01")
         then
            enable_mouse_display <= '1';
         else
            enable_mouse_display <= '0';
         end if;
      end if;
   end process enable_mouse;
   
enable_mouse_display_out <= enable_mouse_display;

 process(pixel_clk)
   begin
      if(rising_edge(pixel_clk)) then
            if(enable_mouse_display = '1') then
               if(mousepixel = "01") then
                  red_out <= (others => '1');
                  green_out <= (others => '1');
                  blue_out <= (others => '1');
               elsif(mousepixel = "00") then
                  red_out <= (others => '0');
                  green_out <= (others => '0');
                  blue_out <= (others => '0');
               end if;
            end if;
      end if;
   end process;

end Behavioral;