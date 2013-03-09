--! @file misc.vhdl
--! @brief File containing miscellaneous datapath components and definitions
--!
--! @todo Add clock generator

library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

package datapath_types is

    constant addr_size : positive := 32;
    constant word_size : positive := 32;

    subtype addr is unsigned( ( addr_size - 1 ) to 0 );
    subtype word is signed( ( word_size - 1 ) to 0 );

end package datapath_types;
