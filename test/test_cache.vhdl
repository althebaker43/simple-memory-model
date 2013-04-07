--! @file test_cache.vhdl
--! @brief File containing unit test for cache

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

--! @brief Cache test-bench entity
entity test_cache is
end entity test_cache;

--!@brief Cache test-bench architecture
architecture test_cache_arch of test_cache is

    signal clk : std_logic;
    signal clk_en : std_logic;
    
    signal cpu_addr     : addr;
    signal cpu_data     : word;
    signal cpu_access   : std_logic;
    signal cpu_write    : std_logic;
    signal cpu_ready    : std_logic;
    
    signal mem_addr     : addr;
    signal mem_data     : word;
    signal mem_access   : std_logic;
    signal mem_write    : std_logic;
    signal mem_ready    : std_logic;

    signal hit : std_logic;

begin

    clk_gen_ent : entity work.clk_gen( clk_gen_behav )
        port map( clk,
                  clk_en );

    cache_ent : entity work.cache( cache_behav )
        port map( clk,
                  cpu_addr,
                  cpu_data,
                  cpu_access,
                  cpu_write,
                  cpu_ready,
                  mem_addr,
                  mem_data,
                  mem_access,
                  mem_write,
                  mem_ready,
                  hit );

    test : process is
    begin
        
        assert false
            report "TEST: Starting cache_behav tests."
            severity note;

        cpu_addr <= NULL_ADDR;
        cpu_data <= NULL_WORD;
        cpu_access <= '0';
        cpu_write <= '0';
        mem_addr <= NULL_ADDR;
        mem_data <= NULL_WORD;
        mem_access <= '0';
        mem_write <= '0';
        wait for CLK_PERIOD;

        clk_en <= '1';
        wait for CLK_PERIOD;


        clk_en <= '0';
        wait for CLK_PERIOD;
        
        assert false
            report "TEST: End of cache_behav tests."
            severity note;

        wait;

    end process test;

end architecture test_cache_arch;
