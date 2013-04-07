--! @file cache.vhdl
--! @brief File containing Cache entity and behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

--! @brief Cache entity
entity cache is

    generic( cache_size : positive;
             min_addr   : addr;
             max_addr   : addr
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

    --! Total size of memory in bytes covered by cache
    --constant MEM_SIZE : positive := max_addr - min_addr + 4;

    --! Capacity of cache in words
    constant NUM_WORDS : positive := cache_size / 4;

    --! Capacity of cache in blocks
    constant NUM_BLOCKS : positive := NUM_WORDS / 8;

    --! Memory coverage size in bytes for each block
    constant BLOCK_MEM_CVRG : natural := mem_size / NUM_BLOCKS;

    --! Cache block type
    type cache_block is array( 0 to 7 ) of word;

    type cache_block_addr is array( 0 to 7 ) of addr;

    --! Cache block array type
    type block_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of cache_block;

    type block_addr_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of cache_block_addr;

    --! Cache block availability flag array type
    type block_arr_avail is array( 0 to ( NUM_BLOCKS - 1 ) ) of bit;

    --! Cache block dirty flag array type
    type block_arr_dirty is array( 0 to ( NUM_BLOCKS - 1 ) ) of bit;

begin

    cpu_ready <= '0';
    cpu_data <= WEAK_WORD;
    mem_data <= WEAK_WORD;
    hit <= '0';

    operate : process( clk ) is

        variable cpu_read_operation : boolean := false;
        variable cpu_write_operation : boolean := false;
        variable mem_read_operation : boolean := false;
        variable mem_write_operation : boolean := false;

        variable cpu_sample_addr : addr;
        variable cpu_sample_data : word;

        variable addr_present : boolean;

        variable mem_sample_data : word;

        variable storage : block_arr;
        variable storage_addr : block_addr_arr;
        variable storage_avail : block_arr_avail;
        variable storage_dirty : block_arr_dirty;


        procedure lookup_addr( sample_addr : in addr;
                               present : out boolean ) is

            variable sample_addr_nat : natural;
            variable min_addr_nat : natural;
            variable abs_addr_nat  : natural;
            variable block_num : natural;
            variable cur_block_addr : cache_block_addr;

        begin

            sample_addr_nat := to_integer( sample_addr );
            min_addr_nat := to_integer( min_addr );
            abs_addr_nat := sample_addr_nat - min_addr_nat;
            block_num := abs_addr_nat / BLOCK_MEM_CVRG;

            if storage_avail( block_num ) = '0' then
                    
                cur_block_addr := storage_addr( block_num );
                present := false;

                for block_addr_indx in cur_block_addr'range loop

                    if sample_addr = cur_block_addr( block_addr_indx ) then

                        present := true;

                    end if;

                end loop;

            else

                present := false;

            end if;

        end procedure;


        --! @todo Convert to procedure
        function block_avail( sample_addr : in addr ) return boolean is

        begin

            return true;

        end function;


        --! @todo Convert to procedure
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

                lookup_addr( cpu_sample_addr, addr_present );

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

                elsif addr_present = true then

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

                lookup_addr( cpu_sample_addr, addr_present );

                if mem_write_operation = true then

                    if mem_ready = '1' then

                        mem_write_operation := false;
                        cpu_write_operation := false;

                    end if;

                elsif addr_present = true then

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
