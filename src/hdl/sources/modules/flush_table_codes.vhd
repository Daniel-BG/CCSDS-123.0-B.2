----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.04.2021 10:05:46
-- Design Name: 
-- Module Name: flush_table_codes - Behavioral
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
use work.ccsds_constants.all;
use ieee.numeric_std.all;

entity flush_table_codes is
	Port (
		clk, rst		: in std_logic;
		in_enable		: in std_logic;
		in_code_index	: in std_logic_vector(3 downto 0);
		in_code			: in std_logic_vector(31 downto 0);
		out_code_index	: in std_logic_vector(3 downto 0);
		out_code		: out std_logic_vector(31 downto 0)
	);
end flush_table_codes;

architecture Behavioral of flush_table_codes is
	signal flush_ram: flush_ram_t;
begin

	seq: process(clk, rst)
	begin
		if rst = '1' then
			flush_ram <= DEFAULT_FLUSH_RAM;
		elsif rising_edge(clk) and in_enable = '1' then
			flush_ram(to_integer(unsigned(in_code_index))) <= in_code;
		end if;
	end process;
	
	out_code <= flush_ram(to_integer(unsigned(out_code_index)));


end Behavioral;
