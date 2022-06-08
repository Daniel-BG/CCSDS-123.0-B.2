----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.02.2022 09:39:20
-- Design Name: 
-- Module Name: equality_checker - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity equality_checker is
	generic (
		BITS: integer := 64
	);
	port (
		rst, clk: in std_logic;
		bits_0, bits_1: in std_logic_vector(BITS - 1 downto 0);
		error: out std_logic
	);
end equality_checker;

architecture Behavioral of equality_checker is
begin

check: process(rst, clk)
begin
	if rising_edge(clk) then
		if (rst = '1') then
			error <= '0';
		else
			--tap bus to see data transferences
			if (bits_0 /= bits_1) then
				error <= '1';
			end if;
		end if;
	end if;
end process;


end Behavioral;
