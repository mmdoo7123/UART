LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY UART IS
    PORT (
        i_clk   : IN STD_LOGIC; -- System Clock
        i_reset : IN STD_LOGIC; -- Active High Global Reset

        -- External Serial Interface (The wires on the left/right of Fig 3)
        i_RxD : IN STD_LOGIC;  
        o_TxD : OUT STD_LOGIC; 

        -- CPU / Data Bus Interface (The "Data Bus" at the top of Fig 3)
        -- We must include these to allow the "Data Bus" to function.
        i_CS    : IN STD_LOGIC;                     -- Chip Select
        i_RW    : IN STD_LOGIC;                     -- 0 = Write, 1 = Read
        i_Addr  : IN STD_LOGIC_VECTOR(1 DOWNTO 0);  -- To select registers
        i_Data  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Data Bus In
        o_Data  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  -- Data Bus Out
    );
END UART;

ARCHITECTURE Structural OF UART IS

    -- =========================================================
    -- COMPONENT DECLARATIONS
    -- =========================================================
    
    COMPONENT Baud_Rate_Generator
        PORT (
            clk      : IN STD_LOGIC;
            reset    : IN STD_LOGIC;
            sel      : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- Connects to SCCR[2:0]
            b_clk    : OUT STD_LOGIC;
            b_clkx8  : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT UART_Receiver
        PORT (
            i_clock  : IN STD_LOGIC;
            i_reset  : IN STD_LOGIC;
            i_RxD    : IN STD_LOGIC;
            i_BClkx8 : IN STD_LOGIC;
            i_Read   : IN STD_LOGIC; -- Signal to clear RDRF
            o_Data   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- The RDR output
            o_RDRF   : OUT STD_LOGIC; -- Status Bit
            o_OE     : OUT STD_LOGIC; -- Status Bit
            o_FE     : OUT STD_LOGIC  -- Status Bit
        );
    END COMPONENT;

    -- UPDATED: Matches the entity in your screenshot exactly
    COMPONENT UART_Transmitter
        PORT (
            -- Note: i_clock removed as it is not in your entity image
            BClk       : IN STD_LOGIC;
            reset      : IN STD_LOGIC;
            i_Tx_Data  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_Load     : IN STD_LOGIC;
            o_TDRE     : OUT STD_LOGIC;
            TxD        : OUT STD_LOGIC
        );
    END COMPONENT;

    -- =========================================================
    -- INTERNAL SIGNALS (The Registers shown in Fig 3)
    -- =========================================================

    -- Clocks from Baud Generator
    SIGNAL int_bclk    : STD_LOGIC;
    SIGNAL int_bclkx8  : STD_LOGIC;

    -- Registers shown in the diagram
    SIGNAL reg_SCCR    : STD_LOGIC_VECTOR(7 DOWNTO 0); 
    SIGNAL reg_TDR     : STD_LOGIC_VECTOR(7 DOWNTO 0); 
    SIGNAL wire_RDR    : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Output from Receiver component
    
    -- Status Bits for SCSR
    SIGNAL stat_TDRE   : STD_LOGIC; 
    SIGNAL stat_RDRF   : STD_LOGIC; 
    SIGNAL stat_OE     : STD_LOGIC; 
    SIGNAL stat_FE     : STD_LOGIC; 
    
    -- Note: tx_busy removed as we are using direct o_TDRE now

    -- Internal Control Signals (Arrows in Fig 3)
    SIGNAL load_tdr    : STD_LOGIC; -- Arrow into TDR
    SIGNAL read_rdr    : STD_LOGIC; -- Feedback to Receiver Control

BEGIN

    -- =========================================================
    -- 1. INSTANTIATE COMPONENTS (The Dashed Boxes in Fig 3)
    -- =========================================================

    -- The "Baud Rate Generator" Box
    inst_BaudGen : Baud_Rate_Generator
    PORT MAP (
        clk     => i_clk,
        reset   => i_reset,
        sel     => reg_SCCR(2 DOWNTO 0), -- Arrow from SCCR to BaudGen
        b_clk   => int_bclk,             -- Arrow to Transmitter
        b_clkx8 => int_bclkx8            -- Arrow to Receiver
    );

    -- The "Receiver" Box (Contains RSR, RDR, Control)
    inst_Receiver : UART_Receiver
    PORT MAP (
        i_clock  => i_clk,
        i_reset  => i_reset,
        i_RxD    => i_RxD,
        i_BClkx8 => int_bclkx8,
        i_Read   => read_rdr,
        o_Data   => wire_RDR,    -- This is the RDR content
        o_RDRF   => stat_RDRF,   -- To SCSR
        o_OE     => stat_OE,     -- To SCSR
        o_FE     => stat_FE      -- To SCSR
    );

    -- The "Transmitter" Box (UPDATED PORT MAP)
    inst_Transmitter : UART_Transmitter
    PORT MAP (
        -- System clock (i_clk) removed to match your entity
        BClk       => int_bclk,
        reset      => i_reset,
        i_Tx_Data  => reg_TDR,   -- From TDR Register
        i_Load     => load_tdr,  -- The "Load" arrow
        o_TDRE     => stat_TDRE, -- Wired directly to Status signal
        TxD        => o_TxD
    );

    -- =========================================================
    -- 2. DATA BUS INTERFACE (Connections to "Data Bus")
    -- =========================================================
    
    -- This process handles the arrows connecting the Data Bus to 
    -- TDR and SCCR (Write operations)
    PROCESS (i_clk, i_reset)
    BEGIN
        IF i_reset = '1' THEN
            reg_SCCR <= (OTHERS => '0');
            reg_TDR  <= (OTHERS => '0');
            load_tdr <= '0';
        ELSIF rising_edge(i_clk) THEN
            
            -- Default: Load signal is a pulse
            load_tdr <= '0';

            -- If Chip Selected and Writing (RW=0)
            IF i_CS = '1' AND i_RW = '0' THEN
                CASE i_Addr IS
                    WHEN "00" => -- Address 00: TDR
                        reg_TDR  <= i_Data; -- Data Bus -> TDR
                        load_tdr <= '1';    -- Trigger "Load" signal
                    WHEN "10" => -- Address 10: SCCR
                        reg_SCCR <= i_Data; -- Data Bus -> SCCR
                    WHEN OTHERS =>
                        NULL;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- This process handles the arrows connecting RDR and SCSR 
    -- to the Data Bus (Read operations)
    PROCESS (i_CS, i_RW, i_Addr, wire_RDR, reg_SCCR, stat_TDRE, stat_RDRF, stat_OE, stat_FE)
    BEGIN
        o_Data   <= (OTHERS => '0'); 
        read_rdr <= '0';

        IF i_CS = '1' AND i_RW = '1' THEN
            CASE i_Addr IS
                WHEN "00" => -- Address 00: RDR
                    o_Data   <= wire_RDR; -- RDR -> Data Bus
                    read_rdr <= '1';      -- Tell Receiver we read it
                
                WHEN "01" => -- Address 01: SCSR (Status Register)
                    -- Construct SCSR from status bits as shown in Table 1
                    o_Data(7) <= stat_TDRE;
                    o_Data(6) <= stat_RDRF;
                    o_Data(5 DOWNTO 3) <= "000"; -- Unused
                    o_Data(2) <= stat_OE;
                    o_Data(1) <= stat_FE;
                    o_Data(0) <= '0';

                WHEN "10" => -- Address 10: SCCR (Control Register)
                    o_Data <= reg_SCCR;  -- SCCR -> Data Bus

                WHEN OTHERS =>
                    o_Data <= (OTHERS => '0');
            END CASE;
        END IF;
    END PROCESS;

END Structural;