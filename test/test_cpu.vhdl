--! @file test_cpu.vhdl
--! @brief File containing unit test for 32-bit CPU

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library std;
use std.textio.all;

--! @brief 32-bit CPU test-bench entity
entity test_cpu is
end entity test_cpu;

--!@brief 32-bit CPU test-bench architecture
architecture test_cpu_arch of test_cpu is
    
    signal clk : std_logic;
    signal clk_en : std_logic;

    signal reset : std_logic;

    signal addr_instr : addr;
    signal instr : word;
    signal access_instr : std_logic;
    signal ready_instr : std_logic;

    signal addr_data : addr;
    signal data : word;
    signal access_data : std_logic;
    signal write_data : std_logic;
    signal ready_data : std_logic;

begin

    clk_gen_ent : entity work.clk_gen( clk_gen_behav )
        port map( clk,
                  clk_en );

    cpu_ent : entity work.cpu( cpu_behav )
        port map( clk,
                  reset,
                  addr_instr,
                  instr,
                  access_instr,
                  ready_instr,
                  addr_data,
                  data,
                  access_data,
                  write_data,
                  ready_data );

    test : process is

        procedure reset_cpu( pc_val : in addr ) is
        begin

            wait until clk = '1';

            reset <= '1';
            wait for CLK_PERIOD;

            reset <= '0';

        end procedure reset_cpu;


        procedure test_reset is
        begin

            wait until clk = '1';

            reset_cpu( NULL_ADDR );

            wait until access_instr = '1';

            assert( addr_instr = NULL_ADDR )
                report "ERROR: Bad CPU program counter output after reset."
                severity error;
            wait for CLK_PERIOD;

            instr <= INSTR_NOP;
            ready_instr <= '1';
            wait for CLK_PERIOD;

            instr <= NULL_WORD;
            ready_instr <= '0';

        end procedure;


        procedure test_sequential is

            variable pc_orig_nat : natural := 0;

        begin

            instr <= NULL_WORD;
            ready_instr <= '0';
            data <= WEAK_WORD;
            ready_data <= '0';
            wait until access_instr = '1';

            pc_orig_nat := to_integer( addr_instr );
            wait for CLK_PERIOD;

            instr <= INSTR_NOP;
            ready_instr <= '1';
            wait for CLK_PERIOD;

            instr <= NULL_WORD;
            ready_instr <= '0';
            wait until access_instr = '1';

            assert( to_integer( addr_instr ) = pc_orig_nat + WORD_BYTE_SIZE )
                report "ERROR: Bad sequential CPU program counter output."
                severity error;
            wait for CLK_PERIOD;

            instr <= INSTR_NOP;
            ready_instr <= '1';
            wait for CLK_PERIOD;

            instr <= NULL_WORD;
            ready_instr <= '0';

        end procedure test_sequential;


        procedure test_lw_instr is
        begin

            instr <= NULL_WORD;
            ready_instr <= '0';
            data <= WEAK_WORD;
            ready_data <= '0';
            wait until access_instr = '1';

            wait for CLK_PERIOD;

            instr <= LW_TEMPLATE;
            ready_instr <= '1';
            wait for CLK_PERIOD;
            
            instr <= NULL_WORD;
            ready_instr <= '0';

            wait on access_instr, access_data;

            assert( access_data = '1' )
                report "ERROR: No data access detected for LW instruction."
                severity error;
            assert( write_data = '0' )
                report "ERROR: Incorrect data access type detected for LW instruction."
                severity error;

            data <= X"12_34_45_78";
            ready_data <= '1';
            wait for CLK_PERIOD;

            data <= NULL_WORD;
            ready_data <= '0';

        end procedure test_lw_instr;


        procedure test_sw_instr is
        begin

            instr <= NULL_WORD;
            ready_instr <= '0';
            data <= WEAK_WORD;
            ready_data <= '0';
            wait until access_instr = '1';

            wait for CLK_PERIOD;

            instr <= SW_TEMPLATE;
            ready_instr <= '1';
            wait for CLK_PERIOD;
            
            instr <= NULL_WORD;
            ready_instr <= '0';

            wait on access_instr, access_data;

            assert( access_data = '1' )
                report "ERROR: No data access detected for SW instruction."
                severity error;
            assert( write_data = '1' )
                report "ERROR: Incorrect data access type detected for SW instruction."
                severity error;

            ready_data <= '1';
            wait for CLK_PERIOD;

            ready_data <= '0';

        end procedure test_sw_instr;


    begin

        println( "TEST: Starting cpu_behav tests." );

        reset <= '0';
        instr <= NULL_WORD;
        ready_instr <= '0';
        data <= WEAK_WORD;
        ready_data <= '0';
        wait for CLK_PERIOD;

        clk_en <= '1';
        wait for CLK_PERIOD;

        println( "TEST:     Starting reset tests." );
        test_reset;
        wait for ( 10 * CLK_PERIOD );
        test_reset;
        println( "TEST:     End of reset tests." );

        println( "TEST:     Starting sequential operation tests." );
        for test_sequential_count in 0 to 29 loop
            test_sequential;
        end loop;
        println( "TEST:     End of sequential operation tests." );

        println( "TEST:     Starting LW instruction tests." );
        test_lw_instr;
        println( "TEST:     End of LW instruction tests." );

        println( "TEST:     Starting SW instruction tests." );
        test_sw_instr;
        println( "TEST:     End of SW instruction tests." );
        
        clk_en <= '0';
        wait for CLK_PERIOD;

        println( "TEST: End of cpu_behav tests." );

        wait;

    end process test;

end architecture test_cpu_arch;
