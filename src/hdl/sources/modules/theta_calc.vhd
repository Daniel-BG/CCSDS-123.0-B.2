----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.03.2021 08:15:50
-- Design Name: 
-- Module Name: theta_calc - Behavioral
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
use work.ccsds_data_structures.all;
use ieee.numeric_std.all;

entity theta_calc is
	Port ( 
		clk, rst			: in std_logic;
		cfg_smax			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_psv_d		: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_psv_valid	: in std_logic;
		axis_in_psv_ready	: out std_logic;
		axis_in_mev_d		: in std_logic_vector(CONST_MEV_BITS - 1 downto 0);
		axis_in_mev_valid	: in std_logic;
		axis_in_mev_ready	: out std_logic;
		axis_out_theta_d	: out std_logic_vector(CONST_THETA_BITS - 1 downto 0);
		axis_out_theta_valid: out std_logic;
		axis_out_theta_ready: in std_logic
	);
end theta_calc;

architecture Behavioral of theta_calc is
	signal joint_valid, joint_ready: std_logic;
	signal joint_mev: std_logic_vector(CONST_MEV_BITS - 1 downto 0);
	signal joint_psv: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	
	constant INNER_REG_SIZE: integer := CONST_MAX_DATA_WIDTH + 1;
	constant DOUBLE_MEV_REG_SIZE: integer := CONST_MEV_BITS + 1;
	signal psv_minus_smin_plus_mev: std_logic_vector(INNER_REG_SIZE - 1 downto 0); --add one bit
	signal smax_minus_psv_plus_mev: std_logic_vector(INNER_REG_SIZE - 1 downto 0);
	signal two_times_mev_plus_one: std_logic_vector(DOUBLE_MEV_REG_SIZE - 1 downto 0);
	
	signal lower_theta, upper_theta: std_logic_vector(INNER_REG_SIZE - 1 downto 0);
	signal lower_theta_ready, lower_theta_valid, upper_theta_ready, upper_theta_valid: std_logic;
	
	signal joint_lower_theta, joint_upper_theta: std_logic_vector(INNER_REG_SIZE - 1 downto 0);
	
	signal inner_reset: std_logic;

begin
	
	reset_replicator: entity work.reset_replicator
		port map (
			clk => clk, rst => rst,
			rst_out => inner_reset
		);

	sync_inputs: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_MAX_DATA_WIDTH,
			DATA_WIDTH_1 => CONST_MEV_BITS,
			LATCH => true
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_0_valid => axis_in_psv_valid,
			input_0_ready => axis_in_psv_ready,
			input_0_data  => axis_in_psv_d,
			input_1_valid => axis_in_mev_valid,
			input_1_ready => axis_in_mev_ready,
			input_1_data  => axis_in_mev_d,
			output_valid  => joint_valid,
			output_ready  => joint_ready,
			output_data_0 => joint_psv,
			output_data_1 => joint_mev
		);
		
	psv_minus_smin_plus_mev <= std_logic_vector(resize(unsigned(joint_psv), INNER_REG_SIZE) + resize(unsigned(joint_mev), INNER_REG_SIZE));
	smax_minus_psv_plus_mev <= std_logic_vector(resize(unsigned(cfg_smax), INNER_REG_SIZE) - resize(unsigned(joint_psv), INNER_REG_SIZE) + resize(unsigned(joint_mev), INNER_REG_SIZE));
	two_times_mev_plus_one  <= joint_mev & "1";

	divider_lower_theta: entity work.axis_segmented_unsigned_divider 
		generic map (
			DIVIDEND_WIDTH => INNER_REG_SIZE,
			DIVISOR_WIDTH => DOUBLE_MEV_REG_SIZE
		)
		port map ( 
			clk => clk, rst => inner_reset,
			axis_dividend_data		=> psv_minus_smin_plus_mev,
			axis_dividend_ready		=> joint_ready,
			axis_dividend_valid		=> joint_valid,
			axis_divisor_data		=> two_times_mev_plus_one,
			axis_divisor_ready		=> open,
			axis_divisor_valid		=> joint_valid,
			axis_output_quotient	=> lower_theta,
			axis_output_ready 		=> lower_theta_ready,
			axis_output_valid 		=> lower_theta_valid
		);
		
	divider_upper_theta: entity work.axis_segmented_unsigned_divider 
		generic map (
			DIVIDEND_WIDTH => INNER_REG_SIZE,
			DIVISOR_WIDTH => DOUBLE_MEV_REG_SIZE
		)
		port map ( 
			clk => clk, rst => inner_reset,
			axis_dividend_data		=> smax_minus_psv_plus_mev,
			axis_dividend_ready		=> open,
			axis_dividend_valid		=> joint_valid,
			axis_divisor_data		=> two_times_mev_plus_one,
			axis_divisor_ready		=> open,
			axis_divisor_valid		=> joint_valid,
			axis_output_quotient	=> upper_theta,
			axis_output_ready 		=> upper_theta_ready,
			axis_output_valid 		=> upper_theta_valid
		);
		
	sync_outputs: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => INNER_REG_SIZE,
			DATA_WIDTH_1 => INNER_REG_SIZE,
			LATCH => true
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_0_valid => upper_theta_valid,
			input_0_ready => upper_theta_ready,
			input_0_data  => upper_theta,
			input_1_valid => lower_theta_valid,
			input_1_ready => lower_theta_ready,
			input_1_data  => lower_theta,
			output_valid  => axis_out_theta_valid,
			output_ready  => axis_out_theta_ready,
			output_data_0 => joint_upper_theta,
			output_data_1 => joint_lower_theta
		);
		
	axis_out_theta_d <= std_logic_vector(resize(unsigned(joint_lower_theta), CONST_THETA_BITS))
		when unsigned(joint_lower_theta) < unsigned(joint_upper_theta) else
		std_logic_vector(resize(unsigned(joint_upper_theta), CONST_THETA_BITS));

end Behavioral;
