----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 14:01:16
-- Design Name: 
-- Module Name: cqbc_calc - Behavioral
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

entity cqbc_calc is
	Port ( 
		clk, rst			: in std_logic;
		cfg_smax			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_psv_d		: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_psv_valid	: in std_logic;
		axis_in_psv_ready	: out std_logic;
		axis_in_qi_d		: in std_logic_vector(CONST_QI_BITS - 1 downto 0);
		axis_in_qi_valid	: in std_logic;
		axis_in_qi_ready	: out std_logic;
		axis_in_qi_coord	: in coordinate_bounds_array_t;
		axis_in_mev_d		: in std_logic_vector(CONST_MEV_BITS - 1 downto 0);
		axis_in_mev_valid	: in std_logic;
		axis_in_mev_ready	: out std_logic;
		axis_out_cqbc_d		: out std_logic_vector(CONST_CQBC_BITS - 1 downto 0);
		axis_out_cqbc_ready	: in std_logic;
		axis_out_cqbc_valid	: out std_logic;
		axis_out_cqbc_coord : out coordinate_bounds_array_t
	);
end cqbc_calc;

architecture Behavioral of cqbc_calc is
	
	signal axis_in_mev_t2p1: std_logic_vector(axis_in_mev_d'length downto 0);

	signal axis_mult_valid, axis_mult_ready: std_logic;
	signal axis_mult_d: std_logic_vector(axis_in_qi_d'length + axis_in_mev_d'length downto 0);
	signal axis_mult_coord: coordinate_bounds_array_t;
	
	signal joint_valid, joint_ready: std_logic;
	signal joint_psv: std_logic_vector(axis_in_psv_d'range);
	signal joint_mult: std_logic_vector(axis_in_qi_d'length + axis_in_mev_d'length downto 0);
	signal joint_coord: coordinate_bounds_array_t;

begin

	axis_in_mev_t2p1 <= axis_in_mev_d & "1";

	mult: entity work.AXIS_MULTIPLIER
		Generic map (
			DATA_WIDTH_0 => axis_in_qi_d'length,
			DATA_WIDTH_1 => axis_in_mev_d'length + 1, --length+1
			SIGNED_0=> true,
			SIGNED_1=> false,
			USER_WIDTH   => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst => rst,
			input_0_data	=> axis_in_qi_d,
			input_0_valid	=> axis_in_qi_valid,
			input_0_ready	=> axis_in_qi_ready,
			input_0_user 	=> axis_in_qi_coord,
			input_1_data	=> axis_in_mev_t2p1,
			input_1_valid	=> axis_in_mev_valid,
			input_1_ready	=> axis_in_mev_ready,
			output_data		=> axis_mult_d,
			output_valid	=> axis_mult_valid,
			output_ready	=> axis_mult_ready,
			output_user 	=> axis_mult_coord
		);
		
		
	sync: entity work.AXIS_SYNCHRONIZER_2
		generic map (
			DATA_WIDTH_0 => axis_in_psv_d'length,
			DATA_WIDTH_1 => axis_mult_d'length,
			LATCH 		 => false,
			USER_WIDTH   => coordinate_bounds_array_t'length,
			USER_POLICY  => PASS_ONE
		)
		port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_in_psv_valid,
			input_0_ready => axis_in_psv_ready,
			input_0_data  => axis_in_psv_d,
			input_1_valid => axis_mult_valid,
			input_1_ready => axis_mult_ready,
			input_1_data  => axis_mult_d,
			input_1_user  => axis_mult_coord,
			--to output axi ports
			output_valid  => joint_valid,
			output_ready  => joint_ready,
			output_data_0 => joint_psv,
			output_data_1 => joint_mult,
			output_user   => joint_coord
		);

	axis_out_cqbc_coord <= joint_coord;
	joint_ready <= axis_out_cqbc_ready;
	axis_out_cqbc_valid <= joint_valid;
	axis_out_cqbc_d <= 
				(others => '0') when -signed("0" & unsigned(joint_psv)) > signed(joint_mult)
		else 	cfg_smax when signed("0" & unsigned(joint_psv)) + signed(joint_mult) > signed("0" & unsigned(cfg_smax))
		else    std_logic_vector(resize(signed("0" & unsigned(joint_psv)) + signed(joint_mult), axis_out_cqbc_d'length)); --this is always positive
	

end Behavioral;
