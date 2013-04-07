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

    constant MIN_ADDR_NAT : natural := to_integer( min_addr );

    constant MAX_ADDR_NAT : natural := to_integer( max_addr );

    --! Total size of memory in bytes covered by cache
    constant MEM_SIZE : positive := ( MIN_ADDR_NAT - MAX_ADDR_NAT ) + 4;

    --! Capacity of cache in words
    constant NUM_WORDS : positive := cache_size / 4;

    --! Capacity of cache in blocks
    constant NUM_BLOCKS : positive := NUM_WORDS / 8;

    --! Memory coverage size in bytes for each block
    constant BLOCK_MEM_CVRG : natural := MEM_SIZE / NUM_BLOCKS;

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
        variable mem_read_block_word_indx : natural := 0;
        variable mem_read_block_addr : addr;

        variable mem_sample_data : word;

        variable storage : block_arr;
        variable storage_addrs : block_addrs_arr;
        variable storage_avbls : block_avbls_arr;
        variable storage_dirtys : block_dirtys_arr;


        --! @brief Gets cache block index given address
        --!
        --! @param sample_addr Input address to look up
        --! @param valid_addr Indicates if given address is covered by cache
        --! @param block_indx Block number corresponding to given address (if valid)
        --! 
        --! @todo Verify that included calculations use floor-type functions
        --! for rounding naturals
        procedure get_block_indx( sample_addr   : in addr;
                                  valid_addr    : out boolean;
                                  block_indx    : out natural ) is
            
            variable sample_addr_nat : natural;
            variable min_addr_nat : natural;
            variable max_addr_nat : natural;
            variable abs_addr_nat  : natural;

        begin

            valid_addr := false;
            block_indx := 0;

            sample_addr_nat := to_integer( sample_addr );
            min_addr_nat := to_integer( min_addr );
            max_addr_nat := to_integer( max_addr );

            if( ( sample_addr_nat >= min_addr_nat ) and
                ( sample_addr_nat <= max_addr_nat ) ) then
                    
                valid_addr := true;

            end if;

            abs_addr_nat := sample_addr_nat - min_addr_nat;
            block_indx := abs_addr_nat / BLOCK_MEM_CVRG;

        end procedure get_block_indx;


        --! @brief Gets address given cache block index, address index, and one
        --! address included in block
        --!
        --! @param block_indx Index of block
        --! @param incl_addr Address to be included anywhere within block
        --! @param addr_indx Index of address
        --! @param Resulting address
        --! 
        --! @todo Double-check math
        --! @todo Verify that included calculations use floor-type functions
        --! for rounding naturals
        procedure get_block_addr( block_indx    : in natural;
                                  incl_addr     : in addr;
                                  addr_indx     : in natural;
                                  sample_addr   : out addr ) is

            variable incl_addr_nat : natural;
            variable min_addr_nat : natural;
            variable incl_addr_abs_nat : natural;
            variable mem_block_indx : natural;
            variable start_addr_nat : natural;
            variable sample_addr_nat : natural;

        begin
            
            incl_addr_nat := to_integer( incl_addr );
            min_addr_nat := to_integer( min_addr );
            incl_addr_abs_nat := incl_addr_nat - min_addr_nat;
            mem_block_indx := incl_addr_abs_nat / 32;
            start_addr_nat := ( mem_block_indx * 32 ) + min_addr_nat;
            sample_addr_nat := start_addr_nat + ( addr_indx * 4 );
            sample_addr := to_unsigned( sample_addr_nat, ADDR_SIZE );

        end procedure get_block_addr;


        --! @brief Fetch data word at given index within given block
        --!
        --! @param block_indx Index of block within cache to search within
        --! @param word_indx Index within block to retrieve data from
        --! @param sample_addr Address at index
        --! @param sample_data Data at index
        procedure query_block_indx( block_indx  : in natural;
                                    word_indx   : in natural;
                                    sample_addr : out addr;
                                    sample_data : out word ) is
            
            variable cur_block_addrs : cache_block_addrs;
            variable cur_block : cache_block;

        begin

            sample_addr := NULL_ADDR;
            sample_data := NULL_WORD;

            cur_block_addrs := storage_addrs( block_indx );
            cur_block := storage( block_indx );

            sample_addr := cur_block_addrs( word_indx );
            sample_data := cur_block( word_indx );

        end procedure query_block_indx;


        --! @brief Attempt to fetch data within block given address and block
        --! attributes
        --!
        --! @param block_indx Index of block within cache to search within
        --! @param sample_addr Input address to look up within block
        --! @param present Indicates if given address is present within block
        --! @param avbl Indicates if given block index is available
        --! @param dirty Indicates if given block is dirty or not
        --! @param sample_data Data at address (if address if present)
        procedure query_block_addr( block_indx  : in natural;
                                    sample_addr : in addr;
                                    present     : out boolean;
                                    avbl        : out boolean;
                                    dirty       : out boolean;
                                    sample_data : out word ) is
            
            variable cur_block_addrs : cache_block_addrs;
            variable cur_block : cache_block;

        begin

            present := false;
            avbl := true;
            dirty := false;
            sample_data := NULL_WORD;

            if storage_avbls( block_indx ) = '1' then

                avbl := true;

            else

                if storage_dirtys( block_indx ) = '1' then

                    dirty := true;

                end if;

                cur_block_addrs := storage_addrs( block_indx );
                cur_block := storage( block_indx );

                for block_addr_indx in cur_block_addrs'range loop

                    if sample_addr = cur_block_addrs( block_addr_indx ) then

                        present := true;
                        sample_data := cur_block( block_addr_indx );

                    end if;

                end loop;

            end if;

        end procedure query_block_addr;


        --! @brief Fetches data and block attributes corresponding to given
        --! address
        --!
        --! @param sample_addr Input address to look up
        --! @param valid Indicates if given address is covered by cache
        --! @param present Indicates if address is present within cache
        --! @param avbl Indicates if corresponding block is available
        --! @param dirty Indicates if corresponding block is dirty
        --! @param sample_data Data at address (if address if present)
        procedure query_cache( sample_addr  : in addr;
                               valid        : out boolean;
                               present      : out boolean;
                               avbl         : out boolean;
                               dirty        : out boolean;
                               sample_data  : out word ) is

            variable addr_valid : boolean := false;
            variable block_num : natural := 0;

        begin

            present := false;
            valid := false;
            avbl := true;
            sample_data := NULL_WORD;

            get_block_indx( sample_addr,
                            addr_valid,
                            block_num );

            if addr_valid = true then 

                valid := true;

                query_block_addr( block_num,
                                  sample_addr,
                                  present,
                                  avbl,
                                  dirty,
                                  sample_data );

            end if;

        end procedure query_cache;


        --! @brief Initializes memory-writing operation
        --!
        --! Each call to this procedure writes another word to memory. The
        --! index of the word within the block currently being written is
        --! tracked by the process-global variable mem_write_block_word_indx.
        --! When the value of this variable becomes equal to the size of
        --! a block in words, then mem_write_operation is set to false to
        --! terminate the writing operation. mem_read_operation is then set to
        --! true to begin the reading operation into the same block.
        --!
        --! @param sample_addr Input address to write corresponding block
        procedure mem_write_block( sample_addr : in addr ) is

            variable block_num : natural := 0;
            variable addr_valid : boolean := false;
            variable write_addr : addr := NULL_ADDR;
            variable write_data : word := NULL_WORD;

        begin

            if mem_write_block_word_indx < 8 then

                get_block_indx( sample_addr,
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

                mem_write_block_word_indx := 0;
                mem_write_operation := false;
                mem_read_operation := true;

            end if;

        end procedure mem_write_block;


        --! @brief Initializes memory-reading operation
        --!
        --! @param sample_addr Input address to read corresponding block
        procedure mem_read_block( sample_addr : in addr ) is

            variable block_num : natural := 0;
            variable addr_valid : boolean := false;
            variable read_addr : addr := NULL_ADDR;

        begin

            if mem_read_block_word_indx < 8 then

                get_block_indx( sample_addr,
                                addr_valid,
                                block_num );

                if addr_valid = true then

                    get_block_addr( block_num,
                                    sample_addr,
                                    mem_read_block_word_indx,
                                    read_addr );

                    mem_read_block_word_indx := mem_read_block_word_indx + 1;
                    mem_read_block_addr := read_addr;

                    mem_addr <= read_addr;
                    mem_data <= WEAK_WORD;
                    mem_access <= '1';
                    mem_write <= '0';

                end if;

            else

                mem_read_block_word_indx := 0;
                mem_read_operation := false;

            end if;

        end procedure mem_read_block;


        --! @brief Stores word at the given address within the cache
        --!
        --! @param sample_addr Address to store data at
        --! @param sample_data Data to store
        procedure store_word( sample_addr : in addr;
                              sample_data : in word ) is
            
            variable valid_addr : boolean;
            variable block_num : natural;
            variable sample_addr_nat : natural;
            variable min_addr_nat : natural;
            variable sample_addr_abs_nat : natural;
            variable sample_addr_block_abs_nat : natural;
            variable sample_addr_indx : natural;

            variable cur_block : cache_block;
            variable cur_block_addrs : cache_block_addrs;

        begin

            get_block_indx( sample_addr,
                            valid_addr,
                            block_num );

            cur_block := storage( block_num );
            cur_block_addrs := storage_addrs( block_num );
            
            sample_addr_nat := to_integer( sample_addr );
            min_addr_nat := to_integer( min_addr );
            sample_addr_abs_nat := sample_addr_nat - min_addr_nat;
            sample_addr_block_abs_nat := sample_addr_abs_nat mod 32;
            sample_addr_indx := sample_addr_block_abs_nat / 4;

            cur_block( sample_addr_indx ) := sample_data;
            cur_block_addrs( sample_addr_indx ) := sample_addr;

        end procedure store_word;


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

                        store_word( mem_read_block_addr,
                                    mem_data );
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

                    end if;

                elsif cur_avbl = true then

                    store_word( cpu_sample_addr, cpu_sample_data );
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
