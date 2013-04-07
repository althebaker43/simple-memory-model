--! @file cache.vhdl
--! @brief File containing Cache entity and behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;

--! @brief Cache entity
entity cache is

    generic( cache_size : positive
        );

    port( clk           : in std_logic;
    
          cpu_addr      : in addr;
          cpu_data      : inout word;
          cpu_access    : in std_logic;
          cpu_write     : in std_logic;
          cpu_ready     : out std_logic;
    
          mem_addr      : out addr;
          mem_data      : inout word;
          mem_access    : out std_logic;
          mem_write     : out std_logic;
          mem_ready     : in std_logic;

          hit           : out std_logic
      );

end entity cache;

--! @brief Cache behavioral architecture
--!
--! @details
--!
--! The cache is to have the following characteristics:
--!
--! @li Write scheme is write-back
--! @li Write-miss scheme is no-write-allocate
architecture cache_behav of cache is

begin

    operate : process( clk ) is

        variable cpu_read_operation : boolean := false;
        variable cpu_write_operation : boolean := false;
        variable mem_read_operation : boolean := false;
        variable mem_write_operation : boolean := false;

        variable cpu_sample_addr : addr;
        variable cpu_sample_data : word;

        variable mem_sample_data : word;

        function lookup_addr( sample_addr : in addr ) return boolean is

        begin

            return true;

        end function;


        function block_avail( sample_addr : in addr ) return boolean is

        begin

            return true;

        end function;


        function fetch_data( sample_addr : in addr ) return word is

        begin

            return NULL_WORD;

        end function;


        procedure store_data( sample_addr : in addr;
                              sample_data : in word ) is
        begin

        end procedure;

    begin

        if clk = '1' then

            if cpu_read_operation = true then

                if mem_write_operation = true then

                    if mem_ready = '1' then

                        mem_write_operation := false;
                        mem_read_operation := true;

                    end if;

                elsif mem_read_operation = true then

                    if mem_ready = '1' then

                        store_data( cpu_sample_addr, mem_sample_data );
                        mem_read_operation := false;

                    end if;

                elsif lookup_addr( cpu_sample_addr ) = true then

                    cpu_data <= fetch_data( cpu_sample_addr );
                    cpu_ready <= '1';
                    cpu_read_operation := false;

                else

                    if block_avail( cpu_sample_addr ) = true then

                        mem_read_operation := true;

                    else

                        mem_write_operation := true;

                    end if;

                end if;


            elsif cpu_write_operation = true then

                if mem_write_operation = true then

                    if mem_ready = '1' then

                        mem_write_operation := false;
                        cpu_write_operation := false;

                    end if;

                elsif lookup_addr( cpu_sample_addr ) = true then

                    store_data( cpu_sample_addr, cpu_sample_data );
                    cpu_write_operation := false;

                else

                    mem_write_operation := true;

                end if;

            elsif cpu_access = '1' then

                if cpu_write = '0' then

                    cpu_sample_addr := cpu_addr;
                    cpu_read_operation := true;

                else

                    cpu_sample_addr := cpu_addr;
                    cpu_sample_data := cpu_data;
                    cpu_write_operation := true;

                end if;

            end if;

        end if;

    end process;

end architecture cache_behav;
