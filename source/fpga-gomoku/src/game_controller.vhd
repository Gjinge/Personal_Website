library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity game_controller is
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
end game_controller;

architecture Behavioral of game_controller is
    constant CELL_SIZE  : integer := 28;
    constant LINE_WIDTH : integer := 2;
    constant BOARD_WIDTH : integer := BSIZE * (CELL_SIZE + LINE_WIDTH) - LINE_WIDTH;
    constant FRAME_WIDTH : integer := 640;
    constant FRAME_HEIGHT : integer := 480;
    constant BOARD_OFFSET_X : integer := (FRAME_WIDTH - BOARD_WIDTH) / 2;
    constant BOARD_OFFSET_Y : integer := (FRAME_HEIGHT - BOARD_WIDTH) / 2;
    
    constant PVP_BTN_X : integer := 230;
    constant PVP_BTN_Y : integer := 320;
    constant PVP_BTN_W : integer := 200;
    constant PVP_BTN_H : integer := 25;
    constant PVE_BTN_X : integer := 220;
    constant PVE_BTN_Y : integer := 360;
    constant PVE_BTN_W : integer := 200;
    constant PVE_BTN_H : integer := 35;
    
    type game_state_type is (MODE_SELECT, PLAYING);
    signal state : game_state_type := MODE_SELECT;
    
    signal pieces : std_logic_vector(BSIZE*BSIZE-1 downto 0) := (others => '0');
    signal colors : std_logic_vector(BSIZE*BSIZE-1 downto 0) := (others => '0');
    
    type move_stack is array (0 to 99) of integer;
    signal move_x_stack : move_stack := (others => -1);
    signal move_y_stack : move_stack := (others => -1);
    signal move_cnt : integer range 0 to 100 := 0;
    
    signal player_turn : std_logic := '1';
    signal game_over : std_logic := '0';
    signal last_x, last_y : integer := -1;
    signal winner : std_logic := '0';
    signal mode_reg : std_logic_vector(1 downto 0) := "00";
    signal mode_change_flag : std_logic := '0';
    
    signal win_start_x, win_start_y : integer := -1;
    signal win_end_x, win_end_y : integer := -1;
    signal win_valid_reg : std_logic := '0';
    
    signal ai_request : std_logic := '0';
    signal ai_ready : std_logic := '0';
    signal ai_row, ai_col : integer := 7;
    
    component ai_controller
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
    end component;
    
    function get_grid_x(mouse: std_logic_vector(11 downto 0)) return integer is
        variable pos : integer;
    begin
        pos := (conv_integer(mouse) - BOARD_OFFSET_X) / (CELL_SIZE + LINE_WIDTH);
        if pos < 0 then return -1; elsif pos >= BSIZE then return -1; else return pos; end if;
    end function;
    
    function get_grid_y(mouse: std_logic_vector(11 downto 0)) return integer is
        variable pos : integer;
    begin
        pos := (conv_integer(mouse) - BOARD_OFFSET_Y) / (CELL_SIZE + LINE_WIDTH);
        if pos < 0 then return -1; elsif pos >= BSIZE then return -1; else return pos; end if;
    end function;
    
    function in_button(mx, my : integer; btn_x, btn_y, btn_w, btn_h : integer) return boolean is
    begin
        return mx >= btn_x and mx < btn_x + btn_w and my >= btn_y and my < btn_y + btn_h;
    end function;
    
    function check_win(pieces_sig : std_logic_vector; colors_sig : std_logic_vector;
                       x, y : integer; color : std_logic) return boolean is
        variable cnt : integer;
        variable idx : integer;
    begin
        cnt := 1;
        for i in 1 to 4 loop
            if x+i < BSIZE then
                idx := y * BSIZE + (x+i);
                if pieces_sig(idx) = '1' and colors_sig(idx) = color then cnt := cnt + 1; else exit; end if;
            else exit; end if;
        end loop;
        for i in 1 to 4 loop
            if x-i >= 0 then
                idx := y * BSIZE + (x-i);
                if pieces_sig(idx) = '1' and colors_sig(idx) = color then cnt := cnt + 1; else exit; end if;
            else exit; end if;
        end loop;
        if cnt >= 5 then return true; end if;
        
        cnt := 1;
        for i in 1 to 4 loop
            if y+i < BSIZE then
                idx := (y+i) * BSIZE + x;
                if pieces_sig(idx) = '1' and colors_sig(idx) = color then cnt := cnt + 1; else exit; end if;
            else exit; end if;
        end loop;
        for i in 1 to 4 loop
            if y-i >= 0 then
                idx := (y-i) * BSIZE + x;
                if pieces_sig(idx) = '1' and colors_sig(idx) = color then cnt := cnt + 1; else exit; end if;
            else exit; end if;
        end loop;
        if cnt >= 5 then return true; end if;
        
        cnt := 1;
        for i in 1 to 4 loop
            if x+i < BSIZE and y+i < BSIZE then
                idx := (y+i) * BSIZE + (x+i);
                if pieces_sig(idx) = '1' and colors_sig(idx) = color then cnt := cnt + 1; else exit; end if;
            else exit; end if;
        end loop;
        for i in 1 to 4 loop
            if x-i >= 0 and y-i >= 0 then
                idx := (y-i) * BSIZE + (x-i);
                if pieces_sig(idx) = '1' and colors_sig(idx) = color then cnt := cnt + 1; else exit; end if;
            else exit; end if;
        end loop;
        if cnt >= 5 then return true; end if;
        
        cnt := 1;
        for i in 1 to 4 loop
            if x+i < BSIZE and y-i >= 0 then
                idx := (y-i) * BSIZE + (x+i);
                if pieces_sig(idx) = '1' and colors_sig(idx) = color then cnt := cnt + 1; else exit; end if;
            else exit; end if;
        end loop;
        for i in 1 to 4 loop
            if x-i >= 0 and y+i < BSIZE then
                idx := (y+i) * BSIZE + (x-i);
                if pieces_sig(idx) = '1' and colors_sig(idx) = color then cnt := cnt + 1; else exit; end if;
            else exit; end if;
        end loop;
        if cnt >= 5 then return true; end if;
        return false;
    end function;
    
    procedure get_win_line(x, y : integer; color : std_logic; sx, sy, ex, ey : out integer) is
        variable cnt : integer;
        variable idx : integer;
        variable s_x, s_y, e_x, e_y : integer;
    begin
        sx := x; sy := y; ex := x; ey := y;
        for dir in 0 to 3 loop
            cnt := 1; s_x := x; s_y := y; e_x := x; e_y := y;
            for i in 1 to 4 loop
                if dir = 0 then
                    if x+i < BSIZE then
                        idx := y * BSIZE + (x+i);
                        if pieces(idx) = '1' and colors(idx) = color then cnt := cnt + 1; e_x := x+i; else exit; end if;
                    else exit; end if;
                elsif dir = 1 then
                    if y+i < BSIZE then
                        idx := (y+i) * BSIZE + x;
                        if pieces(idx) = '1' and colors(idx) = color then cnt := cnt + 1; e_y := y+i; else exit; end if;
                    else exit; end if;
                elsif dir = 2 then
                    if x+i < BSIZE and y+i < BSIZE then
                        idx := (y+i) * BSIZE + (x+i);
                        if pieces(idx) = '1' and colors(idx) = color then cnt := cnt + 1; e_x := x+i; e_y := y+i; else exit; end if;
                    else exit; end if;
                else
                    if x+i < BSIZE and y-i >= 0 then
                        idx := (y-i) * BSIZE + (x+i);
                        if pieces(idx) = '1' and colors(idx) = color then cnt := cnt + 1; e_x := x+i; e_y := y-i; else exit; end if;
                    else exit; end if;
                end if;
            end loop;
            for i in 1 to 4 loop
                if dir = 0 then
                    if x-i >= 0 then
                        idx := y * BSIZE + (x-i);
                        if pieces(idx) = '1' and colors(idx) = color then cnt := cnt + 1; s_x := x-i; else exit; end if;
                    else exit; end if;
                elsif dir = 1 then
                    if y-i >= 0 then
                        idx := (y-i) * BSIZE + x;
                        if pieces(idx) = '1' and colors(idx) = color then cnt := cnt + 1; s_y := y-i; else exit; end if;
                    else exit; end if;
                elsif dir = 2 then
                    if x-i >= 0 and y-i >= 0 then
                        idx := (y-i) * BSIZE + (x-i);
                        if pieces(idx) = '1' and colors(idx) = color then cnt := cnt + 1; s_x := x-i; s_y := y-i; else exit; end if;
                    else exit; end if;
                else
                    if x-i >= 0 and y+i < BSIZE then
                        idx := (y+i) * BSIZE + (x-i);
                        if pieces(idx) = '1' and colors(idx) = color then cnt := cnt + 1; s_x := x-i; s_y := y+i; else exit; end if;
                    else exit; end if;
                end if;
            end loop;
            if cnt >= 5 then
                sx := s_x; sy := s_y; ex := e_x; ey := e_y;
                return;
            end if;
        end loop;
    end procedure;
    
begin
    ai_inst: ai_controller
    generic map(BSIZE => BSIZE)
    port map(
        clk          => clk,
        board_pieces => pieces,
        board_colors => colors,
        ai_color     => '0',  -- AI执白
        game_over    => game_over,
        ai_row       => ai_row,
        ai_col       => ai_col,
        ai_move_valid=> ai_ready,
        ai_thinking  => open
    );
    
    process(clk)
        variable gx, gy, mx, my : integer;
        variable idx : integer;
        variable win : boolean;
        variable sx, sy, ex, ey : integer;
    begin
        if rising_edge(clk) then
            mode_change_flag <= '0';
            
            if state = MODE_SELECT then
                if left_click = '1' then
                    mx := conv_integer(mouse_x);
                    my := conv_integer(mouse_y);
                    if in_button(mx, my, PVP_BTN_X, PVP_BTN_Y, PVP_BTN_W, PVP_BTN_H) then
                        mode_reg <= "00";
                        state <= PLAYING;
                        mode_change_flag <= '1';
                        pieces <= (others => '0');
                        colors <= (others => '0');
                        player_turn <= '1';
                        game_over <= '0';
                        move_cnt <= 0;
                        ai_request <= '0';
                        win_valid_reg <= '0';
                    elsif in_button(mx, my, PVE_BTN_X, PVE_BTN_Y, PVE_BTN_W, PVE_BTN_H) then
                        mode_reg <= "01";
                        state <= PLAYING;
                        mode_change_flag <= '1';
                        pieces <= (others => '0');
                        colors <= (others => '0');
                        player_turn <= '1';
                        game_over <= '0';
                        move_cnt <= 0;
                        ai_request <= '0';
                        win_valid_reg <= '0';
                    end if;
                end if;
                
            elsif state = PLAYING then
                if reset_trigger = '1' then
                    state <= MODE_SELECT;
                    pieces <= (others => '0');
                    colors <= (others => '0');
                    player_turn <= '1';
                    game_over <= '0';
                    move_cnt <= 0;
                    ai_request <= '0';
                    win_valid_reg <= '0';
                    
                elsif undo_trigger = '1' and game_over = '0' and move_cnt > 0 then
                    gx := move_x_stack(move_cnt-1);
                    gy := move_y_stack(move_cnt-1);
                    idx := gy * BSIZE + gx;
                    pieces(idx) <= '0';
                    colors(idx) <= '0';
                    move_cnt <= move_cnt - 1;
                    player_turn <= not player_turn;
                    last_x <= -1; last_y <= -1;
                    ai_request <= '0';
                    win_valid_reg <= '0';
                    
                elsif game_over = '0' and mode_reg = "01" and player_turn = '0' and ai_request = '0' then
                    ai_request <= '1';
                    
                elsif game_over = '0' and mode_reg = "01" and player_turn = '0' and ai_request = '1' and ai_ready = '1' then
                    if ai_row >= 0 and ai_row < BSIZE and ai_col >= 0 and ai_col < BSIZE then
                        idx := ai_col * BSIZE + ai_row;
                        if pieces(idx) = '0' then
                            pieces(idx) <= '1';
                            colors(idx) <= '0';
                            if move_cnt < 100 then
                                move_x_stack(move_cnt) <= ai_row;
                                move_y_stack(move_cnt) <= ai_col;
                                move_cnt <= move_cnt + 1;
                            end if;
                            last_x <= ai_row; last_y <= ai_col;
                            if check_win(pieces, colors, ai_row, ai_col, '0') then
                                game_over <= '1';
                                winner <= '0';
                                get_win_line(ai_row, ai_col, '0', sx, sy, ex, ey);
                                win_start_x <= sx; win_start_y <= sy;
                                win_end_x <= ex; win_end_y <= ey;
                                win_valid_reg <= '1';
                            end if;
                            player_turn <= '1';
                            ai_request <= '0';
                        else
                            ai_request <= '0';
                        end if;
                    else
                        ai_request <= '0';
                    end if;
                    
                elsif game_over = '0' and left_click = '1' then
                    gx := get_grid_x(mouse_x);
                    gy := get_grid_y(mouse_y);
                    if gx >= 0 and gy >= 0 then
                        idx := gy * BSIZE + gx;
                        if pieces(idx) = '0' then
                            pieces(idx) <= '1';
                            colors(idx) <= player_turn;
                            if move_cnt < 100 then
                                move_x_stack(move_cnt) <= gx;
                                move_y_stack(move_cnt) <= gy;
                                move_cnt <= move_cnt + 1;
                            end if;
                            last_x <= gx; last_y <= gy;
                            if check_win(pieces, colors, gx, gy, player_turn) then
                                game_over <= '1';
                                winner <= player_turn;
                                get_win_line(gx, gy, player_turn, sx, sy, ex, ey);
                                win_start_x <= sx; win_start_y <= sy;
                                win_end_x <= ex; win_end_y <= ey;
                                win_valid_reg <= '1';
                            end if;
                            player_turn <= not player_turn;
                            ai_request <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    board_pieces <= pieces;
    board_colors <= colors;
    game_status <= "01" when game_over = '1' else "00";
    winner_color <= winner;
    current_player <= player_turn;
    last_move_x <= last_x;
    last_move_y <= last_y;
    game_mode <= mode_reg;
    win_line_start_x <= win_start_x;
    win_line_start_y <= win_start_y;
    win_line_end_x <= win_end_x;
    win_line_end_y <= win_end_y;
    win_line_valid <= win_valid_reg;
    mode_changed <= mode_change_flag;
    
end Behavioral;