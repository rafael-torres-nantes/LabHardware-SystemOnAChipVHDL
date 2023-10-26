library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_codec is
end;

architecture mix of tb_codec is
    signal interrupt: std_logic; -- Interrupt signal
    signal read_signal: std_logic; -- Read signal
    signal write_signal: std_logic; -- Write signal
    signal valid: std_logic; -- Valid signal
    
	-- Byte written to codec
	signal codec_data_in : std_logic_vector(7 downto 0);
	-- Byte read from codec
	signal codec_data_out : std_logic_vector(7 downto 0);

begin
    codec : entity work.codec(dataflow)
        port map (interrupt => interrupt, 
                      read_signal => read_signal, 
                      write_signal => write_signal, 
                      valid => valid, 
                      codec_data_in => codec_data_in, 
                      codec_data_out => codec_data_out);
        
    estimulo : process is
        type line_tabela_verdade is record
            interrupt : std_logic; -- Interrupt signal
            read_signal : std_logic; -- Read signal
            write_signal : std_logic; -- Write signal
            valid : std_logic; -- Valid signal

            -- Byte written to codec
            codec_data_in : std_logic_vector(7 downto 0);
            -- Byte read from codec
            codec_data_out : std_logic_vector(7 downto 0);
        end record;

        type vetor_tv is array (0 to 31) of line_tabela_verdade;
        constant tabela_verdade : vetor_tv := (
        -- inter, r_s, w_s, val, cod_in, cod_out
        -- Hexadecimal para binário com complemento de 2, e após isso converta binário para decimal;
            ('0', '0', '1', '0', x"AB", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
            ('1', '0', '1', '1', x"AB", x"00"), -- WRITE start  / Escrita output_file: -85
            ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
            ('1', '1', '0', '1', x"00", x"0C"), -- READ start   / Leitura input_file: 12, cod_out : "0C" == "12"
            ('0', '0', '1', '0', x"FF", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
            ('1', '0', '1', '1', x"FF", x"00"), -- WRITE start  / Escrita output_file: -1
            ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
            ('1', '1', '0', '1', x"00", x"0B"), -- READ start   / Leitura input_file: 11, cod_out : "0B" == "11"
            ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
            ('1', '1', '0', '0', x"00", x"00"), -- READ start   / Não executa a leitura (linha sem valor)
            ('0', '0', '1', '0', x"00", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
            ('1', '0', '1', '1', x"00", x"00"), -- WRITE start  / Escrita output_file: 0
            ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
            ('1', '1', '0', '1', x"00", x"1F"), -- READ start   / Leitura input_file: 31, cod_out : "1F" == "31"
            ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
            ('1', '1', '0', '1', x"00", x"29"), -- READ start   / Leitura input_file: 41, cod_out : "29" == "41"
            ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
            ('1', '1', '0', '1', x"00", x"CD"), -- READ start   / Leitura input_file: -51, cod_out : "CD" == "-51"
            ('0', '0', '1', '0', x"27", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
            ('1', '0', '1', '1', x"27", x"00"), -- WRITE start  / Escrita output_file: 39
            ('0', '0', '1', '0', x"11", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
            ('1', '0', '1', '1', x"11", x"00"), -- WRITE start  / Escrita output_file: 17
            ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
            ('1', '1', '0', '1', x"00", x"7F"), -- READ start   / Leitura input_file: 127, cod_out : "7F" == "127"
            ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
            ('1', '1', '0', '1', x"00", x"80"), -- READ start
            ('0', '0', '1', '0', x"7F", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
            ('1', '0', '1', '1', x"7F", x"00"), -- WRITE start
            ('0', '0', '1', '0', x"80", x"00"), -- WRITE wait   / Não executa a escrita (falling_edge)
            ('1', '0', '1', '1', x"80", x"00"), -- WRITE start
            ('0', '1', '0', '0', x"00", x"00"), -- READ wait    / Não executa a leitura (falling_edge)
            ('1', '1', '0', '0', x"00", x"00") -- READ start
        );

    begin

        for i in tabela_verdade'range loop
            interrupt <= tabela_verdade(i).interrupt;
            read_signal <= tabela_verdade(i).read_signal;
            write_signal <= tabela_verdade(i).write_signal;
            codec_data_in <= tabela_verdade(i).codec_data_in;

            wait for 1 ns;

            assert valid = tabela_verdade(i).valid 
            report "Erro resultado! " &
                integer'image(i) & " != "
            severity failure;

            assert codec_data_out = tabela_verdade(i).codec_data_out
            report "Erro resultado! " &
                integer'image(i) & " != "
            severity failure;
            
        end loop; 

        report "The end of tests" ;

        wait;
    end process estimulo;
end;