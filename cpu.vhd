library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
    generic (
    addr_width: natural := 16; -- Memory Address Width (in bits)
    data_width: natural := 8 -- Data Width (in bits)
);
    port (
        clock: in std_logic; -- Clock signal
        halt: in std_logic; -- Halt processor execution when '1'

        ---- Begin Memory Signals ---
        -- Instruction byte received from memory
        instruction_in : in std_logic_vector(data_width - 1 downto 0);
        -- Instruction address given to memory
        instruction_addr: out std_logic_vector(addr_width-1 downto 0);

        mem_data_read : out std_logic; -- When '1', read data from memory
        mem_data_write: out std_logic; -- When '1', write data to memory
        -- Data address given to memory
        mem_data_addr : out std_logic_vector(addr_width-1 downto 0);
        -- Data sent from memory when data_read = '1' and data_write = '0'
        mem_data_in : out std_logic_vector((data_width*2)-1 downto 0);
        -- Data sent to memory when data_read = '0' and data_write = '1'
        mem_data_out : in std_logic_vector((data_width*4)-1 downto 0);
        ---- End Memory Signals ---

        ---- Begin Codec Signals ---
        codec_interrupt: out std_logic; -- Interrupt signal
        codec_read: out std_logic; -- Read signal
        codec_write: out std_logic; -- Write signal
        codec_valid: in std_logic; -- Valid signal

        -- Byte written to codec
        codec_data_out : in std_logic_vector(7 downto 0);
        -- Byte read from codec
        codec_data_in : out std_logic_vector(7 downto 0)
        ---- End Codec Signals ---
 );
 end entity;

 architecture behavioral of cpu is

    type state_type is (halted, fetch_instruction, decode_instruction, execute_instruction, modify_ip);

    signal instruction_pointer, stack_pointer : natural := 0;
    signal current_state, next_state: state_type := halted; 

    signal instruction_opcode : std_logic_vector(data_width - 1 downto 4) := (others => '0');
    signal instruction_immediate : std_logic_vector((data_width/2)-1 downto 0) := (others => '0');

    -----------------------------------------------------------------------------------------------
    ---- Codec Signals Auxiliars ---
    signal aux_codec_interrupt, aux_codec_read, aux_codec_write : std_logic := '0'; 
    signal aux_codec_data_in : std_logic_vector(7 downto 0) := (others => '0');

     ---- Memory Signals Auxiliars ---
    signal aux_instruction_addr: std_logic_vector(addr_width-1 downto 0);

    signal aux_mem_data_read, aux_mem_data_write : std_logic := '0';
    signal aux_mem_data_addr : std_logic_vector(addr_width - 1 downto 0) := (others => '0');
    signal aux_mem_data_in : std_logic_vector((2 * data_width) - 1 downto 0) := (others => '0');

begin	

    process(clock) 
    begin
        if rising_edge(clock) then
            current_state <= next_state;
        end if;
    end process;

    process(current_state, halt) 
        variable operator_1, operator_2 : std_logic_vector(data_width - 1 downto 0) := (others => '0');
        variable operator_2bytes : std_logic_vector((2 * data_width) - 1 downto 0) := (others => '0');
    begin

        instruction_opcode <= instruction_in(data_width - 1 downto (data_width/2));
        instruction_immediate <= instruction_in((data_width/2)-1 downto 0);

        case current_state is

            -- Instruction : PUSHIP, JEQ e JMP (16 bits)

            -- IMEM : Intruction Memory = Memoria dos Opcodes
            -- DMEM : Data Memory = Memória dos Dados 

            -- codec_read = 1 : Lê o arquivo input.txt e possui o codec_out
            -- codec_write = 1 : Escreve no arquivo output.txt e NAO tem o codec_out

            -----------------------------------------------------------------------------------
            -- CPU está parada e não executa nenhuma instrução.
            when halted =>
                if(halt = '0') then
                    next_state <= fetch_instruction;
                end if;

            -----------------------------------------------------------------------------------
            -- CPU busco o próximo Endereço da Instrução; 
            when fetch_instruction =>
                -- O próximo estado será Halted, caso receba Halt = 1 do SoC.
                if(halt = '1') then
                    next_state <= halted;
        
                else
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= decode_instruction;

                    -- Impede o Coded de interromper a instrução, evita que o Codec funcione por rising_edge
                    -- O CPU recebe o Endereço da Instrução em Bits
                    aux_codec_interrupt <= '0';
                    aux_instruction_addr <= std_logic_vector(to_unsigned(instruction_pointer, addr_width));
                    -- Instruction_addr = data_addr
                end if;
            
            -----------------------------------------------------------------------------------
            -- CPU decodifica a instrução e carrega os operandos necessários para a execução.
            -- CPU recebe instruction da IMEM e a decodifica;
            when decode_instruction =>
                -- O próximo estado será Halted, caso receba Halt = 1 do SoC.
                if(halt = '1') then
                    next_state <= halted;
                
                -- Não carrega Bytes da DMEM: Instruções de Empilhar e/ou não acessam memória
                -- Halt : Interrompe a CPU indefinidamente
                -- Push IP : Empilha o endere¸co armazenado no registrador IP (2 bytes, primeiro MSB2 e depois LSB3).
                -- Push Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
                elsif(instruction_opcode = x"0" or instruction_opcode = x"3" or instruction_opcode = x"4") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= execute_instruction;

                -- Define as variáveis para o CODEC_READ
                -- In : Empilha byte recebido do CODEC (Codec_Read e Mem_Write)
                elsif(instruction_opcode = x"1") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= execute_instruction;

                    aux_codec_interrupt <= '1';
                    aux_codec_read <= '1';
                    aux_codec_write <= '0';
                
                -- Carrega 1 Byte da DMEM: Instruções de Empilhar/Desempilhar da memória
                -- OUT : Desempilha um byte e envia para o CODEC (Mem_Read e Codec_Write)
                -- DROP : Elimina um elemento da pilha.
                -- DUP : Reempilha o elemento no topo da pilha.
                elsif(instruction_opcode = x"2" or instruction_opcode = x"5" or instruction_opcode = x"6") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= execute_instruction;

                    aux_mem_data_read <= '1';
                    aux_mem_data_write <= '0';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer - 1, addr_width));
                    stack_pointer <= stack_pointer - 1;

                -- Carrega 4 Byte da DMEM: Instruções que precisa acessar a memória
                -- JEQ : Desempilha 3 OP's, verifica se OP1 é igual OP2 e se sim soma o OP3 no Instruction_Pointer
                elsif(instruction_opcode = x"E") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= execute_instruction;

                    aux_mem_data_read <= '1';
                    aux_mem_data_write <= '0';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer - 4, addr_width));
                    stack_pointer <= stack_pointer - 4;

                -- Carrega 2 Byte da DMEM: Instruções que precisa acessar a memória
                -- ADD : Desempilha Op1 e Op2 e empilha (Op1 + Op2).
                -- SUB : Desempilha Op1 e Op2 e empilha (Op1 - Op2).
                -- NAND : Desempilha Op1 e Op2 e empilha NAND(Op1, Op2).
                -- SLT : Desempilha Op1 e Op2 e empilha (Op1 < Op2).
                -- SHL : Desempilha Op1 e Op2 e empilha (Op1 ≪ Op2).
                -- SHR : Desempilha Op1 e Op2 e empilha (Op1 ≫ Op2).
                -- JUMP :Desempilha Op1(2 bytes) e o atribui no registrador IP.

                elsif (instruction_opcode = x"8" or instruction_opcode = x"9"  or instruction_opcode = x"A"  or 
                       instruction_opcode = x"B" or instruction_opcode = x"C" or instruction_opcode = x"D" or 
                       instruction_opcode = x"F") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= execute_instruction;

                    aux_mem_data_read <= '1';
                    aux_mem_data_write <= '0';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer - 2, addr_width));
                    stack_pointer <= stack_pointer - 2;

                end if;

            -----------------------------------------------------------------------------------       
            -- CPU executa a Instrução.
            when execute_instruction =>
                -- Go to halted state
                if(halt = '1') then
                    next_state <= halted;
                
                -- Halt : Interrompe a CPU indefinidamente
                elsif(instruction_opcode = x"0") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                -- In : Empilha byte recebido do CODEC (Codec_Read e Mem_Write)
                elsif(instruction_opcode = x"1") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    if (codec_valid = '1') then
                        aux_mem_data_read <= '0';
                        aux_mem_data_write <= '1';

                        aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                        aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & codec_data_out;

                        stack_pointer <= stack_pointer + 1;
                    end if;
    
                -- OUT : Desempilha um byte e envia para o CODEC (Mem_Read e Codec_Write)
                elsif(instruction_opcode = x"2") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    aux_codec_interrupt <= '1';
                    aux_codec_read <= '0';
                    aux_codec_write <= '1';
                    aux_codec_data_in <= mem_data_out(data_width - 1 downto 0);
        
                -- PUSHIP : Empilha o endereco armazenado no registrador IP(2 bytes, primeiro MSB2 e depois LSB3).
                elsif(instruction_opcode = x"3") then
                    -- Retorna o ciclo da Máquina de Estado da CPU..
                    next_state <= modify_ip;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';

                    stack_pointer <= stack_pointer + 1;
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    aux_mem_data_in <= instruction_in;

                -- PUSH imm : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrucao)
                elsif(instruction_opcode = x"4") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    aux_mem_data_in <= instruction_immediate;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    
                -- DROP : Elimina um elemento da pilha.
                elsif(instruction_opcode = x"5") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;
 
                    operator_1 := mem_data_out(data_width - 1 downto 0);
 
                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= STD_LOGIC_VECTOR(to_unsigned(stack_pointer, addr_width));
                    

                -- DUP : Reempilha o elemento no topo da pilha.
                elsif(instruction_opcode = x"6") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;
 
                    operator_1 := mem_data_out(data_width - 1 downto 0);
                    aux_mem_data_in <= STD_LOGIC_VECTOR(to_unsigned(0, data_width)) & operator_1;
 
                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= STD_LOGIC_VECTOR(to_unsigned(stack_pointer, addr_width));

                -- ADD : Desempilha Op1 e Op2 e empilha (Op1 + Op2).
                elsif(instruction_opcode = x"8") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;
                    
                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    operator_1 := std_logic_vector((signed(operator_1)) + (signed(operator_2)));

                    aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    
                -- SUB : Desempilha Op1 e Op2 e empilha (Op1 − Op2).
                elsif(instruction_opcode = x"9") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    operator_1 := std_logic_vector((signed(operator_1)) - (signed(operator_2)));

                    aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));

                -- NAND : Desempilha Op1 e Op2 e empilha NAND(Op1, Op2).
                elsif(instruction_opcode = x"A") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    operator_1 := std_logic_vector((signed(operator_1)) nand (signed(operator_2)));

                    mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));

                -- SLT : Desempilha Op1 e Op2 e empilha (Op1 < Op2).
                elsif(instruction_opcode = x"B") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);

                    if to_integer(unsigned(operator_1)) < to_integer(unsigned(operator_2)) then
                        aux_mem_data_in <= std_logic_vector(to_unsigned(1, data_width * 2));
                    else
                        aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width * 2));
                    end if;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));

                -- SHL : Desempilha Op1 e Op2 e empilha (Op1 ≪ Op2).
                elsif(instruction_opcode = x"C") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    
                    operator_1 := std_logic_vector(shift_left(unsigned(operator_1), to_integer(unsigned(operator_2))));

                    aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;
                    
                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));

                -- SHR : Desempilha Op1 e Op2 e empilha (Op1 ≫ Op2).
                elsif(instruction_opcode = x"D") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    operator_1 := std_logic_vector(shift_right(unsigned(operator_1), to_integer(unsigned(operator_2))));

                    aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;
                    
                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));                  
                
                -- JEQ : Desempilha Op1(1 byte), Op2(1 byte) e Op3(2 bytes); Verifica se (Op1 = Op2), caso positivo soma Op3 no registrador IP.
                elsif(instruction_opcode = x"E") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    operator_1 := mem_data_out((4 * data_width) - 1 downto 3 * data_width);
                    operator_2 := mem_data_out((3 * data_width) - 1 downto 2 * data_width);
                    operator_2bytes := mem_data_out((2 * data_width) - 1 downto 0);

                -- JUMP :Desempilha Op1(2 bytes) e o atribui no registrador IP.
                elsif(instruction_opcode = x"F") then
                    -- Retorna o ciclo da Máquina de Estado da CPU.
                    next_state <= modify_ip;

                    operator_2bytes := mem_data_out((2 * data_width) - 1 downto 0);             
                end if;

                -----------------------------------------------------------------------------------       
            -- CPU altera o IP.
            when modify_ip =>
            
                -- Go to halted state
                if(halt = '1') then
                    next_state <= halted;

                -- Não carrega Bytes da DMEM: Instruções de Empilhar e/ou não acessam memória
                -- Halt : Interrompe a CPU indefinidamente
                -- Push IP : Empilha o endere¸co armazenado no registrador IP (2 bytes, primeiro MSB2 e depois LSB3).
                -- Push Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
                elsif(instruction_opcode = x"0") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= halted;
                    instruction_pointer <= instruction_pointer + 1;

                -- In : Empilha byte recebido do CODEC (Codec_Read e Mem_Write)
                -- OUT : Desempilha um byte e envia para o CODEC (Mem_Read e Codec_Write)
                elsif(instruction_opcode = x"1" or instruction_opcode = x"2") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= fetch_instruction;

                    instruction_pointer <= instruction_pointer + 1;
    
                -- DROP : Elimina um elemento da pilha.
                -- DUP : Reempilha o elemento no topo da pilha.
                -- Push IP : Empilha o endere¸co armazenado no registrador IP (2 bytes, primeiro MSB2 e depois LSB3).
                -- Push Imme : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrução)
                -- ADD : Desempilha Op1 e Op2 e empilha (Op1 + Op2).
                -- SUB : Desempilha Op1 e Op2 e empilha (Op1 - Op2).
                -- NAND : Desempilha Op1 e Op2 e empilha NAND(Op1, Op2).
                -- SLT : Desempilha Op1 e Op2 e empilha (Op1 < Op2).
                -- SHL : Desempilha Op1 e Op2 e empilha (Op1 ≪ Op2).
                -- SHR : Desempilha Op1 e Op2 e empilha (Op1 ≫ Op2).
                elsif(instruction_opcode = x"3" or instruction_opcode = x"4" or instruction_opcode = x"5" or
                      instruction_opcode = x"6" or instruction_opcode = x"8" or instruction_opcode = x"9" or
                      instruction_opcode = x"A" or instruction_opcode = x"B" or instruction_opcode = x"C" or
                      instruction_opcode = x"D") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= fetch_instruction;

                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;

                -- JEQ : Desempilha 3 OP's, verifica se OP1 é igual OP2 e se sim soma o OP3 no Instruction_Pointer
                elsif(instruction_opcode = x"E") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= fetch_instruction;

                    if to_integer(unsigned(operator_1)) = to_integer(unsigned(operator_2)) then
                        instruction_pointer <= to_integer(unsigned(operator_2bytes));
                    else
                        instruction_pointer <= instruction_pointer + 1;
                    end if;
                
                -- JUMP :Desempilha Op1(2 bytes) e o atribui no registrador IP.
                elsif (instruction_opcode = x"F") then
                    -- Continua o ciclo da Máquina de Estado da CPU.
                    next_state <= fetch_instruction;

                    instruction_pointer <= to_integer(unsigned(operator_2bytes));         
                end if;
        
        end case;
    end process;
    

    ---- Begin Memory Signals ---
    instruction_addr <= aux_instruction_addr;  -- Instruction address given to memory

    mem_data_read <= aux_mem_data_read; -- When '1', read data from memory
    mem_data_write <= aux_mem_data_write; -- When '1', write data to memory
    mem_data_addr <= aux_mem_data_addr; -- Data address given to memory
    mem_data_in <= aux_mem_data_in; -- Data sent from memory when data_read = '1' and data_write = '0'

    ---- Begin Codec Signals ---
    codec_interrupt <= aux_codec_interrupt; -- Interrupt signal
    codec_read <= aux_codec_read; -- Read signal
    codec_write <= aux_codec_write; -- Write signal

    codec_data_in <= aux_codec_data_in;  -- Byte read from codec

end architecture;