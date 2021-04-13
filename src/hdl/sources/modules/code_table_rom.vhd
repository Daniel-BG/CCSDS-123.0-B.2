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
		addr: in std_logic_vector(9 downto 0);
		data: out std_logic_vector(15*32-1 downto 0)
	);
end code_table_rom;

architecture Behavioral of code_table_rom is
	signal table_data: table_rom_t := CONST_LOW_ENTROPY_CODING_TABLE;
begin
	data <= table_data(to_integer(unsigned(addr)));
--	seq: process(clk, enable)
--	begin
--		if rising_edge(clk) then
--			if enable = '1' then
--				data <= low_entropy_coding_table(to_integer(unsigned(addr)));
--			end if;
--		end if;
--	end process;

end Behavioral;
