----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.04.2021 14:17:25
-- Design Name: 
-- Module Name: code_table_clocked_rom - Behavioral
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

entity code_table_clocked_rom is
	Port ( 
		clk, enable, rst: in std_logic;
		addr_table_entry: in std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
		addr_input_symbol: in std_logic_vector(3 downto 0);
		data: out std_logic_vector(CONST_LOW_ENTROPY_TABLE_ENTRY_BITS-1 downto 0)
	);
end code_table_clocked_rom;

architecture Behavioral of code_table_clocked_rom is
	signal table_data: table_rom_t_v2 := CONST_LOW_ENTROPY_CODING_TABLE_V2;
	attribute rom_style : string; 
	attribute rom_style of table_data: signal is "block";
	
	signal inner_data: std_logic_vector(CONST_LOW_ENTROPY_TABLE_ENTRY_BITS-1 downto 0);

	signal final_addr: std_logic_vector(4 + CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
begin


	read_rom : process (clk, rst, enable)
	begin
		if rising_edge(clk) and enable = '1' then
			data <= inner_data;
		end if;
	end process read_rom;
	
	final_addr <= addr_table_entry & addr_input_symbol;
	inner_data <= table_data(to_integer(unsigned(final_addr)));	
	

end Behavioral;
