--! @file cache.vhdl
--! @brief File containing Cache entity and behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;

--! @brief Cache entity
entity cache is
    port( clk_in : in std_logic;
          addr_in : in addr;
          data_in : in word;
          addr_out : out addr;
          data_out : out word );
end entity cache;

--! @brief Cache behavioral architecture
architecture cache_behav of cache is
begin
end architecture cache_behav;
