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

    constant CACHE_SIZE : positive := 128;
    constant MIN_ADDR : addr := X"00_00_00_00";
    constant MAX_ADDR : addr := X"00_00_00_7C";

    constant MEM_SIZE : positive := 1024;
    constant MEM_WORD_SIZE : positive := ( MEM_SIZE / 4 );
    
    constant MEM_READ_ACCESS_DELAY  : natural := 5;
    constant MEM_READ_ADDNL_DELAY   : natural := 3;
    constant MEM_WRITE_ACCESS_DELAY : natural := 3;
    constant MEM_WRITE_ADDNL_DELAY  : natural := 4;

    signal clk          : std_logic;
    signal clk_en       : std_logic;
    
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

    type storage is array ( 0 to ( MEM_WORD_SIZE - 1 ) ) of word;

begin

    clk_gen_ent : entity work.clk_gen( clk_gen_behav )
        port map( clk,
                  clk_en );

    cache_ent : entity work.cache( cache_behav )
        generic map( CACHE_SIZE,
                     MIN_ADDR,
                     MAX_ADDR )
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

        variable mem_data_indx : integer;
        variable mem_data_sample : word;

        variable mem_storage : storage := ( others => NULL_WORD );

        procedure test_data_retention( sample_data  : in word;
                                       sample_addr  : in addr ) is
        begin

            assert false
                report "INFO: Writing data."
                severity note;

            cpu_addr <= sample_addr;
            cpu_data <= sample_data;
            cpu_access <= '1';
            cpu_write <= '1';
            wait for ( CLK_PERIOD / 2 );

            cpu_addr <= NULL_ADDR;
            cpu_data <= WEAK_WORD;
            cpu_access <= '0';
            cpu_write <= '0';

            while true loop
            
                wait on cpu_ready, mem_access;

                if cpu_ready = '1' then
                    exit;
                end if;

                if mem_access = '1' then

                    mem_data_indx := to_integer( mem_addr srl 2 );

                    if mem_write = '1' then

                        assert false
                            report "INFO: Serving memory write request from cache."
                            severity note;
                        
                        mem_data_sample := mem_data;

                        wait for ( ( MEM_WRITE_ACCESS_DELAY + MEM_WRITE_ACCESS_DELAY ) * CLK_PERIOD );

                        mem_storage( mem_data_indx ) := mem_data_sample;
                        mem_ready <= '1';
                        wait for ( CLK_PERIOD / 2 );

                        mem_ready <= '0';

                    else

                        assert false
                            report "INFO: Serving memory read request from cache."
                            severity note;

                        wait for ( ( MEM_READ_ACCESS_DELAY + MEM_READ_ACCESS_DELAY ) * CLK_PERIOD );
                        mem_data <= mem_storage( mem_data_indx );
                        mem_ready <= '1';
                        wait for ( CLK_PERIOD / 2 );

                        mem_ready <= '0';

                    end if;

                end if;

            end loop;

            assert false
                report "INFO: Reading data."
                severity note;

            wait for CLK_PERIOD;

            cpu_addr <= sample_addr;
            cpu_data <= WEAK_WORD;
            cpu_access <= '1';
            cpu_write <= '0';
            wait for ( CLK_PERIOD / 2 );

            cpu_addr <= NULL_ADDR;
            cpu_data <= WEAK_WORD;
            cpu_access <= '0';
            cpu_write <= '0';

            while true loop
            
                wait on cpu_ready, mem_access;

                if cpu_ready = '1' then
                    exit;
                end if;

                if mem_access = '1' then
                        
                    mem_data_indx := to_integer( mem_addr srl 2 );

                    if mem_write = '1' then

                        assert false
                            report "INFO: Serving memory write request from cache."
                            severity note;

                        mem_data_sample := mem_data;

                        wait for ( ( MEM_WRITE_ACCESS_DELAY + MEM_WRITE_ACCESS_DELAY ) * CLK_PERIOD );

                        mem_storage( mem_data_indx ) := mem_data_sample;
                        mem_ready <= '1';
                        wait for ( CLK_PERIOD / 2 );

                        mem_ready <= '0';

                    else

                        assert false
                            report "INFO: Serving memory read request from cache."
                            severity note;

                        wait for ( ( MEM_READ_ACCESS_DELAY + MEM_READ_ACCESS_DELAY ) * CLK_PERIOD );
                        mem_data <= mem_storage( mem_data_indx );
                        mem_ready <= '1';
                        wait for ( CLK_PERIOD / 2 );

                        mem_ready <= '0';

                    end if;

                end if;

            end loop;

            assert( cpu_data = sample_data )
                report "ERROR: Bad cpu cache output."
                severity error;
            wait for CLK_PERIOD;

        end procedure;

    begin
        
        assert false
            report "TEST: Starting cache_behav tests."
            severity note;

        cpu_addr <= NULL_ADDR;
        cpu_data <= WEAK_WORD;
        cpu_access <= '0';
        cpu_write <= '0';
        mem_data <= WEAK_WORD;
        mem_ready <= '0';
        wait for CLK_PERIOD;

        clk_en <= '1';
        wait for CLK_PERIOD;

        test_data_retention( X"55_55_55_55",
                             X"00_00_00_04" );
        
        test_data_retention( X"77_77_77_77",
                             X"00_00_00_08" );
        
        test_data_retention( X"CC_CC_CC_CC",
                             X"00_00_00_00" );
        
        test_data_retention( X"11_11_11_11",
                             X"00_00_00_18" );

        clk_en <= '0';
        wait for CLK_PERIOD;
        
        assert false
            report "TEST: End of cache_behav tests."
            severity note;

        wait;

    end process test;

end architecture test_cache_arch;
