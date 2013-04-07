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

    --! Cache block addresses type
    type cache_block_addrs is array( 0 to 7 ) of addr;

    --! Cache block array type
    type block_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of cache_block;

    --! Cache block addresses array type
    type block_addrs_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of cache_block_addrs;

    --! Cache block availability flag array type
    type block_avbls_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of bit;

    --! Cache block dirty flag array type
    type block_dirtys_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of bit;

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

        variable cur_valid : boolean := false;
        variable cur_present : boolean := false;
        variable cur_avbl : boolean := false;
        variable cur_dirty : boolean := false;

        variable mem_write_block_word_indx : natural := 0;

        variable mem_sample_data : word;

        variable storage : block_arr;
        variable storage_addrs : block_addrs_arr;
        variable storage_avbls : block_avbls_arr;
        variable storage_dirtys : block_dirtys_arr;


        procedure get_block_num( sample_addr : in addr;     --!< Input address to look up
                                 valid_addr : out boolean;  --!< Indicates if given address is covered by cache
                                 block_num  : out natural   --!< Block number corresponding to given address (if valid)
                             ) is
            
            variable sample_addr_nat : natural;
            variable min_addr_nat : natural;
            variable max_addr_nat : natural;
            variable abs_addr_nat  : natural;

        begin

            valid_addr := false;
            block_num := 0;

            sample_addr_nat := to_integer( sample_addr );
            min_addr_nat := to_integer( min_addr );
            max_addr_nat := to_integer( max_addr );

            if( ( sample_addr_nat >= min_addr_nat ) and
                ( sample_addr_nat <= max_addr_nat ) ) then
                    
                valid_addr := true;

            end if;

            abs_addr_nat := sample_addr_nat - min_addr_nat;
            block_num := abs_addr_nat / BLOCK_MEM_CVRG;

        end procedure get_block_num;


        --! Fetch data word at given index within given block
        procedure query_block_indx( block_num   : in natural;   --!< Index of block to search within
                                    word_indx   : in natural;   --!< Index to retrieve data from
                                    sample_addr : out addr;     --!< Address at index
                                    sample_data : out word      --!< Data at index
                                ) is
            
            variable cur_block_addrs : cache_block_addrs;
            variable cur_block : cache_block;

        begin

            sample_addr := NULL_ADDR;
            sample_data := NULL_WORD;

            cur_block_addrs := storage_addrs( block_num );
            cur_block := storage( block_num );

            sample_addr := cur_block_addrs( word_indx );
            sample_data := cur_block( word_indx );

        end procedure query_block_indx;


        --! Attempt to fetch data within block given address and block attributes
        procedure query_block_addr( sample_addr : in addr;      --!< Input address to look up within block
                                    block_num   : in natural;   --!< Index of block to search within
                                    present     : out boolean;  --!< Indicates if given address is present within given block
                                    avbl        : out boolean;  --!< Indicates if given block index is available
                                    dirty       : out boolean;  --!< Indicates if given block is dirty or not
                                    sample_data : out word      --!< Data at address (if present)
                           ) is
            
            variable cur_block_addrs : cache_block_addrs;
            variable cur_block : cache_block;

        begin

            present := false;
            avbl := true;
            dirty := false;
            sample_data := NULL_WORD;

            if storage_avbls( block_num ) = '1' then

                avbl := true;

            else

                if storage_dirtys( block_num ) = '1' then

                    dirty := true;

                end if;

                cur_block_addrs := storage_addrs( block_num );
                cur_block := storage( block_num );

                for block_addr_indx in cur_block_addrs'range loop

                    if sample_addr = cur_block_addrs( block_addr_indx ) then

                        present := true;
                        sample_data := cur_block( block_addr_indx );

                    end if;

                end loop;

            end if;

        end procedure query_block_addr;


        --! Fetches data and block attributes corresponding to given address
        procedure query_cache( sample_addr  : in addr;      --!< Input address to look up
                               valid        : out boolean;  --!< Indicates if given address if covered by cache
                               present      : out boolean;  --!< Indicates if address is present within cache
                               avbl         : out boolean;  --!< Indicates if corresponding block is available
                               dirty        : out boolean;  --!< Indicates if corresponding block is dirty
                               sample_data  : out word      --!< Data at address (if present)
                          ) is

            variable addr_valid : boolean := false;
            variable block_num : natural := 0;

        begin

            present := false;
            valid := false;
            avbl := true;
            sample_data := NULL_WORD;

            get_block_num( sample_addr,
                           addr_valid,
                           block_num );

            if addr_valid = true then 

                valid := true;

                query_block_addr( sample_addr,
                                  block_num,
                                  present,
                                  avbl,
                                  dirty,
                                  sample_data );

            end if;

        end procedure query_cache;


        --! Writes block from cache to memory
        --!
        --! Each call to this procedure writes another word to memory. The
        --! index of the word within the block currently being written is
        --! tracked by the process-global variable mem_write_block_word_indx.
        --! When the value of this variable becomes equal to the size of
        --! a block in words, then mem_write_operation is set to false to
        --! terminate the writing operation. mem_read_operation is then set to
        --! true to begin the reading operation into the same block.
        procedure mem_write_block( sample_addr : in addr    --!< Input address to write corresponding block
                                 ) is

            variable block_num : natural := 0;
            variable addr_valid : boolean := false;
            variable write_addr : addr := NULL_ADDR;
            variable write_data : word := NULL_WORD;

        begin

            if mem_write_block_word_indx < 8 then

                get_block_num( sample_addr,
                               addr_valid,
                               block_num );

                if addr_valid = true then

                    query_block_indx( block_num,
                                      mem_write_block_word_indx,
                                      write_addr,
                                      write_data );

                    mem_write_block_word_indx := mem_write_block_word_indx + 1;

                    mem_addr <= write_addr;
                    mem_data <= write_data;
                    mem_access <= '1';
                    mem_write <= '1';

                end if;

            else

                mem_write_operation := false;
                mem_read_operation := true;

            end if;

        end procedure mem_write_block;


        --! Reads block from memory into cache
        procedure mem_read_block( sample_addr : in addr     --!< Input address to read corresponding block
                                ) is

            variable block_num : natural := 0;
            variable addr_valid : boolean := false;

        begin

            get_block_num( sample_addr,
                           addr_valid,
                           block_num );


        end procedure mem_read_block;


        procedure store_data( sample_addr : in addr;
                              sample_data : in word ) is
        begin

        end procedure store_data;

    begin

        if clk = '1' then

            -- Currently serving CPU read request
            if cpu_read_operation = true then

                query_cache( cpu_sample_addr,
                             cur_valid,
                             cur_present,
                             cur_avbl,
                             cur_dirty,
                             cpu_sample_data );

                -- Currently writing block into memory
                if mem_write_operation = true then

                    -- Finished waiting for memory to finish write
                    if mem_ready = '1' then

                        mem_write_block( cpu_sample_addr );

                    end if;

                -- Currently reading block into cache
                elsif mem_read_operation = true then

                    -- Finished waiting for memory to finish read
                    if mem_ready = '1' then

                        mem_read_block( cpu_sample_addr );

                    end if;

                -- Block is present within cache
                elsif cur_present = true then

                    cpu_data <= cpu_sample_data;
                    cpu_ready <= '1';
                    cpu_read_operation := false;

                else

                    if cur_avbl = true then

                        mem_read_operation := true;

                    else

                        if cur_dirty = false then

                            mem_read_operation := true;

                        else

                            mem_write_operation := true;

                        end if;

                    end if;

                end if;


            elsif cpu_write_operation = true then

                query_cache( cpu_sample_addr,
                             cur_valid,
                             cur_present,
                             cur_avbl,
                             cur_dirty,
                             cpu_sample_data );

                if mem_write_operation = true then

                    if mem_ready = '1' then

                        mem_write_operation := false;
                        cpu_write_operation := false;

                    end if;

                elsif cur_avbl = true then

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
