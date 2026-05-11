LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY RSR IS
    PORT (
        i_reset      : IN STD_LOGIC; -- Active High Reset
        i_clock      : IN STD_LOGIC;

        -- Inputs
        i_RxD        : IN STD_LOGIC; -- Serial Data In
        i_shift      : IN STD_LOGIC; -- Control: Shift Right

        -- Output
        o_parallel_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) -- Data sent to RDR
    );
END RSR;

ARCHITECTURE Struct OF RSR IS

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
    SIGNAL int_q      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL int_d      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sys_enable : STD_LOGIC;
    SIGNAL int_reset_bar : STD_LOGIC;

BEGIN

    -- Invert Active High Reset
    int_reset_bar <= NOT i_reset;

    -- Enable Flip-Flops only when shifting
    sys_enable <= i_shift;

    -- ***********************************
    -- NEXT STATE LOGIC (Shift Right)
    -- ***********************************
    -- UART sends LSB first. To assemble the byte correctly:
    -- We shift the new bit into the MSB (7), and move everything down.
    -- After 8 shifts, the first bit received (LSB) will be at int_q(0).
    
    int_d(7) <= i_RxD;    -- New bit enters MSB
    int_d(6) <= int_q(7);
    int_d(5) <= int_q(6);
    int_d(4) <= int_q(5);
    int_d(3) <= int_q(4);
    int_d(2) <= int_q(3);
    int_d(1) <= int_q(2);
    int_d(0) <= int_q(1);

    -- ***********************************
    -- FLIP-FLOP INSTANTIATIONS
    -- ***********************************
    instDFF7 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(7), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(7), o_qBar => OPEN );
    instDFF6 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(6), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(6), o_qBar => OPEN );
    instDFF5 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(5), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(5), o_qBar => OPEN );
    instDFF4 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(4), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(4), o_qBar => OPEN );
    instDFF3 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(3), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(3), o_qBar => OPEN );
    instDFF2 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(2), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(2), o_qBar => OPEN );
    instDFF1 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(1), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(1), o_qBar => OPEN );
    instDFF0 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(0), i_enable => sys_enable, i_clock => i_clock, o_q => int_q(0), o_qBar => OPEN );

    o_parallel_out <= int_q;

END Struct;