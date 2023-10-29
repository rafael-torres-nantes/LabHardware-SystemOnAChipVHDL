library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_memory is
end entity;

architecture mix of tb_memory is
    constant addr_width: natural := 16; -- Memory Address Width (in bits)
    constant data_width: natural := 8; -- Data Width (in bits)

    -- Clock signal; Write on Falling-Edge
    -- data_read : When '1', read data from memory
    -- data_write : When '1', write data to memory
    signal clock, data_read, data_write : std_logic;
    -- Data address given to memory
    signal data_addr : std_logic_vector(addr_width-1 downto 0);
    -- Data sent from memory when data_read = '1' and data_write = '0'
    signal data_in : std_logic_vector((data_width*2)-1 downto 0);
    -- Data sent to memory when data_read = '0' and data_write = '1'
    signal data_out : std_logic_vector((data_width*4)-1 downto 0);

begin
    memory : entity work.memory(behavioral)
            generic map (addr_width => addr_width, data_width => data_width)
            port map (clock => clock, 
                      data_read => data_read, 
                      data_write => data_write, 
                      data_addr => data_addr, 
                      data_in => data_in, 
                      data_out => data_out);
        
    estimulo : process is
        type line_tabela_verdade is record
            clock, data_read, data_write : std_logic;
            data_addr : std_logic_vector(addr_width-1 downto 0);
            data_in : std_logic_vector((data_width*2)-1 downto 0);
            data_out : std_logic_vector((data_width*4)-1 downto 0);
        end record;

        type vetor_tv is array (0 to 17) of line_tabela_verdade;
        constant tabela_verdade : vetor_tv := (
         
        -- Tabela Verdade Corrigida (falling_edge)
        -- clock, d_r, d_w, adress, data_in, r: data_out
            ('1', '0', '1', x"0010", x"1234", x"00000000"), -- Não faz nada (pq não é falling_edge), out : 0
            ('0', '0', '1', x"0010", x"1234", x"00000000"), -- Escreve [10, 11] : 1234, out : 0
            ('1', '1', '0', x"0010", x"0000", x"00001234"), -- Print [10, 11, 12, 13] : 00001234, out : 00001234
            ('0', '1', '0', x"0010", x"0000", x"00001234"), -- Print [10, 11, 12, 13] : 00001234, out : 00001234
            ('1', '1', '0', x"000F", x"0000", x"00123400"), -- Print [xF, 10, 11, 12] : 00123400, out : 00123400
            ('0', '1', '0', x"000F", x"0000", x"00123400"), -- Print [xF, 10, 11, 12] : 00123400, out : 00123400
            ('1', '1', '0', x"000E", x"0000", x"12340000"), -- Print [xE, xF, 10, 11] : 12340000, out : 12340000
            ('0', '1', '0', x"000D", x"0000", x"34000000"), -- Print [xD, xE, xF, 10] : 34000000, out : 34000000
            ('1', '1', '0', x"0011", x"0000", x"00000012"), -- Print [11, 12, 13, 14] : 00000012, out : 00000012
            ('0', '1', '0', x"0012", x"0000", x"00000000"), -- Print [12, 13, 14, 15] : 00000000, out : 00000000
            ('1', '0', '1', x"000E", x"5678", x"00000000"), -- Não faz nada (pq não é falling_edge), out : 0
            ('0', '0', '1', x"000E", x"9123", x"00000000"), -- Escreve [xE, xF, 10, 11] : 12349101, out : 0
            ('1', '1', '0', x"000E", x"0000", x"12349123"), -- Print [xE, xF, 10, 11] : 12349123, out : 12349123
            ('0', '1', '0', x"000E", x"0000", x"12349123"),  -- Print [xE, xF, 10, 11] : 12349123, out : 12349123
            ('1', '0', '1', x"0010", x"4567", x"00000000"), -- Não faz nada (pq não é falling_edge), out : 0
            ('0', '0', '1', x"0010", x"4567", x"00000000"), -- Escreve [10, 11, 12, 13] : 45679101, out : 0
            ('1', '1', '0', x"000E", x"0000", x"45679123"), -- Print [xE, xF, 10, 11] : 45679123, out : 45679123
            ('0', '1', '0', x"0010", x"0000", x"00004567")  -- Print [10, 11, 12, 13] : 45679123, out : 00004567
        );

    begin
        for i in tabela_verdade'range loop
            clock <= tabela_verdade(i).clock;
            data_read <= tabela_verdade(i).data_read;
            data_write <= tabela_verdade(i).data_write;
            data_addr <= tabela_verdade(i).data_addr;
            data_in <= tabela_verdade(i).data_in;

            wait for 1 ns;

            assert data_out = tabela_verdade(i).data_out 
                report "ERROR : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: " &
                integer'image(to_integer(signed(tabela_verdade(i).data_out))) & " != " &
                integer'image(to_integer(signed(data_out)))
            severity failure;
            
        end loop; 

        report "The end of tests" ;

        wait;
    end process;

end architecture;