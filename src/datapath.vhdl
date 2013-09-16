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


--! @mainpage Simple Memory Hierarcy Project
--!
--! @section intro_sec Introduction
--!
--! The purpose of this project was to give students the opportunity to
--! exercise their knowledge about computer architectures by giving them the
--! task of constructing and testing a memory hierarchy using the VHDL hardware
--! description language. The memory hierarchy is to include a CPU, one or more
--! caches, and a main memory. Test results showing the proper operation of the
--! datapath should be provided along with the sources to the component designs
--! in the final deliverable.
--!
--! @section design_sec Design and Implementation
--! 
--! The overall design of the heirarchy is split into three main parts: the
--! CPU, the caches, and the main memory. A graphical overview of is provided
--! below.
--! 
--! @subsection cpu_design_sec CPU Design and Implementation
--!
--! The CPU is implemented as one large behavioral architecture. Its interfaces
--! include separate data and address buses, each 32 bits wide, for
--! instructions and data. There are also separate instruction and data memory
--! access indicators and input ports for "ready" signals from the cache.
--! Whenever the CPU needs to access instructions or data, it will first raise
--! the appropriate access signal and provide an address and, if necessary,
--! data on the appropriate ports for one clock cycle. Afterwards, the CPU will
--! block its internal operations until the memory request has completed and
--! the appropriate ready signal is raised. The CPUs interfaces also include
--! a clock input signal and a reset signal to restor the Program Counter to
--! zero for testing purposes.
--!
--! @subsection cache_design_sec Cache Design
--!
--! Both the instruction cache and data cache are implemented in one large
--! behavioral archicture and declared as separate entities within the top
--! datapath source. The cache design is symmetrical due to the face that it
--! provides the same address, data, and indicator ports to both the CPU and
--! the memory. During fetching operations, the cache will take an address from
--! the CPU and look it up in its internal block array. If a miss occurs, then
--! the address is forwarded to the main memory and the main memory access
--! indicator is raised. The cache must then wait for the entire block
--! containing the needed data to be provided before it can store it internally
--! and then forward it to the CPU. Since the write-miss scheme used here is
--! no-write-allocate, a write-miss results in only the word being written to
--! the memory without reading the entire containing block back into the cache.
--! In addition to the conventional address, data, and indicator ports, the
--! cache also includes a hit indicator output signal that is pulsed whenever
--! a read hit or write hit occurs.
--!
--! @subsection mem_design_sec Memory Design and Implementation
--!
--! The memory design is relatively straightforward. A single memory entity
--! contains access ports for both instruction and data sections, and
--! instruction and data requests can be served concurrently. Instructions of
--! different types are provided upon request depending on the address of the
--! request and the type address boundaries provided as parameters to the
--! entity. The delays for carrying out reading and writing operations are
--! implemented as internal constants.
--!
--! @subsection misc_design_sec Miscellaneous Component Design and Implementation
--!
--! A separate file contains miscellaneous constants, data types, and functions
--! that may be utilized by any of the main hierarcy components. Also included
--! entity and architecure for the global clock generator that provides a clock
--! signal to the components and keeps them in sync.
--!
--! @section test_sec Testing
--!
--! Basic testing was done using VHDL testbenches both seperately for each
--! major component and finally as whole hierarchy. Value change dump (VCD)
--! output files were collected for each test and used to generate waveforms to
--! provide visual verification in addition to assertion statements written
--! within the testbenches themselves.
--!
--! @subsection cpu_test_sec CPU Testing
--!
--! The first test written for the CPU prior to any actual design code being
--! written was a basic test to verify that the Program Counter incremented
--! properly after exectuting an instruction. This was done by comparing the
--! instruction address output port values with each other over time.
--!
--! This test was then followed by tests written to verify the correct memory
--! access procedures taken whenever the CPU processes a "Load Word" or "Store
--! Word" instruction. After feeding the CPU the instruction, its access
--! indicators were monitored to ensure that the CPU requested read-only memory
--! access after being given a "Load Word" instruction and write-only memory
--! access after a "Store Word" instruction.
--! 
--! @subsection cache_test_sec Cache Testing
--! 
--! The cache behavioral architecture test procedures basically ensured that
--! data was stored properly and could be read out again upon request. For the
--! first tests, only the first block of the cache was used to verify that free
--! blocks were properly filled upon the very first read miss. The following
--! waveforms show the missed write request being forwarded to memory and the
--! containing block being read into the cache for the following read miss.
--!
--! The next series of tests verified that block replacement was properly done
--! when another block from memory needed to occupy the cache were a dirty
--! block was present. The following waveforms show the initial CPU request
--! followed by the dirty block being written into memory before the desired
--! block is read into the cache.
--!
--! Finally, tests were done on the other cache block placements to ensure that
--! different sections of memory were assigned to the correct sections within
--! the cache. The final waveform shows a read miss pattern without a dirty
--! block being written into memory first, which indicates that the new block
--! is being written into another free block placement.
--! 
--! @subsection mem_test_sec Memory Testing
--!
--! The instruction and data sections of main memory were tested separately.
--! First, tests were carried out to ensure that the provided instruction type
--! boundaries were properly enforced. The following waveform images show the
--! appropriate instruction templates begin provided by memory following
--! a request to the corresponding section.
--!
--! Afterwards, basic data retention tests were conducted on the data section
--! of main memory to ensure that a word of data previously stored could be
--! retrieved later on by a subsequent read-only access. The following waveform
--! shows the same word being written to and then read out of memory.
--!
--! @subsection datapth_test_sec Datapath Testing
--!
--! After all of the major components were seperately designed and tested, they
--! were then instantiated as entites within an encompassing datapath
--! structural architecture. The corresponding testbench then simply acitvated
--! the enable signal and verified that the CPU was able to conduct basic
--! sequential operation, which is displayed in the waveform below.
--!
--!
