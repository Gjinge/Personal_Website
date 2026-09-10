library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity Ps2Interface is
port(
   ps2_clk  : inout std_logic;
   ps2_data : inout std_logic;

   clk      : in std_logic;
   rst      : in std_logic;

   tx_data  : in std_logic_vector(7 downto 0);
   write_data : in std_logic;
   
   rx_data  : out std_logic_vector(7 downto 0);
   read_data  : out std_logic;
   busy     : out std_logic;
   err      : out std_logic

);
attribute rom_extract : string;
attribute rom_extract of Ps2Interface: entity is "yes";
attribute rom_style : string;
attribute rom_style of Ps2Interface: entity is "distributed";
end Ps2Interface;

architecture Behavioral of Ps2Interface is

constant DELAY_100US : std_logic_vector(13 downto 0):= "10011100010000";
constant DELAY_20US  : std_logic_vector(10 downto 0) := "11111010000";
constant DELAY_63CLK : std_logic_vector(6 downto 0)  := "1111111";
constant DEBOUNCE_DELAY : std_logic_vector(3 downto 0)  := "1111";
constant NUMBITS: std_logic_vector(3 downto 0) := "1011";
constant PARITY_BIT: positive := 9;

type ROM is array(0 to 255) of std_logic;
constant parityrom : ROM := (
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1',
'1','0','0','1','0','1','1','0',
'1','0','0','1','0','1','1','0',
'0','1','1','0','1','0','0','1'
);

signal delay_100us_count: std_logic_vector(13 downto 0) := (others => '0');
signal delay_20us_count: std_logic_vector(10 downto 0) := (others => '0');
signal delay_63clk_count: std_logic_vector(6 downto 0) := (others => '0');
signal delay_100us_done, delay_20us_done, delay_63clk_done: std_logic;
signal delay_100us_counter_enable: std_logic := '0';
signal delay_20us_counter_enable : std_logic := '0';
signal delay_63clk_counter_enable: std_logic := '0';
signal ps2_clk_s,ps2_data_s: std_logic := '1';
signal ps2_clk_h,ps2_data_h: std_logic := '1';

type fsm_state is
(
   idle,rx_clk_h,rx_clk_l,rx_down_edge,rx_error_parity,rx_data_ready,
   tx_force_clk_l,tx_bring_data_down,tx_release_clk,
   tx_first_wait_down_edge,tx_clk_l,tx_wait_up_edge,tx_clk_h,
   tx_wait_up_edge_before_ack,tx_wait_ack,tx_received_ack,
   tx_error_no_ack
);
signal state: fsm_state := idle;
signal frame: std_logic_vector(10 downto 0) := (others => '0');
signal bit_count: std_logic_vector(3 downto 0) := (others => '0');
signal reset_bit_count: std_logic := '0';
signal shift_frame: std_logic := '0';
signal rx_parity: std_logic := '0';
signal tx_parity: std_logic := '0';
signal load_tx_data: std_logic := '0';
signal load_rx_data: std_logic := '0';
signal ps2_clk_clean,ps2_data_clean: std_logic := '1';
signal clk_count,data_count: std_logic_vector(3 downto 0);
signal clk_inter,data_inter: std_logic := '1';

begin

   process(clk)
   begin
      if(rising_edge(clk)) then
         if(ps2_clk /= clk_inter) then
            clk_inter <= ps2_clk;
            clk_count <= (others => '0');
         elsif(clk_count = DEBOUNCE_DELAY) then
            ps2_clk_clean <= clk_inter;
         else
            clk_count <= clk_count + 1;
         end if;
      end if;
   end process;

   process(clk)
   begin
      if(rising_edge(clk)) then
         if(ps2_data /= data_inter) then
            data_inter <= ps2_data;
            data_count <= (others => '0');
         elsif(data_count = DEBOUNCE_DELAY) then
            ps2_data_clean <= data_inter;
         else
            data_count <= data_count + 1;
         end if;
      end if;
   end process;
   
   ps2_clk_s <= ps2_clk_clean when rising_edge(clk);
   ps2_data_s <= ps2_data_clean when rising_edge(clk);

   rx_parity <= parityrom(conv_integer(frame(8 downto 1))) when rising_edge(clk);
   tx_parity <= parityrom(conv_integer(tx_data)) when rising_edge(clk);

   ps2_clk <= 'Z' when ps2_clk_h = '1' else '0';
   ps2_data <= 'Z' when ps2_data_h = '1' else '0';

   busy <= '0' when state = idle else '1';
   reset_bit_count <= '1' when state = idle else '0';
   shift_frame <= '1' when state = rx_down_edge or state = tx_clk_l else '0';

manage_fsm: process(clk,rst,state,ps2_clk_s,ps2_data_s,write_data,tx_data,
                       bit_count,rx_parity,frame,delay_100us_done,
                       delay_20us_done,delay_63clk_done)
   begin
      if(rst = '1') then
         state <= idle;
      elsif(rising_edge(clk)) then
         ps2_clk_h <= '1';
         ps2_data_h <= '1';
         load_tx_data <= '0';
         load_rx_data <= '0';
         read_data <= '0';
         err <= '0';

         case state is
            when idle =>
               if(ps2_clk_s = '0') then
                  state <= rx_down_edge;
               elsif(write_data = '1') then
                  state <= tx_force_clk_l;               
               else
                  state <= idle;
               end if;
   
            when rx_clk_h =>
               if(bit_count = NUMBITS) then
                  if(not (rx_parity = frame(PARITY_BIT))) then
                     state <= rx_error_parity;
                  else
                     load_rx_data <= '1';
                     state <= rx_data_ready;
                  end if;
               elsif(ps2_clk_s = '0') then
                  state <= rx_down_edge;
               else
                  state <= rx_clk_h;
               end if;
   
            when rx_down_edge =>
               state <= rx_clk_l;
   
            when rx_clk_l =>
               if(ps2_clk_s = '1') then
                  state <= rx_clk_h;
               else
                  state <= rx_clk_l;
               end if;
   
            when rx_error_parity =>
               err <= '1';
               state <= idle;
   
            when rx_data_ready =>
               read_data <= '1';
               state <= idle;
   
            when tx_force_clk_l =>
               load_tx_data <= '1';
               ps2_clk_h <= '0';
               if(delay_100us_done = '1') then
                  state <= tx_bring_data_down;
               else
                  state <= tx_force_clk_l;
               end if;
   
            when tx_bring_data_down =>
               ps2_clk_h <= '0';
               ps2_data_h <= '0';
               if(delay_20us_done = '1') then
                  state <= tx_release_clk;
               else
                  state <= tx_bring_data_down;
               end if;
   
            when tx_release_clk =>
               ps2_clk_h <= '1';
               ps2_data_h <= '0';
               state <= tx_first_wait_down_edge;
   
            when tx_first_wait_down_edge =>
               ps2_data_h <= '0';
               if(delay_63clk_done = '1') then
                  if(ps2_clk_s = '0') then
                     state <= tx_clk_l;
                  else
                     state <= tx_first_wait_down_edge;
                  end if;
               else
                  state <= tx_first_wait_down_edge;
               end if;
   
            when tx_clk_l =>
               ps2_data_h <= frame(0);
               state <= tx_wait_up_edge;

            when tx_wait_up_edge =>
               ps2_data_h <= frame(0);
               if(bit_count = NUMBITS-1) then
                  ps2_data_h <= '1';
                  state <= tx_wait_up_edge_before_ack;
               elsif(ps2_clk_s = '1') then
                  state <= tx_clk_h;
               else
                  state <= tx_wait_up_edge;
               end if;
   
            when tx_clk_h =>
               ps2_data_h <= frame(0);
               if(ps2_clk_s = '0') then
                  state <= tx_clk_l;
               else
                  state <= tx_clk_h;
               end if;
   
            when tx_wait_up_edge_before_ack =>
               ps2_data_h <= '1';
               if(ps2_clk_s = '1') then
                  state <= tx_wait_ack;
               else
                  state <= tx_wait_up_edge_before_ack;
               end if;
            
            when tx_wait_ack =>
               if(ps2_clk_s = '0') then
                  if(ps2_data_s = '0') then
                     state <= tx_received_ack;
                  else
                     state <= tx_error_no_ack;
                  end if;
               else
                  state <= tx_wait_ack;
               end if;
   
            when tx_received_ack =>
               if(ps2_clk_s = '1' and ps2_data_s = '1') then
                  state  <= idle;
               else
                  state <= tx_received_ack;
               end if;
   
            when tx_error_no_ack =>
               if(ps2_clk_s = '1' and ps2_data_s = '1') then
                  err <= '1';
                  state  <= idle;
               else
                  state <= tx_error_no_ack;
               end if;
   
            when others =>
               err <= '1';
               state  <= idle;
         end case;
      end if;
   end process manage_fsm;

   delay_100us_counter_enable <= '1' when state = tx_force_clk_l else '0';
   delay_100us_counter: process(clk)
   begin
      if(rising_edge(clk)) then
         if(delay_100us_counter_enable = '1') then
            if(delay_100us_count = (DELAY_100US)) then
               delay_100us_count <= delay_100us_count;
               delay_100us_done <= '1';
            else
               delay_100us_count <= delay_100us_count + 1;
               delay_100us_done <= '0';
            end if;
         else
            delay_100us_count <= (others => '0');
            delay_100us_done <= '0';
         end if;
      end if;
   end process delay_100us_counter;

   delay_20us_counter_enable <= '1' when state = tx_bring_data_down else '0'; 
   delay_20us_counter: process(clk)
   begin
      if(rising_edge(clk)) then
         if(delay_20us_counter_enable = '1') then
            if(delay_20us_count = (DELAY_20US)) then
               delay_20us_count <= delay_20us_count;
               delay_20us_done <= '1';
            else
               delay_20us_count <= delay_20us_count + 1;
               delay_20us_done <= '0';
            end if;
         else
            delay_20us_count <= (others => '0');
            delay_20us_done <= '0';
         end if;
      end if;
   end process delay_20us_counter;

   delay_63clk_counter_enable <= '1' when state = tx_first_wait_down_edge else '0';
   delay_63clk_counter: process(clk)
   begin
      if(rising_edge(clk)) then
         if(delay_63clk_counter_enable = '1') then
            if(delay_63clk_count = (DELAY_63CLK)) then
               delay_63clk_count <= delay_63clk_count;
               delay_63clk_done <= '1';
            else
               delay_63clk_count <= delay_63clk_count + 1;
               delay_63clk_done <= '0';
            end if;
         else
            delay_63clk_count <= (others => '0');
            delay_63clk_done <= '0';
         end if;
      end if;
   end process delay_63clk_counter;

   bit_counter: process(clk)
   begin
      if(rising_edge(clk)) then
         if(reset_bit_count = '1') then
            bit_count <= (others => '0');
         elsif(shift_frame = '1') then
            bit_count <= bit_count + 1;
         end if;
      end if;
   end process bit_counter;

   load_tx_data_into_frame: process(clk)
   begin
      if(rising_edge(clk)) then
         if(load_tx_data = '1') then
            frame(8 downto 1) <= tx_data;
            frame(0) <= '0';
            frame(10) <= '1';
            frame(9) <= tx_parity;
         elsif(shift_frame = '1') then
            frame(9 downto 0) <= frame(10 downto 1);
            frame(10) <= ps2_data_s;
         end if;
      end if;
   end process load_tx_data_into_frame;

   do_load_rx_data: process(clk)
   begin
      if(rising_edge(clk)) then
         if(load_rx_data = '1') then
            rx_data <= frame(8 downto 1);
         end if;
      end if;
   end process do_load_rx_data;

end Behavioral;