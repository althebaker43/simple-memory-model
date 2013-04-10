--! @file test_datapath.vhdl
--! @brief File containing unit tests for datapath

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

--! @brief Datapath test-bench entity
entity test_datapath is
end entity test_datapath;

--! @brief Datapath test-bench architecture
architecture test_datapath_arch of test_datapath is

    signal en : std_logic;
    signal reset : std_logic;
    signal addr_instr  : addr;
    signal instr_hit : std_logic;
    signal data_hit : std_logic;

begin

    datapath_ent : entity work.datapath( datapath_struct )
        port map( en,
                  reset,
                  addr_instr,
                  instr_hit,
                  data_hit );

    test : process is
    begin

        println( "TEST: Starting datapath tests." );

        println( "TEST: End of datapath tests." );

        wait;

    end process test;

end architecture test_datapath_arch;
