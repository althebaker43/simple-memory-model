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
    signal access_instr : std_logic;
    signal instr_hit : std_logic;
    signal data_hit : std_logic;

begin

    datapath_ent : entity work.datapath( datapath_struct )
        port map( en,
                  reset,
                  addr_instr,
                  access_instr,
                  instr_hit,
                  data_hit );

    test : process is

        procedure test_sequential is

            variable pc_orig_nat : natural := 0;

        begin

            wait until access_instr = '1';

            pc_orig_nat := to_integer( addr_instr );
            wait on access_instr;

            wait until access_instr = '1';

            assert( to_integer( addr_instr ) = pc_orig_nat + WORD_BYTE_SIZE )
                report "ERROR: Bad sequential CPU program counter output."
                severity error;

            wait for CLK_PERIOD;

        end procedure test_sequential;

    begin

        reset <= '0';
        wait for CLK_PERIOD;

        en <= '1';
        wait for CLK_PERIOD;

        println( "TEST: Starting datapath tests." );

        println( "TEST:     Starting sequential operation tests." );
        for test_sequential_count in 0 to 10 loop
            test_sequential;
        end loop;
        println( "TEST:     End of sequential operation tests." );

        en <= '0';
        wait for CLK_PERIOD;

        println( "TEST: End of datapath tests." );

        wait;

    end process test;

end architecture test_datapath_arch;
