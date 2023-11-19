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
     signal codec_out : std_logic_vector(7 downto 0) := (others => '0');                -- Byte read from codec

    -- signal codec_read, codec_write, codec_interrupt : std_logic;
    -- signal codec_valid : std_logic; -- Out
    -- signal codec_data_out : std_logic_vector(7 downto 0);
    -- signal codec_data_in : std_logic_vector(7 downto 0); -- Out

begin

    cpu : entity work.cpu(behavioral)
        generic map (addr_width => addr_width, data_width => data_width)
        port map (clock, halt, instruction_in, instruction_addr,
                r_dmem, w_dmem, dmem_data_addr, dmem_data_in, dmem_data_out,
                interrupt, codec_read, codec_write, valid, codec_out, codec_in);

    -- memory : entity work.memory(behavioral)
    --     generic map (addr_width => addr_width, data_width => data_width)
    --     port map (clock => clock, 
    --         data_read => r_dmem, 
    --         data_write => w_dmem, 
    --         data_addr => dmem_data_addr, 
    --         data_in => dmem_data_in, 
    --         data_out => dmem_data_out);
        
    --     codec : entity work.codec(dataflow)
    --         port map (interrupt, codec_read, codec_write, valid, codec_in , codec_out);

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

        type vetor_tv is array (0 to 3) of line_tabela_verdade;
        constant tabela_verdade : vetor_tv := (
         
        -- Tabela Verdade
        -- (+) Entrada e (-) Saída
        -- IN

            ('0', x"10", x"0000",                       -- halt         (+), instruction_in (+), instruction_addr   (-)
            '0', '1', x"0000", x"0000",  x"00000000",   -- r_dmem       (-), w_dmem         (-), dmem_data_addr     (-), dmem_data_in   (-), dmem_data_out  (+)
            '1', '0', '1', '1',  x"00", x"00"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in (-)
            ), 

            ('0', x"20", x"0001",                       -- halt         (+), instruction_in (+), instruction_addr   (-)
            '1', '0', x"0000", x"00F3",  x"000000F3",   -- r_dmem       (-), w_dmem         (-), dmem_data_addr     (-), dmem_data_in   (-), dmem_data_out  (+)
            '0', '1', '1', '1',  x"00", x"F3"           -- codec_read   (-), codec_write    (-), interrupt          (-), codec_valid    (+), codec_out      (+), codec_in (-)
            ),

            ('0', x"20", x"0001", -- halt (+), instruction_in (+), instruction_addr (-)
            '1', '0', x"0001", x"00F3",  x"000000F3",  -- r_dmem (-), w_dmem (-), dmem_data_addr (-), dmem_data_in (-), dmem_data_out (+)
            '0', '1', '1', '1',  x"00", x"F3"   -- , codec_read (-), codec_write (-), interrupt (-), codec_valid (+), codec_out (+), codec_in (-)
            ),

            ('0', x"10", x"0001", -- halt (+), instruction_in (+), instruction_addr (-)
             '0', '1', x"0000", x"0000",  x"00000000",  -- r_dmem (-), w_dmem (-), dmem_data_addr (-), dmem_data_in (-), dmem_data_out (+)
             '1', '0', '1', '1',  "00000000", "00000000"   -- codec_read (-), codec_write (-), interrupt (-), codec_valid (+), codec_out (+), codec_in (-)
            )

        );

    --     TYPE vetor_tabela_verdade IS ARRAY (0 TO 3) OF colunas_tabela_verdade;

    --     -- Implement more test cases
    --     CONSTANT tabela_verdade : vetor_tabela_verdade := (
    --     (
    --         '0', x"10", x"0000", -- IN
    --         '0', '1', x"0000", x"0000", x"00000000", -- Write DMEM
    --         '1', '1', '0', '1', x"00", x"00" -- Read CODEC
    --         )
    --         , (
    --         '0', x"10", x"0000", -- IN
    --         '0', '1', x"0000", x"0000", x"00000000", -- Write DMEM
    --         '1', '1', '0', '1', x"00", x"00" -- Read CODEC
    --         )
    --         , (
    --         '0', x"10", x"0000", -- IN
    --         '0', '1', x"0000", x"0000", x"00000000",
    --         '1', '1', '0', '1', x"00", x"00"
    --         )
    --         , (
    --         '0', x"A0", x"0000",
    --         '1', '0', x"0000", x"0000", x"00000000", -- Read DMEM
    --         '1', '0', '1', '1', x"00", x"00" -- Write CODEC
    --         )
    --         -- , (
    --         -- '0', x"C0", x"0003", -- OUT
    --         -- '1', '0', x"0001", x"00F3", x"000000F3", -- Read DMEM
    --         -- '1', '0', '1', '1', x"00", x"F3" -- Write CODEC
    --         -- )
    --         -- , (
    --         -- '0', x"D0", x"0004", -- OUT
    --         -- '1', '0', x"0001", x"00F3", x"000000F3", -- Read DMEM
    --         -- '1', '0', '1', '1', x"00", x"F3" -- Write CODEC
    --         -- )
    --         -- , (
    --         -- '0', x"20", x"0005", -- OUT
    --         -- '1', '0', x"0001", x"00F3", x"000000F3", -- Read DMEM
    --         -- '1', '0', '1', '1', x"00", x"F3" -- Write CODEC
    --         -- )
    --         -- , (
    --         -- '0', x"20", x"0006", -- OUT
    --         -- '1', '0', x"0000", x"00F3", x"0000000C", -- Read DMEM
    --         -- '1', '0', '1', '1', x"00", x"0C" -- Write CODEC
    --         -- )
    --     );

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

            assert to_integer(unsigned(dmem_data_addr)) = to_integer(unsigned(tabela_verdade(i).mem_data_addr))
                report "ERROR mem_data_addr : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: "  &
                integer'image(to_integer(unsigned(tabela_verdade(i).mem_data_addr))) & " != " &
                integer'image(to_integer(unsigned(dmem_data_addr)))
            severity failure;

            assert to_integer(unsigned(dmem_data_in)) = to_integer(unsigned(tabela_verdade(i).mem_data_in))
                report "ERROR mem_data_in : Valor não correspondente na tabela verdade. Linha[" &
                integer'image(i) & "], o resultado deveria ser: " &
                integer'image(to_integer(unsigned(tabela_verdade(i).mem_data_in))) & " != " &
                integer'image(to_integer(unsigned(dmem_data_in)))
            severity failure;
        

            ---- Begin Codec Signals ---
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

            assert codec_in = tabela_verdade(i).codec_data_in;

            clock <= '0';
            
        end loop; 

    end process;
end architecture;