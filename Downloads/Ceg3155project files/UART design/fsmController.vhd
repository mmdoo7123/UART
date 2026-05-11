library ieee;
use ieee.std_logic_1164.all;

entity fsmController is
    port(
        SSCS, clk      : in  std_logic;
        i_reset        : in  std_logic;
        MSC, SSC       : in  std_logic;
        MSTL, SSTL     : out std_logic_vector(2 downto 0);
        state_information : out std_logic_vector(1 downto 0)
    );
end fsmController;

architecture rtl of fsmController is
    
    signal y0, y1, y0_prime, y1_prime : std_logic;
    signal bigY0, bigY1, enable       : std_logic;
    
    signal int_reset_bar : std_logic;

    component enARdFF_2 is
        port(
            i_resetBar : in  std_logic;
            i_d        : in  std_logic;
            i_enable   : in  std_logic;
            i_clock    : in  std_logic;
            o_q        : out std_logic;
            o_qBar     : out std_logic
        );
    end component;

begin

    int_reset_bar <= NOT i_reset;

    ffy0: enARdFF_2
    port map(
        i_resetBar => int_reset_bar, 
        i_d        => bigY0,
        i_enable   => enable,
        i_clock    => clk,
        o_q        => y0,
        o_qBar     => y0_prime
    );

    ffy1: enARdFF_2
    port map(
        i_resetBar => int_reset_bar, 
        i_d        => bigY1,
        i_enable   => enable,
        i_clock    => clk,
        o_q        => y1,
        o_qBar     => y1_prime
    );

   
    bigY0 <= y0_prime; 
    
    bigY1 <= (y1 AND y0_prime) OR (y1_prime AND y0);

   
    MSTL(2) <= y1;                       
    MSTL(1) <= y1_prime AND y0;          
    MSTL(0) <= y1_prime AND y0_prime;    

    
    SSTL(2) <= y1_prime;                 
    SSTL(1) <= y1 AND y0;                
    SSTL(0) <= y1 AND y0_prime;          

    
    enable <= (y1_prime AND y0_prime AND MSC AND SSCS) OR 
              (y1_prime AND y0       AND MSC)          OR 
              (y1       AND y0_prime AND SSC)          OR 
              (y1       AND y0       AND SSC);            

    
    state_information(1) <= y1;
    state_information(0) <= y0;

end rtl;