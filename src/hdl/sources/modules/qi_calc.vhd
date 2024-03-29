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
		axis_in_pr_d 		: in std_logic_vector(CONST_PR_BITS - 1 downto 0);
		axis_in_pr_coord	: in coordinate_bounds_array_t;
		axis_in_pr_valid	: in std_logic;
		axis_in_pr_ready	: out std_logic;
		axis_in_mev_d 		: in std_logic_vector(CONST_MEV_BITS - 1 downto 0);
		axis_in_mev_valid	: in std_logic;
		axis_in_mev_ready	: out std_logic;
		axis_out_qi_d 		: out std_logic_vector(CONST_QI_BITS - 1 downto 0);
		axis_out_qi_valid	: out std_logic;
		axis_out_qi_ready 	: in std_logic;
		axis_out_qi_coord	: out coordinate_bounds_array_t
	);
end qi_calc;

architecture Behavioral of qi_calc is
	constant CONST_INNER_R_BITS: integer := CONST_PR_BITS + 1;

	signal axis_joint_valid, axis_joint_ready: std_logic;
	signal axis_joint_pr: std_logic_vector(CONST_PR_BITS - 1 downto 0);
	signal axis_joint_mev: std_logic_vector(CONST_MEV_BITS - 1 downto 0);
	signal axis_joint_coord: coordinate_bounds_array_t;
	
	--modified signals
	signal axis_joint_pr_abs, axis_joint_pr_abs_plus_mev: std_logic_vector(CONST_INNER_R_BITS - 1 downto 0);
	signal axis_joint_mev_div: std_logic_vector(axis_joint_mev'length downto 0); --adds one bit
	
	--output signals
	signal axis_quot_d: std_logic_vector(axis_joint_pr_abs'range);
	signal axis_out_pr: std_logic_vector(CONST_PR_BITS - 1 downto 0);
	
	signal inner_reset: std_logic;

begin
	
	reset_replicator: entity work.reset_replicator
		port map (
			clk => clk, rst => rst,
			rst_out => inner_reset
		);

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
			clk => clk, rst => inner_reset,
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
	
	axis_joint_pr_abs <= std_logic_vector(resize(unsigned(axis_joint_pr), CONST_INNER_R_BITS)) when signed(axis_joint_pr) >= 0 else std_logic_vector(resize("0" & (-signed(axis_joint_pr)), CONST_INNER_R_BITS));
	axis_joint_pr_abs_plus_mev <= std_logic_vector(unsigned(axis_joint_pr_abs) + unsigned(axis_joint_mev));
	axis_joint_mev_div <= axis_joint_mev & "1";	
	
	divider: entity work.axis_segmented_unsigned_divider
		generic map (
			DIVIDEND_WIDTH 	=> axis_joint_pr_abs_plus_mev'length,
			DIVISOR_WIDTH  	=> axis_joint_mev_div'length,
			USER_WIDTH		=> axis_joint_coord'length + axis_joint_pr'length,
			USER_POLICY		=> PASS_ZERO
		)
		port map ( 
			clk => clk, rst => inner_reset,
			axis_dividend_data		=> axis_joint_pr_abs_plus_mev,
			axis_dividend_ready		=> axis_joint_ready,
			axis_dividend_valid		=> axis_joint_valid,
			axis_dividend_user(axis_joint_coord'length + axis_joint_pr'length - 1 downto axis_joint_pr'length) => axis_joint_coord,
			axis_dividend_user(axis_joint_pr'length - 1 downto 0) => axis_joint_pr,
			axis_divisor_data		=> axis_joint_mev_div,
			axis_divisor_ready		=> open,
			axis_divisor_valid		=> axis_joint_valid,
			axis_output_quotient	=> axis_quot_d,
			axis_output_remainder	=> open,
			axis_output_ready 		=> axis_out_qi_ready,
			axis_output_valid 		=> axis_out_qi_valid,
			axis_output_user(axis_joint_coord'length + axis_joint_pr'length - 1 downto axis_joint_pr'length) => axis_out_qi_coord,
			axis_output_user(axis_joint_pr'length - 1 downto 0) => axis_out_pr
		);

	axis_out_qi_d <= (others => '0') when axis_out_pr = (axis_out_pr'range => '0') else
						std_logic_vector(resize(unsigned(axis_quot_d), CONST_QI_BITS))  when axis_out_pr(axis_out_pr'high) = '0' else
						std_logic_vector(resize(-signed(axis_quot_d), CONST_QI_BITS));
	
end Behavioral;
