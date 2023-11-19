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

    type state_type is (halted, fetch_memory, decode_load, execute_store);

    signal instruction_pointer, stack_pointer : natural := 0;
    signal current_state, next_state: state_type := halted; 

    signal instruction_opcode : std_logic_vector(data_width - 1 downto 4) := (others => '0');
    signal instruction_immediate : std_logic_vector((data_width/2)-1 downto 0) := (others => '0');

    -----------------------------------------------------------------------------------------------
    signal aux_instruction_addr: std_logic_vector(addr_width-1 downto 0);

    signal aux_codec_interrupt, aux_codec_read, aux_codec_write : std_logic := '0'; 
    signal aux_codec_data_in : std_logic_vector(7 downto 0) := (others => '0');

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
                    next_state <= fetch_memory;
                end if;

            -----------------------------------------------------------------------------------
            -- CPU busca o endereço da instrução da memória; 
            -- CPU recupera a próxima instrução da memória.
            -- CPU acessa IMEM no endereco apontado por IP;
            when fetch_memory =>
                -- O próximo estado será: Halted
                if(halt = '1') then
                    next_state <= halted;
        
                else
                    -- Continua o ciclo normal da máquina de estado da CPU
                    next_state <= decode_load;

                    -- Impede o Coded de interromper a instrução, evita que o Codec funcione por rising_edge
                    -- O CPU recebe o valor do adress da instruction
                    aux_codec_interrupt <= '0';
                    aux_instruction_addr <= std_logic_vector(to_unsigned(instruction_pointer, addr_width));
                    -- Instruction_addr = data_addr
                end if;
            
            -----------------------------------------------------------------------------------
            -- CPU decodifica a instrução e carrega os operandos necessários para a execução.
            -- CPU recebe instruction da IMEM e a decodifica;
            when decode_load =>
                -- O próximo estado será: Halte
                if(halt = '1') then
                    next_state <= halted;
            
                -- Halt : Interrompe a CPU indefinidamente
                -- Load 0 byte from DMEM
                elsif(instruction_opcode = x"0") then
                    next_state <= execute_store;

                -- In : Empilha byte recebido do CODEC
                -- Read from CODEC and next Write on Memory
                elsif(instruction_opcode = x"1") then
                    next_state <= execute_store;

                    aux_codec_interrupt <= '1';
                    aux_codec_read <= '1';
                    aux_codec_write <= '0';
                
                -- OUT : Desempilha um byte e envia para o CODEC
                -- Load 1 byte from DMEM
                elsif(instruction_opcode = x"2") then
                    next_state <= execute_store;

                    aux_mem_data_read <= '1';
                    aux_mem_data_write <= '0';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer - 1, addr_width));
                    stack_pointer <= stack_pointer - 1;

                -- JEQ : Desempilha 3 OP's, verifica se OP1 é igual OP2 e se sim soma o OP3 no Instruction_Pointer
                -- Load 4 byte from DMEM
                elsif(instruction_opcode = x"E") then
                    next_state <= execute_store;

                    aux_mem_data_read <= '1';
                    aux_mem_data_write <= '0';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer - 4, addr_width));
                    stack_pointer <= stack_pointer - 4;

                -- Others Opcode: 
                -- Load 2 bytes from DMEM
                else
                    -- Continua o ciclo normal da máquina de estado da CPU
                    next_state <= execute_store;

                    aux_mem_data_read <= '1';
                    aux_mem_data_write <= '0';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer - 2, addr_width));
                    stack_pointer <= stack_pointer - 2;

                end if;

            -----------------------------------------------------------------------------------       
            -- CPU executa a instrução e armazena o resultado na memória, se necessário.
            -- CPU executa instruction (aplica opcode) e altera IP
            when execute_store =>
                -- Go to halted state
                if(halt = '1') then
                    next_state <= halted;
                
                -- Halt : Interrompe a CPU indefinidamente
                elsif(instruction_opcode = x"0") then
                    next_state <= halted;
                    instruction_pointer <= instruction_pointer + 1;

                -- In : Empilha byte recebido do CODEC
                -- Write in MEMORY 
                elsif(instruction_opcode = x"1") then
                    next_state <= fetch_memory;

                    if (codec_valid = '1') then
                        aux_mem_data_read <= '0';
                        aux_mem_data_write <= '1';

                        aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                        aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & codec_data_out;
                        -- mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & codec_data_out;
                        
                        stack_pointer <= stack_pointer + 1;
                    end if;

                    instruction_pointer <= instruction_pointer + 1;
    
                -- Out : Desempilha um byte e envia para o CODEC
                -- Write in MEMORY 
                elsif(instruction_opcode = x"2") then
                    next_state <= fetch_memory;

                    aux_codec_interrupt <= '1';
                    aux_codec_read <= '0';
                    aux_codec_write <= '1';
                    aux_codec_data_in <= mem_data_out(data_width - 1 downto 0);
                    
                    instruction_pointer <= instruction_pointer + 1;
        
                -- PUSHIP : ????????????? Empilha o endereco armazenado no registrador IP(2 bytes, primeiro MSB2 e depois LSB3).
                -- ?????????????
                elsif(instruction_opcode = x"3") then
                    next_state <= fetch_memory;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    
                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;

                -- PUSH imm : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrucao)
                -- ?????????????
                elsif(instruction_opcode = x"4") then
                    next_state <= fetch_memory;

                    aux_mem_data_in <= instruction_immediate;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    
                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;

                -- ADD : Desempilha Op1 e Op2 e empilha (Op1 + Op2).
                -- ?????????????
                elsif(instruction_opcode = x"8") then
                    next_state <= fetch_memory;
                    
                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    operator_1 := std_logic_vector((signed(operator_1)) + (signed(operator_2)));

                    aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    
                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;

                -- SUB : Desempilha Op1 e Op2 e empilha (Op1 − Op2).
                -- ?????????????
                elsif(instruction_opcode = x"9") then
                    next_state <= fetch_memory;

                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    operator_1 := std_logic_vector((signed(operator_1)) - (signed(operator_2)));

                    aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    
                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;

                -- NAND : Desempilha Op1 e Op2 e empilha NAND(Op1, Op2).
                -- ?????????????
                elsif(instruction_opcode = x"A") then
                    next_state <= fetch_memory;

                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    operator_1 := std_logic_vector((signed(operator_1)) nand (signed(operator_2)));

                    mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;

                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    
                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;

                -- SLT : Desempilha Op1 e Op2 e empilha (Op1 < Op2).
                -- ?????????????
                elsif(instruction_opcode = x"B") then
                    next_state <= fetch_memory;

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
                    
                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;

                -- SHL : Desempilha Op1 e Op2 e empilha (Op1 ≪ Op2).
                -- ?????????????
                elsif(instruction_opcode = x"C") then
                    next_state <= fetch_memory;

                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    
                    operator_1 := std_logic_vector(shift_left(unsigned(operator_1), to_integer(unsigned(operator_2))));

                    aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;
                    
                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    
                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;

                -- SHR : Desempilha Op1 e Op2 e empilha (Op1 ≫ Op2).
                -- ?????????????
                elsif(instruction_opcode = x"D") then
                    next_state <= fetch_memory;

                    -- Remove dois bytes da IMEM e devolva 1 byte
                    operator_1 := mem_data_out((2 * data_width) - 1 downto data_width);
                    operator_2 := mem_data_out(data_width - 1 downto 0);
                    operator_1 := std_logic_vector(shift_right(unsigned(operator_1), to_integer(unsigned(operator_2))));

                    aux_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;
                    
                    aux_mem_data_read <= '0';
                    aux_mem_data_write <= '1';
                    aux_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    
                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;
                
                -- JEQ : Desempilha Op1(1 byte), Op2(1 byte) e Op3(2 bytes); Verifica se (Op1 = Op2), caso positivo soma Op3 no registrador IP.
                -- ?????????????
                elsif(instruction_opcode = x"E") then
                    next_state <= fetch_memory;

                    stack_pointer <= stack_pointer + 1;
                    instruction_pointer <= instruction_pointer + 1;
                
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