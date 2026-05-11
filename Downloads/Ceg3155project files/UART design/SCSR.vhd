LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY SCSR IS
    PORT (
        i_reset      : IN STD_LOGIC; -- Active High Reset (included for consistency)
        i_clock      : IN STD_LOGIC;

        -- Status Inputs from other modules
        i_tdre       : IN STD_LOGIC; -- From TDR
        i_rdrf       : IN STD_LOGIC; -- From RDR
        i_oe         : IN STD_LOGIC; -- From Receiver Control
        i_fe         : IN STD_LOGIC; -- From Receiver Control

        -- Output to Data Bus
        o_data       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END SCSR;

ARCHITECTURE Struct OF SCSR IS

    -- Internal Active Low Reset (Standardizing pattern, even if unused in combinational logic)
    SIGNAL int_reset_bar : STD_LOGIC;

    SIGNAL int_data : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

    -- INVERT the Active High reset (Standard Practice for this project)
    int_reset_bar <= NOT i_reset;

    -- -------------------------------------------------------------------
    -- Status Register Bit Mapping
    -- -------------------------------------------------------------------
    -- The SCSR is a read-only register that presents live status signals.
    -- Storage for these bits is handled in their respective source modules
    -- (TDR, RDR, and Receiver Control).

    int_data(7) <= i_tdre; -- Bit 7: Transmit Data Register Empty
    int_data(6) <= i_rdrf; -- Bit 6: Receive Data Register Full
    
    int_data(5) <= '0';    -- Unused
    int_data(4) <= '0';    -- Unused
    int_data(3) <= '0';    -- Unused
    
    int_data(2) <= i_oe;   -- Bit 2: Overrun Error
    int_data(1) <= i_fe;   -- Bit 1: Framing Error
    
    int_data(0) <= '0';    -- Unused

    o_data <= int_data;

END Struct;