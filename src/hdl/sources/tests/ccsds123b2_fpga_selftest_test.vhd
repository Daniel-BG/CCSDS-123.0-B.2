----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.07.2021 19:07:16
-- Design Name: 
-- Module Name: ccsds123b2_fpga_selftest_test - Behavioral
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

entity ccsds123b2_fpga_selftest_test is
--  Port ( );
end ccsds123b2_fpga_selftest_test;

architecture Behavioral of ccsds123b2_fpga_selftest_test is
	signal clk, rst, failed, finished: std_logic;
	-- Other constants
	constant C_CLK_PERIOD : real := 10.0e-9; -- NS
begin

	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	CLK_GEN : process
	begin
		clk <= '1';
		wait for C_CLK_PERIOD / 2.0 * (1 SEC);
		clk <= '0';
		wait for C_CLK_PERIOD / 2.0 * (1 SEC);
	end process CLK_GEN;

	RESET_GEN : process
	begin
		wait until rising_edge(clk);
		rst <= '1';
		--input_enable <= '0';
		wait for 20.0*C_CLK_PERIOD * (1 SEC);
		wait for 0.5*C_CLK_PERIOD * (1 SEC);
		wait until rising_edge(clk);
		rst <= '0';
		wait;
	end process RESET_GEN;


	
	dut: entity work.ccsds123b2_fpga_selftest port map(
		clk => clk,
		rst => rst,
		failed => failed,
		finished => finished
    );


end Behavioral;
