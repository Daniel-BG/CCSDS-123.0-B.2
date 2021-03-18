----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.03.2021 15:18:52
-- Design Name: 
-- Module Name: hrpsv_calc - Behavioral
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
use work.ccsds_math_functions.all;
use work.ccsds_constants.all;
use work.ccsds_data_structures.all;
use work.am_data_types.all;

entity hrpsv_calc is
	Port ( 
		clk, rst: in std_logic;
		cfg_in_data_width_log: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		cfg_in_weight_width_log: in std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0); 
		axis_in_pcd_d: in std_logic_vector(CONST_PCLD_BITS - 1 downto 0);
		axis_in_pcd_valid: in std_logic;
		axis_in_pcd_ready: out std_logic;
		axis_in_pcd_coord: in coordinate_bounds_array_t; --just piped
		axis_in_lsum_d: in std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
		axis_in_lsum_valid: in std_logic;
		axis_in_lsum_ready: out std_logic;
		axis_out_hrpsv_d: out std_logic_vector(CONST_HRPSV_BITS - 1 downto 0);
		axis_out_hrpsv_valid: out std_logic;
		axis_out_hrpsv_ready: in std_logic;
		axis_out_hrpsv_coord: out coordinate_bounds_array_t
	);
end hrpsv_calc;

architecture Behavioral of hrpsv_calc is

	signal axis_joint_valid, axis_joint_ready: std_logic;
	signal axis_joint_lsum: std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
	signal axis_joint_pcd: std_logic_vector(CONST_PCLD_BITS - 1 downto 0);
	signal axis_joint_coord: coordinate_bounds_array_t;
	
	--this ensures no overflow (maybe move somewhere else)
	constant U_TWO: std_logic_vector(2 downto 0) := "010";
	constant U_ONE: std_logic_vector(1 downto 0) := "01";
	signal hrpsv_unclamped, hrpsv_clamped, hrpsv_low, hrpsv_high: std_logic_vector(CONST_HRPSV_BITS - 1 downto 0);

begin

	sync_inputs: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_PCLD_BITS,
			DATA_WIDTH_1 => CONST_LSUM_BITS,
			LATCH 		 => false,
			USER_WIDTH   => coordinate_bounds_array_t'length,
			USER_POLICY  => PASS_ZERO
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_in_pcd_valid,
			input_0_ready => axis_in_pcd_ready,
			input_0_data  => axis_in_pcd_d,
			input_0_user  => axis_in_pcd_coord,
			input_1_valid => axis_in_lsum_valid,
			input_1_ready => axis_in_lsum_ready,
			input_1_data  => axis_in_lsum_d,
			--to output axi ports
			output_valid  => axis_joint_valid,
			output_ready  => axis_joint_ready,
			output_data_0 => axis_joint_pcd,
			output_data_1 => axis_joint_lsum,
			output_user   => axis_joint_coord
		);
		
		
		axis_out_hrpsv_valid <= axis_joint_valid;
		axis_out_hrpsv_coord <= axis_joint_coord;
		axis_joint_ready <= axis_out_hrpsv_ready;

		hrpsv_unclamped <= std_logic_vector(
			resize(signed(axis_joint_pcd), hrpsv_unclamped'length) 
			+
			shift_left(resize(signed(axis_joint_lsum), hrpsv_unclamped'length) , to_integer(unsigned(cfg_in_weight_width_log))) 
			+
			shift_left(resize(signed(U_TWO), hrpsv_unclamped'length), to_integer(unsigned(cfg_in_weight_width_log)))
		);
		
		hrpsv_low <= (others => '0');
		hrpsv_high <= std_logic_vector(
			shift_left(
				shift_left(resize(signed(U_ONE), hrpsv_unclamped'length), to_integer(unsigned(cfg_in_data_width_log))) - 1,
				to_integer(unsigned(cfg_in_weight_width_log) + 2)
			)
			+
			shift_left(resize(signed(U_TWO), hrpsv_unclamped'length), to_integer(unsigned(cfg_in_weight_width_log)))
		);
		
		axis_out_hrpsv_d <= hrpsv_low when hrpsv_unclamped(hrpsv_unclamped'high) = '1' --is negative
			else hrpsv_high when signed(hrpsv_unclamped) > signed(hrpsv_high) 
			else hrpsv_unclamped;

end Behavioral;
