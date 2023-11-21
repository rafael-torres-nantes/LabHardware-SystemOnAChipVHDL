library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_soc is
end entity;

architecture mix of tb_soc is
    constant addr_width: natural := 16; -- Memory Address Width (in bits)
    constant data_width: natural := 8; -- Data Width (in bits)

    constant firmware_filename: string := "test_cases/firmware.bin";

    signal clock: std_logic := '0'; -- Clock signal
    signal started: std_logic := '0'; -- Start execution when '1'
 
begin

    soc : entity work.soc(dataflow)
        generic map (firmware_filename => firmware_filename)
        port map (clock, started);

    estimulo : process is

    begin
        -- Carrega as informações do Firmware para IMEM
        started <= '0';

        for i in 0 to 50 loop
            clock <= not clock;
            wait for 1 ns;
            clock <= not clock;
            wait for 1 ns;
        end loop;

         -- Inicia os processos da CPU
        started <= '1';
    
        clock <= not clock;
        wait for 1 ns;
        clock <= not clock;
        wait for 1 ns;

        for i in 0 to (3 * 50) loop
            clock <= not clock;
            wait for 1 ns;
            clock <= not clock;
            wait for 1 ns;
        end loop;

        clock <= not clock;
        wait for 1 ns;
        clock <= not clock;
        wait for 1 ns;

        clock <= not clock;
        wait for 1 ns;
        clock <= not clock;
        wait for 1 ns;

        report "The end of tests";
        wait;
    end process;
end architecture;
