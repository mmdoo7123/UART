LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY TSR IS
    PORT (
        i_reset      : IN STD_LOGIC; -- Reset is now ACTIVE HIGH (was i_resetBar)
        i_clock      : IN STD_LOGIC;

        -- Inputs
        i_data       : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Data coming from TDR
        i_load       : IN STD_LOGIC;                    -- Control: Load Parallel Data
        i_shift      : IN STD_LOGIC;                    -- Control: Shift Right

        -- Output
        o_bit_out    : OUT STD_LOGIC                    -- The LSB (Bit 0) sent to TxD
    );
END TSR;

ARCHITECTURE Struct OF TSR IS

    COMPONENT enARdFF_2
        PORT (
            i_resetBar : IN STD_LOGIC;
            i_d        : IN STD_LOGIC;
            i_enable   : IN STD_LOGIC;
            i_clock    : IN STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Internal Signals
    SIGNAL int_q      : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Current values of FFs
    SIGNAL int_d      : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Next values of FFs
    SIGNAL sys_enable : STD_LOGIC;

    -- Internal Active Low Reset
    SIGNAL int_reset_bar : STD_LOGIC;

BEGIN

    -- INVERT the Active High reset to create Active Low for the flip-flops
    int_reset_bar <= NOT i_reset;

    -- Global Enable: The FFs only change if we are Loading OR Shifting
    sys_enable <= i_load OR i_shift;

    -- ***********************************
    -- NEXT STATE LOGIC (MUXES)
    -- ***********************************
    -- For each bit, we decide:
    -- 1. If i_load = '1', take the value from i_data (TDR).
    -- 2. Else (i_shift must be '1'), take the neighbor's value.

    -- Bit 7 (MSB): Loads data(7) OR Shifts in a '1' (Idle/Stop level)
    int_d(7) <= (i_load AND i_data(7)) OR (NOT i_load AND '1');

    -- Bit 6: Loads data(6) OR Shifts in Bit 7
    int_d(6) <= (i_load AND i_data(6)) OR (NOT i_load AND int_q(7));

    -- Bit 5: Loads data(5) OR Shifts in Bit 6
    int_d(5) <= (i_load AND i_data(5)) OR (NOT i_load AND int_q(6));

    -- Bit 4: Loads data(4) OR Shifts in Bit 5
    int_d(4) <= (i_load AND i_data(4)) OR (NOT i_load AND int_q(5));

    -- Bit 3: Loads data(3) OR Shifts in Bit 4
    int_d(3) <= (i_load AND i_data(3)) OR (NOT i_load AND int_q(4));

    -- Bit 2: Loads data(2) OR Shifts in Bit 3
    int_d(2) <= (i_load AND i_data(2)) OR (NOT i_load AND int_q(3));

    -- Bit 1: Loads data(1) OR Shifts in Bit 2
    int_d(1) <= (i_load AND i_data(1)) OR (NOT i_load AND int_q(2));

    -- Bit 0 (LSB): Loads data(0) OR Shifts in Bit 1
    int_d(0) <= (i_load AND i_data(0)) OR (NOT i_load AND int_q(1));

    -- ***********************************
    -- FLIP-FLOP INSTANTIATIONS
    -- Mapped i_resetBar to int_reset_bar
    -- ***********************************
    instDFF7 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(7), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(7), o_qBar => OPEN );
    instDFF6 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(6), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(6), o_qBar => OPEN );
    instDFF5 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(5), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(5), o_qBar => OPEN );
    instDFF4 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(4), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(4), o_qBar => OPEN );
    instDFF3 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(3), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(3), o_qBar => OPEN );
    instDFF2 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(2), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(2), o_qBar => OPEN );
    instDFF1 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(1), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(1), o_qBar => OPEN );
    instDFF0 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(0), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(0), o_qBar => OPEN );

    -- Output the LSB. This will go to the MUX in the Transmitter Controller.
    o_bit_out <= int_q(0);

END Struct;