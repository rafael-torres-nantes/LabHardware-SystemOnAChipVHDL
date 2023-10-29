library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
 	generic (
		addr_width: natural := 16; -- Memory Address Width (in bits)
	 	data_width: natural := 8 -- Data Width (in bits)
 );
	port (
		clock: in std_logic; -- Clock signal; Write on Falling-Edge

		data_read : in std_logic; -- When '1', read data from memory
		data_write: in std_logic; -- When '1', write data to memory
		-- Data address given to memory
		data_addr : in std_logic_vector(addr_width-1 downto 0);
		-- Data sent from memory when data_read = '1' and data_write = '0'
		data_in : in std_logic_vector((data_width*2)-1 downto 0);
		-- Data sent to memory when data_read = '0' and data_write = '1'
		data_out : out std_logic_vector((data_width*4)-1 downto 0)
);
end entity;

architecture behavioral of memory is
	subtype instruction is std_logic_vector((data_width-1) downto 0);
    type mem_type is array ((2 ** data_width - 1) downto 0) of instruction;
    signal mem : mem_type := (others => (others => '0'));

begin 
	process(clock) 
    begin

		data_out <= std_logic_vector(to_unsigned(0, data_width*4));

        if(data_write = '1' and falling_edge(clock)) then
                mem(to_integer(unsigned(data_addr))) <= data_in(data_width-1 downto 0); -- Instruction (OpCode + Immediate)
				mem(to_integer(unsigned(data_addr)) + 1) <= data_in(2*data_width-1 downto data_width); -- Instruction : PUSHIP, JEQ e JMP
        end if;

		if(data_read = '1') then
            data_out <= mem(to_integer(unsigned(data_addr)) + 3) &
						mem(to_integer(unsigned(data_addr)) + 2) &
						mem(to_integer(unsigned(data_addr)) + 1) &
						mem(to_integer(unsigned(data_addr)) + 0);
        end if;

    end process;

end behavioral;