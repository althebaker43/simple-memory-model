--! @file datapath.vhdl
--! @brief File containing datapath entity and structural architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--! @brief Datapath entity
entity datapath is

    port( en            : in std_logic;     --! Input signal to activate datapath
          reset         : in std_logic;     --! Input signal to reset CPU within datapath
          addr_instr    : out addr;         --! Output address of instructin CPU is currently fetching
          access_instr  : out std_logic;    --! Output indicator for CPU instruction fetching
          instr_hit     : out std_logic;    --! Output indicator for instruction cache hits
          data_hit      : out std_logic     --! Output indicator for data cache hits
        );

end entity datapath;


--! @brief Datapath structural architecture
architecture datapath_struct of datapath is

    --! Global clock signal
    signal clk              : std_logic;
    

    --! Address of instruction being fetched by CPU
    signal cpu_addr_instr   : addr;

    --! Instruction being fetched by CPU
    signal cpu_instr        : word;

    --! Indicator for instruction memory access by CPU
    signal cpu_access_instr : std_logic;

    --! Indicator for write/read access to instruction memory by CPU (not used)
    signal cpu_write_instr  : std_logic;

    --! Indicator to CPU that instruction is ready
    signal cpu_ready_instr  : std_logic;
    
    --! Address of instruction being fetched from main memory
    signal mem_addr_instr   : addr;

    --! Instruction being fetched from main memory
    signal mem_instr        : word;

    --! Indicator for access to instructions in main memory
    signal mem_access_instr : std_logic;

    --! Indicator for write/read access to instructions in main memory (not used)
    signal mem_write_instr  : std_logic;

    --! Indicator from main memory that instruction is ready
    signal mem_ready_instr  : std_logic;

    --! Address of data word being fetched by CPU
    signal cpu_addr_data   : addr;

    --! Instruction being fetched by CPU
    signal cpu_data        : word;

    --! Indicator for data word memory access by CPU
    signal cpu_access_data : std_logic;

    --! Indicator for write/read access to data word memory by CPU (not used)
    signal cpu_write_data  : std_logic;

    --! Indicator to CPU that data word is ready
    signal cpu_ready_data  : std_logic;
    
    --! Address of data word being fetched from main memory
    signal mem_addr_data   : addr;

    --! Instruction being fetched from main memory
    signal mem_data        : word;

    --! Indicator for access to data words in main memory
    signal mem_access_data : std_logic;

    --! Indicator for write/read access to data words in main memory (not used)
    signal mem_write_data  : std_logic;

    --! Indicator from main memory that data word is ready
    signal mem_ready_data  : std_logic;

    --! Total size of instruction cache in bytes
    constant INSTR_CACHE_SIZE : positive := 256;

    --! Lower memory address to be covered by instruction cache
    constant INSTR_MIN_ADDR : addr := X"00_00_00_00";

    --! Upper memory address to be covered by instruction cache
    constant INSTR_MAX_ADDR : addr := X"00_00_01_FC";

    --! Total size of data cache in bytes
    constant DATA_CACHE_SIZE : positive := 128;

    --! Lower memory address to be covered by data cache
    constant DATA_MIN_ADDR : addr := X"00_00_02_00";
    
    --! Upper memory address to be covered by data cache
    constant DATA_MAX_ADDR : addr := X"00_00_03_FC";
    
    constant NOP_RANGE_MIN : addr := X"00_00_00_00"; --!< Minimum address from which to fetch NOP instructions
    constant NOP_RANGE_MAX : addr := X"00_00_00_7C"; --!< Maximum address from which to fetch NOP instructions
    constant LW_RANGE_MIN  : addr := X"00_00_00_80"; --!< Minimum address from which to fetch LW instructions
    constant LW_RANGE_MAX  : addr := X"00_00_00_BC"; --!< Maximum address from which to fetch LW instructions
    constant SW_RANGE_MIN  : addr := X"00_00_00_C0"; --!< Minimum address from which to fetch SW instructions
    constant SW_RANGE_MAX  : addr := X"00_00_00_FC"; --!< Maximum address from which to fetch SW instructions
    constant ADD_RANGE_MIN : addr := X"00_00_01_00"; --!< Minimum address from which to fetch ADD instructions
    constant ADD_RANGE_MAX : addr := X"00_00_01_3C"; --!< Maximum address from which to fetch ADD instructions
    constant BEQ_RANGE_MIN : addr := X"00_00_01_40"; --!< Minimum address from which to fetch BEQ instructions
    constant BEQ_RANGE_MAX : addr := X"00_00_01_7C"; --!< Maximum address from which to fetch BEQ instructions
    constant BNE_RANGE_MIN : addr := X"00_00_01_80"; --!< Minimum address from which to fetch BNE instructions
    constant BNE_RANGE_MAX : addr := X"00_00_01_BC"; --!< Maximum address from which to fetch BNE instructions
    constant LUI_RANGE_MIN : addr := X"00_00_01_C0"; --!< Minimum address from which to fetch LUI instructions
    constant LUI_RANGE_MAX : addr := X"00_00_01_FC"; --!< Maximum address from which to fetch LUI instructions

begin

    cpu_write_instr <= '0';

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
        generic map( NOP_RANGE_MIN, NOP_RANGE_MAX,
                     LW_RANGE_MIN,  LW_RANGE_MAX,
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

    --! @brief Instruction access process
    --!
    --! @details
    --! This process forwards the instruction memory indicator and instruction
    --! address values from the CPU to the datapath output ports when they
    --! become active
    instr_access : process( cpu_access_instr ) is
    begin

        if cpu_access_instr = '1' then
            addr_instr <= cpu_addr_instr;
        else
            addr_instr <= NULL_ADDR;
        end if;

        access_instr <= cpu_access_instr;

    end process instr_access;

end architecture datapath_struct;
