library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_codec is
end entity;

architecture mix of tb_codec is
    signal interrupt  : std_logic := '0'; -- Interrupt signal and Valid signal
    signal r_signal, w_signal, valid: std_logic; -- Read signal and  Write signal
    
	signal codec_in : std_logic_vector(7 downto 0) := "01010101"; 	-- Byte written to codec
	signal codec_out : std_logic_vector(7 downto 0);                -- Byte read from codec
 
begin
    codec : entity work.codec(dataflow)
        port map (interrupt, r_signal, w_signal, valid, codec_in , codec_out);
        
    estimulo : process is
        variable on_signal : std_logic := '1';
    begin

        interrupt <= not interrupt;
        r_signal <= '0';
        w_signal <= '1';
        -- codec_in <= std_logic_vector(to_unsigned(i, codec_in'length));
        wait for 3 ns;

        assert on_signal = valid
            report "ERROR: Codec cound not write on file(rising_edge)!!!"
            severity failure;

        interrupt <= not interrupt;
        wait for 3 ns;
        
        r_signal <='1';
        w_signal <= '0';
        interrupt <= not interrupt;
        wait for 3 ns;
        
        assert on_signal = valid
            report "ERROR: Codec cound not read the file(rising_edge)!!!"
            severity failure;

        report "The end of tests";
        wait;

    end process estimulo;
end;