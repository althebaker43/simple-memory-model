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
        generic map( CACHE_SIZE )
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

        variable mem_data_pos : integer;
        variable mem_data_input : word;

        variable mem_storage : storage;

        procedure test_data_retention( sample_data  : in word;
                                       sample_addr  : in addr ) is
        begin

            cpu_addr <= sample_addr;
            cpu_data <= sample_data;
            cpu_access <= '1';
            cpu_write <= '1';
            wait for ( CLK_PERIOD / 2 );

            cpu_addr <= NULL_ADDR;
            cpu_data <= NULL_WORD;
            cpu_access <= '0';
            cpu_write <= '0';

            while cpu_ready = '0' loop
            
                wait on cpu_ready, mem_access;

                if mem_access = '1' then
                        
                    mem_data_pos := to_integer( mem_addr srl 2 );

                    if mem_write = '1' then

                        wait for ( ( MEM_WRITE_ACCESS_DELAY + MEM_WRITE_ACCESS_DELAY ) * CLK_PERIOD );
                        mem_storage( mem_data_pos ) := mem_data;
                        mem_ready <= '1';

                    else

                        wait for ( ( MEM_READ_ACCESS_DELAY + MEM_READ_ACCESS_DELAY ) * CLK_PERIOD );
                        mem_data <= mem_storage( mem_data_pos );
                        mem_ready <= '1';

                    end if;

                end if;

            end loop;

            wait for CLK_PERIOD;

            cpu_addr <= sample_addr;
            cpu_data <= WEAK_WORD;
            cpu_write <= '0';
            wait for ( CLK_PERIOD / 2 );

            cpu_addr <= NULL_ADDR;
            cpu_data <= WEAK_WORD;
            cpu_access <= '0';
            cpu_write <= '0';

            while cpu_ready = '0' loop
            
                wait on cpu_ready, mem_access;

                if mem_access = '1' then
                        
                    mem_data_pos := to_integer( mem_addr srl 2 );

                    if mem_write = '1' then

                        wait for ( ( MEM_WRITE_ACCESS_DELAY + MEM_WRITE_ACCESS_DELAY ) * CLK_PERIOD );
                        mem_storage( mem_data_pos ) := mem_data;
                        mem_ready <= '1';

                    else

                        wait for ( ( MEM_READ_ACCESS_DELAY + MEM_READ_ACCESS_DELAY ) * CLK_PERIOD );
                        mem_data <= mem_storage( mem_data_pos );
                        mem_ready <= '1';

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
