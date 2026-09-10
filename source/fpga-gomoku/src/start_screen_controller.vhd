library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity start_screen_controller is
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
end start_screen_controller;

architecture Behavioral of start_screen_controller is

    type state_type is (START_SCREEN, GAME_SCREEN);
    signal state : state_type := START_SCREEN;

    signal rom_addr : std_logic_vector(ROM_ADDR_BITS-1 downto 0);
    signal rom_data : std_logic_vector(ROM_DATA_BITS-1 downto 0);

    signal left_click_d, right_click_d, middle_click_d : std_logic := '0';
    signal left_click_re, right_click_re, middle_click_re : std_logic;

begin

    -- 直接例化 ROM IP（请确保实体名与实际 IP 一致）
    rom_inst : entity work.blk_mem_gen_0_1
        port map (
            clka  => clk,
            addra => rom_addr,
            douta => rom_data
        );

    process(clk)
        variable y_adj : integer;
    begin
        if rising_edge(clk) then
            if video_active = '1' then
                y_adj := pixel_y - Y_OFFSET;
                if (pixel_x >= 0 and pixel_x < SCREEN_WIDTH) and
                   (y_adj >= 0 and y_adj < SCREEN_HEIGHT) then
                    rom_addr <= conv_std_logic_vector(y_adj * SCREEN_WIDTH + pixel_x, ROM_ADDR_BITS);
                else
                    rom_addr <= (others => '0');
                end if;
            else
                rom_addr <= (others => '0');
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            left_click_d   <= left_click;
            right_click_d  <= right_click;
            middle_click_d <= middle_click;
        end if;
    end process;
    left_click_re   <= '1' when left_click = '1' and left_click_d = '0' else '0';
    right_click_re  <= '1' when right_click = '1' and right_click_d = '0' else '0';
    middle_click_re <= '1' when middle_click = '1' and middle_click_d = '0' else '0';

    process(clk, reset)
    begin
        if reset = '1' then
            state <= START_SCREEN;
        elsif rising_edge(clk) then
            case state is
                when START_SCREEN =>
                    if (left_click_re = '1' or right_click_re = '1' or middle_click_re = '1') then
                        state <= GAME_SCREEN;
                    end if;
                when GAME_SCREEN =>
                    null;
            end case;
        end if;
    end process;

    start_active <= '1' when (state = START_SCREEN and video_active = '1' and
                              pixel_x < SCREEN_WIDTH and 
                              (pixel_y >= Y_OFFSET) and (pixel_y < Y_OFFSET + SCREEN_HEIGHT))
                        else '0';
    start_pixel  <= rom_data when state = START_SCREEN else (others => '0');
    game_start   <= '1' when state = GAME_SCREEN else '0';

end Behavioral;