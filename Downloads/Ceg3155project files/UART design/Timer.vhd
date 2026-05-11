library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Timer is
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        ST       : in  std_logic;
        increase : in  std_logic;
        MST      : out std_logic;
        SST      : out std_logic
    );
end Timer;

architecture Behavioral of Timer is
    signal mst_reg : std_logic := '0';
    signal sst_reg : std_logic := '0';
begin

    process(clk, rst)
    begin
        if rst = '1' then
            mst_reg <= '0';
            sst_reg <= '0';

        elsif rising_edge(clk) then
            if ST = '1' then
                if increase = '1' then
                    mst_reg <= not mst_reg;
                    sst_reg <= not sst_reg;
                end if;
            end if;
        end if;
    end process;

    MST <= mst_reg;
    SST <= sst_reg;

end Behavioral;
