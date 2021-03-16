----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 10:41:55
-- Design Name: 
-- Module Name: pr_calc - Behavioral
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

entity pr_calc is
	generic (
		DATA_WIDTH: integer := 16
	);
	Port ( 
		clk, rst: in std_logic;
		axis_in_sample_d: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_in_sample_valid: in std_logic;
		axis_in_sample_ready: out std_logic;
		axis_in_psv_d: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_in_psv_valid: in std_logic;
		axis_in_psv_ready: out std_logic;
		axis_out_pr_d: out std_logic_vector(DATA_WIDTH downto 0);
		axis_out_pr_valid: out std_logic;
		axis_out_pr_ready: in std_logic
	);
end pr_calc;

architecture Behavioral of pr_calc is
	signal axis_joint_sample, axis_joint_psv: std_logic_vector(DATA_WIDTH - 1 downto 0);
begin

	sync_inputs: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => DATA_WIDTH,
			DATA_WIDTH_1 => DATA_WIDTH,
			LATCH 		 => false
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_in_sample_valid,
			input_0_ready => axis_in_sample_ready,
			input_0_data  => axis_in_sample_d,
			input_1_valid => axis_in_psv_valid,
			input_1_ready => axis_in_psv_ready,
			input_1_data  => axis_in_psv_d,
			--to output axi ports
			output_valid  => axis_out_pr_valid,
			output_ready  => axis_out_pr_ready,
			output_data_0 => axis_joint_sample,
			output_data_1 => axis_joint_psv
		);
		axis_out_pr_d <= std_logic_vector(signed("0" & axis_joint_sample) - signed("0" & axis_joint_psv));

end Behavioral;
