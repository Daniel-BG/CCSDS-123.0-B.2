----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.06.2021 10:36:48
-- Design Name: 
-- Module Name: reset_replicator - Behavioral
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

entity reset_replicator is
	port ( 
		clk, rst: in std_logic;
		rst_out: out std_logic
	);
end reset_replicator;

architecture Behavioral of reset_replicator is

	type core_state_t is (ST_RESET, ST_WORKING);
	signal state_curr, state_next: core_state_t;	
begin

	core_state_comb: process( state_curr )
	begin
		state_next <= state_curr;
		if state_curr = ST_RESET then
			rst_out <= '1';
			state_next <= ST_WORKING;
		else
			rst_out <= '0';
		end if;
	end process core_state_comb; -- core_state_process

	core_state_seq : process (clk)
	begin
		if (rising_edge(clk)) then
			if rst = '1' then
				state_curr <= ST_RESET;
			else
				state_curr <= state_next;
			end if;
		end if;
	end process core_state_seq;

end Behavioral;
