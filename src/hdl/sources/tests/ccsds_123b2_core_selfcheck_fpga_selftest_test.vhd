----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.01.2022 16:28:17
-- Design Name: 
-- Module Name: ccsds_123b2_core_selfcheck_fpga_selftest_test - Behavioral
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

entity ccsds_123b2_core_selfcheck_fpga_selftest_test is
--  Port ( );
end ccsds_123b2_core_selfcheck_fpga_selftest_test;

architecture Behavioral of ccsds_123b2_core_selfcheck_fpga_selftest_test is
	signal clk, rst: std_logic;
	signal selfcheck_full_failed, selfcheck_full_finished, selfcheck_ref_failed, selfcheck_ref_finished, selfcheck_timeout: std_logic;
	signal check_failed, check_finished: std_logic;
	signal test_finished: std_logic;
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
		wait for 20.0*C_CLK_PERIOD * (1 SEC);
		rst <= '0';
		wait;
	end process RESET_GEN;
	
	
	dut: entity work.ccsds_123b2_core_selfcheck_fpga_selftest port map(
		clk => clk,
		rst => rst,
		selfcheck_full_failed => selfcheck_full_failed,
		selfcheck_full_finished => selfcheck_full_finished,
		selfcheck_ref_failed => selfcheck_ref_failed,
		selfcheck_ref_finished => selfcheck_ref_finished,
		selfcheck_timeout => selfcheck_timeout,
		check_failed => check_failed,
		check_finished => check_finished,
		test_finished => test_finished
    );


end Behavioral;
