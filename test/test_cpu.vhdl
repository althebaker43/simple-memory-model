--! @file test_cpu.vhdl
--! @brief File containing unit test for 32-bit CPU

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;

library std;
use std.textio.all;

--! @brief 32-bit CPU test-bench entity
entity test_cpu is
end entity test_cpu;

--!@brief 32-bit CPU test-bench architecture
architecture test_cpu_arch of test_cpu is

    signal instr_in : word;
    signal data_in : word;
    signal clk : std_logic;
    signal addr_out : addr;
    signal data_out : word;

begin

    cpu_ent : entity work.cpu( cpu_behav )
        port map( instr_in,
                  data_in,
                  clk,
                  addr_out,
                  data_out );

    test : process is
        variable hello_line : line;
    begin
        
        assert false
            report "TEST: Starting cpu_behav tests."
            severity note;

        write( hello_line, string'( "hello from test_cpu" ) );
        writeline( OUTPUT, hello_line );

        assert false
            report "TEST: End of cpu_behav tests."
            severity note;

        wait;

    end process test;

end architecture test_cpu_arch;
