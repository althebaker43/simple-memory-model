use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity test_misc is
end entity test_misc;

architecture test_misc_arch of test_misc is

    signal clk : std_logic;
    signal en : std_logic;

begin

    clk_gen_ent : entity work.clk_gen( clk_gen_behav )
        port map( clk,
                  en );

    test : process is 

        variable input_addr : addr := NULL_ADDR;
        variable exp_addr_mask_value : addr := NULL_ADDR;
        variable act_addr_mask_value : addr := NULL_ADDR;
        variable addr_substring_value : natural := 0;

        variable m_z_nat : natural := 4;
        variable m_w_nat : natural := 3;
        variable first_random_value : natural := 0;
        variable second_random_value : natural := 0;
        variable third_random_value : natural := 0;

    begin

        println( "TEST: Starting misc tests." );

        println( "TEST:     Starting clk_gen tests." );

        wait for CLK_PERIOD;
        en <= '1';

        wait for ( CLK_PERIOD / 4 );
        assert( clk = '1' )
            report "ERROR: Bad clk_gen output."
            severity error;

        wait for ( CLK_PERIOD / 2 );
        assert( clk = '0' )
            report "ERROR: Bad clk_gen output."
            severity error;

        en <= '0';
        wait for ( CLK_PERIOD / 2 );

        println( "TEST:     End of clk_gen tests." );

        println( "TEST:     Starting get_addr_mask tests." );

        act_addr_mask_value := get_addr_mask( 128 );
        exp_addr_mask_value := X"FF_FF_FF_80";
        assert( act_addr_mask_value = exp_addr_mask_value )
            report "ERROR: Bad get_addr_mask output."
            severity error;

        act_addr_mask_value := get_addr_mask( 512 );
        exp_addr_mask_value := X"FF_FF_FE_00";
        assert( act_addr_mask_value = exp_addr_mask_value )
            report "ERROR: Bad get_addr_mask output."
            severity error;

        act_addr_mask_value := get_addr_mask( 1024 );
        exp_addr_mask_value := X"FF_FF_FC_00";
        assert( act_addr_mask_value = exp_addr_mask_value )
            report "ERROR: Bad get_addr_mask output."
            severity error;

        println( "TEST:     End of get_addr_mask tests." );

        println( "TEST:     Starting get_addr_substring_value tests." );

        input_addr := X"00_00_04_00";
        addr_substring_value := get_addr_substring_value( input_addr,
                                                          8,
                                                          8 );
        assert( addr_substring_value = 4 )
            report "ERROR: Bad get_addr_substring_value output."
            severity error;

        input_addr := X"00_11_00_00";
        addr_substring_value := get_addr_substring_value( input_addr,
                                                          16,
                                                          8 );
        assert( addr_substring_value = 17 )
            report "ERROR: Bad get_addr_substring_value output."
            severity error;

        println( "TEST:     End of get_addr_substring_value tests." );

        --println( "TEST:     Starting get_random_nat tests." );

        --get_random_nat( m_z_nat,
        --                m_w_nat,
        --                32,
        --                first_random_value );
        --assert( first_random_value <= 32 )
        --    report "ERROR: Bad get_random_nat output."
        --    severity error;

        --get_random_nat( m_z_nat,
        --                m_w_nat,
        --                32,
        --                second_random_value );
        --assert( not( second_random_value = first_random_value ) and
        --        ( second_random_value < 32 ) )
        --    report "ERROR: Bad get_random_nat output."
        --    severity error;

        --get_random_nat( m_z_nat,
        --                m_w_nat,
        --                32,
        --                third_random_value );
        --assert( not( third_random_value = first_random_value ) and
        --        not( third_random_value = second_random_value ) and
        --        ( third_random_value < 32 ) )
        --    report "ERROR: Bad get_random_nat output."
        --    severity error;
        --
        --println( "TEST:     End of get_random_nat tests." );
        
        println( "TEST: End of misc tests." );

        wait;

    end process test;
end architecture test_misc_arch;


