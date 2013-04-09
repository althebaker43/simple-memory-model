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

    --! Natural representation of minimum covered address
    constant MIN_ADDR_NAT : natural := to_integer( min_addr );

    --! Natural representation of maximum covered address
    constant MAX_ADDR_NAT : natural := to_integer( max_addr );

    --! Total size of memory in bytes covered by cache
    constant MEM_SIZE : positive := ( MAX_ADDR_NAT - MIN_ADDR_NAT ) + 4;

    --! Capacity of cache in words
    constant NUM_WORDS : positive := cache_size / WORD_BYTE_SIZE;

    constant BLOCK_BYTE_SIZE : positive := 32;

    --! Size of one block in words
    constant BLOCK_WORD_SIZE : positive := BLOCK_BYTE_SIZE / WORD_BYTE_SIZE;

    --! Capacity of cache in blocks
    constant NUM_BLOCKS : positive := NUM_WORDS / BLOCK_WORD_SIZE;

    --! Memory coverage size in bytes for each block
    constant BLOCK_MEM_CVRG : natural := MEM_SIZE / NUM_BLOCKS;

    --! Cache block type
    type cache_block is array( 0 to ( BLOCK_WORD_SIZE - 1 ) ) of word;

    constant NULL_CACHE_BLOCK : cache_block := ( others => NULL_WORD );

    --! Cache block addresses type
    type cache_block_addrs is array( 0 to ( BLOCK_WORD_SIZE - 1 ) ) of addr;

    constant NULL_CACHE_BLOCK_ADDRS : cache_block_addrs := ( others => NULL_ADDR );

    --! Cache block array type
    type block_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of cache_block;

    --! Cache block addresses array type
    type block_addrs_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of cache_block_addrs;

    --! Cache block availability flag array type
    type block_avbls_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of bit;

    --! Cache block dirty flag array type
    type block_dirtys_arr is array( 0 to ( NUM_BLOCKS - 1 ) ) of bit;

begin

    --cpu_data <= WEAK_WORD;
    --cpu_ready <= '0';

    --mem_addr <= NULL_ADDR;
    --mem_data <= WEAK_WORD;
    --mem_access <= '0';
    --mem_write <= '0';

    --hit <= '0';

    operate : process( clk ) is

        variable cpu_read_operation : boolean := false;
        variable cpu_write_operation : boolean := false;
        
        variable mem_read_operation : boolean := false;
        variable mem_read_in_progress : boolean := false;
        variable mem_write_operation : boolean := false;
        variable mem_write_operation_finished : boolean := false;
        variable mem_write_in_progress : boolean := false;

        variable cpu_sample_addr : addr;
        variable cpu_sample_data : word;

        variable cur_block_indx : natural := 0;
        variable cur_addr_indx : natural := 0;
        variable cur_present : boolean := false;
        variable cur_avbl : boolean := false;
        variable cur_dirty : boolean := false;
        variable cur_data : word := NULL_WORD;

        variable mem_write_block_word_indx : natural := 0;
        variable mem_read_block_word_indx : natural := 0;
        variable mem_read_block_addr : addr;

        variable mem_sample_data : word;

        variable storage : block_arr := ( others => NULL_CACHE_BLOCK );
        variable storage_addrs : block_addrs_arr := ( others => NULL_CACHE_BLOCK_ADDRS );
        variable storage_avbls : block_avbls_arr := ( others => '1' );
        variable storage_dirtys : block_dirtys_arr := ( others => '0' );


        --! @brief Gets cache block index given address
        --!
        --! @param sample_addr Input address to look up
        --! @param block_indx Index of block within cache
        --! @param word_indx Index of address within block
        --! 
        --! @todo Get rid of magic numbers
        procedure get_cache_location( sample_addr   : in addr;
                                      block_indx    : out natural;
                                      addr_indx     : out natural ) is

            variable block_indx_mask : addr;
            variable addr_indx_mask : addr;

        begin

            block_indx_mask := to_unsigned( cache_size - 1, ADDR_SIZE );
            block_indx := to_integer( ( block_indx_mask and sample_addr ) srl 8 );


            addr_indx_mask := to_unsigned( BLOCK_BYTE_SIZE - 1, ADDR_SIZE );
            addr_indx := to_integer( ( addr_indx_mask and sample_addr ) srl 2 );

        end procedure get_cache_location;


        --! @brief Gets memory address given address index and one
        --! address included in block
        --!
        --! @param incl_addr Address to be included anywhere within block
        --! @param addr_indx Index of address
        --! @param Resulting address
        --! 
        --! @todo Double-check math
        procedure get_block_addr( incl_addr     : in addr;
                                  addr_indx     : in natural;
                                  sample_addr   : out addr ) is

            variable start_addr_mask : addr;
            variable start_addr_nat : natural;
            variable sample_addr_nat : natural;

        begin
            
            --incl_addr_nat := to_integer( incl_addr );
            --incl_addr_abs_nat := incl_addr_nat - MIN_ADDR_NAT;
            --mem_block_indx := incl_addr_abs_nat / 32;
            --start_addr_nat := ( mem_block_indx * 32 ) + MIN_ADDR_NAT;
            --sample_addr_nat := start_addr_nat + ( addr_indx * 4 );

            start_addr_mask := not to_unsigned( BLOCK_BYTE_SIZE - 1, ADDR_SIZE );
            start_addr_nat := to_integer( start_addr_mask and incl_addr );
            sample_addr_nat := start_addr_nat + ( addr_indx * WORD_BYTE_SIZE );

            assert( ( sample_addr_nat mod 4 ) = 0 )
                report "ERROR: Given CPU address not word-aligned."
                severity error;

            assert( ( sample_addr_nat >= MIN_ADDR_NAT ) and
                    ( sample_addr_nat <= MAX_ADDR_NAT ) )
                report "ERROR: Given CPU address not within memory bounds."
                severity error;
            
            sample_addr := to_unsigned( sample_addr_nat, ADDR_SIZE );

        end procedure get_block_addr;


        --! @brief Fetch data word at given index within given block
        --!
        --! @param block_indx Index of block within cache to search within
        --! @param word_indx Index within block to retrieve data from
        --! @param sample_addr Address at index
        --! @param sample_data Data at index
        procedure query_block_indx( block_indx  : in natural;
                                    addr_indx   : in natural;
                                    avbl        : out boolean;
                                    dirty       : out boolean;
                                    sample_addr : out addr;
                                    sample_data : out word ) is
            
            variable cur_block_addrs : cache_block_addrs;
            variable cur_block : cache_block;

        begin

            cur_block_addrs := storage_addrs( block_indx );
            cur_block := storage( block_indx );

            if storage_avbls( block_indx ) = '1' then
                avbl := true;
            else
                avbl := false;
            end if;

            if storage_dirtys( block_indx ) = '1' then
                dirty := true;
            else
                dirty := false;
            end if;

            sample_addr := cur_block_addrs( addr_indx );
            sample_data := cur_block( addr_indx );

        end procedure query_block_indx;


        --! @brief Fetches data and block attributes corresponding to given
        --! address
        --!
        --! @param sample_addr Input address to look up
        --! @param present Indicates if address is present within cache
        --! @param avbl Indicates if corresponding block is available
        --! @param dirty Indicates if corresponding block is dirty
        --! @param sample_data Data at address (if address if present)
        procedure query_cache( sample_addr  : in addr;
                               block_indx   : out natural;
                               addr_indx    : out natural;
                               present      : out boolean;
                               avbl         : out boolean;
                               dirty        : out boolean;
                               sample_data  : out word ) is

            variable sample_block_indx : natural := 0;
            variable sample_addr_indx : natural := 0;
            variable present_addr : addr;
            variable present_data : word;

        begin
            
            --assert false
            --    report "INFO: Querying cache."
            --    severity note;

            get_cache_location( sample_addr,
                                sample_block_indx,
                                sample_addr_indx );

            block_indx := sample_block_indx;
            addr_indx := sample_addr_indx;

            query_block_indx( sample_block_indx,
                              sample_addr_indx,
                              avbl,
                              dirty,
                              present_addr,
                              sample_data );

            if present_addr = sample_addr then
                present := true;
            else
                present := false;
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
        procedure mem_write_block( block_indx : in natural ) is

            variable write_avbl : boolean;
            variable write_dirty : boolean;
            variable write_addr : addr := NULL_ADDR;
            variable write_data : word := NULL_WORD;

        begin

            if mem_write_block_word_indx < BLOCK_WORD_SIZE then

                --assert false
                --    report "INFO: Writing word to memory."
                --    severity note;

                query_block_indx( block_indx,
                                  mem_write_block_word_indx,
                                  write_avbl,
                                  write_dirty,
                                  write_addr,
                                  write_data );

                mem_write_block_word_indx := mem_write_block_word_indx + 1;

                mem_addr <= write_addr;
                mem_data <= write_data;
                mem_access <= '1';
                mem_write <= '1';

                mem_write_in_progress := true;

            else
                
                --assert false
                --    report "INFO: Finished writing block to memory."
                --    severity note;

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

        begin

            if mem_read_block_word_indx < BLOCK_WORD_SIZE then

                --assert false
                --    report "INFO: Reading word from memory."
                --    severity note;

                get_block_addr( sample_addr,
                                mem_read_block_word_indx,
                                mem_read_block_addr );

                mem_read_block_word_indx := mem_read_block_word_indx + 1;

                mem_addr <= mem_read_block_addr;
                mem_data <= WEAK_WORD;
                mem_access <= '1';
                mem_write <= '0';

                mem_read_in_progress := true;

            else

                mem_read_block_word_indx := 0;
                mem_read_operation := false;

                --assert false
                --    report "INFO: Finished reading block from memory."
                --    severity note;

            end if;

        end procedure mem_read_block;


        --! @brief Stores word at the given address within the cache
        --!
        --! @param sample_addr Address to store data at
        --! @param sample_data Data to store
        --! @param set_dirty Set dirty bit for block
        --!
        --! @todo Convert calculations to bitwise
        procedure store_word( sample_addr : in addr;
                              sample_data : in word;
                              set_dirty   : in boolean ) is
            
            --variable sample_addr_nat : natural;
            --variable sample_addr_abs_nat : natural;
            --variable sample_addr_block_abs_nat : natural;
            --variable sample_addr_indx : natural;

            variable block_indx : natural;
            variable addr_indx : natural;
            variable cur_block : cache_block;
            variable cur_block_addrs : cache_block_addrs;

        begin

            if( ( block_indx < NUM_BLOCKS ) and 
                ( addr_indx < BLOCK_WORD_SIZE ) ) then

                get_cache_location( sample_addr,
                                    block_indx,
                                    addr_indx );

                cur_block := storage( block_indx );
                cur_block_addrs := storage_addrs( block_indx );
                storage_avbls( block_indx ) := '0';

                if set_dirty = true then
                    storage_dirtys( block_indx ) := '1';
                else
                    storage_dirtys( block_indx ) := '0';
                end if;

                cur_block( addr_indx ) := sample_data;
                cur_block_addrs( addr_indx ) := sample_addr;
                
                storage( block_indx ) := cur_block;
                storage_addrs( block_indx ) := cur_block_addrs;

            end if;

        end procedure store_word;


    begin

        if clk = '1' then

            -- Currently serving CPU read request
            cache_operation_branches:
            if cpu_read_operation = true then

                -- Currently writing block into memory
                cpu_read_operation_branches:
                if mem_write_operation = true then

                    -- Finished waiting for memory to finish write
                    if mem_ready = '1' then

                        --assert false
                        --    report "INFO: Finished writing word to memory."
                        --    severity note;

                        mem_write_in_progress := false;

                    elsif mem_write_in_progress = false then

                        mem_write_block( cur_block_indx );

                    end if;

                -- Currently reading block into cache
                elsif mem_read_operation = true then

                    -- Finished waiting for memory to finish read
                    if mem_ready = '1' then

                        --assert false
                        --    report "INFO: Finished reading word from memory."
                        --    severity note;

                        store_word( mem_read_block_addr,
                                    mem_data,
                                    false );

                        mem_read_in_progress := false;

                    elsif mem_read_in_progress = false then

                        mem_read_block( cpu_sample_addr );

                    end if;

                -- Block is present within cache

                else

                    query_cache( cpu_sample_addr,
                                 cur_block_indx,
                                 cur_addr_indx,
                                 cur_present,
                                 cur_avbl,
                                 cur_dirty,
                                 cpu_sample_data );

                    if cur_present = true then
                        
                        assert false
                            report "INFO: Cache read hit."
                            severity note;
                            
                        --assert false
                        --    report "INFO: Finished cache read operation."
                        --    severity note;

                        cpu_data <= cpu_sample_data;
                        cpu_ready <= '1';
                        cpu_read_operation := false;

                    else
                        
                        assert false
                            report "INFO: Cache read miss."
                            severity note;

                        if cur_avbl = true then
                        
                                assert false
                                    report "INFO: Cache block fill."
                                    severity note;

                                --assert false
                                --    report "INFO: Starting memory read operation."
                                --    severity note;

                                mem_read_block( cpu_sample_addr );
                                mem_read_operation := true;

                        else

                            if cur_dirty = false then

                                --assert false
                                --    report "INFO: Starting memory read operation."
                                --    severity note;

                                mem_read_block( cpu_sample_addr );
                                mem_read_operation := true;

                            else
                        
                                assert false
                                    report "INFO: Cache block replacement."
                                    severity note;

                                --assert false
                                --    report "INFO: Starting memory write operation."
                                --    severity note;

                                mem_write_block( cur_block_indx );
                                mem_write_operation := true;

                            end if;

                        end if;

                    end if;

                end if cpu_read_operation_branches;

            -- Currently serving cpu write request
            elsif cpu_write_operation = true then

                cpu_write_operation_branches:
                if mem_write_operation = true then

                    if mem_ready = '1' then

                        --assert false
                        --    report "INFO: Finished memory write operation."
                        --    severity note;

                        mem_write_operation_finished := true;
                        mem_write_operation := false;

                    end if;

                elsif mem_write_operation_finished = true then

                    mem_write_operation_finished := false;
                    cpu_write_operation := false;
                    cpu_ready <= '1';

                else

                    query_cache( cpu_sample_addr,
                                 cur_block_indx,
                                 cur_addr_indx,
                                 cur_present,
                                 cur_avbl,
                                 cur_dirty,
                                 cur_data );

                    if cur_present = true then
                        
                        assert false
                            report "INFO: Cache write hit."
                            severity note;

                        store_word( cpu_sample_addr,
                                    cpu_sample_data,
                                    true );
                        cpu_ready <= '1';
                        cpu_write_operation := false;

                    else
                        
                        assert false
                            report "INFO: Cache write miss."
                            severity note;

                        --assert false
                        --    report "INFO: Starting memory write operation."
                        --    severity note;

                        mem_addr <= cpu_sample_addr;
                        mem_data <= cpu_sample_data;
                        mem_access <= '1';
                        mem_write <= '1';
                        mem_write_operation := true;

                    end if;

                end if cpu_write_operation_branches;

            elsif cpu_access = '1' then

                --assert false
                --    report "INFO: Cache access detected."
                --    severity note;

                assert( ( to_integer( cpu_addr ) mod 4 ) = 0 )
                    report "ERROR: Given CPU address not word-aligned."
                    severity error;

                assert( ( to_integer( cpu_addr ) >= MIN_ADDR_NAT ) and
                        ( to_integer( cpu_addr ) <= MAX_ADDR_NAT ) )
                    report "ERROR: Given CPU address not within memory bounds."
                    severity error;

                if cpu_write = '0' then

                    cpu_sample_addr := cpu_addr;
                    cpu_read_operation := true;

                    --assert false
                    --    report "INFO: Starting cache read operation."
                    --    severity note;

                else

                    cpu_sample_addr := cpu_addr;
                    cpu_sample_data := cpu_data;
                    cpu_write_operation := true;
                    
                    --assert false
                    --    report "INFO: Starting cache write operation."
                    --    severity note;

                end if;

            end if cache_operation_branches;

        -- Pull down status indicators on second half of clock cycle
        else

            cpu_data <= WEAK_WORD;
            cpu_ready <= '0';
            mem_data <= WEAK_WORD;
            mem_access <= '0';
            mem_write <= '0';

        end if;

    end process;

end architecture cache_behav;
