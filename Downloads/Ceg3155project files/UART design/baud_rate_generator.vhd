LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY baud_rate_generator IS
    PORT (
        clk     : IN STD_LOGIC;
        reset   : IN STD_LOGIC;
        enable  : IN STD_LOGIC;
        SEL     : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        b_clk   : OUT STD_LOGIC;
        b_clkx8 : OUT STD_LOGIC
    );
END baud_rate_generator;

ARCHITECTURE Struct OF baud_rate_generator IS

    COMPONENT modulo_41_counter
        PORT (
            clk, enable, reset : IN STD_LOGIC;
            pulse_out          : OUT STD_LOGIC;
            count_out          : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT freq_div_256
        PORT (
            clk, enable, reset : IN STD_LOGIC;
            clock_bank         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT Mux8to1
        PORT (
            i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_sel  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            o_y    : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT final_div_8
        PORT (
            clk_in   : IN STD_LOGIC;
            enable   : IN STD_LOGIC;
            reset    : IN STD_LOGIC;
            baud_clk : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL wire_41_to_bank   : STD_LOGIC;
    SIGNAL wires_bank_to_mux : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL wire_mux_to_final : STD_LOGIC;

BEGIN

    inst_Mod41 : modulo_41_counter
    PORT MAP (
        clk       => clk,
        reset     => reset,
        enable    => enable,
        pulse_out => wire_41_to_bank,
        count_out => OPEN
    );

    inst_Bank : freq_div_256
    PORT MAP (
        clk        => wire_41_to_bank,
        reset      => reset,
        enable     => enable,
        clock_bank => wires_bank_to_mux
    );

    inst_MUX : Mux8to1
    PORT MAP (
        i_data => wires_bank_to_mux,
        i_sel  => SEL,
        o_y    => wire_mux_to_final
    );

    inst_FinalDiv : final_div_8
    PORT MAP (
        clk_in   => wire_mux_to_final,
        reset    => reset,
        enable   => enable,
        baud_clk => b_clk
    );

    b_clkx8 <= wire_mux_to_final;

END Struct;