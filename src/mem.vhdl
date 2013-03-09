--! @file mem.vhdl
--! @brief File containing memory entity and behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;

--! @brief Memory entity
entity mem is
    port( clk_in : in std_logic;
          addr_in : in addr;
          data_in : in word;
          addr_out : out addr;
          data_out : out word );
end entity mem;

--! @brief Memory behavioral architecture
architecture mem_behav of mem is
begin
end architecture mem_behav;
