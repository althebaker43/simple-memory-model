--! @file misc.vhdl
--! @brief File containing miscellaneous datapath components and definitions
--!
--! @todo Add clock generator

library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

package datapath_types is

    constant CLK_PERIOD : time := 10 ns;

    constant ADDR_SIZE : positive := 32;
    constant WORD_SIZE : positive := 32;

    subtype addr is unsigned( ( ADDR_SIZE - 1 ) downto 0 );
    subtype word is signed( ( WORD_SIZE - 1 ) downto 0 );

    constant LW_TEMPLATE  : word := X"86_00_00_00";
    constant SW_TEMPLATE  : word := X"A6_00_00_00";
    constant ADD_TEMPLATE : word := X"02_00_00_00";
    constant BEQ_TEMPLATE : word := X"10_00_00_00";

end package datapath_types;


use work.datapath_types.all;

library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

entity clk_gen is
    port( clk : out std_logic;
          en  : in std_logic );
end entity clk_gen;

architecture clk_gen_behav of clk_gen is 
begin

    clock : process is
    begin

        wait on en;

        while en = '1' loop
            clk <= '1';
            wait for ( CLK_PERIOD / 2 );
            clk <= '0';
            wait for ( CLK_PERIOD / 2 );
        end loop;

        wait;

    end process clock;

end architecture clk_gen_behav;
