--! @file mem.vhdl
--! @brief File containing memory entity and behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

--! @brief Memory entity
entity mem is

    generic( nop_range_min : addr; nop_range_max : addr;
             lw_range_min  : addr; lw_range_max  : addr;
             sw_range_min  : addr; sw_range_max  : addr;
             add_range_min : addr; add_range_max : addr;
             beq_range_min : addr; beq_range_max : addr;
             bne_range_min : addr; bne_range_max : addr;
             lui_range_min : addr; lui_range_max : addr );

    port( clk_in        : in std_logic;     --!< Clock signal
          addr_data     : in addr;          --!< Input address for data access
          data          : inout word;       --!< Input or output data word
          access_data   : in std_logic;     --!< Input signal that triggers start of data access operation
          write_data    : in std_logic;     --!< Input signal that indicates if the data operation is a read or write
          ready_data    : out std_logic;    --!< Output signal that indicates when data is ready for read operations
          addr_instr    : in addr;          --!< Input address for instruction access
          instr         : out word;         --!< Output instruction word
          access_instr  : in std_logic;     --!< Input signal that triggers start of instruction access operation
          ready_instr   : out std_logic     --!< Output signal that indicates when instruction is ready for read operation
        );

end entity mem;

--! @brief Memory behavioral architecture
--!
--! @details
--!
--! The memory is to have the following characteristics:
--!
--! @li Total size is 1024 bytes
--! @li Read access time: 5 cycles/word
--! @li Write access time: 3 cycles/word
--! @li Additional read time: 3 cycles/word
--! @li Additional write time: 4 cycles/word
--! @li Split evenly between program and data space
--! @li Variable address ranges for different instruction types
architecture mem_behav of mem is

    constant INSTR_RANGE_MIN : addr := X"00_00_00_00";
    constant INSTR_RANGE_MAX : addr := X"00_00_01_FC";
    constant DATA_RANGE_MIN : addr  := X"00_00_02_00";
    constant DATA_RANGE_MAX : addr  := X"00_00_03_FC";

    type storage is array ( 128 to 255 ) of word;

    constant READ_ACCESS_DELAY : natural := 5;  --!< Read access delay per word
    constant READ_ADDNL_DELAY : natural := 3;   --!< Read additional delay per word
    constant WRITE_ACCESS_DELAY : natural := 3; --!< Write access delay per word
    constant WRITE_ADDNL_DELAY : natural := 4;  --!< Write additional delay per word

begin

    operate : process( clk_in ) is

        variable read_instr_operation : boolean := false;
        variable read_instr_addr : addr;
        variable read_data_countdown : natural := READ_ACCESS_DELAY + READ_ADDNL_DELAY;

        variable read_data_operation : boolean := false;
        variable read_data_pos : integer;
        variable read_instr_countdown : natural := READ_ACCESS_DELAY + READ_ADDNL_DELAY;

        variable write_data_operation : boolean := false;
        variable write_data_pos : integer;
        variable write_data_input : word;
        variable write_data_countdown : natural := WRITE_ACCESS_DELAY + WRITE_ADDNL_DELAY;

        variable storage_var : storage;

        function get_random_instr( addr_instr : in addr ) return word is

            variable random_instr : word := NULL_WORD;
            variable template : word := NULL_WORD;
            variable rs : word := NULL_WORD;
            variable rt : word := NULL_WORD;

        begin

            if ( ( addr_instr >= nop_range_min ) and
                 ( addr_instr <= nop_range_max ) ) then
                template := INSTR_NOP;

            elsif ( ( addr_instr >= lw_range_min ) and
                 ( addr_instr <= lw_range_max ) ) then
                template := LW_TEMPLATE;

            elsif ( ( addr_instr >= sw_range_min ) and
                    ( addr_instr <= sw_range_max ) ) then
                template := SW_TEMPLATE;

            elsif ( ( addr_instr >= add_range_min ) and
                    ( addr_instr <= add_range_max ) ) then
                template := ADD_TEMPLATE;

            elsif ( ( addr_instr >= beq_range_min ) and
                    ( addr_instr <= beq_range_max ) ) then
                template := BEQ_TEMPLATE;

            elsif ( ( addr_instr >= bne_range_min ) and
                    ( addr_instr <= bne_range_max ) ) then
                template := BNE_TEMPLATE;

            elsif ( ( addr_instr >= lui_range_min ) and
                    ( addr_instr <= lui_range_max ) ) then
                template := LUI_TEMPLATE;

            else
                template := NULL_WORD;

            end if;

            --rs := ( to_signed( rand, WORD_SIZE ) sll INSTR_RS_POS ) and INSTR_RS_MASK;
            --rt := ( to_signed( rand, WORD_SIZE ) sll INSTR_RT_POS ) and INSTR_RT_MASK;

            random_instr := random_instr or template;
            random_instr := random_instr or rs;
            random_instr := random_instr or rt;

            return random_instr;

        end function;

    begin

        if clk_in = '1' then

            if read_instr_operation = true then

                if read_instr_countdown = 0 then

                    instr <= get_random_instr( read_instr_addr );
                    ready_instr <= '1';
                    read_instr_operation := false;

                else

                    read_instr_countdown := read_instr_countdown - 1;
                    instr <= NULL_WORD;
                    ready_instr <= '0';

                end if;

            else

                instr <= NULL_WORD;
                ready_instr <= '0';

            end if;

            if read_data_operation = true then

                if read_data_countdown = 0 then

                    data <= storage_var( read_data_pos );
                    ready_data <= '1';
                    read_data_operation := false;

                else

                    read_data_countdown := read_data_countdown - 1;
                    data <= WEAK_WORD;
                    ready_data <= '0';

                end if;

            elsif write_data_operation = true then

                if write_data_countdown = 0 then

                    storage_var( write_data_pos ) := write_data_input;
                    ready_data <= '1';
                    write_data_operation := false;

                else

                    write_data_countdown := write_data_countdown - 1;
                    data <= WEAK_WORD;
                    ready_data <= '0';

                end if;

            else

                data <= WEAK_WORD;
                ready_data <= '0';

            end if;

        else

            if access_instr = '1' then

                read_instr_operation := true;
                read_instr_addr := addr_instr;
                read_instr_countdown := READ_ACCESS_DELAY + READ_ADDNL_DELAY;

            end if;

            if access_data = '1' then

                if write_data = '1' then

                    write_data_operation := true;
                    write_data_pos := to_integer( addr_data srl 2 );
                    write_data_input := data;
                    write_data_countdown := WRITE_ACCESS_DELAY + WRITE_ADDNL_DELAY;

                else

                    read_data_operation := true;
                    read_data_pos := to_integer( addr_data srl 2 );
                    read_data_countdown := READ_ACCESS_DELAY + READ_ADDNL_DELAY;

                end if;

            end if;

        end if;

    end process operate;

end architecture mem_behav;
