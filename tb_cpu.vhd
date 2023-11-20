LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity tb_cpu is
end entity;

architecture mix of tb_cpu is

    constant addr_width: natural := 16; -- Memory Address Width (in bits)
    constant data_width: natural := 8; -- Data Width (in bits)

    -- Clock signal and Halt processor execution when '1'
    signal clock, halt : std_logic := '0';

    signal instruction_in : std_logic_vector(data_width - 1 downto 0) := (others => '0');
    signal instruction_addr : std_logic_vector(addr_width - 1 downto 0) := (others => '0');

    ---- Begin Memory Signals ---
    -- signal dmem_data_read : std_logic;
    -- signal dmem_data_write : std_logic;
    signal r_dmem, w_dmem : std_logic := '0';
    signal dmem_data_addr : std_logic_vector(addr_width - 1 downto 0) := (others => '0');
    signal dmem_data_in : std_logic_vector((data_width * 2) - 1 downto 0) := (others => '0');
    signal dmem_data_out : std_logic_vector((data_width * 4) - 1 downto 0) := (others => '0');

     ---- Begin Codec Signals ---
     signal interrupt  : std_logic := '0'; -- Interrupt signal and Valid signal
     signal codec_read, codec_write, valid: std_logic := '0'; -- Read signal and  Write signal
 
     signal codec_in : std_logic_vector(7 downto 0) := (others => '0'); 	-- Byte written to codec
     signal codec_out : std_logic_vector(7 downto 0) := (others => '0');    -- Byte read from codec

begin

    cpu : entity work.cpu(behavioral)
        generic map (addr_width => addr_width, data_width => data_width)
        port map (clock, halt, instruction_in, instruction_addr,
                r_dmem, w_dmem, dmem_data_addr, dmem_data_in, dmem_data_out,
                interrupt, codec_read, codec_write, valid, codec_out, codec_in);

    estimulo : process is
        type line_tabela_verdade is record
            
            halt : std_logic;
            instruction_in : std_logic_vector(data_width - 1 downto 0);
            instruction_addr : std_logic_vector(addr_width - 1 downto 0); -- assert

            mem_data_read : std_logic; -- assert
            mem_data_write : std_logic; -- assert
            mem_data_addr : std_logic_vector(addr_width - 1 downto 0); -- assert
            mem_data_in : std_logic_vector((2 * data_width) - 1 downto 0); -- assert
            mem_data_out : std_logic_vector((4 * data_width) - 1 downto 0);
            
            codec_read : std_logic; -- assert
            codec_write : std_logic; -- assert
            codec_interrupt : std_logic; -- assert
            codec_valid : std_logic;
            codec_data_out : std_logic_vector(7 downto 0);
            codec_data_in : std_logic_vector(7 downto 0); -- assert
        end record;

        type vetor_tv is array (0 to 25) of line_tabela_verdade;
        constant tabela_verdade : vetor_tv := (
         
        -- Instruction : PUSHIP, JEQ e JMP (16 bits)

        -- IMEM : Intruction Memory = Memoria dos Opcodes
        -- DMEM : Data Memory = Memória dos Dados 

        -- codec_read = 1 : Lê o arquivo input.txt e possui o codec_out
        -- codec_write = 1 : Escreve no arquivo output.txt e NAO tem o codec_out

        -- Tabela Verdade
        -- (+) Entrada e (-) Saída

            -- Opcode Halt: 
            ('0', x"00", x"0000",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '0', x"0000", x"0000", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ), 

            -- Opcode In : Empilha byte recebido do CODEC (Codec_Read e Mem_Write)
            -- codec_read = 1 : Lê o arquivo input.txt e possui o codec_out
            ('0', x"10", x"0001",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0000", x"0010", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '1', '0', '1', '1', x"10",  x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Out : Empilha byte recebido do CODEC (Codec_Read e Mem_Write)
            -- codec_write = 1 : Escreve no arquivo output.txt e NAO tem o codec_out
            ('0', x"20", x"0002",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '1', '0', x"0000", x"0000", x"00000010",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '1', '1', '0',  x"00", x"10"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode PushIP : Empilha o endereço armazenado no registrador IP (2 bytes, primeiro MSB2 e depois LSB3).
            ('0', x"30", x"0003",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0000", x"0003", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01001100", x"0004",                   -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0001", x"FFFC", x"00000000",     -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0', x"00", x"00"             -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01001101", x"0005",                   -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0002", x"FFFD", x"00000000",     -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"            -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01001110", x"0006",                  -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0003", x"FFFE", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
           ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01001111", x"0007",                 -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0004", x"FFFF", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01000000", x"0008",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0005", x"0000", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01000001", x"0009",                  -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0006", x"0001", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
           ),


            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01000010", x"000A",                  -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0007", x"0002", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01000011", x"000B",                  -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0008", x"0003", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
           ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01000100", x"000C",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0009", x"0004", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Drop : Elimina um elemento da pilha
            ('0', x"50", x"000D",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '1', '0', x"0009", x"0000", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Dup : Reempilha o elemento no topo da pilha.
            -- hex11 : bin0001.00001 = dec17
            ('0', x"60", x"000E",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0008", x"0011", x"40302011",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Add : Desempilha Op1 e Op2 e empilha (Op1 + Op2).
            -- hex10 : bin0001.0000 = dec16
            -- hex12 : bin0001.0010 = dec18
            -- conta aritimetica = dec16 + dec18 = dec34
            ('0', x"80", x"000F",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0008", x"0022", x"00001210",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Sub : Desempilha Op1 e Op2 e empilha (Op1 - Op2).
            -- hex11 : bin0001.0001 = dec17
            -- hex20 : bin0100.0000 = dec32
            ('0', x"90", x"0010",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0007", x"000F", x"00002011",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode NAND : Desempilha Op1 e Op2 e empilha NAND(Op1, Op2).
            -- hex11 : bin0001.0001 = dec17
            -- hex20 : bin0100.0000 = dec32
            -- NAND  : bin1111.1111 = 
            ('0', x"A0", x"0011",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0006", x"00FF", x"00002011",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode SLT : Desempilha Op1 e Op2 e empilha (Op1 < Op2).
            -- hex20 : bin0100.0000 = dec32
            -- hex10 : bin0010.0000 = dec16
            ('0', x"B0", x"0012",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0005", x"0001", x"00001020",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode SHL : Desempilha Op1 e Op2 e empilha (Op1 ≪ Op2).
            -- hex01 : bin0000.0001 = dec1
            -- hex02 : bin0000.0010 = dec2
            ('0', x"C0", x"0013",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0004", x"0004", x"00000201",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode SHR : Desempilha Op1 e Op2 e empilha (Op1 ≫ Op2).
            -- hex02 : bin0000.0010 = dec2
            -- hex01 : bin0000.0001 = dec1
            ('0', x"D0", x"0014",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '0', '1', x"0003", x"0001", x"00000201",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode JEQ : Desempilha Op1(1 byte), Op2(1 byte) e Op3(2 bytes); Verifica se (Op1 = Op2), caso positivo soma Op3 no registrador IP.
            ('0', x"E0", x"0015",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '1', '0', x"0000", x"0000", x"10100001",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01000101", x"0016",                 -- halt         (+), instruction_in(+), instruction_addr   (-)
            '0', '1', x"0000", x"0005", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01000101", x"0017",                 -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0001", x"0005", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode JMP : Desempilha Op1(2 bytes) e o atribui no registrador IP
            ('0', x"F0", x"0018",                        -- halt         (+), instruction_in (+), instruction_addr   (-)
             '1', '0', x"0000", x"0000", x"0000001A",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
             '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            ),

            -- Opcode Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
            ('0', b"01000101", x"001A",                 -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0000", x"0005", x"00000000",    -- r_dmem       (-), w_dmem         (-),                    (?), dmem_data_addr (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '0', '0', '0',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in       (-)
            )
            

        );
    begin

        for i in tabela_verdade'range loop

            halt <= tabela_verdade(i).halt;
            instruction_in <= tabela_verdade(i).instruction_in;
            dmem_data_out <= tabela_verdade(i).mem_data_out;
            valid <= tabela_verdade(i).codec_valid;
            codec_out <= tabela_verdade(i).codec_data_out;

            -- Range = (halted --> fetch_instruction --> decode_instruction --> execute_instruction --> modify_ip)
            for j in 0 to 3 loop
                clock <= not clock;
                wait for 1 ns;
                clock <= not clock;
                wait for 1 ns;
            end loop;

            wait for 2 ns;

            assert instruction_addr = tabela_verdade(i).instruction_addr 
                report "ERROR instruction_addr : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: "  &
                integer'image(to_integer(unsigned(tabela_verdade(i).instruction_addr))) & " != " &
                integer'image(to_integer(unsigned(instruction_addr)))
            severity failure;

            assert r_dmem = tabela_verdade(i).mem_data_read
                report "ERROR mem_data_read : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: " &
                std_logic'image(tabela_verdade(i).mem_data_read) & " != " &
                std_logic'image(r_dmem)
            severity failure;

            assert w_dmem = tabela_verdade(i).mem_data_write
                report "ERROR mem_data_write : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: " &
                std_logic'image(tabela_verdade(i).mem_data_write) & " != " &
                std_logic'image(w_dmem)
            severity failure;

            assert interrupt = tabela_verdade(i).codec_interrupt
                report "ERROR codec_interrupt : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: " &
                std_logic'image(tabela_verdade(i).codec_interrupt) & " != " &
                std_logic'image(interrupt)
            severity failure;

            assert codec_read = tabela_verdade(i).codec_read
                report "ERROR codec_read : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: " &
                std_logic'image(tabela_verdade(i).codec_read) & " != " &
                std_logic'image(codec_read)
            severity failure;

            assert codec_write = tabela_verdade(i).codec_write
                report "ERROR codec_write : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: " &
                std_logic'image(tabela_verdade(i).codec_write) & " != " &
                std_logic'image(codec_write)
            severity failure;

            assert to_integer(unsigned(dmem_data_addr)) = to_integer(unsigned(tabela_verdade(i).mem_data_addr))
                report "ERROR mem_data_addr : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: "  &
                integer'image(to_integer(unsigned(tabela_verdade(i).mem_data_addr))) & " != " &
                integer'image(to_integer(unsigned(dmem_data_addr)))
            severity failure;

            assert dmem_data_in = tabela_verdade(i).mem_data_in
                report "ERROR mem_data_in : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: " &
                integer'image(to_integer(signed(tabela_verdade(i).mem_data_in))) & " != " &
                integer'image(to_integer(signed(dmem_data_in)))
            severity failure;
        
            assert to_integer(unsigned(codec_in)) = to_integer(unsigned(tabela_verdade(i).codec_data_in))
                report "ERROR codec_in : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: " &
                integer'image(to_integer(unsigned(tabela_verdade(i).codec_data_in))) & " != " &
                integer'image(to_integer(unsigned(codec_in)))
            severity failure;
        end loop; 
    report "The end of tests";
    end process;
end architecture;