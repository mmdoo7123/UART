LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Mux8to1 IS
    PORT (
        i_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        i_sel  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        o_y    : OUT STD_LOGIC
    );
END Mux8to1;

ARCHITECTURE Behavioral OF Mux8to1 IS
BEGIN
    WITH i_sel SELECT
        o_y <= i_data(0) WHEN "000",
               i_data(1) WHEN "001",
               i_data(2) WHEN "010",
               i_data(3) WHEN "011",
               i_data(4) WHEN "100",
               i_data(5) WHEN "101",
               i_data(6) WHEN "110",
               i_data(7) WHEN "111",
               '0'       WHEN OTHERS;
END Behavioral;