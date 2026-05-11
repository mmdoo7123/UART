LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY freq_div_256 IS
    PORT (
        clk, enable, reset : IN STD_LOGIC; -- Reset is now ACTIVE HIGH
        clock_bank         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END freq_div_256;

ARCHITECTURE Struct OF freq_div_256 IS

    SIGNAL int_d : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL int_q : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL carry_0, carry_1, carry_2, carry_3, carry_4, carry_5, carry_6 : STD_LOGIC;

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

    -- Carry Logic (Synchronous Counter Logic)
    carry_0 <= int_q(0);
    carry_1 <= int_q(1) AND carry_0;
    carry_2 <= int_q(2) AND carry_1;
    carry_3 <= int_q(3) AND carry_2;
    carry_4 <= int_q(4) AND carry_3;
    carry_5 <= int_q(5) AND carry_4;
    carry_6 <= int_q(6) AND carry_5;

    -- Next State Logic
    int_d(0) <= NOT int_q(0);

    int_d(1) <= int_q(1) XOR carry_0;
    int_d(2) <= int_q(2) XOR carry_1;
    int_d(3) <= int_q(3) XOR carry_2;
    int_d(4) <= int_q(4) XOR carry_3;
    int_d(5) <= int_q(5) XOR carry_4;
    int_d(6) <= int_q(6) XOR carry_5;
    int_d(7) <= int_q(7) XOR carry_6;

    -- Flip-Flop Instantiation
    -- Mapped i_resetBar to int_reset_bar
    instDFF0 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(0), i_enable => enable, i_clock => clk, o_q => int_q(0), o_qBar => OPEN );
    instDFF1 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(1), i_enable => enable, i_clock => clk, o_q => int_q(1), o_qBar => OPEN );
    instDFF2 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(2), i_enable => enable, i_clock => clk, o_q => int_q(2), o_qBar => OPEN );
    instDFF3 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(3), i_enable => enable, i_clock => clk, o_q => int_q(3), o_qBar => OPEN );
    instDFF4 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(4), i_enable => enable, i_clock => clk, o_q => int_q(4), o_qBar => OPEN );
    instDFF5 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(5), i_enable => enable, i_clock => clk, o_q => int_q(5), o_qBar => OPEN );
    instDFF6 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(6), i_enable => enable, i_clock => clk, o_q => int_q(6), o_qBar => OPEN );
    instDFF7 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(7), i_enable => enable, i_clock => clk, o_q => int_q(7), o_qBar => OPEN );

    clock_bank <= int_q;

END Struct;