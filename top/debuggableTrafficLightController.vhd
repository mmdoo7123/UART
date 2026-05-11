library ieee;
use ieee.std_logic_1164.all;

entity debuggableTrafficLightController is
    port(
        -- Global Inputs
        GClock      : in std_logic;
        GReset      : in std_logic; -- Assumed Active High based on your FSM
        
        -- External Inputs (Sensors/Switches)
        SSCS        : in std_logic; -- Side Street Car Sensor
        SW1         : in std_logic_vector(3 downto 0); -- Main Street Time Setting
        SW2         : in std_logic_vector(3 downto 0); -- Side Street Time Setting
        
        -- UART Serial Inputs
        RxD         : in std_logic;
        
        -- Keyboard Inputs (From Figure 7)
        KeyboardClock : in std_logic;
        KeyboardData  : in std_logic;
        
        -- Outputs
        TxD         : out std_logic;
        MSTL        : out std_logic_vector(2 downto 0); -- Main Street Lights
        SSTL        : out std_logic_vector(2 downto 0); -- Side Street Lights
        BCD1        : out std_logic_vector(3 downto 0); -- Left Digit
        BCD2        : out std_logic_vector(3 downto 0)  -- Right Digit
    );
end debuggableTrafficLightController;

architecture structural of debuggableTrafficLightController is

    -- 1. Internal Signals
    signal clk_slow         : std_logic; -- Output from Clock Divider
    signal reset_bar        : std_logic; -- Inverted reset if needed
    
    -- Traffic Light Signals
    signal state_info_conn  : std_logic_vector(1 downto 0);
    signal msc_status       : std_logic;
    signal ssc_status       : std_logic;
    
    -- UART Bus Signals
    signal uart_address     : std_logic_vector(1 downto 0);
    signal uart_rw          : std_logic;
    signal uart_cs          : std_logic;
    signal uart_data_in     : std_logic_vector(7 downto 0); -- From UART to FSM
    signal uart_data_out    : std_logic_vector(7 downto 0); -- From FSM to UART
    
    -- Counter Values (for BCD)
    signal current_count    : std_logic_vector(3 downto 0); -- Example signal

    -- 2. Component Declarations
    
    -- A. Your Traffic Light Controller
    component fsmController
        port(
            SSCS, clk, reset_BAR, MSC, SSC : in  std_logic;
            MSTL, SSTL                     : out std_logic_vector(2 downto 0);
            state_information              : out std_logic_vector(1 downto 0)
        );
    end component;

    -- B. Your UART FSM (The Debugger)
    component UART_FSM
        port(
            i_clk             : in  std_logic;
            i_reset           : in  std_logic;
            state_information : in  std_logic_vector(1 downto 0);
            o_address         : out std_logic_vector(1 downto 0);
            o_rw              : out std_logic;
            o_chipSelect      : out std_logic;
            i_data_from_uart  : in  std_logic_vector(7 downto 0);
            o_data_to_uart    : out std_logic_vector(7 downto 0)
        );
    end component;

    -- C. The Main UART Component
    -- (Assuming standard interface based on your project description)
    component UART
        port(
            Clk, Reset      : in  std_logic;
            Addr            : in  std_logic_vector(1 downto 0);
            RW              : in  std_logic;
            CS              : in  std_logic;
            DataIn          : in  std_logic_vector(7 downto 0); -- Data to Transmit
            DataOut         : out std_logic_vector(7 downto 0); -- Received Data
            TxD             : out std_logic;
            RxD             : in  std_logic;
            IRQ             : out std_logic -- Interrupt (Optional)
        );
    end component;

    -- D. Clock Divider
    component Clock_Divider
        port(
            i_clk   : in  std_logic;
            i_reset : in  std_logic;
            o_clk   : out std_logic
        );
    end component;

    -- E. Timer/Counter Block (Placeholder - You need to implement this!)
    -- This block should take the switches and generate MSC/SSC for the FSM
    component Traffic_Timer
        port(
            clk         : in std_logic;
            reset       : in std_logic;
            SW1, SW2    : in std_logic_vector(3 downto 0);
            -- Inputs from FSM to control timer? (If your FSM had them)
            MSC_out     : out std_logic;
            SSC_out     : out std_logic;
            Count_Value : out std_logic_vector(3 downto 0)
        );
    end component;

begin

    -- Reset Logic (Inverting if your components use Active Low)
    reset_bar <= not GReset;

    -- 3. Instantiations

    -- Clock Divider
    U_CLK_DIV: Clock_Divider
    port map(
        i_clk   => GClock,
        i_reset => GReset,
        o_clk   => clk_slow
    );

    -- Timer / Counter Logic
    U_TIMER: Traffic_Timer
    port map(
        clk         => clk_slow,
        reset       => GReset,
        SW1         => SW1,
        SW2         => SW2,
        MSC_out     => msc_status,
        SSC_out     => ssc_status,
        Count_Value => current_count -- Connect this to BCD decoders
    );

    -- Traffic Light Controller
    U_TLC: fsmController
    port map(
        SSCS              => SSCS,
        clk               => clk_slow,
        reset_BAR         => reset_bar,
        MSC               => msc_status,
        SSC               => ssc_status,
        MSTL              => MSTL,
        SSTL              => SSTL,
        state_information => state_info_conn -- Sends state "00", "01".. to UART FSM
    );

    -- UART FSM (The "Microcontroller")
    U_UART_FSM: UART_FSM
    port map(
        i_clk             => clk_slow, -- Using slow clock for state transitions
        i_reset           => GReset,
        state_information => state_info_conn, -- Inputs the state from TLC
        o_address         => uart_address,
        o_rw              => uart_rw,
        o_chipSelect      => uart_cs,
        i_data_from_uart  => uart_data_out, -- Read SCSR/RDR
        o_data_to_uart    => uart_data_in   -- Write TDR
    );

    -- Main UART
    U_UART: UART
    port map(
        Clk     => GClock, -- UART usually needs the fast global clock for Baud Rate Gen
        Reset   => GReset,
        Addr    => uart_address,
        RW      => uart_rw,
        CS      => uart_cs,
        DataIn  => uart_data_in,
        DataOut => uart_data_out,
        TxD     => TxD,
        RxD     => RxD,
        IRQ     => open -- IRQ not used in polling mode
    );

    -- BCD Decoders (Direct mapping example - modify based on your BCD component)
    -- BCD1 <= current_count; -- Example mapping
    -- BCD2 <= "0000";

end structural;