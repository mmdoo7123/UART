LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY UART_Receiver IS
    PORT (
        -- Global Signals
        i_clock     : IN STD_LOGIC;
        i_reset     : IN STD_LOGIC; -- Active High Reset

        -- Inputs
        i_RxD       : IN STD_LOGIC; -- Serial Input
        i_BClkx8    : IN STD_LOGIC; -- 8x Baud Clock Enable
        i_Read      : IN STD_LOGIC; -- Read Signal from CPU (to clear RDRF)

        -- Outputs
        o_Data      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Parallel Data Out
        
        -- Status Flags
        o_RDRF      : OUT STD_LOGIC; -- Receive Data Register Full
        o_OE        : OUT STD_LOGIC; -- Overrun Error
        o_FE        : OUT STD_LOGIC  -- Framing Error
    );
END UART_Receiver;

ARCHITECTURE Structural OF UART_Receiver IS

    -- Component Declarations
    
    COMPONENT RSR
        PORT (
            i_reset        : IN STD_LOGIC;
            i_clock        : IN STD_LOGIC;
            i_RxD          : IN STD_LOGIC;
            i_shift        : IN STD_LOGIC;
            o_parallel_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT RDR
        PORT (
            i_reset      : IN STD_LOGIC;
            i_clock      : IN STD_LOGIC;
            i_data       : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_load       : IN STD_LOGIC;
            i_read       : IN STD_LOGIC;
            o_data       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            RDRF         : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT Receiver_Control
        PORT (
            clk         : IN STD_LOGIC;
            reset       : IN STD_LOGIC;
            i_bclk_x8   : IN STD_LOGIC;
            i_rxd       : IN STD_LOGIC;
            i_rdrf      : IN STD_LOGIC;
            o_shift_rsr : OUT STD_LOGIC;
            o_load_rdr  : OUT STD_LOGIC;
            o_oe        : OUT STD_LOGIC;
            o_fe        : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Internal Interconnect Signals
    SIGNAL shift_enable : STD_LOGIC;
    SIGNAL load_enable  : STD_LOGIC;
    SIGNAL rdrf_internal: STD_LOGIC;
    SIGNAL rsr_data     : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
    U_Control : Receiver_Control
    PORT MAP(
        clk         => i_clock,
        reset       => i_reset,
        i_bclk_x8   => i_BClkx8,
        i_rxd       => i_RxD,
        i_rdrf      => rdrf_internal, -- Feedback to check for Overrun
        o_shift_rsr => shift_enable,
        o_load_rdr  => load_enable,
        o_oe        => o_OE,
        o_fe        => o_FE
    );

    -- 2. Receive Shift Register (RSR)
    -- Converts Serial RxD -> Parallel Byte
    U_RSR : RSR
    PORT MAP(
        i_reset        => i_reset,
        i_clock        => i_clock,
        i_RxD          => i_RxD,
        i_shift        => shift_enable,
        o_parallel_out => rsr_data
    );

    -- 3. Receive Data Register (RDR)
    -- Buffers the data so the CPU can read it safely
    U_RDR : RDR
    PORT MAP(
        i_reset      => i_reset,
        i_clock      => i_clock,
        i_data       => rsr_data,
        i_load       => load_enable,
        i_read       => i_Read,
        o_data       => o_Data,
        RDRF         => rdrf_internal
    );

    -- Output the internal RDRF signal to the top-level
    o_RDRF <= rdrf_internal;

END Structural;