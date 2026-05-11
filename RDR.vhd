LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY RDR IS
    PORT (
        i_reset      : IN STD_LOGIC; -- Active High Reset
        i_clock      : IN STD_LOGIC;

        i_data       : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- From RSR
        i_load       : IN STD_LOGIC; -- From Receiver Control (Byte Received)
        
        i_read       : IN STD_LOGIC; -- From Address Decoder (CPU Reading Data)

        o_data       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- To Data Bus
        RDRF         : OUT STD_LOGIC -- Status: Receive Data Register Full
    );
END RDR;

ARCHITECTURE Struct OF RDR IS

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
    SIGNAL rdrf_q       : STD_LOGIC;
    SIGNAL rdrf_d       : STD_LOGIC;
    SIGNAL status_enable: STD_LOGIC;
    SIGNAL int_reset_bar : STD_LOGIC;

BEGIN

    int_reset_bar <= NOT i_reset;

    -- -------------------------------------------------------------------
    -- 8-Bit Data Register
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
    -- RDRF Status Logic
    -- -------------------------------------------------------------------
    -- Logic:
    -- 1. If we load new data (i_load), RDRF becomes '1'.
    -- 2. If CPU reads the data (i_read), RDRF becomes '0'.
    -- 3. i_load takes precedence or they happen at distinct times. Usually i_load sets it.
    
    -- Next state logic: Set to 1 if loading, Set to 0 if Reading, else hold.
    -- rdrf_d <= '1' when i_load else '0' when i_read else rdrf_q;
    
    -- Structural equivalent:
    -- rdrf_d = i_load OR (rdrf_q AND NOT i_read)
    rdrf_d <= i_load OR (rdrf_q AND NOT i_read);
    
    -- Enable the status FF if we are loading OR reading
    status_enable <= i_load OR i_read;

    instDFF_Status : enARdFF_2
    PORT MAP(
        i_resetBar => int_reset_bar,
        i_d        => rdrf_d,
        i_enable   => status_enable,
        i_clock    => i_clock,
        o_q        => rdrf_q,
        o_qBar     => OPEN
    );

    RDRF <= rdrf_q;

END Struct;