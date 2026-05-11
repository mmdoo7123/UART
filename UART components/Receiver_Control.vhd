LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Receiver_Control IS
    PORT (
        clk         : IN STD_LOGIC;
        reset       : IN STD_LOGIC; -- Active High Reset
        
        -- Inputs
        i_bclk_x8   : IN STD_LOGIC; -- 8x Baud Rate Pulse
        i_rxd       : IN STD_LOGIC; -- Serial Data Input
        i_rdrf      : IN STD_LOGIC; -- RDR Full Status (to detect Overrun)

        -- Outputs
        o_shift_rsr : OUT STD_LOGIC; -- Shift bit into RSR
        o_load_rdr  : OUT STD_LOGIC; -- Load byte into RDR
        o_oe        : OUT STD_LOGIC; -- Overrun Error Flag
        o_fe        : OUT STD_LOGIC  -- Framing Error Flag
    );
END Receiver_Control;

ARCHITECTURE Behavioral OF Receiver_Control IS

    -- State Definition
    TYPE t_state IS (IDLE, START_BIT, B0, B1, B2, B3, B4, B5, B6, B7, STOP_BIT);
    -- ADDED ":= IDLE" to initialize state
    SIGNAL current_state : t_state := IDLE;
    
    -- Counter for the 8x ticks (0 to 7)
    -- ADDED ":= 0" to initialize counter
    SIGNAL tick_count : INTEGER RANGE 0 TO 7 := 0;
    
    -- Internal Error Flags
    -- ADDED ":= '0'" to initialize flags
    SIGNAL oe_reg : STD_LOGIC := '0';
    SIGNAL fe_reg : STD_LOGIC := '0';
	 

BEGIN

    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            current_state <= IDLE;
            tick_count    <= 0;
            o_shift_rsr   <= '0';
            o_load_rdr    <= '0';
            oe_reg        <= '0';
            fe_reg        <= '0';
            
        ELSIF rising_edge(clk) THEN
            
            -- Default Pulse Outputs (This clears these signals automatically every clock)
            o_shift_rsr <= '0';
            o_load_rdr  <= '0';

            -- The FSM advances only when the 8x Baud Tick occurs
            IF i_bclk_x8 = '1' THEN
                
                CASE current_state IS
                    
                    -- 1. IDLE: Wait for Falling Edge of Start Bit
                    WHEN IDLE =>
                        tick_count <= 0;
                        IF i_rxd = '0' THEN 
                            current_state <= START_BIT;
                        END IF;

                    -- 2. START BIT: Verify it's still low at the middle (Tick 3 or 4)
                    WHEN START_BIT =>
                        IF tick_count = 3 THEN
                            IF i_rxd = '0' THEN
                                tick_count <= tick_count + 1; -- Valid Start
                            ELSE
                                current_state <= IDLE; -- Noise / False Start
                            END IF;
                        ELSIF tick_count = 7 THEN
                            current_state <= B0;
                            tick_count <= 0;
                        ELSE
                            tick_count <= tick_count + 1;
                        END IF;

                    -- 3. DATA BITS (0-7): Sample at middle
                    WHEN B0 | B1 | B2 | B3 | B4 | B5 | B6 | B7 =>
                        IF tick_count = 3 THEN
                            o_shift_rsr <= '1'; -- Sample & Shift the bit NOW
                        END IF;
                        
                        IF tick_count = 7 THEN
                            tick_count <= 0;
                            -- Transition to next state
                            CASE current_state IS
                                WHEN B0 => current_state <= B1;
                                WHEN B1 => current_state <= B2;
                                WHEN B2 => current_state <= B3;
                                WHEN B3 => current_state <= B4;
                                WHEN B4 => current_state <= B5;
                                WHEN B5 => current_state <= B6;
                                WHEN B6 => current_state <= B7;
                                WHEN B7 => current_state <= STOP_BIT;
                                WHEN OTHERS => NULL;
                            END CASE;
                        ELSE
                            tick_count <= tick_count + 1;
                        END IF;

                    -- 4. STOP BIT: Check for Framing Error & Load RDR
                    WHEN STOP_BIT =>
                        IF tick_count = 3 THEN
                            -- Check Framing Error (Stop bit must be '1')
                            IF i_rxd = '0' THEN
                                fe_reg <= '1';
                            ELSE
                                fe_reg <= '0';
                            END IF;
                            
                            -- Check Overrun Error (Is RDR still full?)
                            IF i_rdrf = '1' THEN
                                oe_reg <= '1';
                            ELSE
                                oe_reg <= '0';
                                o_load_rdr <= '1'; -- Safe to load data
                            END IF;
                        END IF;

                        IF tick_count = 7 THEN
                            current_state <= IDLE;
                            tick_count <= 0;
                        ELSE
                            tick_count <= tick_count + 1;
                        END IF;

                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- Output Error Flags
    o_oe <= oe_reg;
    o_fe <= fe_reg;

END Behavioral;