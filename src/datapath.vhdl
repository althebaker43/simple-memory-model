--! @file datapath.vhdl
--! @brief File containing 32-bit datapath entity and structural architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--! @brief 32-bit datapath entity
entity datapath is

    port( en        : in std_logic;
          reset     : in std_logic;
          addr_instr: out addr;
          instr_hit : out std_logic;
          data_hit  : out std_logic
        );

end entity datapath;


--! @brief 32-bit datapath structural architecture
architecture datapath_struct of datapath is

    signal clk              : std_logic;
    
    signal cpu_addr_instr   : addr;
    signal cpu_instr        : word;
    signal cpu_access_instr : std_logic;
    signal cpu_write_instr  : std_logic;
    signal cpu_ready_instr  : std_logic;
    
    signal mem_addr_instr   : addr;
    signal mem_instr        : word;
    signal mem_access_instr : std_logic;
    signal mem_write_instr  : std_logic;
    signal mem_ready_instr  : std_logic;
    
    signal cpu_addr_data    : addr;
    signal cpu_data         : word;
    signal cpu_access_data  : std_logic;
    signal cpu_write_data   : std_logic;
    signal cpu_ready_data   : std_logic;
    
    signal mem_addr_data    : addr;
    signal mem_data         : word;
    signal mem_access_data  : std_logic;
    signal mem_write_data   : std_logic;
    signal mem_ready_data   : std_logic;

    constant INSTR_CACHE_SIZE : positive := 256;
    constant INSTR_MIN_ADDR : addr := X"00_00_00_00";
    constant INSTR_MAX_ADDR : addr := X"00_00_01_FC";

    constant DATA_CACHE_SIZE : positive := 128;
    constant DATA_MIN_ADDR : addr := X"00_00_02_00";
    constant DATA_MAX_ADDR : addr := X"00_00_03_FC";
    
    constant LW_RANGE_MIN  : addr := X"00_00_02_00";
    constant LW_RANGE_MAX  : addr := X"00_00_02_3C";
    constant SW_RANGE_MIN  : addr := X"00_00_02_40";
    constant SW_RANGE_MAX  : addr := X"00_00_02_7C";
    constant ADD_RANGE_MIN : addr := X"00_00_02_80";
    constant ADD_RANGE_MAX : addr := X"00_00_02_BC";
    constant BEQ_RANGE_MIN : addr := X"00_00_02_C0";
    constant BEQ_RANGE_MAX : addr := X"00_00_02_FC";
    constant BNE_RANGE_MIN : addr := X"00_00_03_00";
    constant BNE_RANGE_MAX : addr := X"00_00_03_3C";
    constant LUI_RANGE_MIN : addr := X"00_00_03_40";
    constant LUI_RANGE_MAX : addr := X"00_00_03_FC";

begin

    clk_gen_ent : entity work.clk_gen( clk_gen_behav )
        port map( clk,
                  en );

    cpu_ent : entity work.cpu( cpu_behav )
        port map( clk,
                  reset,
                  cpu_addr_instr,
                  cpu_instr,
                  cpu_access_instr,
                  cpu_ready_instr,
                  cpu_addr_data,
                  cpu_data,
                  cpu_access_data,
                  cpu_write_data,
                  cpu_ready_data );

    instr_cache_ent : entity work.cache( cache_behav )
        generic map( INSTR_CACHE_SIZE,
                     INSTR_MIN_ADDR,
                     INSTR_MAX_ADDR )
        port map( clk,
                  cpu_addr_instr,
                  cpu_instr,
                  cpu_access_instr,
                  cpu_write_instr,
                  cpu_ready_instr,
                  mem_addr_instr,
                  mem_instr,
                  mem_access_instr,
                  mem_write_instr,
                  mem_ready_instr,
                  instr_hit );

    data_cache_ent : entity work.cache( cache_behav )
        generic map( DATA_CACHE_SIZE,
                     DATA_MIN_ADDR,
                     DATA_MAX_ADDR )
        port map( clk,
                  cpu_addr_data,
                  cpu_data,
                  cpu_access_data,
                  cpu_write_data,
                  cpu_ready_data,
                  mem_addr_data,
                  mem_data,
                  mem_access_data,
                  mem_write_data,
                  mem_ready_data,
                  data_hit );

    mem_ent : entity work.mem( mem_behav )
        generic map( LW_RANGE_MIN,  LW_RANGE_MAX,
                     SW_RANGE_MIN,  SW_RANGE_MAX,
                     ADD_RANGE_MIN, ADD_RANGE_MAX,
                     BEQ_RANGE_MIN, BEQ_RANGE_MAX,
                     BNE_RANGE_MIN, BNE_RANGE_MAX,
                     LUI_RANGE_MIN, LUI_RANGE_MAX )
        port map( clk,
                  mem_addr_data,
                  mem_data,
                  mem_access_data,
                  mem_write_data,
                  mem_ready_data,
                  mem_addr_instr,
                  mem_instr,
                  mem_access_instr,
                  mem_ready_instr );

    operate : process( clk ) is
    begin

    end process operate;

end architecture datapath_struct;