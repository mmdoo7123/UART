LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY TDR IS
    PORT (
        i_reset      : IN STD_LOGIC; -- Reset is now ACTIVE HIGH (was i_resetBar)
        i_clock      : IN STD_LOGIC;

        i_data       : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_load       : IN STD_LOGIC;

        i_load_TSR   : IN STD_LOGIC;

        o_data       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        TDRE         : OUT STD_LOGIC
    );
END TDR;

ARCHITECTURE Struct OF TDR IS

    COMPONENT enARdFF_2
        PORT (
            i_resetBar : IN STD_LOGIC;
            i_d        : IN STD_LOGIC;
            i_enable   : IN STD_LOGIC;
            i_clock    : IN STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL int_data     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    SIGNAL data_valid_q : STD_LOGIC;
    SIGNAL data_valid_d : STD_LOGIC;
    SIGNAL status_enable: STD_LOGIC;

    -- Internal Active Low Reset
    SIGNAL int_reset_bar : STD_LOGIC;

BEGIN

    -- INVERT the Active High reset to create Active Low for the flip-flops
    int_reset_bar <= NOT i_reset;

    -- -------------------------------------------------------------------
    -- Instantiate 8 Flip-Flops for the Data Register
    -- Mapped i_resetBar to int_reset_bar
    -- -------------------------------------------------------------------
    instDFF0 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => i_data(0), i_enable => i_load, i_clock => i_clock, o_q => int_data(0), o_qBar => OPEN );
    instDFF1 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => i_data(1), i_enable => i_load, i_clock => i_clock, o_q => int_data(1), o_qBar => OPEN );
    instDFF2 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => i_data(2), i_enable => i_load, i_clock => i_clock, o_q => int_data(2), o_qBar => OPEN );
    instDFF3 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => i_data(3), i_enable => i_load, i_clock => i_clock, o_q => int_data(3), o_qBar => OPEN );
    instDFF4 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => i_data(4), i_enable => i_load, i_clock => i_clock, o_q => int_data(4), o_qBar => OPEN );
    instDFF5 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => i_data(5), i_enable => i_load, i_clock => i_clock, o_q => int_data(5), o_qBar => OPEN );
    instDFF6 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => i_data(6), i_enable => i_load, i_clock => i_clock, o_q => int_data(6), o_qBar => OPEN );
    instDFF7 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => i_data(7), i_enable => i_load, i_clock => i_clock, o_q => int_data(7), o_qBar => OPEN );

    o_data <= int_data;

    -- -------------------------------------------------------------------
    -- TDRE Status Logic
    -- -------------------------------------------------------------------
    -- Logic from your screenshot:
    -- data_valid_d <= i_load OR (data_valid_q AND NOT i_load_TSR);
    -- status_enable <= i_load OR i_load_TSR;
    
    data_valid_d <= i_load OR (data_valid_q AND NOT i_load_TSR);
    status_enable <= i_load OR i_load_TSR;

    instDFF_Status : enARdFF_2
    PORT MAP(
        i_resetBar => int_reset_bar, -- Mapped to internal inverted reset
        i_d        => data_valid_d,
        i_enable   => status_enable,
        i_clock    => i_clock,
        o_q        => data_valid_q,
        o_qBar     => OPEN
    );

    TDRE <= NOT data_valid_q;

END Struct;