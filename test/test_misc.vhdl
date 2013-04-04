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

    en <= '0';

    test : process is 
    begin
        
        assert false
            report "TEST: Starting clk_gen tests."
            severity note;

        en <= '1';

        wait for ( CLK_PERIOD / 4 );
        assert( clk = '0' )
            report "TEST: Bad clk_gen output."
            severity error;

        wait for ( 3 * ( CLK_PERIOD / 4 ) );
        assert( clk = '1' )
            report "TEST: Bad clk_gen output."
            severity error;
        
        assert false
            report "TEST: End of mem_behav tests."
            severity note;

    end process test;
end architecture test_misc_arch;


