--! @file cpu.vhdl
--! @brief File containing 32-bit CPU entity and behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;

--! @brief 32-bit CPU entity
entity cpu is
    port( instr_in,
          data_in : in word;
          clk_out : out std_logic;
          addr_out : out addr;
          data_out : out word );
end entity cpu;

--! @brief 32-bit CPU behavioral architecture
architecture cpu_behav of cpu is
begin
end architecture cpu_behav;
