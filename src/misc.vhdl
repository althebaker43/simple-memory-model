--! @file misc.vhdl
--! @brief File containing miscellaneous datapath components and definitions

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package datapath_types is

    constant CLK_PERIOD : time := 10 ns;

    constant ADDR_SIZE : positive := 32;
    constant WORD_SIZE : positive := 32;

    subtype addr is unsigned( ( ADDR_SIZE - 1 ) downto 0 );
    subtype word is signed( ( WORD_SIZE - 1 ) downto 0 );

    constant NULL_ADDR    : addr := B"00000000_00000000_00000000_00000000";
    constant NULL_WORD    : word := B"00000000_00000000_00000000_00000000";

    function WEAK_WORD return word;

    constant MEM_SIZE : positive := 1024;

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

end package datapath_types;

package body datapath_types is

    function WEAK_WORD return word is

        variable weak_word : word;

    begin

        for word_indx in weak_word'range loop
            weak_word( word_indx ) := 'H';
        end loop;

        return weak_word;

    end function;

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
