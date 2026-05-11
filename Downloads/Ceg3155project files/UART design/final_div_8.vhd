LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY final_div_8 IS
    PORT (
        clk_in   : IN STD_LOGIC;
        enable   : IN STD_LOGIC;
        reset    : IN STD_LOGIC; -- Reset is now ACTIVE HIGH
        baud_clk : OUT STD_LOGIC
    );
END final_div_8;

ARCHITECTURE Struct OF final_div_8 IS

    SIGNAL int_d : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL int_q : STD_LOGIC_VECTOR(2 DOWNTO 0);

    SIGNAL carry_0, carry_1 : STD_LOGIC;

    -- Internal Active Low Reset
    SIGNAL int_reset_bar : STD_LOGIC;

    COMPONENT enARdFF_2
        PORT (
            i_resetBar : IN STD_LOGIC;
            i_d        : IN STD_LOGIC;
            i_enable   : IN STD_LOGIC;
            i_clock    : IN STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    -- INVERT the Active High reset to create Active Low for the components
    int_reset_bar <= NOT reset;

    -- -------------------------------------------------------------------
    -- 3-Bit Counter Logic (Counts 0 to 7)
    -- -------------------------------------------------------------------
    
    -- Carry Logic
    carry_0 <= int_q(0);
    carry_1 <= int_q(1) AND carry_0;

    -- Next State Logic
    int_d(0) <= NOT int_q(0);
    int_d(1) <= int_q(1) XOR carry_0;
    int_d(2) <= int_q(2) XOR carry_1;

    -- -------------------------------------------------------------------
    -- Flip-Flop Instantiation
    -- Mapped i_resetBar to int_reset_bar
    -- -------------------------------------------------------------------
    instDFF0 : enARdFF_2 
    PORT MAP( 
        i_resetBar => int_reset_bar, 
        i_d        => int_d(0), 
        i_enable   => enable, 
        i_clock    => clk_in, 
        o_q        => int_q(0), 
        o_qBar     => OPEN 
    );

    instDFF1 : enARdFF_2 
    PORT MAP( 
        i_resetBar => int_reset_bar, 
        i_d        => int_d(1), 
        i_enable   => enable, 
        i_clock    => clk_in, 
        o_q        => int_q(1), 
        o_qBar     => OPEN 
    );

    instDFF2 : enARdFF_2 
    PORT MAP( 
        i_resetBar => int_reset_bar, 
        i_d        => int_d(2), 
        i_enable   => enable, 
        i_clock    => clk_in, 
        o_q        => int_q(2), 
        o_qBar     => OPEN 
    );

    -- -------------------------------------------------------------------
    -- Output Generation
    -- MSB (Bit 2) acts as the Divide-by-8 Clock
    -- -------------------------------------------------------------------
    baud_clk <= int_q(2);

END Struct;