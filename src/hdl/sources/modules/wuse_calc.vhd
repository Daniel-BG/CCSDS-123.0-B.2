----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.03.2021 14:21:06
-- Design Name: 
-- Module Name: wuse_calc - Behavioral
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
use ieee.numeric_std.all;

entity wuse_calc is
	Port ( 
		clk, rst			: in std_logic;
		cfg_samples			: in std_logic_vector(CONST_MAX_SAMPLES_BITS - 1 downto 0);
		cfg_tinc			: in std_logic_vector(CONST_TINC_BITS - 1 downto 0);
		cfg_vmax, cfg_vmin	: in std_logic_vector(CONST_VMINMAX_BITS - 1 downto 0);
		cfg_depth			: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		cfg_omega			: in std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
		axis_in_coord_t		: in std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
		axis_in_coord_valid	: in std_logic;
		axis_in_coord_ready	: out std_logic;
		axis_out_wuse_ready	: in std_logic;
		axis_out_wuse_valid	: out std_logic;
		axis_out_wuse_d		: out std_logic_vector(CONST_WUSE_BITS - 1 downto 0)
	);
end wuse_calc;

architecture Behavioral of wuse_calc is
	signal t_minus_samples: std_logic_vector(CONST_MAX_T_VALUE_BITS downto 0);
	signal t_minus_samples_ready, t_minus_samples_valid: std_logic;
	signal t_minus_samples_shifted: std_logic_vector(CONST_MAX_T_VALUE_BITS downto 0);
	
	signal t_minus_samples_shifted_plus_vmin: std_logic_vector(CONST_MAX_T_VALUE_BITS downto 0);
	signal t_minus_samples_shifted_plus_vmin_ready, t_minus_samples_shifted_plus_vmin_valid: std_logic;
	
	signal depth_minus_omega: std_logic_vector(CONST_WUSE_BITS - 1 downto 0);
	
	
	signal t_clipped: std_logic_vector(CONST_VMINMAX_BITS - 1 downto 0);
begin

	substract_samples_from_t: entity work.AXIS_ARITHMETIC_OP
		Generic map (
			DATA_WIDTH_0 => CONST_MAX_T_VALUE_BITS + 1,
			DATA_WIDTH_1 => CONST_MAX_SAMPLES_BITS + 1,
			OUTPUT_DATA_WIDTH => CONST_MAX_T_VALUE_BITS + 1,
			IS_ADD => false,
			SIGN_EXTEND_0	=> true,
			SIGN_EXTEND_1	=> true,
			SIGNED_OP		=> true,
			LATCH_INPUT_SYNC=> true
		)
		Port map (
			clk => clk, rst => rst,
			input_0_data(CONST_MAX_T_VALUE_BITS) => '0',
			input_0_data(CONST_MAX_T_VALUE_BITS - 1 downto 0) => axis_in_coord_t,
			input_0_valid	=> axis_in_coord_valid,
			input_0_ready	=> axis_in_coord_ready,
			input_1_data(CONST_MAX_SAMPLES_BITS) => '0',
			input_1_data(CONST_MAX_SAMPLES_BITS - 1 downto 0) => cfg_samples,
			input_1_valid	=> '1',
			input_1_ready	=> open,
			output_data		=> t_minus_samples,
			output_valid	=> t_minus_samples_valid,
			output_ready	=> t_minus_samples_ready
		);
	
	t_minus_samples_shifted <= std_logic_vector(shift_right(signed(t_minus_samples), to_integer(unsigned(cfg_tinc))));
	add_vmin_to_shifted_t_minus_samples: entity work.AXIS_ARITHMETIC_OP
		Generic map (
			DATA_WIDTH_0 => CONST_MAX_T_VALUE_BITS + 1,
			DATA_WIDTH_1 => CONST_VMINMAX_BITS,
			OUTPUT_DATA_WIDTH => CONST_MAX_T_VALUE_BITS + 1,
			IS_ADD => true,
			SIGN_EXTEND_0	=> true,
			SIGN_EXTEND_1	=> true,
			SIGNED_OP		=> true,
			LATCH_INPUT_SYNC=> false
		)
		Port map (
			clk => clk, rst => rst,
			input_0_data	=> t_minus_samples_shifted,
			input_0_valid	=> t_minus_samples_valid,
			input_0_ready	=> t_minus_samples_ready,
			input_1_data	=> cfg_vmin,
			input_1_valid	=> '1',
			input_1_ready	=> open,
			output_data		=> t_minus_samples_shifted_plus_vmin,
			output_valid	=> t_minus_samples_shifted_plus_vmin_valid,
			output_ready	=> t_minus_samples_shifted_plus_vmin_ready
		);
		
	depth_minus_omega <= std_logic_vector(signed("00" & cfg_depth) - signed("00" & cfg_omega));
	
	t_clipped <= 
		std_logic_vector(resize(signed(cfg_vmin), t_clipped'length)) when signed(t_minus_samples_shifted_plus_vmin) < signed(cfg_vmin) else
		std_logic_vector(resize(signed(cfg_vmax), t_clipped'length)) when signed(t_minus_samples_shifted_plus_vmin) > signed(cfg_vmax) else
		std_logic_vector(resize(signed(t_minus_samples_shifted_plus_vmin), t_clipped'length));
		
	final_adder: entity work.AXIS_ARITHMETIC_OP
		Generic map (
			DATA_WIDTH_0 => CONST_VMINMAX_BITS,
			DATA_WIDTH_1 => CONST_WUSE_BITS,
			OUTPUT_DATA_WIDTH => CONST_WUSE_BITS,
			IS_ADD => true,
			SIGN_EXTEND_0	=> true,
			SIGN_EXTEND_1	=> true,
			SIGNED_OP		=> true,
			LATCH_INPUT_SYNC=> true
		)
		Port map (
			clk => clk, rst => rst,
			input_0_data	=> t_clipped,
			input_0_valid	=> t_minus_samples_shifted_plus_vmin_valid,
			input_0_ready	=> t_minus_samples_shifted_plus_vmin_ready,
			input_1_data	=> depth_minus_omega,
			input_1_valid	=> '1',
			input_1_ready	=> open,
			output_data		=> axis_out_wuse_d,
			output_valid	=> axis_out_wuse_valid,
			output_ready	=> axis_out_wuse_ready
		);
	
end Behavioral;








