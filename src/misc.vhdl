--! @file misc.vhdl
--! @brief File containing miscellaneous datapath components and definitions

library std;
use std.textio.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package datapath_types is

    --! Cycle time of global clock
    constant CLK_PERIOD : time := 10 ns;

    --! Size of an address in bits
    constant ADDR_SIZE : positive := 32;

    --! Size of a word in bits
    constant WORD_SIZE : positive := 32;

    --! Size of a word in bytes
    constant WORD_BYTE_SIZE : positive := WORD_SIZE / 8;

    --! Address subtype
    subtype addr is unsigned( ( ADDR_SIZE - 1 ) downto 0 );

    --! Data word subtype
    subtype word is signed( ( WORD_SIZE - 1 ) downto 0 );

    --! Null value for address
    constant NULL_ADDR    : addr := B"00000000_00000000_00000000_00000000";

    --! Null value for data word
    constant NULL_WORD    : word := B"00000000_00000000_00000000_00000000";

    --! @brief Weak-high value for word
    --! 
    --! @details
    --! The returned value is used to allow data to be read from inout ports
    function WEAK_WORD return word;

    --! @brief Returns the value of a substring of an address
    function get_addr_substring_value( sample_addr  : in addr;
                                       start_indx   : in natural;
                                       num_bits     : in positive ) return natural;

    --! Total size of memory in bytes
    constant MEM_SIZE : positive := 1024;

    --! No-operation instruction
    constant INSTR_NOP : word := B"111111_00000_00000_0000000000000000";

    constant LW_TEMPLATE  : word := B"100011_00000_00000_0000000000000000";
    constant SW_TEMPLATE  : word := B"101011_00000_00000_0000000000000000";
    constant ADD_TEMPLATE : word := B"000000_00000_00000_00000_00000_100000";
    constant BEQ_TEMPLATE : word := B"000100_00000_00000_0000000000000000";
    constant BNE_TEMPLATE : word := B"000101_00000_00000_0000000000000000";
    constant LUI_TEMPLATE : word := B"100100_00000_00000_0000000000000000";

    constant INSTR_OP_MASK : word       := B"111111_00000_00000_0000000000000000";
    constant INSTR_RS_MASK : word       := B"000000_11111_00000_0000000000000000";
    constant INSTR_RT_MASK : word       := B"000000_00000_11111_0000000000000000";
    constant INSTR_IMMED_MASK : word    := B"000000_00000_00000_1111111111111111";
    constant INSTR_RD_MASK : word       := B"000000_00000_00000_11111_00000_000000";
    constant INSTR_SHMT_MASK : word     := B"000000_00000_00000_00000_11111_000000";
    constant INSTR_FUNCT_MASK : word    := B"000000_00000_00000_00000_00000_111111";
    
    constant INSTR_RS_POS : natural     := 21;
    constant INSTR_RT_POS : natural     := 16;
    constant INSTR_IMMED_POS : natural  := 0;
    constant INSTR_RD_RD_POS : natural  := 11;
    constant INSTR_SHMT_POS : natural   := 6;
    constant INSTR_FUNCT_POS : natural  := 0;

    constant INSTR_RS_SIZE : natural    := 5;
    constant INSTR_RT_SIZE : natural    := 5;
    constant INSTR_IMMED_SIZE : natural := 16;
    constant INSTR_RD_SIZE : natural    := 5;
    constant INSTR_SHMT_SIZE : natural  := 5;
    constant INSTR_FUNCT_SIZE : natural := 6;

    procedure println( print_string : in string );

end package datapath_types;

package body datapath_types is

    function WEAK_WORD return word is

        variable weak_word : word;

    begin

        for word_indx in weak_word'range loop
            weak_word( word_indx ) := 'H';
        end loop;

        return weak_word;

    end function WEAK_WORD;
        

    function get_addr_substring_value( sample_addr  : in addr;
                                       start_indx   : in natural;
                                       num_bits     : in positive ) return natural is

        variable mask_addr : addr := NULL_ADDR;
        variable end_indx : natural := start_indx + num_bits - 1;
        variable masked_result : addr := NULL_ADDR;

        variable result : natural := 0;

    begin

        for mask_addr_indx in start_indx to end_indx loop
            mask_addr( mask_addr_indx ) := '1';
        end loop;

        masked_result := mask_addr and sample_addr;

        result := to_integer( masked_result srl start_indx );

        return result;

    end function get_addr_substring_value;

    
    procedure println( print_string : in string ) is

        variable print_line : line;

    begin

        write( print_line, print_string );
        writeline( OUTPUT, print_line );

    end println;

end package body;


use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clk_gen is
    port( clk : out std_logic;
          en  : in std_logic );
end entity clk_gen;

architecture clk_gen_behav of clk_gen is 
begin

    clock : process is
    begin

        wait on en;

        while en = '1' loop
            clk <= '1';
            wait for ( CLK_PERIOD / 2 );
            clk <= '0';
            wait for ( CLK_PERIOD / 2 );
        end loop;

        wait;

    end process clock;

end architecture clk_gen_behav;
