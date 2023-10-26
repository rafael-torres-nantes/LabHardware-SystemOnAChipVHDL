library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity codec is
 	port (
 		interrupt: in std_logic; -- Interrupt signal
		read_signal: in std_logic; -- Read signal
		write_signal: in std_logic; -- Write signal
		valid: out std_logic; -- Valid signal

		-- Byte written to codec
		codec_data_in : in std_logic_vector(7 downto 0);
		-- Byte read from codec
		codec_data_out : out std_logic_vector(7 downto 0)
 	);

 end entity;

 architecture dataflow of codec is
    
    file file_input : text open read_mode is "input.txt";
    file file_output : text open write_mode is "output.txt";

    signal aux_data : std_logic_vector(7 downto 0);

begin

    process (interrupt)
        variable text_line : line;
        variable text_number : integer;
    begin 
        -- Converte o valor inteiro "0"[Decimal] para um vetor de lógico "00000000"[Binário]
        aux_data <= std_logic_vector(to_unsigned(0, 8));
        text_line := null;
        valid <= '0';

        -- Instrução IN (read/leitura) no arquivo TXT
        -- Caso o sinal de leitura estiver ativo e houver dados disponíveis no arquivo de entrada:
        if(read_signal = '1' and rising_edge(interrupt) and not endfile(file_input)) then 
            -- Lê uma linha de texto do arquivo de entrada
            readline(file_input, text_line);

            -- Caso a linha de texto não estiver vazia
            -- Converte um número de texto "0"[Text] para um vetor de lógico "00000000"[Binário]
            if text_line'length > 0 then
                read(text_line, text_number);
                aux_data <= std_logic_vector(to_signed(text_number, 8));
                valid <= '1';
            end if;
        end if;

        -- Instrução OUT (write/escrita) no arquivo TXT, caso o sinal de escrita estiver ativo:
        if(write_signal = '1' and rising_edge(interrupt)) then 
            -- Converte o vetor de lógico "00000000"[Binário] para um número de texto  "0"
             -- Escreve a linha de texto no arquivo de saída, e sinaliza o valor como válido
            write(text_line, to_integer(signed(codec_data_in)));
            writeline(file_output, text_line);
            valid <= '1';
                
        end if;
    
    end process;
     -- A saída do codec é o vetor de dados a ser escrito
    codec_data_out <= aux_data;

end architecture;