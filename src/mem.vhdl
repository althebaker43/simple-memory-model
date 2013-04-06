--! @file mem.vhdl
--! @brief File containing memory entity and behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;

--! @brief Memory entity
entity mem is

    generic( lw_range_min  : addr; lw_range_max  : addr;
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
          addr_instr    : out addr;         --!< Input address for instruction access
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

    constant READ_ACCESS_DELAY : natural := 5;  --!< Read access delay per word
    constant READ_ADDNL_DELAY : natural := 3;   --!< Read additional delay per word
    constant WRITE_ACCESS_DELAY : natural := 3; --!< Write access delay per word
    constant WRITE_ADDNL_DELAY : natural := 4;  --!< Write additional delay per word

begin

    operate : process( clk_in ) is

        variable read_instr_operation : boolean := false;
        variable read_data_countdown : natural := READ_ACCESS_DELAY + READ_ADDNL_DELAY;

        variable read_data_operation : boolean := false;
        variable read_instr_countdown : natural := READ_ACCESS_DELAY + READ_ADDNL_DELAY;

        variable write_data_operation : boolean := false;
        variable write_data_countdown : natural := WRITE_ACCESS_DELAY + WRITE_ADDNL_DELAY;

    begin

        if clk_in = '1' then

            if read_instr_operation = true then

                if read_instr_countdown = 0 then
                    instr <= LW_TEMPLATE;
                    ready_instr <= '1';
                    read_instr_operation := false;
                    read_instr_countdown := READ_ACCESS_DELAY + READ_ADDNL_DELAY;
                else
                    read_instr_countdown := read_instr_countdown - 1;
                end if;

            elsif( access_instr = '1' ) then

                read_instr_operation := true;
                ready_instr <= '0';

            end if;


            if read_data_operation = true then

                if read_data_countdown = 0 then
                    data <= NULL_WORD;
                    ready_data <= '1';
                    read_data_operation := false;
                    read_data_countdown := READ_ACCESS_DELAY + READ_ADDNL_DELAY;
                else
                    read_data_countdown := read_data_countdown - 1;
                end if;

            elsif write_data_operation = true then

                if write_data_countdown = 0 then
                    ready_data <= '1';
                    write_data_operation := false;
                    write_data_countdown := WRITE_ACCESS_DELAY + WRITE_ADDNL_DELAY;
                else
                    write_data_countdown := write_data_countdown - 1;
                end if;

            elsif access_data = '1' then

                if write_data = '1' then
                    write_data_operation := true;
                else
                    read_data_operation := false;
                end if;

                ready_data <= '0';

            end if;

        end if;

    end process operate;

end architecture mem_behav;
