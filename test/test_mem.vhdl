--! @file test_mem.vhdl
--! @brief File containing unit test for memory behavioral architecture

use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

--! @brief Memory test-bench entity
entity test_mem is
end entity test_mem;

--!@brief Memory test-bench architecture
architecture test_mem_arch of test_mem is

    constant NOP_RANGE_MIN : addr := X"00_00_00_00";
    constant NOP_RANGE_MAX : addr := X"00_00_00_7C";
    constant LW_RANGE_MIN  : addr := X"00_00_00_80";
    constant LW_RANGE_MAX  : addr := X"00_00_00_BC";
    constant SW_RANGE_MIN  : addr := X"00_00_00_C0";
    constant SW_RANGE_MAX  : addr := X"00_00_00_FC";
    constant ADD_RANGE_MIN : addr := X"00_00_01_00";
    constant ADD_RANGE_MAX : addr := X"00_00_01_3C";
    constant BEQ_RANGE_MIN : addr := X"00_00_01_40";
    constant BEQ_RANGE_MAX : addr := X"00_00_01_7C";
    constant BNE_RANGE_MIN : addr := X"00_00_01_80";
    constant BNE_RANGE_MAX : addr := X"00_00_01_BC";
    constant LUI_RANGE_MIN : addr := X"00_00_01_C0";
    constant LUI_RANGE_MAX : addr := X"00_00_01_FC";

    constant DATA_RANGE_MIN : addr := X"00_00_02_00";
    constant DATA_RANGE_MAX : addr := X"00_00_03_FC";

    signal clk           : std_logic;
    signal clk_en        : std_logic;
    signal addr_data     : addr;     
    signal data          : word;  
    signal access_data   : std_logic;
    signal write_data    : std_logic;
    signal ready_data    : std_logic;
    signal addr_instr    : addr;    
    signal instr         : word;    
    signal access_instr  : std_logic;
    signal ready_instr   : std_logic;

begin

    clk_gen_ent : entity work.clk_gen( clk_gen_behav )
        port map( clk,
                  clk_en );

    mem_ent : entity work.mem( mem_behav )
        generic map( NOP_RANGE_MIN, NOP_RANGE_MAX,
                     LW_RANGE_MIN,  LW_RANGE_MAX,
                     SW_RANGE_MIN,  SW_RANGE_MAX,
                     ADD_RANGE_MIN, ADD_RANGE_MAX,
                     BEQ_RANGE_MIN, BEQ_RANGE_MAX,
                     BNE_RANGE_MIN, BNE_RANGE_MAX,
                     LUI_RANGE_MIN, LUI_RANGE_MAX )
        port map( clk,
                  addr_data,
                  data,
                  access_data,
                  write_data,
                  ready_data,
                  addr_instr,
                  instr,
                  access_instr,
                  ready_instr );

    test : process is

        procedure test_instr_mem_bounds( min_bound      : in addr;
                                         max_bound      : in addr;
                                         instr_template : in word ) is
        begin

            addr_instr <= min_bound;
            access_instr <= '1';
            wait for CLK_PERIOD;

            addr_instr <= NULL_ADDR;
            access_instr <= '0';
            wait on ready_instr;
            
            if instr_template = ADD_TEMPLATE then

                assert( ( instr and INSTR_FUNCT_MASK ) = instr_template )
                    report "ERROR: Bad instr output."
                    severity error;
                wait for CLK_PERIOD;

            else

                assert( ( instr and INSTR_OP_MASK ) = instr_template )
                    report "ERROR: Bad instr output."
                    severity error;
                wait for CLK_PERIOD;
                
            end if;

            addr_instr <= max_bound;
            access_instr <= '1';
            wait for CLK_PERIOD;

            addr_instr <= NULL_ADDR;
            access_instr <= '0';
            wait on ready_instr;
            
            if instr_template = ADD_TEMPLATE then

                assert( ( instr and INSTR_FUNCT_MASK ) = instr_template )
                    report "ERROR: Bad instr output."
                    severity error;
                wait for CLK_PERIOD;

            else

                assert( ( instr and INSTR_OP_MASK ) = instr_template )
                    report "ERROR: Bad instr output."
                    severity error;
                wait for CLK_PERIOD;
                
            end if;

        end procedure;

        procedure test_data_retention( sample_data  : in word;
                                       sample_addr  : in addr ) is
        begin

            addr_data <= sample_addr;
            data <= sample_data;
            access_data <= '1';
            write_data <= '1';
            wait for CLK_PERIOD;

            addr_data <= NULL_ADDR;
            data <= NULL_WORD;
            access_data <= '0';
            write_data <= '0';
            wait on ready_data;
            wait for CLK_PERIOD;

            data <= WEAK_WORD;
            addr_data <= sample_addr;
            access_data <= '1';
            write_data <= '0';
            wait for CLK_PERIOD;

            data <= WEAK_WORD;
            addr_data <= NULL_ADDR;
            access_data <= '0';
            write_data <= '0';
            wait on ready_data;

            assert( data = sample_data )
                report "ERROR: Bad data output."
                severity error;
            wait for CLK_PERIOD;

        end procedure;

    begin
        
        println( "TEST: Starting mem_behav test." );
        
        addr_data <= NULL_ADDR;
        data <= NULL_WORD;
        access_data <= '0';
        write_data <= '0';
        access_instr <= '0';
        wait for CLK_PERIOD;
        
        clk_en <= '1';
        wait for CLK_PERIOD;
        
        println( "TEST:     Starting instruction bound tests." );

        println( "TEST:         Testing NOP bounds." );
        test_instr_mem_bounds( NOP_RANGE_MIN,
                               NOP_RANGE_MAX,
                               INSTR_NOP );

        println( "TEST:         Testing LW bounds." );
        test_instr_mem_bounds( LW_RANGE_MIN,
                               LW_RANGE_MAX,
                               LW_TEMPLATE );

        println( "TEST:         Testing SW bounds." );
        test_instr_mem_bounds( SW_RANGE_MIN,
                               SW_RANGE_MAX,
                               SW_TEMPLATE );

        println( "TEST:         Testing ADD bounds." );
        test_instr_mem_bounds( ADD_RANGE_MIN,
                               ADD_RANGE_MAX,
                               ADD_TEMPLATE );

        println( "TEST:         Testing BEQ bounds." );
        test_instr_mem_bounds( BEQ_RANGE_MIN,
                               BEQ_RANGE_MAX,
                               BEQ_TEMPLATE );

        println( "TEST:         Testing BNE bounds." );
        test_instr_mem_bounds( BNE_RANGE_MIN,
                               BNE_RANGE_MAX,
                               BNE_TEMPLATE );

        println( "TEST:         Testing LUI bounds." );
        test_instr_mem_bounds( LUI_RANGE_MIN,
                               LUI_RANGE_MAX,
                               LUI_TEMPLATE );

        println( "TEST:     End of instruction bound tests." );

        println( "TEST:     Starting data retention tests." );
        test_data_retention( X"55_55_55_55",
                             DATA_RANGE_MIN );
        println( "TEST:     End of data retention tests." );

        clk_en <= '0';
        wait for CLK_PERIOD;
        
        println( "TEST: End of mem_behav test." );

        wait;

    end process test;

end architecture test_mem_arch;
