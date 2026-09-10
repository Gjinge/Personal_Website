library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TopGobangSystem is
    Port (
        clk_100mhz   : in  STD_LOGIC;
        rst_n        : in  STD_LOGIC;
        ps2_clk      : inout STD_LOGIC;
        ps2_data     : inout STD_LOGIC;
        vga_hsync    : out STD_LOGIC;
        vga_vsync    : out STD_LOGIC;
        vga_red      : out STD_LOGIC_VECTOR(3 downto 0);
        vga_green    : out STD_LOGIC_VECTOR(3 downto 0);
        vga_blue     : out STD_LOGIC_VECTOR(3 downto 0);
        leds         : out STD_LOGIC_VECTOR(7 downto 0)
    );
end TopGobangSystem;

architecture Behavioral of TopGobangSystem is
    
    -- 游戏参数
    constant BOARD_SIZE : integer := 15;
    constant CELL_SIZE  : integer := 32;
    constant LINE_WIDTH : integer := 2;
    constant BOARD_WIDTH_PX  : integer := BOARD_SIZE * (CELL_SIZE + LINE_WIDTH) - LINE_WIDTH;
    constant BOARD_HEIGHT_PX : integer := BOARD_WIDTH_PX;
    constant FRAME_WIDTH  : integer := 640;
    constant FRAME_HEIGHT : integer := 480;
    constant BOARD_OFFSET_X : integer := (FRAME_WIDTH - BOARD_WIDTH_PX) / 2;
    constant BOARD_OFFSET_Y : integer := (FRAME_HEIGHT - BOARD_HEIGHT_PX) / 2;
    
    -- 鼠标控制器组件
    component MouseCtl
        generic(
            SYSCLK_FREQUENCY_HZ : integer := 100000000;
            CHECK_PERIOD_MS     : integer := 500;
            TIMEOUT_PERIOD_MS   : integer := 100
        );
        port(
            clk         : in  std_logic;
            rst         : in  std_logic;
            xpos        : out std_logic_vector(11 downto 0);
            ypos        : out std_logic_vector(11 downto 0);
            zpos        : out std_logic_vector(3 downto 0);
            left        : out std_logic;
            middle      : out std_logic;
            right       : out std_logic;
            new_event   : out std_logic;
            value       : in  std_logic_vector(11 downto 0);
            setx        : in  std_logic;
            sety        : in  std_logic;
            setmax_x    : in  std_logic;
            setmax_y    : in  std_logic;
            ps2_clk     : inout std_logic;
            ps2_data    : inout std_logic
        );
    end component;
    
    -- VGA显示组件
    component vga_ctrl
        generic(
            BSIZE : integer := 15
        );
        port(
            CLK_I       : in  STD_LOGIC;
            VGA_HS_O    : out STD_LOGIC;
            VGA_VS_O    : out STD_LOGIC;
            VGA_RED_O   : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_BLUE_O  : out STD_LOGIC_VECTOR(3 downto 0);
            VGA_GREEN_O : out STD_LOGIC_VECTOR(3 downto 0);
            PS2_CLK     : inout STD_LOGIC;
            PS2_DATA    : inout STD_LOGIC;
            board_state : in  STD_LOGIC_VECTOR(BSIZE*BSIZE*2 - 1 downto 0);
            current_player : in STD_LOGIC;
            game_status : in  STD_LOGIC_VECTOR(1 downto 0);
            last_move_x : in  INTEGER;
            last_move_y : in  INTEGER;
            mouse_x     : in  STD_LOGIC_VECTOR(11 downto 0);
            mouse_y     : in  STD_LOGIC_VECTOR(11 downto 0);
            left_click  : in  STD_LOGIC;
            reset_click : in  STD_LOGIC
        );
    end component;
    
    -- 游戏控制器组件
    component game_controller
        generic(
            BSIZE : integer := 15
        );
        port(
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            mouse_x     : in  STD_LOGIC_VECTOR(11 downto 0);
            mouse_y     : in  STD_LOGIC_VECTOR(11 downto 0);
            left_click  : in  STD_LOGIC;
            board_state : out STD_LOGIC_VECTOR(BSIZE*BSIZE*2 - 1 downto 0);
            game_status : out STD_LOGIC_VECTOR(1 downto 0);
            current_player : out STD_LOGIC;
            last_move_x : inout INTEGER;
            last_move_y : inout INTEGER
        );
    end component;
    
    -- 时钟分频信号
    signal clk_25mhz_sig : STD_LOGIC := '0';
    signal clk_div_cnt : integer range 0 to 3 := 0;
    signal clk_100mhz_buf : STD_LOGIC;
    
    -- 鼠标信号
    signal mouse_x, mouse_y : STD_LOGIC_VECTOR(11 downto 0);
    signal mouse_left, mouse_right, mouse_middle : STD_LOGIC;
    signal mouse_new_event : STD_LOGIC;
    signal mouse_left_click : STD_LOGIC := '0';
    signal mouse_left_prev : STD_LOGIC := '0';
    signal reset_click : STD_LOGIC := '0';
    signal reset_prev : STD_LOGIC := '0';
    
    -- 游戏信号
    signal board_state_sig : STD_LOGIC_VECTOR(BOARD_SIZE*BOARD_SIZE*2 - 1 downto 0);
    signal game_status_sig : STD_LOGIC_VECTOR(1 downto 0);
    signal current_player_sig : STD_LOGIC;
    signal last_move_x_sig, last_move_y_sig : INTEGER := 0;
    
    -- 鼠标边界设置
    signal setmax_x, setmax_y : STD_LOGIC := '0';
    signal max_x_value : STD_LOGIC_VECTOR(11 downto 0) := std_logic_vector(to_unsigned(FRAME_WIDTH - 1, 12));
    signal max_y_value : STD_LOGIC_VECTOR(11 downto 0) := std_logic_vector(to_unsigned(FRAME_HEIGHT - 1, 12));
    
begin
    
    -- 时钟分频：100MHz -> 25MHz
    process(clk_100mhz)
    begin
        if rising_edge(clk_100mhz) then
            if clk_div_cnt = 3 then
                clk_div_cnt <= 0;
                clk_25mhz_sig <= not clk_25mhz_sig;
            else
                clk_div_cnt <= clk_div_cnt + 1;
            end if;
        end if;
    end process;
    
    -- 鼠标左键边沿检测
    process(clk_100mhz, rst_n)
    begin
        if rst_n = '0' then
            mouse_left_prev <= '0';
            mouse_left_click <= '0';
            reset_prev <= '0';
            reset_click <= '0';
        elsif rising_edge(clk_100mhz) then
            -- 鼠标左键边沿
            mouse_left_prev <= mouse_left;
            if mouse_left = '1' and mouse_left_prev = '0' then
                mouse_left_click <= '1';
            else
                mouse_left_click <= '0';
            end if;
            
            -- 复位检测（右键长按或特殊区域）
            reset_prev <= mouse_right;
            if mouse_right = '1' and reset_prev = '0' then
                reset_click <= '1';
            else
                reset_click <= '0';
            end if;
        end if;
    end process;
    
    -- 鼠标控制器
    u_mouse: MouseCtl
        generic map(
            SYSCLK_FREQUENCY_HZ => 100000000,
            CHECK_PERIOD_MS     => 500,
            TIMEOUT_PERIOD_MS   => 100
        )
        port map(
            clk      => clk_100mhz,
            rst      => '0',
            xpos     => mouse_x,
            ypos     => mouse_y,
            zpos     => open,
            left     => mouse_left,
            middle   => open,
            right    => mouse_right,
            new_event=> mouse_new_event,
            value    => (others => '0'),
            setx     => '0',
            sety     => '0',
            setmax_x => setmax_x,
            setmax_y => setmax_y,
            ps2_clk  => ps2_clk,
            ps2_data => ps2_data
        );
    
    -- 设置鼠标边界
    process(clk_100mhz)
    begin
        if rising_edge(clk_100mhz) then
            setmax_x <= '1';
            setmax_y <= '1';
        end if;
    end process;
    
    -- 游戏控制器
    u_game: game_controller
        generic map(
            BSIZE => BOARD_SIZE
        )
        port map(
            clk         => clk_25mhz_sig,
            reset       => reset_click,
            mouse_x     => mouse_x,
            mouse_y     => mouse_y,
            left_click  => mouse_left_click,
            board_state => board_state_sig,
            game_status => game_status_sig,
            current_player => current_player_sig,
            last_move_x => last_move_x_sig,
            last_move_y => last_move_y_sig
        );
    
    -- VGA显示控制器
    u_vga: vga_ctrl
        generic map(
            BSIZE => BOARD_SIZE
        )
        port map(
            CLK_I       => clk_100mhz,
            VGA_HS_O    => vga_hsync,
            VGA_VS_O    => vga_vsync,
            VGA_RED_O   => vga_red,
            VGA_GREEN_O => vga_green,
            VGA_BLUE_O  => vga_blue,
            PS2_CLK     => ps2_clk,
            PS2_DATA    => ps2_data,
            board_state => board_state_sig,
            current_player => current_player_sig,
            game_status => game_status_sig,
            last_move_x => last_move_x_sig,
            last_move_y => last_move_y_sig,
            mouse_x     => mouse_x,
            mouse_y     => mouse_y,
            left_click  => mouse_left_click,
            reset_click => reset_click
        );
    
    -- LED显示
    leds(0) <= mouse_left;
    leds(1) <= mouse_right;
    leds(2) <= mouse_new_event;
    leds(3) <= current_player_sig;
    leds(4) <= game_status_sig(0);
    leds(5) <= game_status_sig(1);
    leds(6) <= '0';
    leds(7) <= '0';
    
end Behavioral;