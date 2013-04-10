use work.datapath_types.all;

library IEEE;
use IEEE.std_logic_1164.all;

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

        variable input_addr : addr;
        variable addr_substring_value : natural := 0;

    begin

        println( "TEST: Starting clk_gen tests." );

        wait for CLK_PERIOD;
        en <= '1';

        wait for ( CLK_PERIOD / 4 );
        assert( clk = '1' )
            report "TEST: Bad clk_gen output."
            severity error;

        wait for ( CLK_PERIOD / 2 );
        assert( clk = '0' )
            report "TEST: Bad clk_gen output."
            severity error;

        en <= '0';
        wait for ( CLK_PERIOD / 2 );

        println( "TEST: End of clk_gen tests." );

        println( "TEST: Starting get_addr_substring_value tests." );

        input_addr := X"00_00_04_00";
        addr_substring_value := get_addr_substring_value( input_addr,
                                                          8,
                                                          8 );
        assert( addr_substring_value = 4 )
            report "TEST: Bad get_addr_substring_value output."
            severity error;

        input_addr := X"00_11_00_00";
        addr_substring_value := get_addr_substring_value( input_addr,
                                                          16,
                                                          8 );
        assert( addr_substring_value = 17 )
            report "TEST: Bad get_addr_substring_value output."
            severity error;

        println( "TEST: End of get_addr_substring_value tests." );

        wait;

    end process test;
end architecture test_misc_arch;


