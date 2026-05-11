library ieee;
use ieee.std_logic_1164.all;

entity modulo_41_counter is
    port(
        clk, enable, reset : in  std_logic; -- reset is now ACTIVE HIGH
        pulse_out          : out std_logic;
        count_out          : out std_logic_vector(5 downto 0)
    );
end modulo_41_counter;

architecture Struct of modulo_41_counter is

    -- Component Declaration
    component enARdFF_2
        port(
            i_resetBar : in  std_logic;
            i_d        : in  std_logic;
            i_enable   : in  std_logic;
            i_clock    : in  std_logic;
            o_q        : out std_logic;
            o_qBar     : out std_logic
        );
    end component;

    -- Internal Signals
    signal int_d   : std_logic_vector(5 downto 0);
    signal raw_d   : std_logic_vector(5 downto 0);
    signal int_q   : std_logic_vector(5 downto 0);
    
    signal carry_0, carry_1, carry_2, carry_3, carry_4 : std_logic;
    signal is_40   : std_logic;
    signal pulse_q : std_logic;

    -- Internal Active Low Reset signal for the Flip-Flops
    signal int_reset_bar : std_logic;

begin

    -- INVERT the Active High reset to create Active Low for the DFFs
    int_reset_bar <= NOT reset;

    -- -----------------------------------------------------
    -- Carry Logic (Half Adder Chains)
    -- -----------------------------------------------------
    carry_0 <= int_q(0);
    carry_1 <= int_q(1) AND carry_0;
    carry_2 <= int_q(2) AND carry_1;
    carry_3 <= int_q(3) AND carry_2;
    carry_4 <= int_q(4) AND carry_3;

    -- -----------------------------------------------------
    -- Next State Logic (XORs for Increment)
    -- -----------------------------------------------------
    raw_d(0) <= NOT int_q(0);
    raw_d(1) <= int_q(1) XOR carry_0;
    raw_d(2) <= int_q(2) XOR carry_1;
    raw_d(3) <= int_q(3) XOR carry_2;
    raw_d(4) <= int_q(4) XOR carry_3;
    raw_d(5) <= int_q(5) XOR carry_4;

    -- -----------------------------------------------------
    -- Comparator: Detect Count = 40 (Binary 101000)
    -- -----------------------------------------------------
    -- 40 = 32 + 8 => bits 5 and 3 are 1.
    -- is_40 = q(5) & !q(4) & q(3) & !q(2) & !q(1) & !q(0)
    is_40 <= int_q(5) AND (NOT int_q(4)) AND int_q(3) AND (NOT int_q(2)) AND (NOT int_q(1)) AND (NOT int_q(0));

    -- -----------------------------------------------------
    -- Reset to 0 if count is 40
    -- -----------------------------------------------------
    int_d(0) <= raw_d(0) AND (NOT is_40);
    int_d(1) <= raw_d(1) AND (NOT is_40);
    int_d(2) <= raw_d(2) AND (NOT is_40);
    int_d(3) <= raw_d(3) AND (NOT is_40);
    int_d(4) <= raw_d(4) AND (NOT is_40);
    int_d(5) <= raw_d(5) AND (NOT is_40);

    -- -----------------------------------------------------
    -- Flip-Flop Instantiation
    -- Changed mapping: i_resetBar => int_reset_bar
    -- -----------------------------------------------------
    instDFF0 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(0), i_enable => enable, i_clock => clk, o_q => int_q(0), o_qBar => OPEN );
    instDFF1 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(1), i_enable => enable, i_clock => clk, o_q => int_q(1), o_qBar => OPEN );
    instDFF2 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(2), i_enable => enable, i_clock => clk, o_q => int_q(2), o_qBar => OPEN );
    instDFF3 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(3), i_enable => enable, i_clock => clk, o_q => int_q(3), o_qBar => OPEN );
    instDFF4 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(4), i_enable => enable, i_clock => clk, o_q => int_q(4), o_qBar => OPEN );
    instDFF5 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => int_d(5), i_enable => enable, i_clock => clk, o_q => int_q(5), o_qBar => OPEN );

    -- -----------------------------------------------------
    -- Pulse Output FF
    -- -----------------------------------------------------
    instDFF_Pulse : enARdFF_2
    PORT MAP(
        i_resetBar => int_reset_bar, -- Connected inverted reset
        i_d        => is_40,         -- Latch the 'is_40' signal
        i_enable   => enable,
        i_clock    => clk,
        o_q        => pulse_q,
        o_qBar     => OPEN
    );

    pulse_out <= pulse_q;
    count_out <= int_q;

end Struct;