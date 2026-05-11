library ieee;
use ieee.std_logic_1164.all;


entity andGate is
    port(
        i_A, i_B : in  std_logic;
        o_Y      : out std_logic
    );
end andGate;

architecture dataflow of andGate is
begin
    o_Y <= i_A and i_B;
end dataflow;


library ieee;
use ieee.std_logic_1164.all;

entity orGate is
    port(
        i_A, i_B : in  std_logic;
        o_Y      : out std_logic
    );
end orGate;

architecture dataflow of orGate is
begin
    o_Y <= i_A or i_B;
end dataflow;


library ieee;
use ieee.std_logic_1164.all;

entity interruptGenerator is
    port(
        -- Control Inputs from SCCR
        RIE  : in std_logic; -- Receive Interrupt Enable
        TIE  : in std_logic; -- Transmit Interrupt Enable

        -- Status Inputs from SCSR
        RDRF : in std_logic; -- Receive Data Register Full (Text calls this RDRE)
        OE   : in std_logic; -- Overrun Error
        TDRE : in std_logic; -- Transmit Data Register Empty
        
        -- Output
        IRQ  : out std_logic -- Interrupt Request
    );
end interruptGenerator;

architecture structural of interruptGenerator is

    -- Declare the components we defined above
    component andGate
        port(i_A, i_B : in std_logic; o_Y : out std_logic);
    end component;

    component orGate
        port(i_A, i_B : in std_logic; o_Y : out std_logic);
    end component;

    -- Internal signals to connect the gates
    signal rx_status_condition : std_logic; -- Result of (RDRF or OE)
    signal rx_interrupt_fire   : std_logic; -- Result of (RIE and rx_status_condition)
    signal tx_interrupt_fire   : std_logic; -- Result of (TIE and TDRE)

begin
    
    -- LOGIC EQUATION: 
    -- IRQ = (RIE AND (RDRF OR OE)) OR (TIE AND TDRE)

    -- Step 1: Combine Receive Status Flags (RDRF OR OE)
    U1: orGate port map (
        i_A => RDRF,
        i_B => OE,
        o_Y => rx_status_condition
    );

    -- Step 2: Check if Receive Interrupt is Enabled (RIE AND ...)
    U2: andGate port map (
        i_A => RIE,
        i_B => rx_status_condition,
        o_Y => rx_interrupt_fire
    );

    -- Step 3: Check if Transmit Interrupt is Triggered (TIE AND TDRE)
    U3: andGate port map (
        i_A => TIE,
        i_B => TDRE,
        o_Y => tx_interrupt_fire
    );

    -- Step 4: Final OR to generate the main IRQ (Rx_IRQ OR Tx_IRQ)
    U4: orGate port map (
        i_A => rx_interrupt_fire,
        i_B => tx_interrupt_fire,
        o_Y => IRQ
    );

end structural;