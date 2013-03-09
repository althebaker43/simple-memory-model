--! @file test_cache.vhdl
--! @brief File containing unit test for cache

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;

--! @brief Cache test-bench entity
entity test_cache is
end entity test_cache;

--!@brief Cache test-bench architecture
architecture test_cache_arch of test_cache is

    signal clk : std_logic;
    signal addr_in : addr;
    signal data_in : word;
    signal addr_out : addr;
    signal data_out : word;

begin

    cache_ent : entity work.cache( cache_behav )
        port map( clk,
                  addr_in,
                  data_in,
                  addr_out,
                  data_out );

    test : process is
    begin
        
        assert false
            report "TEST: Starting cache_behav tests."
            severity note;
        
        assert false
            report "TEST: End of cache_behav tests."
            severity note;

        wait;

    end process test;

end architecture test_cache_arch;
