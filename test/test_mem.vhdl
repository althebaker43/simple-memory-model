--! @file test_mem.vhdl
--! @brief File containing unit test for memory behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;

--! @brief Memory test-bench entity
entity test_mem is
end entity test_mem;

--!@brief Memory test-bench architecture
architecture test_mem_arch of test_mem is

    signal clk : std_logic;
    signal addr_in : addr;
    signal data_in : word;
    signal addr_out : addr;
    signal data_out : word;

begin

    mem_ent : entity work.mem( mem_behav )
        port map( clk,
                  addr_in,
                  data_in,
                  addr_out,
                  data_out );

    test : process is
    begin
        
        assert false
            report "TEST: Starting mem_behav tests."
            severity note;
        
        assert false
            report "TEST: End of mem_behav tests."
            severity note;

        wait;

    end process test;

end architecture test_mem_arch;
