----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.04.2021 14:17:25
-- Design Name: 
-- Module Name: code_table_rom - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ccsds_constants.all;

entity code_table_rom is
	Port ( 
--		clk, enable: in std_logic;
		addr: in std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS-1 downto 0);
		data: out std_logic_vector(CONST_INPUT_SYMBOL_AMOUNT*CONST_LOW_ENTROPY_TABLE_ENTRY_BITS-1 downto 0)
	);
end code_table_rom;

architecture Behavioral of code_table_rom is
	signal table_data: table_rom_t := CONST_LOW_ENTROPY_CODING_TABLE;
--	attribute ram_style : string;
--	attribute ram_style of table_data : signal is "block";
begin

data <= table_data(to_integer(unsigned(addr)));

--	seq: process(clk, enable)
--	begin
--		if rising_edge(clk) then
--			if enable = '1' then
--				data <= table_data(to_integer(unsigned(addr)));
--			end if;
--		end if;
--	end process;

end Behavioral;
