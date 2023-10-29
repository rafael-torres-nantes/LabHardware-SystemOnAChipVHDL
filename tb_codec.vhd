library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_codec is
end;

architecture mix of tb_codec is
    signal interrupt, valid: std_logic; -- Interrupt signal and Valid signal
    signal r_signal, w_signal: std_logic; -- Read signal and  Write signal
    
	signal codec_in : std_logic_vector(7 downto 0) := (others => '0'); 	-- Byte written to codec
	signal codec_out : std_logic_vector(7 downto 0); -- Byte read from codec
 
begin
    codec : entity work.codec(dataflow)
        port map (interrupt, r_signal, w_signal, valid, codec_in , codec_out);
        
    estimulo : process is
        variable zero_int : integer := 0;
    begin
        for i in 0 to 255 loop

            interrupt <= '0';
            r_signal <= '1';
            w_signal <= '0';
            codec_in <= std_logic_vector(to_unsigned(i, codec_in'length));

            wait for 1 ns;

            if (interrupt = '0') then
                assert zero_int = to_integer(signed(valid))
                    report "Não deveria executar a leitura ou escrita (falling_edge)" &
                        integer'image(zero_int) & " != " &
                        integer'image(to_integer(signed(valid)))
                    severity failure;

            interrupt <= '1';
            r_signal <='1';
            w_signal <= '0';
            
            elsif (interrupt = '1' and r_signal = '1') then
                assert i = to_integer(signed(codec_out))
                report "Não deveria executar a leitura ou escrita (falling_edge)" &
                    integer'image(i) & " != " &
                    integer'image(to_integer(signed(codec_out)))
                severity failure;

            interrupt <= '1';
            r_signal <= '0';
            w_signal <= '1';

            
            wait for 1 ns;

            elsif (interrupt = '1' and w_signal = '1') then
                assert zero_int = to_integer(signed(codec_out))
                report "Não deveria executar a leitura ou escrita (falling_edge)" &
                    integer'image(zero_int) & " != " &
                    integer'image(to_integer(signed(codec_out)))
                severity failure;
            end if; 
            
        end loop; 

        report "The end of tests" ;
        wait;

    end process estimulo;
end;