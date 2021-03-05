----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.03.2021 14:21:18
-- Design Name: 
-- Module Name: simple_dual_port_ram - Behavioral
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

entity simple_dual_port_ram is
	generic (
		DATA_WIDTH	: integer := 16;
		ADDR_WIDTH	: integer := 18;
		DEPTH		: integer := 2**18
	);
	port ( 
		clk: in std_logic;
		addra: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		dina: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		wena: in std_logic;
		addrb: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		doutb: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		rdenb: in std_logic
	);
end simple_dual_port_ram;

architecture Behavioral of simple_dual_port_ram is
	--ram signals
	type ram_t is array (0 to DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal ram: ram_t;
	
	signal output_reg: std_logic_vector(DATA_WIDTH - 1 downto 0);
	
begin
	assert DEPTH <= 2**ADDR_WIDTH report "RAM TOO DEEP FOR THE ADDRESS WIDTH" severity failure;
	
	doutb <= output_reg;
	
	ram_update: process(clk, addra, addrb, wena, dina) 
	begin
		if rising_edge(clk) then
			if wena = '1' then
				ram(to_integer(unsigned(addra))) <= dina;
			end if;
			if rdenb = '1' then
				output_reg <= ram(to_integer(unsigned(addrb)));
			end if;
		end if;
	end process;

end Behavioral;
