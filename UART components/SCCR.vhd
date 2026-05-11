LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY SCCR IS
    PORT (
        clk       : IN STD_LOGIC;
        reset     : IN STD_LOGIC; -- Reset is now ACTIVE HIGH
        sccr_load : IN STD_LOGIC;
        data_bus  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        
        sel_out   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        rie_out   : OUT STD_LOGIC;
        tie_out   : OUT STD_LOGIC
    );
END SCCR;

ARCHITECTURE Struct OF SCCR IS

    COMPONENT enARdFF_2
        PORT (
            i_resetBar : IN STD_LOGIC;
            i_d        : IN STD_LOGIC;
            i_enable   : IN STD_LOGIC;
            i_clock    : IN STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL int_q : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Internal Active Low Reset
    SIGNAL int_reset_bar : STD_LOGIC;

BEGIN

    -- INVERT the Active High reset to create Active Low for the flip-flops
    int_reset_bar <= NOT reset;

    -- -------------------------------------------------------------------
    -- Instantiate 8 Flip-Flops for the Register
    -- Mapped i_resetBar to int_reset_bar
    -- -------------------------------------------------------------------
    
    instDFF0 : enARdFF_2 
    PORT MAP( i_resetBar => int_reset_bar, i_d => data_bus(0), i_enable => sccr_load, i_clock => clk, o_q => int_q(0), o_qBar => OPEN );

    instDFF1 : enARdFF_2 
    PORT MAP( i_resetBar => int_reset_bar, i_d => data_bus(1), i_enable => sccr_load, i_clock => clk, o_q => int_q(1), o_qBar => OPEN );

    instDFF2 : enARdFF_2 
    PORT MAP( i_resetBar => int_reset_bar, i_d => data_bus(2), i_enable => sccr_load, i_clock => clk, o_q => int_q(2), o_qBar => OPEN );

    instDFF3 : enARdFF_2 
    PORT MAP( i_resetBar => int_reset_bar, i_d => data_bus(3), i_enable => sccr_load, i_clock => clk, o_q => int_q(3), o_qBar => OPEN );

    instDFF4 : enARdFF_2 
    PORT MAP( i_resetBar => int_reset_bar, i_d => data_bus(4), i_enable => sccr_load, i_clock => clk, o_q => int_q(4), o_qBar => OPEN );

    instDFF5 : enARdFF_2 
    PORT MAP( i_resetBar => int_reset_bar, i_d => data_bus(5), i_enable => sccr_load, i_clock => clk, o_q => int_q(5), o_qBar => OPEN );

    instDFF6 : enARdFF_2 
    PORT MAP( i_resetBar => int_reset_bar, i_d => data_bus(6), i_enable => sccr_load, i_clock => clk, o_q => int_q(6), o_qBar => OPEN );

    instDFF7 : enARdFF_2 
    PORT MAP( i_resetBar => int_reset_bar, i_d => data_bus(7), i_enable => sccr_load, i_clock => clk, o_q => int_q(7), o_qBar => OPEN );

    -- -------------------------------------------------------------------
    -- Output Assignments
    -- -------------------------------------------------------------------
    sel_out <= int_q(2 DOWNTO 0); -- Baud Rate Selectors
    rie_out <= int_q(6);          -- Receive Interrupt Enable
    tie_out <= int_q(7);          -- Transmit Interrupt Enable

END Struct;