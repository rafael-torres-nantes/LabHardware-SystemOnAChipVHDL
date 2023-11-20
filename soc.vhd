library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

--> Entidade de mais alto nível da hierarquia
--> Irá conter todas as outras entidades.
--> Soc encapsula todas outras as entidades, de forma a interligá-las.

entity soc is
    generic (
        --> firmware filename informa o nome de arquivo que contém o firmware.
        --> O firmware será carregado na memória IMEM a partir do endereço zero quando a entidade soc for instanciada. 
        firmware_filename: string := "test_cases/firmware.bin"
    );
    port (
        -- clock: recebe o pulso de clock gerado por um circuito auxiliar externo.
        clock: in std_logic; -- Clock signal
        -- started: inicia a execução quando colocado no valor ’1’.
        -- started <= '1' a cpu irá buscar a primeira instrução do firmware no endereço zero da IMEM.
        started: in std_logic -- Start execution when '1'
    );
end entity;

architecture dataflow of soc is
    
    file firmware : text open read_mode is firmware_filename;

    constant addr_width : natural := 16;    -- Memory Address Width (in bits)
    constant data_width : natural := 8;     -- Data Width (in bits)

    -------------- CODEC --------------

    signal codec_interrupt: std_logic := '0';
    signal codec_read: std_logic  := '0';
    signal codec_write: std_logic := '0';
    signal codec_valid: std_logic := '0';

    signal codec_data_in: std_logic_vector(7 downto 0) := (others => '0');
    signal codec_data_out: std_logic_vector(7 downto 0):= (others => '0');
    
    -------------- IMEM --------------

    signal imem_data_read : std_logic := '0';
    signal imem_data_write: std_logic := '0';
    signal imem_data_addr : std_logic_vector(addr_width-1 downto 0)       := (others => '0');
    signal imem_data_in : std_logic_vector((2 * data_width)-1 downto 0)   := (others => '0');
    signal imem_data_out : std_logic_vector((4 * data_width)-1 downto 0) := (others => '0');

    -------------- DMEM --------------

    signal dmem_data_read : std_logic := '0';
    signal dmem_data_write: std_logic := '0';
    signal dmem_data_addr : std_logic_vector(addr_width-1 downto 0)      := (others => '0');
    signal dmem_data_in : std_logic_vector((2 * data_width)-1 downto 0)  := (others => '0');
    signal dmem_data_out : std_logic_vector((4 * data_width)-1 downto 0) := (others => '0');

    -------------- CPU --------------
    signal cpu_halt : std_logic  := '0';

    signal cpu_instruction_in : std_logic_vector(data_width - 1 downto 0):= (others => '0');
    signal cpu_instruction_addr: std_logic_vector(addr_width-1 downto 0) := (others => '0');

    ----------------------------------
    signal index : natural := 0;
    begin
        codec : entity work.codec(dataflow)
            port map(
                interrupt => codec_interrupt,
                read_signal => codec_read,
                write_signal => codec_write,
                valid => codec_valid,
                codec_data_in => codec_data_in,
                codec_data_out => codec_data_out
            );

        imem : entity work.memory(behavioral)
            generic map(
                addr_width => addr_width,
                data_width => data_width
            )
            port map(
                clock => clock,
                data_read => imem_data_read,
                data_write => imem_data_write,
                data_addr => imem_data_addr,
                data_in => imem_data_in,
                data_out => imem_data_out
            );

        dmem : entity work.memory(behavioral)
            generic map(
                addr_width => addr_width,
                data_width => data_width
            )
            port map(
                clock => clock,
                data_read => dmem_data_read,
                data_write => dmem_data_write,
                data_addr => dmem_data_addr,
                data_in => dmem_data_in,
                data_out => dmem_data_out
            );

        cpu : entity work.cpu(behavioral)
            generic map(
                addr_width => addr_width,
                data_width => data_width
            )
            port map(
                clock => clock,
                halt => cpu_halt,
                instruction_in => cpu_instruction_in,
                instruction_addr => cpu_instruction_addr,
                mem_data_read => dmem_data_read,
                mem_data_write => dmem_data_write,
                mem_data_addr => dmem_data_addr,
                mem_data_in => dmem_data_in,
                mem_data_out => dmem_data_out,
                codec_interrupt => codec_interrupt,
                codec_read => codec_read,
                codec_write => codec_write,
                codec_valid => codec_valid,
                codec_data_out => codec_data_out,
                codec_data_in => codec_data_in
            );
        
        process (clock, started, imem_data_out, cpu_instruction_addr) -- process to fill IMEM
            variable text_line : line;
            variable text_character : character;
        begin
            if not endfile(firmware) and rising_edge(clock) then
                -- Lê uma linha de texto do arquivo de entrada
                readline(firmware, text_line);
                for i in 0 to data_width - 1 loop
                    read(text_line, text_character);
                    if(text_character = '0') then
                        imem_data_in(data_width - 1 - i) <= '0'; 
                    else
                        imem_data_in(data_width - 1 - i) <= '1'; 
                    end if;
                end loop;
                
                -- Escreve os caracteres na IMEM : Instruction Memory
                -- Define as variáveis para passar para IMEM
                imem_data_read <= '0';
                imem_data_write <= '1';
                imem_data_addr <= std_logic_vector(to_unsigned(index, addr_width));

                index <= index + 1;
            end if;
            
            -- Leitura dos valores da IMEM : Instruction Memory
            -- Define as variáveis para passar para a CPU funcionar
            if (started = '1') then
                imem_data_read <= '1';
                imem_data_write <= '0';

                cpu_instruction_in <= imem_data_out(data_width - 1 downto 0);
                imem_data_addr <= cpu_instruction_addr;
                cpu_halt <= '0';
            else
                cpu_halt <= '1';

            end if;
    end process;
end architecture;