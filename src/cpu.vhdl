--! @file cpu.vhdl
--! @brief File containing CPU entity and behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--! @brief CPU entity
entity cpu is
    port( clk           : in std_logic;     --! Input clock signal

          reset         : in std_logic;     --! Input CPU reset signal

          addr_instr    : out addr;         --! Ouput address of instruction to fetch
          instr         : in word;          --! Input instruction being fetched
          access_instr  : out std_logic;    --! Output instruction memory access indicator
          ready_instr   : in std_logic;     --! Input instruction memory operation-complete indicator

          addr_data     : out addr;         --! Ouput address of data to load or store
          data          : inout word;       --! Bi-directional data to load or store
          access_data   : out std_logic;    --! Ouput data memory access indicator
          write_data    : out std_logic;    --! Output write/read data memory indicator
          ready_data    : in std_logic      --! Input data memory operation-complete indicator
        );

end entity cpu;

--! @brief CPU behavioral architecture
architecture cpu_behav of cpu is

    --! Subtype for different CPU operation modes
    subtype cpu_mode is positive range 1 to 6;
    
    --! Indicates that the CPU is in Instruction Fetch mode
    constant CPU_MODE_INSTR_FETCH   : cpu_mode := 1;
    
    --! Indicates that the CPU is in Instruction Decode mode
    constant CPU_MODE_INSTR_DECODE  : cpu_mode := 2;
    
    --! Indicates that the CPU is in Execution mode
    constant CPU_MODE_EXECUTE       : cpu_mode := 3;
    
    --! Indicates that the CPU is in Memory Modify mode
    constant CPU_MODE_MEMORY_MODIFY : cpu_mode := 4;
    
    --! Indicates that the CPU is in Write Back mode
    constant CPU_MODE_WRITE_BACK    : cpu_mode := 5;
    
    --! Indicates that the CPU is in Reset mode
    constant CPU_MODE_RESET         : cpu_mode := 6;

    --! Subtype for different instruction-type modes
    subtype instr_mode is positive range 1 to 7;

    --! Indicates that the CPU is currently processing a Load Word instruction
    constant INSTR_MODE_LW : instr_mode := 1;

    --! Indicates that the CPU is currently processing a Store Word instruction
    constant INSTR_MODE_SW : instr_mode := 2;

    --! Indicates that the CPU is currently processing an Add Words instruction
    constant INSTR_MODE_ADD : instr_mode := 3;

    --! Indicates that the CPU is currently processing a Branch-if-Equal instruction
    constant INSTR_MODE_BEQ : instr_mode := 4;

    --! Indicates that the CPU is currently processing a Branch-if-Not-Equal instruction
    constant INSTR_MODE_BNE : instr_mode := 5;

    --! Indicates that the CPU is currently processing a Load Upper-Immediate instruction
    constant INSTR_MODE_LUI : instr_mode := 6;

    --! Indicates that the CPU is currently processing a No-Operation instruction
    constant INSTR_MODE_NOP : instr_mode := 7;

    --! Total number of general purpose data registers in CPU
    constant NUM_REGS : positive := 32;

    --! Word array type to represent the data register file
    type reg_file is array( 0 to ( NUM_REGS - 1 ) ) of word;

begin

    --! Main operation process for CPU
    operate : process( clk ) is

        -- Input sampling variables
        variable sample_instr : word := NULL_WORD;
        variable sample_ready_instr : std_logic := '0';
        variable sample_data : word := NULL_WORD;
        variable sample_ready_data : std_logic := '0';

        -- General purpose variables
        variable cur_cpu_mode : cpu_mode := CPU_MODE_RESET;
        variable pc_nat : natural := 0;
        variable cur_instr : word;
        variable cur_instr_mode : instr_mode := INSTR_MODE_NOP;
        variable reg_file_var : reg_file := ( others => NULL_WORD );

        -- Instruction Fetch Mode variables
        variable instr_request_placed : boolean := false;

        -- Instruction Decode Mode variables
        variable masked_instr : word := NULL_WORD;
        variable cur_rs_indx : natural := 0;
        variable cur_rt_indx : natural := 0;
        variable cur_immed_value : natural := 0;
        variable cur_rd_indx : natural := 0;
        variable cur_shmt_value : natural := 0;
        variable new_pc_addr_value : natural := 0;
        variable cur_rs_value : natural := 0;
        variable cur_rt_value : natural := 0;

        -- Execute variables
        variable final_addr_data_value : natural := 0;
        variable final_add_value : natural := 0;
        variable lui_word : word := NULL_WORD;

        -- Memory Modify variables
        variable final_addr_data : addr := NULL_ADDR;
        variable final_lw_data : word := NULL_WORD;
        variable final_sw_data : word := NULL_WORD;
        variable memory_modify_in_progress : boolean := false;

    begin

        if clk = '1' then

            case cur_cpu_mode is

                when CPU_MODE_INSTR_FETCH =>

                    if sample_ready_instr = '1' then

                        cur_instr := sample_instr;
                        pc_nat := pc_nat + WORD_BYTE_SIZE;
                        instr_request_placed := false;
                        cur_cpu_mode := CPU_MODE_INSTR_DECODE;
                    
                    elsif instr_request_placed = false then

                        addr_instr <= to_unsigned( pc_nat, ADDR_SIZE );
                        access_instr <= '1';
                        addr_data <= NULL_ADDR;
                        data <= WEAK_WORD;
                        access_data <= '0';
                        write_data <= '0'; 

                        instr_request_placed := true;

                    else

                        addr_instr <= NULL_ADDR;
                        access_instr <= '0';
                        addr_data <= NULL_ADDR;
                        data <= WEAK_WORD;
                        access_data <= '0';
                        write_data <= '0'; 

                    end if;


                when CPU_MODE_INSTR_DECODE =>

                    masked_instr := cur_instr and INSTR_OP_MASK;

                    cur_rs_indx := get_word_substring_value( cur_instr,
                                                             INSTR_RS_POS,
                                                             INSTR_RS_SIZE );

                    cur_rt_indx := get_word_substring_value( cur_instr,
                                                             INSTR_RT_POS,
                                                             INSTR_RT_SIZE );

                    cur_immed_value := get_word_substring_value( cur_instr,
                                                                 INSTR_IMMED_POS,
                                                                 INSTR_IMMED_SIZE );

                    cur_rd_indx := get_word_substring_value( cur_instr,
                                                             INSTR_RD_POS,
                                                             INSTR_RD_SIZE );

                    cur_shmt_value := get_word_substring_value( cur_instr,
                                                                INSTR_SHMT_POS,
                                                                INSTR_SHMT_SIZE );

                    instruction_decode_cases:
                    case masked_instr is

                        when LW_TEMPLATE =>
                            cur_instr_mode := INSTR_MODE_LW;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when SW_TEMPLATE =>
                            cur_instr_mode := INSTR_MODE_SW;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when BEQ_TEMPLATE =>
                            new_pc_addr_value := pc_nat + cur_immed_value;
                            cur_instr_mode := INSTR_MODE_BEQ;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when BNE_TEMPLATE =>
                            new_pc_addr_value := pc_nat + cur_immed_value;
                            cur_instr_mode := INSTR_MODE_BNE;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when LUI_TEMPLATE =>
                            cur_instr_mode := INSTR_MODE_LUI;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when NULL_WORD =>
                            if( ( cur_instr and INSTR_FUNCT_MASK ) = ADD_TEMPLATE ) then
                                cur_rs_value := to_integer( reg_file_var( cur_rs_indx ) );
                                cur_rt_value := to_integer( reg_file_var( cur_rt_indx ) );
                                cur_instr_mode := INSTR_MODE_ADD;
                                cur_cpu_mode := CPU_MODE_EXECUTE;
                            else
                                cur_cpu_mode := CPU_MODE_INSTR_FETCH;
                            end if;

                        when INSTR_NOP =>
                            cur_instr_mode := INSTR_MODE_NOP;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when others =>
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                    end case instruction_decode_cases;

                    addr_instr <= NULL_ADDR;
                    access_instr <= '0';
                    addr_data <= NULL_ADDR;
                    data <= WEAK_WORD;
                    access_data <= '0';
                    write_data <= '0'; 


                when CPU_MODE_EXECUTE =>

                    execute_cases:
                    case cur_instr_mode is

                        when INSTR_MODE_LW =>
                            final_addr_data_value := cur_rt_value + cur_immed_value;
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_SW =>
                            final_addr_data_value := cur_rt_value + cur_immed_value;
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_ADD =>
                            final_add_value := cur_rt_value + cur_rs_value;
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_BEQ =>
                            if( reg_file_var( cur_rs_indx ) = NULL_WORD ) then
                                pc_nat := pc_nat + cur_immed_value;
                            end if;
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                        when INSTR_MODE_BNE =>
                            if( not( reg_file_var( cur_rs_indx ) = NULL_WORD ) ) then
                                pc_nat := pc_nat + cur_immed_value;
                            end if;
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                        when INSTR_MODE_LUI =>
                            lui_word := to_signed( cur_immed_value, WORD_SIZE );
                            reg_file_var( cur_rt_indx ) := to_signed( cur_rt_value, WORD_SIZE ) or lui_word;
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_NOP =>  
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                    end case execute_cases;

                    addr_instr <= NULL_ADDR;
                    access_instr <= '0';
                    addr_data <= NULL_ADDR;
                    data <= WEAK_WORD;
                    access_data <= '0';
                    write_data <= '0'; 


                when CPU_MODE_MEMORY_MODIFY =>

                    final_addr_data := to_unsigned( final_addr_data_value, WORD_SIZE );

                    memory_modify_cases:
                    case cur_instr_mode is

                        when INSTR_MODE_LW =>
                            
                            if( memory_modify_in_progress = false ) then

                                memory_modify_in_progress := true;
                                
                                addr_instr <= NULL_ADDR;
                                access_instr <= '0';
                                addr_data <= final_addr_data;
                                data <= WEAK_WORD;
                                access_data <= '1';
                                write_data <= '0'; 

                            else

                                if( sample_ready_data = '1' ) then

                                    final_lw_data := sample_data;
                                    memory_modify_in_progress := false;
                                    cur_cpu_mode := CPU_MODE_WRITE_BACK;

                                end if;

                                addr_instr <= NULL_ADDR;
                                access_instr <= '0';
                                addr_data <= NULL_ADDR;
                                data <= WEAK_WORD;
                                access_data <= '0';
                                write_data <= '0';

                            end if;

                        when INSTR_MODE_SW =>
                            
                            if( memory_modify_in_progress = false ) then

                                memory_modify_in_progress := true;
                                
                                addr_instr <= NULL_ADDR;
                                access_instr <= '0';
                                addr_data <= final_addr_data;
                                data <= final_sw_data;
                                access_data <= '1';
                                write_data <= '1'; 

                            else

                                if( sample_ready_data = '1' ) then

                                    memory_modify_in_progress := false;
                                    cur_cpu_mode := CPU_MODE_WRITE_BACK;

                                end if;

                                    addr_instr <= NULL_ADDR;
                                    access_instr <= '0';
                                    addr_data <= NULL_ADDR;
                                    data <= WEAK_WORD;
                                    access_data <= '0';
                                    write_data <= '0';

                            end if;

                        when others =>  
                            cur_cpu_mode := CPU_MODE_WRITE_BACK;

                    end case memory_modify_cases;


                when CPU_MODE_WRITE_BACK =>
                    
                    write_back_cases:
                    case cur_instr_mode is

                        when INSTR_MODE_LW =>
                            reg_file_var( cur_rt_indx ) := final_lw_data;

                        when INSTR_MODE_ADD =>
                            reg_file_var( cur_rd_indx ) := to_signed( final_add_value, WORD_SIZE );

                        when others =>

                    end case write_back_cases;
                            
                    cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                    addr_instr <= NULL_ADDR;
                    access_instr <= '0';
                    addr_data <= NULL_ADDR;
                    data <= WEAK_WORD;
                    access_data <= '0';
                    write_data <= '0'; 


                when CPU_MODE_RESET =>

                    pc_nat := 0;
                    cur_cpu_mode := CPU_MODE_INSTR_FETCH;
                        
                    instr_request_placed := false;

                    addr_instr <= NULL_ADDR;
                    access_instr <= '0';
                    addr_data <= NULL_ADDR;
                    data <= WEAK_WORD;
                    access_data <= '0';
                    write_data <= '0'; 

            end case;

        else

            if reset = '1' then
                cur_cpu_mode := CPU_MODE_RESET;
            end if;

            sample_instr := instr;
            sample_ready_instr := ready_instr;

            sample_data := data;
            sample_ready_data := ready_data;

        end if;

    end process operate;

end architecture cpu_behav;
