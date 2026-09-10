library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ai_controller is
    generic(BSIZE : integer := 15);
    port(
        clk          : in  std_logic;
        board_pieces : in  std_logic_vector(BSIZE*BSIZE-1 downto 0);
        board_colors : in  std_logic_vector(BSIZE*BSIZE-1 downto 0);
        ai_color     : in  std_logic;
        game_over    : in  std_logic;
        ai_row       : out integer;
        ai_col       : out integer;
        ai_move_valid: out std_logic;
        ai_thinking  : out std_logic
    );
end ai_controller;

architecture Behavioral of ai_controller is
    type state_type is (IDLE, THINKING, DONE);
    signal state : state_type := IDLE;
    signal best_row, best_col : integer := 7;
    signal move_valid_reg : std_logic := '0';
    signal think_cnt : integer := 0;
    
    -- 方向数组
    type dir_array is array (0 to 3) of integer;
    constant DIR_R : dir_array := (0, 1, 1, -1);
    constant DIR_C : dir_array := (1, 0, 1, 1);
    
    -- 检查是否有棋子
    function has_piece(pieces: std_logic_vector; row: integer; col: integer) return boolean is
        variable idx : integer;
    begin
        if row < 0 or row >= BSIZE or col < 0 or col >= BSIZE then
            return false;
        end if;
        idx := row * BSIZE + col;
        if pieces(idx) = '1' then
            return true;
        else
            return false;
        end if;
    end function;
    
    -- 获取棋子颜色
    function get_color(pieces: std_logic_vector; colors: std_logic_vector; row: integer; col: integer) return std_logic is
        variable idx : integer;
    begin
        if not has_piece(pieces, row, col) then
            return 'X';
        end if;
        idx := row * BSIZE + col;
        return colors(idx);
    end function;
    
    -- 计算单方向连续棋子数
    function count_dir(pieces: std_logic_vector; colors: std_logic_vector; 
                       r: integer; c: integer; dr: integer; dc: integer; color: std_logic) return integer is
        variable cnt : integer;
        variable step : integer;
        variable nr, nc : integer;
    begin
        cnt := 0;
        -- 正方向
        for step in 1 to 4 loop
            nr := r + dr * step;
            nc := c + dc * step;
            if nr >= 0 and nr < BSIZE and nc >= 0 and nc < BSIZE then
                if has_piece(pieces, nr, nc) and get_color(pieces, colors, nr, nc) = color then
                    cnt := cnt + 1;
                else
                    exit;
                end if;
            else
                exit;
            end if;
        end loop;
        -- 负方向
        for step in 1 to 4 loop
            nr := r - dr * step;
            nc := c - dc * step;
            if nr >= 0 and nr < BSIZE and nc >= 0 and nc < BSIZE then
                if has_piece(pieces, nr, nc) and get_color(pieces, colors, nr, nc) = color then
                    cnt := cnt + 1;
                else
                    exit;
                end if;
            else
                exit;
            end if;
        end loop;
        return cnt;
    end function;
    
    -- 检查指定方向是否有空格
    function has_open(pieces: std_logic_vector; colors: std_logic_vector;
                      r: integer; c: integer; dr: integer; dc: integer; color: std_logic; pos_dir: integer) return boolean is
        variable step : integer;
        variable nr, nc : integer;
    begin
        for step in 1 to 5 loop
            if pos_dir = 1 then
                nr := r + dr * step;
                nc := c + dc * step;
            else
                nr := r - dr * step;
                nc := c - dc * step;
            end if;
            if nr >= 0 and nr < BSIZE and nc >= 0 and nc < BSIZE then
                if has_piece(pieces, nr, nc) then
                    if get_color(pieces, colors, nr, nc) = color then
                        next;
                    else
                        return false;
                    end if;
                else
                    return true;
                end if;
            else
                return false;
            end if;
        end loop;
        return false;
    end function;
    
    -- 完整评分函数
    function calc_score(pieces: std_logic_vector; colors: std_logic_vector; ai_c: std_logic; r: integer; c: integer) return integer is
        variable total : integer;
        variable self_c, enemy_c : std_logic;
        variable d : integer;
        variable cnt : integer;
        variable left_open, right_open : boolean;
    begin
        if has_piece(pieces, r, c) then
            return -10000;
        end if;
        
        self_c := ai_c;
        enemy_c := not ai_c;
        
        total := (7 - abs(r-7)) * (7 - abs(r-7)) + (7 - abs(c-7)) * (7 - abs(c-7));
        
        for d in 0 to 3 loop
            -- 己方评分
            cnt := count_dir(pieces, colors, r, c, DIR_R(d), DIR_C(d), self_c);
            left_open := has_open(pieces, colors, r, c, DIR_R(d), DIR_C(d), self_c, 1);
            right_open := has_open(pieces, colors, r, c, DIR_R(d), DIR_C(d), self_c, 0);
            
            if cnt = 4 then
                total := total + 10000;
            elsif cnt = 3 then
                if left_open and right_open then
                    total := total + 2000;
                elsif left_open or right_open then
                    total := total + 500;
                else
                    total := total + 100;
                end if;
            elsif cnt = 2 then
                if left_open and right_open then
                    total := total + 200;
                elsif left_open or right_open then
                    total := total + 50;
                else
                    total := total + 10;
                end if;
            elsif cnt = 1 then
                if left_open or right_open then
                    total := total + 10;
                end if;
            end if;
            
            -- 对方评分（防守）
            cnt := count_dir(pieces, colors, r, c, DIR_R(d), DIR_C(d), enemy_c);
            left_open := has_open(pieces, colors, r, c, DIR_R(d), DIR_C(d), enemy_c, 1);
            right_open := has_open(pieces, colors, r, c, DIR_R(d), DIR_C(d), enemy_c, 0);
            
            if cnt = 4 then
                total := total + 8000;
            elsif cnt = 3 then
                if left_open and right_open then
                    total := total + 1500;
                elsif left_open or right_open then
                    total := total + 400;
                else
                    total := total + 80;
                end if;
            elsif cnt = 2 then
                if left_open and right_open then
                    total := total + 150;
                elsif left_open or right_open then
                    total := total + 40;
                else
                    total := total + 8;
                end if;
            elsif cnt = 1 then
                if left_open or right_open then
                    total := total + 8;
                end if;
            end if;
        end loop;
        
        return total;
    end function;
    
begin
    process(clk)
        variable best_score : integer := -1;
        variable temp_score : integer;
        variable found : boolean := false;
        variable i, j : integer;
    begin
        if rising_edge(clk) then
            move_valid_reg <= '0';
            ai_thinking <= '0';
            
            case state is
                when IDLE =>
                    if game_over = '0' then
                        state <= THINKING;
                        best_score := -1;
                        best_row <= 7;
                        best_col <= 7;
                        think_cnt <= 0;
                        found := false;
                    end if;
                    
                when THINKING =>
                    ai_thinking <= '1';
                    if think_cnt < BSIZE*BSIZE then
                        i := think_cnt / BSIZE;
                        j := think_cnt mod BSIZE;
                        if not has_piece(board_pieces, i, j) then
                            temp_score := calc_score(board_pieces, board_colors, ai_color, i, j);
                            if temp_score > best_score then
                                best_score := temp_score;
                                best_row <= i;
                                best_col <= j;
                                found := true;
                            end if;
                        end if;
                        think_cnt <= think_cnt + 1;
                    else
                        if found then
                            state <= DONE;
                        else
                            state <= IDLE;
                        end if;
                    end if;
                    
                when DONE =>
                    move_valid_reg <= '1';
                    state <= IDLE;
                    
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
    
    ai_row <= best_row;
    ai_col <= best_col;
    ai_move_valid <= move_valid_reg;
    
end Behavioral;