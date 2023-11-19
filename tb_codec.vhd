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

        -- inter, r_s, w_s, val, cod_in, cod_out
        -- -- Hexadecimal para binário com complemento de 2, e após isso converta binário para decimal;
        -- ('0', '0', '1', '0', x"AB", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
        -- ('1', '0', '1', '1', x"AB", x"00"), -- WRITE start  / Escrita output_file: -85
        -- ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
        -- ('1', '1', '0', '1', x"00", x"0C"), -- READ start   / Leitura input_file: 12, cod_out : "0C" == "12"
        -- ('0', '0', '1', '0', x"FF", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
        -- ('1', '0', '1', '1', x"FF", x"00"), -- WRITE start  / Escrita output_file: -1
        -- ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
        -- ('1', '1', '0', '1', x"00", x"0B"), -- READ start   / Leitura input_file: 11, cod_out : "0B" == "11"
        -- ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
        -- ('1', '1', '0', '0', x"00", x"00"), -- READ start   / Não executa a leitura (linha sem valor)
        -- ('0', '0', '1', '0', x"00", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
        -- ('1', '0', '1', '1', x"00", x"00"), -- WRITE start  / Escrita output_file: 0
        -- ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
        -- ('1', '1', '0', '1', x"00", x"1F"), -- READ start   / Leitura input_file: 31, cod_out : "1F" == "31"
        -- ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
        -- ('1', '1', '0', '1', x"00", x"29"), -- READ start   / Leitura input_file: 41, cod_out : "29" == "41"
        -- ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
        -- ('1', '1', '0', '1', x"00", x"CD"), -- READ start   / Leitura input_file: -51, cod_out : "CD" == "-51"
        -- ('0', '0', '1', '0', x"27", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
        -- ('1', '0', '1', '1', x"27", x"00"), -- WRITE start  / Escrita output_file: 39
        -- ('0', '0', '1', '0', x"11", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
        -- ('1', '0', '1', '1', x"11", x"00"), -- WRITE start  / Escrita output_file: 17
        -- ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
        -- ('1', '1', '0', '1', x"00", x"7F"), -- READ start   / Leitura input_file: 127, cod_out : "7F" == "127"
        -- ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
        -- ('1', '1', '0', '1', x"00", x"80"), -- READ start
        -- ('0', '0', '1', '0', x"7F", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
        -- ('1', '0', '1', '1', x"7F", x"00"), -- WRITE start
        -- ('0', '0', '1', '0', x"80", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
        -- ('1', '0', '1', '1', x"80", x"00"), -- WRITE start
        -- ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
        -- ('1', '1', '0', '0', x"00", x"00") -- READ start