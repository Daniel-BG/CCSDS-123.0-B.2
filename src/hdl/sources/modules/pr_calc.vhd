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
use work.ccsds_constants.all;
use work.ccsds_data_structures.all;
use work.am_data_types.all;

entity pr_calc is
	Port ( 
		clk, rst			: in std_logic;
		axis_in_sample_d	: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_sample_valid: in std_logic;
		axis_in_sample_ready: out std_logic;
		axis_in_psv_d		: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_psv_valid	: in std_logic;
		axis_in_psv_ready	: out std_logic;
		axis_in_psv_coord	: in coordinate_bounds_array_t;
		axis_out_pr_d		: out std_logic_vector(CONST_PR_BITS - 1 downto 0);
		axis_out_pr_valid	: out std_logic;
		axis_out_pr_ready	: in std_logic;
		axis_out_pr_coord	: out coordinate_bounds_array_t
	);
end pr_calc;

architecture Behavioral of pr_calc is
	signal axis_joint_sample, axis_joint_psv: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
begin

	sync_inputs: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_MAX_DATA_WIDTH,
			DATA_WIDTH_1 => CONST_MAX_DATA_WIDTH,
			LATCH 		 => false,
			USER_WIDTH   => coordinate_bounds_array_t'length,
			USER_POLICY  => PASS_ONE
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
			input_1_user  => axis_in_psv_coord,
			--to output axi ports
			output_valid  => axis_out_pr_valid,
			output_ready  => axis_out_pr_ready,
			output_data_0 => axis_joint_sample,
			output_data_1 => axis_joint_psv,
			output_user   => axis_out_pr_coord
		);
		axis_out_pr_d <= std_logic_vector(signed("0" & unsigned(axis_joint_sample)) - signed("0" & unsigned(axis_joint_psv)));

end Behavioral;
