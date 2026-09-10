library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_controller is
    generic(
        BSIZE : integer := 15;
        CELL_SIZE : integer := 30;
        LINE_WIDTH : integer := 2;
        BOARD_OFFSET_X : integer := 95;
        BOARD_OFFSET_Y : integer := 15
    );
    Port (
        clk          : in  STD_LOGIC;
        active       : in  STD_LOGIC;
        hcount       : in  integer;
        vcount       : in  integer;
        board_state  : in  STD_LOGIC_VECTOR(BSIZE*BSIZE*2-1 downto 0);
        game_status  : in  STD_LOGIC_VECTOR(1 downto 0);
        current_player : in STD_LOGIC;
        last_move_x  : in  integer;
        last_move_y  : in  integer;
        grid_x       : in  integer;
        grid_y       : in  integer;
        vga_red      : out STD_LOGIC_VECTOR(3 downto 0);
        vga_green    : out STD_LOGIC_VECTOR(3 downto 0);
        vga_blue     : out STD_LOGIC_VECTOR(3 downto 0)
    );
end display_controller;

architecture Behavioral of display_controller is
    constant BOARD_WIDTH  : integer := BSIZE * (CELL_SIZE + LINE_WIDTH) - LINE_WIDTH;
    constant BOARD_HEIGHT : integer := BOARD_WIDTH;
    constant PIECE_RADIUS : integer := CELL_SIZE / 2 - 3;
    
    constant COLOR_BLACK : std_logic_vector(3 downto 0) := "0000";
    constant COLOR_WHITE : std_logic_vector(3 downto 0) := "1111";
    constant COLOR_RED   : std_logic_vector(3 downto 0) := "1111";
    constant COLOR_GREEN : std_logic_vector(3 downto 0) := "1110";
    
    signal blink_counter : integer range 0 to 12500000 := 0;
    signal blink_state : std_logic := '0';
    
begin
    -- 光标闪烁计数器 (0.5秒周期 @25MHz)
    process(clk)
    begin
        if rising_edge(clk) then
            if blink_counter = 12500000 then
                blink_counter <= 0;
                blink_state <= not blink_state;
            else
                blink_counter <= blink_counter + 1;
            end if;
        end if;
    end process;
    
    -- 渲染
    process(clk)
        variable px, py : integer;
        variable board_x, board_y : integer;
        variable cell_x, cell_y : integer;
        variable stone_idx : integer;
        variable stone_val : std_logic_vector(1 downto 0);
        variable stone_color : std_logic_vector(3 downto 0);
        variable dist : integer;
        variable stone_cx, stone_cy : integer;
    begin
        if rising_edge(clk) then
            if active = '1' then
                px := hcount;
                py := vcount;
                
                -- 默认背景（深蓝色）
                vga_red <= "0000";
                vga_green <= "0000";
                vga_blue <= "0100";
                
                -- 棋盘区域
                if px >= BOARD_OFFSET_X and px < BOARD_OFFSET_X + BOARD_WIDTH and
                   py >= BOARD_OFFSET_Y and py < BOARD_OFFSET_Y + BOARD_HEIGHT then
                    
                    board_x := (px - BOARD_OFFSET_X) / (CELL_SIZE + LINE_WIDTH);
                    board_y := (py - BOARD_OFFSET_Y) / (CELL_SIZE + LINE_WIDTH);
                    cell_x := (px - BOARD_OFFSET_X) mod (CELL_SIZE + LINE_WIDTH);
                    cell_y := (py - BOARD_OFFSET_Y) mod (CELL_SIZE + LINE_WIDTH);
                    
                    -- 棋盘底色（浅黄色）
                    vga_red <= "1110";
                    vga_green <= "1101";
                    vga_blue <= "1011";
                    
                    -- 网格线
                    if cell_x < LINE_WIDTH or cell_x > CELL_SIZE + LINE_WIDTH - LINE_WIDTH - 1 or
                       cell_y < LINE_WIDTH or cell_y > CELL_SIZE + LINE_WIDTH - LINE_WIDTH - 1 then
                        vga_red <= "0000";
                        vga_green <= "0000";
                        vga_blue <= "0000";
                    else
                        -- 棋子
                        stone_idx := (board_y * BSIZE + board_x) * 2;
                        stone_val := board_state(stone_idx+1 downto stone_idx);
                        
                        if stone_val(1) = '1' then
                            if stone_val(0) = '1' then
                                stone_color := COLOR_BLACK;
                            else
                                stone_color := COLOR_WHITE;
                            end if;
                            
                            stone_cx := BOARD_OFFSET_X + board_x*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            stone_cy := BOARD_OFFSET_Y + board_y*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            dist := (px - stone_cx)*(px - stone_cx) + (py - stone_cy)*(py - stone_cy);
                            
                            if dist <= PIECE_RADIUS*PIECE_RADIUS then
                                vga_red <= stone_color;
                                vga_green <= stone_color;
                                vga_blue <= stone_color;
                            end if;
                        end if;
                        
                        -- 圆形光标
                        if board_x = grid_x and board_y = grid_y then
                            stone_cx := BOARD_OFFSET_X + board_x*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            stone_cy := BOARD_OFFSET_Y + board_y*(CELL_SIZE+LINE_WIDTH) + (CELL_SIZE+LINE_WIDTH)/2;
                            dist := (px - stone_cx)*(px - stone_cx) + (py - stone_cy)*(py - stone_cy);
                            
                            -- 光标外框（绿色）
                            if dist <= (PIECE_RADIUS+3)*(PIECE_RADIUS+3) and dist >= (PIECE_RADIUS+1)*(PIECE_RADIUS+1) then
                                vga_red <= COLOR_GREEN;
                                vga_green <= COLOR_GREEN;
                                vga_blue <= "0000";
                            -- 光标内填充（红色闪烁）
                            elsif dist <= PIECE_RADIUS*PIECE_RADIUS and blink_state = '1' then
                                vga_red <= COLOR_RED;
                                vga_green <= "0000";
                                vga_blue <= "0000";
                            end if;
                        end if;
                    end if;
                end if;
            else
                vga_red <= "0000";
                vga_green <= "0000";
                vga_blue <= "0000";
            end if;
        end if;
    end process;
    
end Behavioral;