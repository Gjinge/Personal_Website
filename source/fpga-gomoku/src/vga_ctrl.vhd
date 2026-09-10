library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vga_ctrl is
    Port ( 
        CLK_I      : in STD_LOGIC;
        VGA_HS_O   : out STD_LOGIC;
        VGA_VS_O   : out STD_LOGIC;
        VGA_RED_O  : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_BLUE_O : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_GREEN_O: out STD_LOGIC_VECTOR(3 downto 0);
        PS2_CLK    : inout STD_LOGIC;
        PS2_DATA   : inout STD_LOGIC
    );
end vga_ctrl;

architecture Behavioral of vga_ctrl is

    -- 时钟与 VGA 参数
    signal vga_clk : std_logic := '0';
    signal clk_div_cnt : integer range 0 to 3 := 0;
    
    constant H_ACTIVE   : integer := 640;
    constant H_FRONT    : integer := 16;
    constant H_SYNC     : integer := 96;
    constant H_BACK     : integer := 48;
    constant H_TOTAL    : integer := 800;
    
    constant V_ACTIVE   : integer := 480;
    constant V_FRONT    : integer := 10;
    constant V_SYNC     : integer := 2;
    constant V_BACK     : integer := 33;
    constant V_TOTAL    : integer := 525;
    
    constant BOARD_SIZE : integer := 15;
    constant CELL_SIZE  : integer := 28;
    constant LINE_WIDTH : integer := 2;
    constant BOARD_WIDTH  : integer := BOARD_SIZE * (CELL_SIZE + LINE_WIDTH) - LINE_WIDTH;
    constant BOARD_HEIGHT : integer := BOARD_WIDTH;
    constant BOARD_OFFSET_X : integer := (H_ACTIVE - BOARD_WIDTH) / 2;
    constant BOARD_OFFSET_Y : integer := (V_ACTIVE - BOARD_HEIGHT) / 2;
    constant PIECE_RADIUS : integer := 11;
    
    signal h_cnt : integer range 0 to H_TOTAL-1 := 0;
    signal v_cnt : integer range 0 to V_TOTAL-1 := 0;
    signal h_sync_int, v_sync_int : std_logic := '1';
    signal active : std_logic;
    
    -- 鼠标信号
    signal mouse_x, mouse_y : std_logic_vector(11 downto 0);
    signal mouse_left, mouse_middle, mouse_right : std_logic;
    signal mouse_left_reg, mouse_middle_reg, mouse_right_reg : std_logic := '0';
    signal left_click_pulse, middle_click_pulse, right_click_pulse : std_logic := '0';
    signal mouse_cursor_x, mouse_cursor_y : integer := 0;
    
    -- 游戏信号
    signal board_pieces : std_logic_vector(224 downto 0) := (others => '0');
    signal board_colors : std_logic_vector(224 downto 0) := (others => '0');
    signal current_player : std_logic := '1';
    signal game_status : std_logic_vector(1 downto 0) := "00";
    signal winner_color : std_logic := '0';
    signal last_move_x, last_move_y : integer := 0;
    signal grid_x, grid_y : integer := -1;
    signal undo_trigger : std_logic := '0';
    signal reset_trigger : std_logic := '0';
    signal game_mode : std_logic_vector(1 downto 0);
    signal mode_changed : std_logic;
    
    signal screen_state : std_logic := '0';   -- 0=开始界面, 1=游戏中
    
    signal win_line_start_x, win_line_start_y : integer := -1;
    signal win_line_end_x, win_line_end_y : integer := -1;
    signal win_line_valid : std_logic := '0';
    
    -- 开始界面贴图
    signal start_pixel  : std_logic_vector(11 downto 0);
    signal start_active : std_logic;
    signal pixel_x_int  : integer range 0 to 639;
    signal pixel_y_int  : integer range 0 to 479;

    -- 组件声明
    component MouseCtl
    generic(SYSCLK_FREQUENCY_HZ : integer := 25000000);
    port(
        clk        : in std_logic;
        rst        : in std_logic;
        xpos       : out std_logic_vector(11 downto 0);
        ypos       : out std_logic_vector(11 downto 0);
        zpos       : out std_logic_vector(3 downto 0);
        left       : out std_logic;
        middle     : out std_logic;
        right      : out std_logic;
        new_event  : out std_logic;
        ps2_clk    : inout std_logic;
        ps2_data   : inout std_logic
    );
    end component;
    
    component game_controller
    generic(BSIZE : integer := 15);
    port(
        clk              : in  std_logic;
        reset            : in  std_logic;
        mouse_x          : in  std_logic_vector(11 downto 0);
        mouse_y          : in  std_logic_vector(11 downto 0);
        left_click       : in  std_logic;
        right_click      : in  std_logic;
        middle_click     : in  std_logic;
        board_pieces     : out std_logic_vector(BSIZE*BSIZE-1 downto 0);
        board_colors     : out std_logic_vector(BSIZE*BSIZE-1 downto 0);
        game_status      : out std_logic_vector(1 downto 0);
        winner_color     : out std_logic;
        current_player   : out std_logic;
        last_move_x      : out integer;
        last_move_y      : out integer;
        undo_trigger     : in  std_logic;
        reset_trigger    : in  std_logic;
        game_mode        : out std_logic_vector(1 downto 0);
        win_line_start_x : out integer;
        win_line_start_y : out integer;
        win_line_end_x   : out integer;
        win_line_end_y   : out integer;
        win_line_valid   : out std_logic;
        mode_changed     : out std_logic
    );
    end component;

    component start_screen_controller
    generic (
        SCREEN_WIDTH  : integer := 640;
        SCREEN_HEIGHT : integer := 480;
        Y_OFFSET      : integer := 0;
        ROM_ADDR_BITS : integer := 19;
        ROM_DATA_BITS : integer := 12
    );
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        pixel_x       : in  integer range 0 to 639;
        pixel_y       : in  integer range 0 to 479;
        video_active  : in  std_logic;
        left_click    : in  std_logic;
        right_click   : in  std_logic;
        middle_click  : in  std_logic;
        start_pixel   : out std_logic_vector(11 downto 0);
        start_active  : out std_logic;
        game_start    : out std_logic
    );
    end component;

begin

    -- 时钟分频 100MHz -> 25MHz
    process(CLK_I)
    begin
        if rising_edge(CLK_I) then
            if clk_div_cnt = 3 then
                clk_div_cnt <= 0;
                vga_clk <= not vga_clk;
            else
                clk_div_cnt <= clk_div_cnt + 1;
            end if;
        end if;
    end process;

    -- VGA 时序
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if h_cnt = H_TOTAL - 1 then
                h_cnt <= 0;
                if v_cnt = V_TOTAL - 1 then
                    v_cnt <= 0;
                else
                    v_cnt <= v_cnt + 1;
                end if;
            else
                h_cnt <= h_cnt + 1;
            end if;
        end if;
    end process;

    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if h_cnt >= H_ACTIVE + H_FRONT and h_cnt < H_ACTIVE + H_FRONT + H_SYNC then
                h_sync_int <= '0';
            else
                h_sync_int <= '1';
            end if;
            if v_cnt >= V_ACTIVE + V_FRONT and v_cnt < V_ACTIVE + V_FRONT + V_SYNC then
                v_sync_int <= '0';
            else
                v_sync_int <= '1';
            end if;
        end if;
    end process;
    VGA_HS_O <= h_sync_int;
    VGA_VS_O <= v_sync_int;
    active <= '1' when h_cnt < H_ACTIVE and v_cnt < V_ACTIVE else '0';
    pixel_x_int <= h_cnt;
    pixel_y_int <= v_cnt;

    -- 鼠标驱动
    mouse_inst: MouseCtl
    generic map(SYSCLK_FREQUENCY_HZ => 25000000)
    port map(
        clk       => vga_clk,
        rst       => '0',
        xpos      => mouse_x,
        ypos      => mouse_y,
        zpos      => open,
        left      => mouse_left,
        middle    => mouse_middle,
        right     => mouse_right,
        new_event => open,
        ps2_clk   => PS2_CLK,
        ps2_data  => PS2_DATA
    );
    mouse_cursor_x <= conv_integer(mouse_x);
    mouse_cursor_y <= conv_integer(mouse_y);

    -- 鼠标按键边沿检测
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            mouse_left_reg <= mouse_left;
            if mouse_left = '1' and mouse_left_reg = '0' then
                left_click_pulse <= '1';
            else
                left_click_pulse <= '0';
            end if;
            mouse_middle_reg <= mouse_middle;
            if mouse_middle = '1' and mouse_middle_reg = '0' then
                middle_click_pulse <= '1';
            else
                middle_click_pulse <= '0';
            end if;
            mouse_right_reg <= mouse_right;
            if mouse_right = '1' and mouse_right_reg = '0' then
                right_click_pulse <= '1';
            else
                right_click_pulse <= '0';
            end if;
        end if;
    end process;

    -- 开始界面贴图控制器（鼠标输入接地）
    start_inst : start_screen_controller
    generic map (
        SCREEN_WIDTH  => 640,
        SCREEN_HEIGHT => 480,
        Y_OFFSET      => 0,
        ROM_ADDR_BITS => 19,
        ROM_DATA_BITS => 12
    )
    port map (
        clk           => vga_clk,
        reset         => '0',
        pixel_x       => pixel_x_int,
        pixel_y       => pixel_y_int,
        video_active  => active,
        left_click    => '0',
        right_click   => '0',
        middle_click  => '0',
        start_pixel   => start_pixel,
        start_active  => start_active,
        game_start    => open
    );

    -- 游戏控制器
    game_ctrl_inst: game_controller
    generic map(BSIZE => BOARD_SIZE)
    port map(
        clk              => vga_clk,
        reset            => '0',
        mouse_x          => mouse_x,
        mouse_y          => mouse_y,
        left_click       => left_click_pulse,    -- 始终传递，由内部状态机处理
        right_click      => right_click_pulse,
        middle_click     => middle_click_pulse,
        board_pieces     => board_pieces,
        board_colors     => board_colors,
        game_status      => game_status,
        winner_color     => winner_color,
        current_player   => current_player,
        last_move_x      => last_move_x,
        last_move_y      => last_move_y,
        undo_trigger     => undo_trigger,
        reset_trigger    => reset_trigger,       -- 修复后的复位
        game_mode        => game_mode,
        win_line_start_x => win_line_start_x,
        win_line_start_y => win_line_start_y,
        win_line_end_x   => win_line_end_x,
        win_line_end_y   => win_line_end_y,
        win_line_valid   => win_line_valid,
        mode_changed     => mode_changed
    );

    -- 复位信号：仅由中键产生，避免竞争
    reset_trigger <= middle_click_pulse;

    -- 界面状态切换
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if middle_click_pulse = '1' then
                screen_state <= '0';          -- 中键返回开始界面
            elsif mode_changed = '1' then
                screen_state <= '1';          -- 检测到模式切换，进入游戏
            end if;
        end if;
    end process;

    -- 悔棋（仅在游戏中）
    process(vga_clk)
    begin
        if rising_edge(vga_clk) then
            if screen_state = '1' and right_click_pulse = '1' then
                undo_trigger <= '1';
            else
                undo_trigger <= '0';
            end if;
        end if;
    end process;

    -- 鼠标坐标转棋盘格子
    process(mouse_x, mouse_y)
        variable pos_x, pos_y : integer;
    begin
        pos_x := (conv_integer(mouse_x) - BOARD_OFFSET_X) / (CELL_SIZE + LINE_WIDTH);
        pos_y := (conv_integer(mouse_y) - BOARD_OFFSET_Y) / (CELL_SIZE + LINE_WIDTH);
        if pos_x >= 0 and pos_x < BOARD_SIZE and pos_y >= 0 and pos_y < BOARD_SIZE then
            if conv_integer(mouse_x) >= BOARD_OFFSET_X and 
               conv_integer(mouse_x) < BOARD_OFFSET_X + BOARD_WIDTH and
               conv_integer(mouse_y) >= BOARD_OFFSET_Y and 
               conv_integer(mouse_y) < BOARD_OFFSET_Y + BOARD_HEIGHT then
                grid_x <= pos_x;
                grid_y <= pos_y;
            else
                grid_x <= -1;
                grid_y <= -1;
            end if;
        else
            grid_x <= -1;
            grid_y <= -1;
        end if;
    end process;

    -- VGA 颜色输出
    process(vga_clk)
        variable px, py : integer;
        variable board_x, board_y : integer;
        variable cell_x, cell_y : integer;
        variable idx : integer;
        variable has_piece : std_logic;
        variable piece_color : std_logic;
        variable stone_cx, stone_cy : integer;
        variable dx, dy : integer;
        variable line_cx1, line_cy1, line_cx2, line_cy2 : integer;
        variable t : integer;
        variable line_x, line_y : integer;
        variable dist_to_line : integer;
        variable red_t, green_t, blue_t : std_logic_vector(3 downto 0);
        variable draw_cursor : boolean;
    begin
        if rising_edge(vga_clk) then
            if active = '1' then
                px := h_cnt;
                py := v_cnt;
                red_t := "0000";
                green_t := "0000";
                blue_t := "0000";

                if screen_state = '0' then
                    -- 开始界面：显示贴图
                    if start_active = '1' then
                        red_t   := start_pixel(11 downto 8);
                        green_t := start_pixel(7 downto 4);
                        blue_t  := start_pixel(3 downto 0);
                    else
                        red_t   := "0000";
                        green_t := "0000";
                        blue_t := "0000";
                    end if;
                else
                    -- 游戏界面（棋盘渲染）
                    red_t := "0000";
                    green_t := "0000";
                    blue_t := "0100";
                    
                    if px >= BOARD_OFFSET_X and px < BOARD_OFFSET_X + BOARD_WIDTH and
                       py >= BOARD_OFFSET_Y and py < BOARD_OFFSET_Y + BOARD_HEIGHT then
                        
                        board_x := (px - BOARD_OFFSET_X) / (CELL_SIZE + LINE_WIDTH);
                        board_y := (py - BOARD_OFFSET_Y) / (CELL_SIZE + LINE_WIDTH);
                        cell_x := (px - BOARD_OFFSET_X) mod (CELL_SIZE + LINE_WIDTH);
                        cell_y := (py - BOARD_OFFSET_Y) mod (CELL_SIZE + LINE_WIDTH);
                        
                        idx := board_y * BOARD_SIZE + board_x;
                        has_piece := board_pieces(idx);
                        piece_color := board_colors(idx);
                        
                        red_t := "1110";
                        green_t := "1101";
                        blue_t := "1011";
                        
                        if cell_x < LINE_WIDTH or cell_x > CELL_SIZE + LINE_WIDTH - LINE_WIDTH - 1 or
                           cell_y < LINE_WIDTH or cell_y > CELL_SIZE + LINE_WIDTH - LINE_WIDTH - 1 then
                            red_t := "0000";
                            green_t := "0000";
                            blue_t := "0000";
                        elsif has_piece = '1' then
                            stone_cx := BOARD_OFFSET_X + board_x*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            stone_cy := BOARD_OFFSET_Y + board_y*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            dx := px - stone_cx;
                            dy := py - stone_cy;
                            if dx*dx + dy*dy <= PIECE_RADIUS*PIECE_RADIUS then
                                if piece_color = '1' then
                                    red_t := "0000";
                                    green_t := "0000";
                                    blue_t := "0000";
                                else
                                    red_t := "1111";
                                    green_t := "1111";
                                    blue_t := "1111";
                                end if;
                            end if;
                        end if;
                        
                        if win_line_valid = '1' and win_line_start_x >= 0 then
                            line_cx1 := BOARD_OFFSET_X + win_line_start_x*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            line_cy1 := BOARD_OFFSET_Y + win_line_start_y*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            line_cx2 := BOARD_OFFSET_X + win_line_end_x*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            line_cy2 := BOARD_OFFSET_Y + win_line_end_y*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            
                            if (line_cx2 - line_cx1) /= 0 or (line_cy2 - line_cy1) /= 0 then
                                t := ((px - line_cx1)*(line_cx2 - line_cx1) + (py - line_cy1)*(line_cy2 - line_cy1)) / 
                                     ((line_cx2 - line_cx1)*(line_cx2 - line_cx1) + (line_cy2 - line_cy1)*(line_cy2 - line_cy1) + 1);
                                if t < 0 then t := 0; end if;
                                if t > 1 then t := 1; end if;
                                line_x := line_cx1 + t * (line_cx2 - line_cx1);
                                line_y := line_cy1 + t * (line_cy2 - line_cy1);
                                dist_to_line := (px - line_x)*(px - line_x) + (py - line_y)*(py - line_y);
                                if dist_to_line <= 9 then
                                    red_t := "1111";
                                    green_t := "0000";
                                    blue_t := "0000";
                                end if;
                            end if;
                        end if;
                        
                        if board_x = grid_x and board_y = grid_y and game_status = "00" then
                            stone_cx := BOARD_OFFSET_X + board_x*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            stone_cy := BOARD_OFFSET_Y + board_y*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            dx := px - stone_cx;
                            dy := py - stone_cy;
                            if dx*dx + dy*dy <= (PIECE_RADIUS+3)*(PIECE_RADIUS+3) and 
                               dx*dx + dy*dy >= (PIECE_RADIUS+1)*(PIECE_RADIUS+1) then
                                red_t := "1110";
                                green_t := "1110";
                                blue_t := "0000";
                            elsif dx*dx + dy*dy <= PIECE_RADIUS*PIECE_RADIUS then
                                red_t := "1100";
                                green_t := "0000";
                                blue_t := "0000";
                            end if;
                        end if;
                    end if;
                end if;

                -- 绘制鼠标光标（所有界面均显示）
                draw_cursor := false;
                if (px >= mouse_cursor_x-5 and px <= mouse_cursor_x+5 and 
                    py >= mouse_cursor_y-1 and py <= mouse_cursor_y+1) or
                   (px >= mouse_cursor_x-1 and px <= mouse_cursor_x+1 and 
                    py >= mouse_cursor_y-5 and py <= mouse_cursor_y+5) then
                    draw_cursor := true;
                end if;
                if draw_cursor then
                    red_t := "1111";
                    green_t := "1111";
                    blue_t := "1111";
                end if;

                VGA_RED_O   <= red_t;
                VGA_GREEN_O <= green_t;
                VGA_BLUE_O  <= blue_t;
            else
                VGA_RED_O   <= "0000";
                VGA_GREEN_O <= "0000";
                VGA_BLUE_O  <= "0000";
            end if;
        end if;
    end process;

end Behavioral;