library ieee;
use ieee.std_logic_1164.all;

entity cpu is
    generic (
    addr_width: natural := 16; -- Memory Address Width (in bits)
    data_width: natural := 8 -- Data Width (in bits)
);
    port (
        clock: in std_logic; -- Clock signal
        halt : in std_logic; -- Halt processor execution when '1'

        ---- Begin Memory Signals ---
        -- Instruction byte received from memory
        instruction_in : in std_logic_vector(data_width-1 downto 0);
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

    type state_type is (halted, fetch, decode_load, execute_store)

    signal instruction_pointer, stack_pointer : natural := 0;,
    signal current_state, next_state: state_type := halted; 

begin	

    process(clock) 
    begin
        if rising_edge(clock) THEN
            current_state <= next_state;
        end if;
    end process;

    process(current_state, halt) 
        variable operator_1, operator_2 : std_logic_vector(data_width - 1 downto 0);
        variable operator_2bytes : std_logic_vector(addr_width - 1 downto 0);
    
    begin

    case current_state is

        -- Instruction : PUSHIP, JEQ e JMP (16bits)

        -- IMEM : Intruction Memory = Memoria dos Opcodes
        -- DMEM : Data Memory = Memória dos Dados 

        -----------------------------------------------------------------------------------
        -- CPU está parada e não executa nenhuma instrução.
        when halted =>
            if(halt = '0') then
                next_state <= fetch;
            end if;

        -----------------------------------------------------------------------------------
        -- CPU recupera a próxima instrução da memória.
        when fetch =>
            -- O próximo estado será: Halted
            if(halt = '1') then
                next_state <= halted;
      
            else
                -- Get instruction from IMEM
                next_state <= decode_load;

                -- Impede o Coded de interromper a instrução, evita que o Codec funcione por rising_edge
                temp_codec_interrupt <= '0';
                instruction_addr <= std_logic_vector(to_unsigned(instruction_pointer, addr_width));
            end if;
        
        -----------------------------------------------------------------------------------
        -- CPU decodifica a instrução e carrega os operandos necessários para a execução.
        when decode_load =>
            -- Go to halted state
            if(halt = '1') then
                next_state <= halted;
        
            -- Halt : Interrompe a CPU indefinidamente
            -- Load 0 byte from DMEM
            elsif(instruction_in = x"0") then
                next_state <= execute_store;

            -- In : Empilha byte recebido do CODEC
            -- Read from CODEC and next Write on Memory
            elsif(instruction_in = x"1") then
                next_state <= execute_store;

                temp_codec_interrupt <= '1';
                temp_codec_read <= '1';
                temp_codec_write <= '0';
            
            -- OUT : Desempilha um byte e envia para o CODEC
            -- Load 1 byte from DMEM
            elsif(instruction_in = x"2") then
                next_state <= execute_store;

                temp_mem_data_read <= '1';
                temp_mem_data_write <= '0';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer - 1, addr_width));
                stack_pointer <= stack_pointer - 1;

            -- JEQ : Desempilha 3 OP's, verifica se OP1 é igual OP2 e se sim soma o OP3 no Instruction_Pointer
            -- Load 4 byte from DMEM
            elsif(instruction_in = x"E") then
                next_state <= execute_store;

                temp_mem_data_read <= '1';
                temp_mem_data_write <= '0';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer - 4, addr_width));
                stack_pointer <= stack_pointer - 4;

            -- Others Opcode: 
            -- Load 2 bytes from DMEM
            else
                next_state <= execute_store;

                temp_mem_data_read <= '1';
                temp_mem_data_write <= '0';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer - 2, addr_width));
                stack_pointer <= stack_pointer - 2;

            end if;

        -----------------------------------------------------------------------------------       
        -- CPU executa a instrução e armazena o resultado na memória, se necessário.
        when execute_store =>
            -- Go to halted state
            if(halt = '1') then
                next_state <= halt;
            
            -- Halt : Interrompe a CPU indefinidamente
            elsif(instruction_in = x"0") then
                next_state <= halted;
                instruction_pointer <= instruction_pointer + 1;

            -- In : Empilha byte recebido do CODEC
            -- Write in MEMORY 
            elsif(instruction_in = x"1") then
                next_state <= fetch;

                if (codec_valid = '1') then
                    temp_mem_data_read <= '0';
                    temp_mem_data_write <= '1';
                    temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                    temp_mem_data_in <= std_logic_vector(0, data_width - 1 downto 7) & 
                                        codec_data_out;
                    -- temp_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & codec_data_out;
                    
                    stack_pointer <= stack_pointer + 1;
                end if;

                instruction_pointer <= instruction_pointer + 1;
 
            -- Out : Desempilha um byte e envia para o CODEC
            -- Write in MEMORY 
            elsif(instruction_in = x"2") then
                next_state <= fetch;

                temp_codec_interrupt <= '1';
                temp_codec_read <= '0';
                temp_codec_write <= '1';
                temp_codec_data_in <= mem_data_out(data_width - 1 downto 0);
                
                instruction_pointer <= instruction_pointer + 1;
    
            -- PUSHIP : ????????????? Empilha o endereco armazenado no registrador IP(2 bytes, primeiro MSB2 e depois LSB3).
            -- ?????????????
            elsif(instruction_in = x"3") then
                next_state <= fetch;

                temp_mem_data_read <= '0';
                temp_mem_data_write <= '1';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                
                stack_pointer <= stack_pointer + 1;
                instruction_pointer <= instruction_pointer + 1;

            -- PUSH imm : Empilha um byte contendo imediato (armazenado nos 4 bits menos significativos da instrucao)
            -- ?????????????
            elsif(instruction_in = x"4") then
                next_state <= fetch;

                temp_mem_data_in <= std_logic_vector(to_unsigned(data_width - 1 downto 7));

                temp_mem_data_read <= '0';
                temp_mem_data_write <= '1';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                
                stack_pointer <= stack_pointer + 1;
                instruction_pointer <= instruction_pointer + 1;

            -- ADD : Desempilha Op1 e Op2 e empilha (Op1 + Op2).
            -- ?????????????
            elsif(instruction_in = x"8") then
                next_state <= fetch;
                
                -- Remove dois bytes da IMEM e devolva 1 byte
                operator_1 := mem_data_out(2 * data_width - 1 downto data_width);
                operator_2 := mem_data_out(data_width - 1 downto 0);
                operator_1 := std_logic_vector((signed(operator_1)) + (signed(operator_2)));

                temp_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;

                temp_mem_data_read <= '0';
                temp_mem_data_write <= '1';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                
                stack_pointer <= stack_pointer + 1;
                instruction_pointer <= instruction_pointer + 1;

            -- SUB : Desempilha Op1 e Op2 e empilha (Op1 − Op2).
            -- ?????????????
            elsif(instruction_in = x"9") then
                next_state <= fetch;

                -- Remove dois bytes da IMEM e devolva 1 byte
                operator_1 := mem_data_out(2 * data_width - 1 downto data_width);
                operator_2 := mem_data_out(data_width - 1 downto 0);
                operator_1 := std_logic_vector((signed(operator_1)) - (signed(operator_2)));

                temp_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;

                temp_mem_data_read <= '0';
                temp_mem_data_write <= '1';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                
                stack_pointer <= stack_pointer + 1;
                instruction_pointer <= instruction_pointer + 1;

            -- NAND : Desempilha Op1 e Op2 e empilha NAND(Op1, Op2).
            -- ?????????????
            elsif(instruction_in = x"A") then
                next_state <= fetch;

                -- Remove dois bytes da IMEM e devolva 1 byte
                operator_1 := mem_data_out(2 * data_width - 1 downto data_width);
                operator_2 := mem_data_out(data_width - 1 downto 0);
                operator_1 := std_logic_vector((signed(operator_1)) nand (signed(operator_2)));

                temp_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;

                temp_mem_data_read <= '0';
                temp_mem_data_write <= '1';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                
                stack_pointer <= stack_pointer + 1;
                instruction_pointer <= instruction_pointer + 1;

            -- SLT : Desempilha Op1 e Op2 e empilha (Op1 < Op2).
            -- ?????????????
            elsif(instruction_in = x"B") then
                next_state <= fetch;

                -- Remove dois bytes da IMEM e devolva 1 byte
                operator_1 := mem_data_out(2 * data_width - 1 downto data_width);
                operator_2 := mem_data_out(data_width - 1 downto 0);

                if to_integer(unsigned(operator_1)) < to_integer(unsigned(operator_2)) then
                    temp_mem_data_in <= std_logic_vector(to_unsigned(1, data_width * 2));
                else
                    temp_mem_data_in <= std_logic_vector(to_unsigned(0, data_width * 2));
                end if;

                temp_mem_data_read <= '0';
                temp_mem_data_write <= '1';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                
                stack_pointer <= stack_pointer + 1;
                instruction_pointer <= instruction_pointer + 1;

            -- SHL : Desempilha Op1 e Op2 e empilha (Op1 ≪ Op2).
            -- ?????????????
            elsif(instruction_in = x"C") then
                next_state <= fetch;

                -- Remove dois bytes da IMEM e devolva 1 byte
                operator_1 := mem_data_out(2 * data_width - 1 downto data_width);
                operator_2 := mem_data_out(data_width - 1 downto 0);
                operator_1 := std_logic_vector(shift_left(unsigned(operator_1)), to_integer(unsigned(operator_2)));

                temp_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;
                
                temp_mem_data_read <= '0';
                temp_mem_data_write <= '1';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                
                stack_pointer <= stack_pointer + 1;
                instruction_pointer <= instruction_pointer + 1;

            -- SHR : Desempilha Op1 e Op2 e empilha (Op1 ≫ Op2).
            -- ?????????????
            elsif(instruction_in = x"D") then
                next_state <= fetch;

                -- Remove dois bytes da IMEM e devolva 1 byte
                operator_1 := mem_data_out(2 * data_width - 1 downto data_width);
                operator_2 := mem_data_out(data_width - 1 downto 0);
                operator_1 := std_logic_vector(shift_right(unsigned(operator_1)), to_integer(unsigned(operator_2)));

                temp_mem_data_in <= std_logic_vector(to_unsigned(0, data_width)) & operator_1;
                
                temp_mem_data_read <= '0';
                temp_mem_data_write <= '1';
                temp_mem_data_addr <= std_logic_vector(to_unsigned(stack_pointer, addr_width));
                
                stack_pointer <= stack_pointer + 1;
                instruction_pointer <= instruction_pointer + 1;
            
            -- JEQ : Desempilha Op1(1 byte), Op2(1 byte) e Op3(2 bytes); Verifica se (Op1 = Op2), caso positivo soma Op3 no registrador IP.
            -- ?????????????
            elsif(instruction_in = x"E") then
                next_state <= fetch;

                stack_pointer <= stack_pointer + 1;
                instruction_pointer <= instruction_pointer + 1;
    end case;
    
    ---- Begin Memory Signals ---
    instruction_addr <= ;  -- Instruction address given to memory

    mem_data_read <= ; -- When '1', read data from memory
    mem_data_write <= ; -- When '1', write data to memory
    mem_data_addr <= ; -- Data address given to memory
    mem_data_in <= ; -- Data sent from memory when data_read = '1' and data_write = '0'

    ---- Begin Codec Signals ---
    codec_interrupt <= ; -- Interrupt signal
    codec_read <= ; -- Read signal
    codec_write <= ; -- Write signal

    codec_data_in <= ;  -- Byte read from codec

end architecture