----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 12:35:19
-- Design Name: 
-- Module Name: qi_calc - Behavioral
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
use ieee.numeric_std.all;
use work.ccsds_data_structures.all;
use work.am_data_types.all;
use work.ccsds_constants.all;

entity qi_calc is
	Port ( 
		clk, rst: in std_logic;
		axis_in_pr_d 		: in std_logic_vector(CONST_PR_BITS downto 0);
		axis_in_pr_coord	: in coordinate_bounds_array_t;
		axis_in_pr_valid	: in std_logic;
		axis_in_pr_ready	: out std_logic;
		axis_in_mev_d 		: in std_logic_vector(CONST_MEV_BITS - 1 downto 0);
		axis_in_mev_valid	: in std_logic;
		axis_in_mev_ready	: out std_logic;
		axis_out_qi_d 		: out std_logic_vector(CONST_QI_BITS downto 0);
		axis_out_qi_valid	: out std_logic;
		axis_out_qi_ready 	: in std_logic;
		axis_out_qi_coord	: out coordinate_bounds_array_t
	);
end qi_calc;

architecture Behavioral of qi_calc is
	signal axis_joint_valid, axis_joint_ready: std_logic;
	signal axis_joint_pr: std_logic_vector(CONST_PR_BITS downto 0);
	signal axis_joint_mev: std_logic_vector(CONST_MEV_BITS downto 0);
	signal axis_joint_coord: coordinate_bounds_array_t;
	
	--modified signals
	signal axis_joint_pr_sign: std_logic;
	signal axis_joint_pr_abs: std_logic_vector(CONST_PR_BITS downto 0);
	signal axis_joint_mev_div: std_logic_vector(axis_joint_mev'length downto 0); --adds one bit
	
	
	signal axis_quot_d: std_logic_vector(axis_joint_pr_abs'range);
	signal axis_quot_sign: std_logic;
	
begin

	--DELTA is DWIDTH + 1 bits
	--we take abs value so DWIDTH + 2, but it never reaches minimum so we can get away with DWIDTH + 1
	--plus whatever bits mev has for the division
	--and we output the same, so DWIDTH + 1
	
	sync: entity work.AXIS_SYNCHRONIZER_2
		generic map (
			DATA_WIDTH_0	=> CONST_PR_BITS,
			DATA_WIDTH_1	=> CONST_MEV_BITS,
			LATCH			=> false,
			USER_WIDTH 		=> coordinate_bounds_array_t'length,
			USER_POLICY 	=> PASS_ZERO
		)
		port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid	=> axis_in_pr_valid,
			input_0_ready	=> axis_in_pr_ready,
			input_0_data   	=> axis_in_pr_d,
			input_0_user	=> axis_in_pr_coord, 
			input_1_valid 	=> axis_in_mev_valid,
			input_1_ready	=> axis_in_mev_ready,
			input_1_data 	=> axis_in_mev_d,

			--to output axi ports
			output_valid	=> axis_joint_valid,
			output_ready	=> axis_joint_ready,
			output_data_0	=> axis_joint_pr,
			output_data_1	=> axis_joint_mev,
			output_user		=> axis_joint_coord
		);
	
	axis_joint_pr_abs <= axis_joint_pr when signed(axis_joint_pr) >= 0 else std_logic_vector(-signed(axis_joint_pr));
	axis_joint_mev_div <= axis_joint_mev & "1";	
	axis_joint_pr_sign <= axis_joint_pr(axis_joint_pr'high);
	
	divider: entity work.axis_segmented_unsigned_divider
		generic map (
			DIVIDEND_WIDTH 	=> axis_joint_pr_abs'length,
			DIVISOR_WIDTH  	=> axis_joint_mev_div'length,
			LAST_POLICY    	=> PASS_ZERO,
			USER_WIDTH		=> axis_joint_coord'length,
			USER_POLICY		=> PASS_ZERO
		)
		port map ( 
			clk => clk, rst => rst,
			axis_dividend_data		=> axis_joint_pr_abs,
			axis_dividend_ready		=> axis_joint_ready,
			axis_dividend_valid		=> axis_joint_valid,
			axis_dividend_user		=> axis_joint_coord,
			axis_dividend_last 		=> axis_joint_pr_sign,
			axis_divisor_data		=> axis_joint_mev_div,
			axis_divisor_ready		=> open,
			axis_divisor_valid		=> axis_joint_valid,
			axis_output_quotient	=> axis_quot_d,
			axis_output_remainder	=> open,
			axis_output_last 		=> axis_quot_sign,
			axis_output_ready 		=> axis_out_qi_ready,
			axis_output_valid 		=> axis_out_qi_valid,
			axis_output_user 		=> axis_out_qi_coord
		);

	axis_out_qi_d <= axis_quot_d when axis_quot_sign = '0' else std_logic_vector(-signed(axis_quot_d));
	
end Behavioral;
