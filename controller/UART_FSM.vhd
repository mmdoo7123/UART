library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_FSM is
    port(
        i_clk             : in  std_logic;
        i_reset           : in  std_logic;
        
        
        state_information : in  std_logic_vector(1 downto 0); 
        
        o_address         : out std_logic_vector(1 downto 0); 
        o_rw              : out std_logic;                    
        o_chipSelect      : out std_logic;                    
        i_data_from_uart  : in  std_logic_vector(7 downto 0); 
        o_data_to_uart    : out std_logic_vector(7 downto 0)  
    );
end UART_FSM;

architecture behavioral of UART_FSM is

    type t_state is (IDLE, POLL_STATUS, CHECK_TDRE, WRITE_CHAR, NEXT_CHAR);
    signal current_state : t_state;
    
    signal prev_state    : std_logic_vector(1 downto 0);
    signal char_index    : integer range 0 to 6;
    signal current_char  : std_logic_vector(7 downto 0);
    
    constant CHAR_CR : std_logic_vector(7 downto 0) := x"0D"; -- Carriage Return
    constant CHAR_SP : std_logic_vector(7 downto 0) := x"20"; -- Space
    constant CHAR_M  : std_logic_vector(7 downto 0) := x"4D"; -- 'M'
    constant CHAR_S  : std_logic_vector(7 downto 0) := x"53"; -- 'S'
    constant CHAR_g  : std_logic_vector(7 downto 0) := x"67"; -- 'g'
    constant CHAR_y  : std_logic_vector(7 downto 0) := x"79"; -- 'y'
    constant CHAR_r  : std_logic_vector(7 downto 0) := x"72"; -- 'r'

begin

    process(i_clk, i_reset)
    begin
        if i_reset = '1' then
            current_state <= IDLE;
            prev_state    <= "00";
            char_index    <= 0;
            o_chipSelect  <= '0';
            o_rw          <= '1';
            o_address     <= "00";
            o_data_to_uart <= (others => '0');
            
        elsif rising_edge(i_clk) then
            o_chipSelect <= '0';
            
            case current_state is
                
                when IDLE =>
                    if state_information /= prev_state then
                        prev_state <= state_information; 
                        char_index <= 0;                 
                        current_state <= POLL_STATUS;    
                    else
                        current_state <= IDLE;
                    end if;

                when POLL_STATUS =>
                    o_address <= "01";   
                    o_rw <= '1';         
                    o_chipSelect <= '1'; 
                    current_state <= CHECK_TDRE;

                when CHECK_TDRE =>
                    if i_data_from_uart(7) = '1' then 
                        current_state <= WRITE_CHAR;
                    else
                        current_state <= POLL_STATUS;
                    end if;
                    o_chipSelect <= '0'; 

                when WRITE_CHAR =>
                    o_address <= "00";   
                    o_rw <= '0';         
                    o_data_to_uart <= current_char;
                    o_chipSelect <= '1'; 
                    current_state <= NEXT_CHAR;

                when NEXT_CHAR =>
                    o_chipSelect <= '0'; 
                    if char_index < 5 then
                        char_index <= char_index + 1;
                        current_state <= POLL_STATUS; 
                    else
                        current_state <= IDLE;
                    end if;
                    
            end case;
        end if;
    end process;

   
    process(prev_state, char_index)
    begin
        current_char <= CHAR_SP; 

        case prev_state is
            when "00" => 
                case char_index is
                    when 0 => current_char <= CHAR_M;
                    when 1 => current_char <= CHAR_g;
                    when 2 => current_char <= CHAR_SP;
                    when 3 => current_char <= CHAR_S;
                    when 4 => current_char <= CHAR_r;
                    when 5 => current_char <= CHAR_CR;
                    when others => current_char <= CHAR_SP;
                end case;
                
            when "01" => 
                case char_index is
                    when 0 => current_char <= CHAR_M;
                    when 1 => current_char <= CHAR_y;
                    when 2 => current_char <= CHAR_SP;
                    when 3 => current_char <= CHAR_S;
                    when 4 => current_char <= CHAR_r;
                    when 5 => current_char <= CHAR_CR;
                    when others => current_char <= CHAR_SP;
                end case;

            when "10" => 
                case char_index is
                    when 0 => current_char <= CHAR_M;
                    when 1 => current_char <= CHAR_r;
                    when 2 => current_char <= CHAR_SP;
                    when 3 => current_char <= CHAR_S;
                    when 4 => current_char <= CHAR_g;
                    when 5 => current_char <= CHAR_CR;
                    when others => current_char <= CHAR_SP;
                end case;

            when "11" => 
                case char_index is
                    when 0 => current_char <= CHAR_M;
                    when 1 => current_char <= CHAR_r;
                    when 2 => current_char <= CHAR_SP;
                    when 3 => current_char <= CHAR_S;
                    when 4 => current_char <= CHAR_y;
                    when 5 => current_char <= CHAR_CR;
                    when others => current_char <= CHAR_SP;
                end case;
                
            when others =>
                current_char <= CHAR_SP;
        end case;
    end process;

end behavioral;