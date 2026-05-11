LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Transmitter_Control IS
    PORT (
        clk         : IN STD_LOGIC;
        reset       : IN STD_LOGIC; -- Reset is now ACTIVE HIGH
        
        TDRE        : IN STD_LOGIC;
        i_tsr_bit   : IN STD_LOGIC;
        
        o_load_TSR  : OUT STD_LOGIC;
        o_shift_TSR : OUT STD_LOGIC;
        o_TxD       : OUT STD_LOGIC
    );
END Transmitter_Control;

ARCHITECTURE Struct OF Transmitter_Control IS

    COMPONENT enARdFF_2
        PORT (
            i_resetBar : IN STD_LOGIC;
            i_d        : IN STD_LOGIC;
            i_enable   : IN STD_LOGIC;
            i_clock    : IN STD_LOGIC;
            o_q, o_qBar : OUT STD_LOGIC
        );
    END COMPONENT;

    -- State Encoding Constants
    CONSTANT ST_IDLE  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
    CONSTANT ST_LOAD  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
    CONSTANT ST_START : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";
    
    CONSTANT ST_S0    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011";
    CONSTANT ST_S1    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100";
    CONSTANT ST_S2    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101";
    CONSTANT ST_S3    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";
    CONSTANT ST_S4    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111";
    CONSTANT ST_S5    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000";
    CONSTANT ST_S6    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1001";
    CONSTANT ST_S7    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";
    
    CONSTANT ST_STOP  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1011";

    SIGNAL current_state : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL next_state    : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- Internal Active Low Reset
    SIGNAL int_reset_bar : STD_LOGIC;

BEGIN

    -- INVERT the Active High reset to create Active Low for the flip-flops
    int_reset_bar <= NOT reset;

    -- -------------------------------------------------------------------
    -- State Registers (4 Bits)
    -- Mapped i_resetBar to int_reset_bar
    -- -------------------------------------------------------------------
    inst_FF0 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => next_state(0), i_enable => '1', i_clock => clk, o_q => current_state(0), o_qBar => OPEN );
    inst_FF1 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => next_state(1), i_enable => '1', i_clock => clk, o_q => current_state(1), o_qBar => OPEN );
    inst_FF2 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => next_state(2), i_enable => '1', i_clock => clk, o_q => current_state(2), o_qBar => OPEN );
    inst_FF3 : enARdFF_2 PORT MAP( i_resetBar => int_reset_bar, i_d => next_state(3), i_enable => '1', i_clock => clk, o_q => current_state(3), o_qBar => OPEN );

    -- -------------------------------------------------------------------
    -- Next State Logic
    -- -------------------------------------------------------------------
    PROCESS (current_state, TDRE)
    BEGIN
        CASE current_state IS
            WHEN ST_IDLE =>
                -- Note: TDRE='0' usually implies the Transmit Data Register is Full (data is waiting)
                -- If your TDRE logic is inverted elsewhere, check this condition.
                -- Based on typical UART: '0' means busy/full.
                IF TDRE = '0' THEN next_state <= ST_LOAD; ELSE next_state <= ST_IDLE; END IF;

            WHEN ST_LOAD  => next_state <= ST_START;
            WHEN ST_START => next_state <= ST_S0;
            WHEN ST_S0    => next_state <= ST_S1;
            WHEN ST_S1    => next_state <= ST_S2;
            WHEN ST_S2    => next_state <= ST_S3;
            WHEN ST_S3    => next_state <= ST_S4;
            WHEN ST_S4    => next_state <= ST_S5;
            WHEN ST_S5    => next_state <= ST_S6;
            WHEN ST_S6    => next_state <= ST_S7;
            WHEN ST_S7    => next_state <= ST_STOP;
            
            WHEN ST_STOP =>
                IF TDRE = '0' THEN next_state <= ST_LOAD; ELSE next_state <= ST_IDLE; END IF;
                
            WHEN OTHERS => next_state <= ST_IDLE;
        END CASE;
    END PROCESS;

    -- -------------------------------------------------------------------
    -- Output Logic
    -- -------------------------------------------------------------------
    
    -- Load TSR Control
    o_load_TSR <= '1' WHEN (current_state = ST_LOAD) ELSE '0';

    -- Shift TSR Control (Active during data bits S0-S7)
    o_shift_TSR <= '1' WHEN (current_state = ST_S0 OR
                             current_state = ST_S1 OR
                             current_state = ST_S2 OR
                             current_state = ST_S3 OR
                             current_state = ST_S4 OR
                             current_state = ST_S5 OR
                             current_state = ST_S6 OR
                             current_state = ST_S7) ELSE '0';

    -- TxD Output Logic
    PROCESS (current_state, i_tsr_bit)
    BEGIN
        IF (current_state = ST_START) THEN
            o_TxD <= '0'; -- Start Bit (Low)
        ELSIF (current_state = ST_S0 OR current_state = ST_S1 OR current_state = ST_S2 OR
               current_state = ST_S3 OR current_state = ST_S4 OR current_state = ST_S5 OR
               current_state = ST_S6 OR current_state = ST_S7) THEN
            o_TxD <= i_tsr_bit; -- Data Bits
        ELSE
            o_TxD <= '1'; -- Idle or Stop Bit (High)
        END IF;
    END PROCESS;

END Struct;