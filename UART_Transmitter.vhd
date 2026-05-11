LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY UART_Transmitter IS
    PORT (
        BClk       : IN STD_LOGIC;
        reset      : IN STD_LOGIC;
        i_Tx_Data  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_Load     : IN STD_LOGIC;

        o_TDRE     : OUT STD_LOGIC;
        TxD        : OUT STD_LOGIC
    );
END UART_Transmitter;

ARCHITECTURE Struct OF UART_Transmitter IS

    COMPONENT TDR
        PORT (
            i_reset : IN STD_LOGIC;
            i_clock    : IN STD_LOGIC;
            i_data     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_load     : IN STD_LOGIC;
            i_load_TSR : IN STD_LOGIC;
            o_data     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            TDRE       : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT TSR
        PORT (
            i_reset : IN STD_LOGIC;
            i_clock    : IN STD_LOGIC;
            i_data     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_load     : IN STD_LOGIC;
            i_shift    : IN STD_LOGIC;
            o_bit_out  : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT Transmitter_Control
        PORT (
            clk         : IN STD_LOGIC;
            reset       : IN STD_LOGIC;
            TDRE        : IN STD_LOGIC;
            i_tsr_bit   : IN STD_LOGIC;
            o_load_TSR  : OUT STD_LOGIC;
            o_shift_TSR : OUT STD_LOGIC;
            o_TxD       : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL wire_TDR_to_TSR : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL wire_TDRE       : STD_LOGIC;
    SIGNAL ctrl_load_TSR   : STD_LOGIC;
    SIGNAL ctrl_shift_TSR  : STD_LOGIC;
    SIGNAL wire_tsr_bit    : STD_LOGIC;

BEGIN

    inst_TDR : TDR
    PORT MAP (
        i_reset => reset,
        i_clock    => BClk,
        i_data     => i_Tx_Data,
        i_load     => i_Load,
        i_load_TSR => ctrl_load_TSR,
        o_data     => wire_TDR_to_TSR,
        TDRE       => wire_TDRE
    );

    o_TDRE <= wire_TDRE;

    inst_TSR : TSR
    PORT MAP (
        i_reset => reset,
        i_clock    => BClk,
        i_data     => wire_TDR_to_TSR,
        i_load     => ctrl_load_TSR,
        i_shift    => ctrl_shift_TSR,
        o_bit_out  => wire_tsr_bit
    );

    inst_Control : Transmitter_Control
    PORT MAP (
        clk         => BClk,
        reset       => reset,
        TDRE        => wire_TDRE,
        i_tsr_bit   => wire_tsr_bit,
        o_load_TSR  => ctrl_load_TSR,
        o_shift_TSR => ctrl_shift_TSR,
        o_TxD       => TxD
    );

END Struct;