--! @file cpu.vhdl
--! @brief File containing 32-bit CPU entity and behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--! @brief 32-bit CPU entity
entity cpu is
    port( clk           : in std_logic;

          reset         : in std_logic;

          addr_instr    : out addr;
          instr         : in word;
          access_instr  : out std_logic;
          ready_instr   : in std_logic;

          addr_data     : out addr;
          data          : inout word;
          access_data   : out std_logic;
          write_data    : out std_logic;
          ready_data    : in std_logic
        );

end entity cpu;

--! @brief 32-bit CPU behavioral architecture
architecture cpu_behav of cpu is

    subtype cpu_mode is positive range 1 to 6;
    
    constant CPU_MODE_INSTR_FETCH   : cpu_mode := 1;
    constant CPU_MODE_INSTR_DECODE  : cpu_mode := 2;
    constant CPU_MODE_EXECUTE       : cpu_mode := 3;
    constant CPU_MODE_MEMORY_MODIFY : cpu_mode := 4;
    constant CPU_MODE_WRITE_BACK    : cpu_mode := 5;
    constant CPU_MODE_RESET         : cpu_mode := 6;

    subtype instr_mode is positive range 1 to 7;

    constant INSTR_MODE_LW : instr_mode := 1;
    constant INSTR_MODE_SW : instr_mode := 2;
    constant INSTR_MODE_ADD : instr_mode := 3;
    constant INSTR_MODE_BEQ : instr_mode := 4;
    constant INSTR_MODE_BNE : instr_mode := 5;
    constant INSTR_MODE_LUI : instr_mode := 6;
    constant INSTR_MODE_NOP : instr_mode := 7;

begin

    operate : process( clk ) is

        -- General purpose variables
        variable cur_cpu_mode : cpu_mode := CPU_MODE_RESET;
        variable pc_nat : natural := 0;
        variable cur_instr : word;
        variable cur_instr_mode : instr_mode := INSTR_MODE_NOP;

        -- Instruction Fetch Mode variables
        variable instr_request_placed : boolean := false;

        -- Instruction Decode Mode variables
        variable masked_instr : word := NULL_WORD;


    begin

        if clk = '1' then

            if reset = '1' then
                cur_cpu_mode := CPU_MODE_RESET;
            end if;

            case cur_cpu_mode is

                when CPU_MODE_INSTR_FETCH =>

                    if ready_instr = '1' then

                        cur_instr := instr;
                        pc_nat := pc_nat + WORD_BYTE_SIZE;
                        instr_request_placed := false;
                        cur_cpu_mode := CPU_MODE_INSTR_DECODE;
                    
                    elsif instr_request_placed = false then

                        addr_instr <= to_unsigned( pc_nat, ADDR_SIZE );
                        access_instr <= '1';
                        instr_request_placed := true;

                    end if;


                when CPU_MODE_INSTR_DECODE =>

                    masked_instr := cur_instr and INSTR_OP_MASK;

                    instruction_decode_cases:
                    case masked_instr is

                        when LW_TEMPLATE =>
                            cur_instr_mode := INSTR_MODE_LW;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when SW_TEMPLATE =>
                            cur_instr_mode := INSTR_MODE_SW;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when BEQ_TEMPLATE =>
                            cur_instr_mode := INSTR_MODE_BEQ;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when BNE_TEMPLATE =>
                            cur_instr_mode := INSTR_MODE_BNE;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when LUI_TEMPLATE =>
                            cur_instr_mode := INSTR_MODE_LUI;
                            cur_cpu_mode := CPU_MODE_EXECUTE;

                        when NULL_WORD =>
                            if( ( cur_instr and INSTR_FUNCT_MASK ) = ADD_TEMPLATE ) then
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


                when CPU_MODE_EXECUTE =>

                    execute_cases:
                    case cur_instr_mode is

                        when INSTR_MODE_LW =>
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_SW =>
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_ADD =>
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_BEQ =>
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_BNE =>
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_LUI =>
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                        when INSTR_MODE_NOP =>  
                            cur_cpu_mode := CPU_MODE_MEMORY_MODIFY;

                    end case execute_cases;


                when CPU_MODE_MEMORY_MODIFY =>

                    memory_modify_cases:
                    case cur_instr_mode is

                        when INSTR_MODE_LW =>
                            cur_cpu_mode := CPU_MODE_WRITE_BACK;

                        when INSTR_MODE_SW =>
                            cur_cpu_mode := CPU_MODE_WRITE_BACK;

                        when INSTR_MODE_ADD =>
                            cur_cpu_mode := CPU_MODE_WRITE_BACK;

                        when INSTR_MODE_BEQ =>
                            cur_cpu_mode := CPU_MODE_WRITE_BACK;

                        when INSTR_MODE_BNE =>
                            cur_cpu_mode := CPU_MODE_WRITE_BACK;

                        when INSTR_MODE_LUI =>
                            cur_cpu_mode := CPU_MODE_WRITE_BACK;

                        when INSTR_MODE_NOP =>  
                            cur_cpu_mode := CPU_MODE_WRITE_BACK;

                    end case memory_modify_cases;


                when CPU_MODE_WRITE_BACK =>
                    
                    write_back_cases:
                    case cur_instr_mode is

                        when INSTR_MODE_LW =>
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                        when INSTR_MODE_SW =>
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                        when INSTR_MODE_ADD =>
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                        when INSTR_MODE_BEQ =>
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                        when INSTR_MODE_BNE =>
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                        when INSTR_MODE_LUI =>
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                        when INSTR_MODE_NOP =>  
                            cur_cpu_mode := CPU_MODE_INSTR_FETCH;

                    end case write_back_cases;


                when CPU_MODE_RESET =>
                    pc_nat := 0;
                    cur_cpu_mode := CPU_MODE_INSTR_FETCH;
                        
                    instr_request_placed := false;

            end case;

        else

            addr_instr <= NULL_ADDR;
            access_instr <= '0';
            addr_data <= NULL_ADDR;
            data <= WEAK_WORD;
            access_data <= '0';
            write_data <= '0'; 

        end if;

    end process operate;

end architecture cpu_behav;
