library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity MouseCtl is
generic
(
   SYSCLK_FREQUENCY_HZ : integer := 25000000;
   CHECK_PERIOD_MS     : integer := 500;
   TIMEOUT_PERIOD_MS   : integer := 100
);
port(
   clk         : in std_logic;
   rst         : in std_logic;
   xpos        : out std_logic_vector(11 downto 0);
   ypos        : out std_logic_vector(11 downto 0);
   zpos        : out std_logic_vector(3 downto 0);
   left        : out std_logic;
   middle      : out std_logic;
   right       : out std_logic;
   new_event   : out std_logic;
   ps2_clk     : inout std_logic;
   ps2_data    : inout std_logic
);
end MouseCtl;

architecture Behavioral of MouseCtl is

COMPONENT Ps2Interface
PORT(
   ps2_clk        : inout std_logic;
   ps2_data       : inout std_logic;
   clk            : in std_logic;
   rst            : in std_logic;
   tx_data        : in std_logic_vector(7 downto 0);
   write_data     : in std_logic;
   rx_data        : out std_logic_vector(7 downto 0);
   read_data      : out std_logic;
   busy           : out std_logic;
   err            : out std_logic
);
END COMPONENT;

constant FA: std_logic_vector(7 downto 0) := "11111010";
constant FF: std_logic_vector(7 downto 0) := "11111111";
constant AA: std_logic_vector(7 downto 0) := "10101010";
constant OO: std_logic_vector(7 downto 0) := "00000000";
constant READ_ID          : std_logic_vector(7 downto 0) := x"F2";
constant ENABLE_REPORTING : std_logic_vector(7 downto 0) := x"F4";
constant SET_RESOLUTION   : std_logic_vector(7 downto 0) := x"E8";
constant RESOLUTION       : std_logic_vector(7 downto 0) := x"03";
constant SET_SAMPLE_RATE  : std_logic_vector(7 downto 0) := x"F3";
constant SAMPLE_RATE      : std_logic_vector(7 downto 0) := x"28";
constant DEFAULT_MAX_X : std_logic_vector(11 downto 0) := x"280";  -- 640
constant DEFAULT_MAX_Y : std_logic_vector(11 downto 0) := x"1E0";  -- 480
constant CHECK_PERIOD_CLOCKS   : integer := ((CHECK_PERIOD_MS*1000000)/(1000000000/SYSCLK_FREQUENCY_HZ));
constant TIMEOUT_PERIOD_CLOCKS : integer := ((TIMEOUT_PERIOD_MS*1000000)/(1000000000/SYSCLK_FREQUENCY_HZ));

signal haswheel: std_logic := '0';
signal x_pos,y_pos: std_logic_vector(11 downto 0) := (others => '0');
signal x_overflow,y_overflow: std_logic := '0';
signal x_sign,y_sign: std_logic := '0';
signal x_inc,y_inc: std_logic_vector(7 downto 0) := (others => '0');
signal x_new,y_new: std_logic := '0';
signal x_max: std_logic_vector(11 downto 0) := DEFAULT_MAX_X;
signal y_max: std_logic_vector(11 downto 0) := DEFAULT_MAX_Y;
signal left_down,middle_down,right_down: std_logic := '0';

type fsm_state is
(
   reset,reset_wait_ack,reset_wait_bat_completion,reset_wait_id,
   reset_set_sample_rate_200,reset_set_sample_rate_200_wait_ack,
   reset_send_sample_rate_200,reset_send_sample_rate_200_wait_ack,
   reset_set_sample_rate_100,reset_set_sample_rate_100_wait_ack,
   reset_send_sample_rate_100,reset_send_sample_rate_100_wait_ack,
   reset_set_sample_rate_80,reset_set_sample_rate_80_wait_ack,
   reset_send_sample_rate_80,reset_send_sample_rate_80_wait_ack,
   reset_read_id,reset_read_id_wait_ack,reset_read_id_wait_id,
   reset_set_resolution,reset_set_resolution_wait_ack,
   reset_send_resolution,reset_send_resolution_wait_ack,
   reset_set_sample_rate_40,reset_set_sample_rate_40_wait_ack,
   reset_send_sample_rate_40,reset_send_sample_rate_40_wait_ack,
   reset_enable_reporting,reset_enable_reporting_wait_ack,   
   read_byte_1,read_byte_2,read_byte_3,read_byte_4,
   check_read_id,check_read_id_wait_ack,check_read_id_wait_id,
   mark_new_event
);
signal state: fsm_state := reset;

signal read_data  : std_logic;
signal err  : std_logic;
signal rx_data: std_logic_vector (7 downto 0);
signal tx_data: std_logic_vector (7 downto 0);
signal write_data : std_logic;

signal periodic_check_cnt        : integer range 0 to (CHECK_PERIOD_CLOCKS - 1) := 0;
signal reset_periodic_check_cnt  : STD_LOGIC := '0';
signal periodic_check_tick       : STD_LOGIC := '0';

signal timeout_cnt        : integer range 0 to (TIMEOUT_PERIOD_CLOCKS - 1) := 0;
signal reset_timeout_cnt  : STD_LOGIC := '0';
signal timeout            : STD_LOGIC := '0';

begin

   Inst_Ps2Interface: Ps2Interface
   PORT MAP
   (
      ps2_clk        => ps2_clk,
      ps2_data       => ps2_data,
      clk            => clk,
      rst            => rst,
      tx_data        => tx_data,
      write_data     => write_data,
      rx_data        => rx_data,
      read_data      => read_data,
      busy           => open,
      err            => err
   );

Count_periodic_check: process (clk, periodic_check_cnt, reset_periodic_check_cnt)
begin
   if clk'EVENT AND clk = '1' then
      if reset_periodic_check_cnt = '1' then
         periodic_check_cnt <= 0;
      elsif periodic_check_cnt = (CHECK_PERIOD_CLOCKS - 1) then   
         periodic_check_cnt <= 0;
      else
         periodic_check_cnt <= periodic_check_cnt + 1;
      end if;
   end if;
end process Count_periodic_check;

periodic_check_tick  <= '1' when periodic_check_cnt = (CHECK_PERIOD_CLOCKS - 1) else '0';

Count_timeout: process (clk, timeout_cnt, reset_timeout_cnt)
begin
   if clk'EVENT AND clk = '1' then
      if reset_timeout_cnt = '1' then
         timeout_cnt <= 0;
      elsif timeout_cnt = (TIMEOUT_PERIOD_CLOCKS - 1) then   
         timeout_cnt <= (TIMEOUT_PERIOD_CLOCKS - 1);
      else
         timeout_cnt <= timeout_cnt + 1;
      end if;
   end if;
end process Count_timeout;

timeout  <= '1' when timeout_cnt = (TIMEOUT_PERIOD_CLOCKS - 1) else '0';

-- 输出鼠标按键状态
left <= left_down when rising_edge(clk);
middle <= middle_down when rising_edge(clk);
right <= right_down when rising_edge(clk);
xpos <= x_pos(11 downto 0) when rising_edge(clk);
ypos <= y_pos(11 downto 0) when rising_edge(clk);
zpos <= (others => '0') when rising_edge(clk);
new_event <= '0';

set_x: process(clk)
variable x_inter: std_logic_vector(11 downto 0);
variable inc: std_logic_vector(11 downto 0);
begin
   if(rising_edge(clk)) then
      if(x_new = '1') then
         if(x_sign = '1') then
            if(x_overflow = '1') then
               inc := "111000000000";
            else
               inc := "1111" & x_inc;
            end if;
            x_inter := x_pos + inc;
            if(x_inter(11) = '1') then
               x_pos <= (others => '0');
            else
               x_pos <= x_inter;
            end if;
         else
            if(x_overflow = '1') then
               inc := "000100000000";
            else
               inc := "0000" & x_inc;
            end if;
            x_inter := x_pos + inc;
            if(x_inter > ('0' & x_max)) then
               x_pos <= x_max;
            else
               x_pos <= x_inter;
            end if;
         end if;
      end if;
   end if;
end process set_x;

set_y: process(clk)
variable y_inter: std_logic_vector(11 downto 0);
variable inc: std_logic_vector(11 downto 0);
begin
   if(rising_edge(clk)) then
      if(y_new = '1') then
         if(y_sign = '1') then
            if(y_overflow = '1') then
               inc := "111100000000";
            else
               inc := "1111" & y_inc;
            end if;
            y_inter := y_pos + inc;
            if(y_inter(11) = '1') then
               y_pos <= (others => '0');
            else
               y_pos <= y_inter;
            end if;
         else
            if(y_overflow = '1') then
               inc := "000100000000";
            else
               inc := "0000" & y_inc;
            end if;
            y_inter := y_pos + inc;
            if(y_inter > (y_max)) then
               y_pos <= y_max;
            else
               y_pos <= y_inter;
            end if;
         end if;
      end if;
   end if;
end process set_y;

manage_fsm: process(clk,rst)
begin
   if(rst = '1') then
      state <= reset;
      haswheel <= '0';
      x_overflow <= '0';
      y_overflow <= '0';
      x_sign <= '0';
      y_sign <= '0';
      x_inc <= (others => '0');
      y_inc <= (others => '0');
      x_new <= '0';
      y_new <= '0';
      left_down <= '0';
      middle_down <= '0';
      right_down <= '0';
      reset_periodic_check_cnt <= '1';
      reset_timeout_cnt <= '1';
   elsif(rising_edge(clk)) then
      write_data <= '0';
      x_new <= '0';
      y_new <= '0';
      
      case state is
         when reset =>
            haswheel <= '0';
            x_overflow <= '0';
            y_overflow <= '0';
            x_sign <= '0';
            y_sign <= '0';
            x_inc <= (others => '0');
            y_inc <= (others => '0');
            x_new <= '0';
            y_new <= '0';
            left_down <= '0';
            middle_down <= '0';
            right_down <= '0';
            tx_data <= FF;
            write_data <= '1';
            reset_periodic_check_cnt <= '1';
            reset_timeout_cnt <= '1';               
            state <= reset_wait_ack;

         when reset_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_wait_bat_completion;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_wait_ack;
            end if;

         when reset_wait_bat_completion =>
            if(read_data = '1') then
               if(rx_data = AA) then
                  state <= reset_wait_id;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_wait_bat_completion;
            end if;

         when reset_wait_id =>
            if(read_data = '1') then
               if(rx_data = OO) then
                  state <= reset_set_sample_rate_200;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_wait_id;
            end if;

         when reset_set_sample_rate_200 =>
            tx_data <= SET_SAMPLE_RATE;
            write_data <= '1';
            state <= reset_set_sample_rate_200_wait_ack;

         when reset_set_sample_rate_200_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_send_sample_rate_200;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_set_sample_rate_200_wait_ack;
            end if;

         when reset_send_sample_rate_200 =>
            tx_data <= "11001000";
            write_data <= '1';
            state <= reset_send_sample_rate_200_wait_ack;

         when reset_send_sample_rate_200_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_set_sample_rate_100;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_send_sample_rate_200_wait_ack;
            end if;

         when reset_set_sample_rate_100 =>
            tx_data <= SET_SAMPLE_RATE;
            write_data <= '1';
            state <= reset_set_sample_rate_100_wait_ack;

         when reset_set_sample_rate_100_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_send_sample_rate_100;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_set_sample_rate_100_wait_ack;
            end if;

         when reset_send_sample_rate_100 =>
            tx_data <= "01100100";
            write_data <= '1';
            state <= reset_send_sample_rate_100_wait_ack;

         when reset_send_sample_rate_100_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_set_sample_rate_80;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_send_sample_rate_100_wait_ack;
            end if;           

         when reset_set_sample_rate_80 =>
            tx_data <= SET_SAMPLE_RATE;
            write_data <= '1';
            state <= reset_set_sample_rate_80_wait_ack;

         when reset_set_sample_rate_80_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_send_sample_rate_80;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_set_sample_rate_80_wait_ack;
            end if;

         when reset_send_sample_rate_80 =>
            tx_data <= "01010000";
            write_data <= '1';
            state <= reset_send_sample_rate_80_wait_ack;

         when reset_send_sample_rate_80_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_read_id;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_send_sample_rate_80_wait_ack;
            end if;           

         when reset_read_id =>
            tx_data <= READ_ID;
            write_data <= '1';
            state <= reset_read_id_wait_ack;

         when reset_read_id_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_read_id_wait_id;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_read_id_wait_ack;
            end if;

         when reset_read_id_wait_id =>
            if(read_data = '1') then
               if(rx_data = "000000000") then
                  haswheel <= '0';
                  state <= reset_set_resolution;
               elsif(rx_data = "00000011") then
                  haswheel <= '1';
                  state <= reset_set_resolution;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_read_id_wait_id;
            end if;

         when reset_set_resolution =>
            tx_data <= SET_RESOLUTION;
            write_data <= '1';
            state <= reset_set_resolution_wait_ack;

         when reset_set_resolution_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_send_resolution;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_set_resolution_wait_ack;
            end if;

         when reset_send_resolution =>
            tx_data <= RESOLUTION;
            write_data <= '1';
            state <= reset_send_resolution_wait_ack;

         when reset_send_resolution_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_set_sample_rate_40;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_send_resolution_wait_ack;
            end if;

         when reset_set_sample_rate_40 =>
            tx_data <= SET_SAMPLE_RATE;
            write_data <= '1';
            state <= reset_set_sample_rate_40_wait_ack;

         when reset_set_sample_rate_40_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_send_sample_rate_40;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_set_sample_rate_40_wait_ack;
            end if;

         when reset_send_sample_rate_40 =>
            tx_data <= SAMPLE_RATE;
            write_data <= '1';
            state <= reset_send_sample_rate_40_wait_ack;

         when reset_send_sample_rate_40_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= reset_enable_reporting;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_send_sample_rate_40_wait_ack;
            end if;

         when reset_enable_reporting =>
            tx_data <= ENABLE_REPORTING;
            write_data <= '1';
            state <= reset_enable_reporting_wait_ack;

         when reset_enable_reporting_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= read_byte_1;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            else
               state <= reset_enable_reporting_wait_ack;
            end if;

         when read_byte_1 =>
            reset_periodic_check_cnt <= '0';
            if(read_data = '1') then
               -- 读取鼠标按键状态（第一个字节的bit0-2）
               left_down <= rx_data(0);
               right_down <= rx_data(1);
               middle_down <= rx_data(2);
               x_sign <= rx_data(4);
               y_sign <= not rx_data(5);
               x_overflow <= rx_data(6);
               y_overflow <= rx_data(7);
               state <= read_byte_2;
            elsif periodic_check_tick = '1' then
               state <= check_read_id;
            else
               state <= read_byte_1;
            end if;

         when read_byte_2 =>
            if(read_data = '1') then
               x_inc <= rx_data;
               x_new <= '1';
               state <= read_byte_3;
            elsif periodic_check_tick = '1' then
               state <= check_read_id;
            elsif(err = '1') then
               state <= reset;
            else
               state <= read_byte_2;
            end if;
            
         when read_byte_3 =>
            if(read_data = '1') then
               if(rx_data /= "00000000") then
                  y_inc <= (not rx_data) + "00000001";
                  y_new <= '1';        
               end if;
               if(haswheel = '1') then
                  state <= read_byte_4;
               else
                  state <= read_byte_1;
               end if;
            elsif periodic_check_tick = '1' then
               state <= check_read_id;
            elsif(err = '1') then
               state <= reset;
            else
               state <= read_byte_3;
            end if;

         when read_byte_4 =>
            if(read_data = '1') then
               state <= read_byte_1;
            elsif periodic_check_tick = '1' then
               state <= check_read_id;
            elsif(err = '1') then
               state <= reset;
            else
               state <= read_byte_4;
            end if;
            
         when check_read_id =>
            reset_timeout_cnt <= '0';
            tx_data <= READ_ID;
            write_data <= '1';
            state <= check_read_id_wait_ack;

         when check_read_id_wait_ack =>
            if(read_data = '1') then
               if(rx_data = FA) then
                  state <= check_read_id_wait_id;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            elsif (timeout = '1') then
               state <= reset;
            else
               state <= check_read_id_wait_ack;
            end if;

         when check_read_id_wait_id =>
            if(read_data = '1') then
               if(rx_data = "000000000") or (rx_data = "00000011") then
                  reset_timeout_cnt <= '1';
                  state <= read_byte_1;
               else
                  state <= reset;
               end if;
            elsif(err = '1') then
               state <= reset;
            elsif (timeout = '1') then
               state <= reset;
            else
               state <= check_read_id_wait_id;
            end if;

         when others =>
            state <= reset;
      end case;
   end if;
end process manage_fsm;

end Behavioral;