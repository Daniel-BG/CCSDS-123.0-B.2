----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.04.2021 15:03:16
-- Design Name: 
-- Module Name: hybrid_encoder_active_table_address_table - Behavioral
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

entity hybrid_encoder_active_table_address_table is
	Port ( 
		clk, rst: in std_logic;
		read_index: in std_logic_vector(3 downto 0);
		read_addr: out std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
		write_enable: in std_logic;
		write_index: in std_logic_vector(3 downto 0);
		write_addr: in std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0)
	);
end hybrid_encoder_active_table_address_table;

architecture Behavioral of hybrid_encoder_active_table_address_table is
	type active_address_register_file_t is array(0 to 15) of std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
	
	signal active_addresses: active_address_register_file_t;
begin
	
	bypass: process(write_addr, read_index, write_index, active_addresses)
	begin
		if (read_index /= write_index) then
			read_addr <= active_addresses(to_integer(unsigned(read_index)));
		else
			read_addr <= write_addr;
		end if;
	end process;
	
	seq: process(clk, rst)
	begin
		if rst = '1' then
			for i in 0 to 15 loop
				active_addresses(i) <= std_logic_vector(to_unsigned(i, CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS));
			end loop;
		elsif (rising_edge(clk)) then
			if write_enable = '1' then
				active_addresses(to_integer(unsigned(write_index))) <= write_addr;
			end if;
		end if;
	end process;


end Behavioral;
