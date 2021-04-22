----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2021 12:19:46
-- Design Name: 
-- Module Name: predictor - Behavioral
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

entity predictor is
	port (
		clk, rst				: in std_logic;
		--core config
		cfg_p					: in std_logic_vector(CONST_MAX_P_WIDTH_BITS - 1 downto 0);
		cfg_sum_type 			: in local_sum_t;
		cfg_samples				: in std_logic_vector(CONST_MAX_SAMPLES_BITS - 1 downto 0);
		cfg_tinc				: in std_logic_vector(CONST_TINC_BITS - 1 downto 0);
		cfg_vmax, cfg_vmin		: in std_logic_vector(CONST_VMINMAX_BITS - 1 downto 0);
		cfg_depth				: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		cfg_omega				: in std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
		cfg_weo					: in std_logic_vector(CONST_WEO_BITS - 1 downto 0);
		cfg_use_abs_err			: in std_logic;
		cfg_use_rel_err			: in std_logic;
		cfg_abs_err 			: in std_logic_vector(CONST_ABS_ERR_BITS - 1 downto 0);
		cfg_rel_err 			: in std_logic_vector(CONST_REL_ERR_BITS - 1 downto 0);
		cfg_smax				: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		cfg_resolution			: in std_logic_vector(CONST_RES_BITS - 1 downto 0);
		cfg_damping				: in std_logic_vector(CONST_DAMPING_BITS - 1 downto 0);
		cfg_offset				: in std_logic_vector(CONST_OFFSET_BITS - 1 downto 0);
		--relocators config
		cfg_max_x				: in std_logic_vector(CONST_MAX_X_VALUE_BITS - 1 downto 0);
		cfg_max_y				: in std_logic_vector(CONST_MAX_Y_VALUE_BITS - 1 downto 0);
		cfg_max_z 				: in std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);	
		cfg_max_t				: in std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
		cfg_min_preload_value 	: in std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);
		cfg_max_preload_value 	: in std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);
		--axis for starting weights (cfg)
		cfg_weight_vec			: in std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
		--input itself
		axis_in_s_d				: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_s_valid			: in std_logic;
		axis_in_s_ready			: out std_logic;
		--output
		axis_out_mqi_d			: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_mqi_ready		: in std_logic;
		axis_out_mqi_valid		: out std_logic;
		axis_out_mqi_coord		: out coordinate_bounds_array_t
	);
end predictor;

architecture Behavioral of predictor is
	signal axis_v2d_core_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_v2d_core_coord: coordinate_array_t;
	signal axis_v2d_core_valid, axis_v2d_core_ready: std_logic;
	
	signal axis_core_d2v_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_core_d2v_ready, axis_core_d2v_valid: std_logic;
	
	signal axis_out_mqi_full_coord: coordinate_array_t;
begin
	
	v2d: entity work.sample_rearrange
		port map ( 
			clk => clk, rst => rst,
			finished => open,
			cfg_max_x				=> cfg_max_x,
			cfg_max_y				=> cfg_max_y,
			cfg_max_z 				=> cfg_max_z,	
			cfg_max_t				=> cfg_max_t,
			cfg_min_preload_value 	=> cfg_min_preload_value,
			cfg_max_preload_value 	=> cfg_max_preload_value,
			axis_input_d			=> axis_in_s_d,
			axis_input_ready		=> axis_in_s_ready,
			axis_input_valid		=> axis_in_s_valid,
			axis_output_d			=> axis_v2d_core_d,
			axis_output_coord 		=> axis_v2d_core_coord,
			axis_output_last		=> open,
			axis_output_valid		=> axis_v2d_core_valid,
			axis_output_ready		=> axis_v2d_core_ready
		);
		
	core: entity work.predictor_core
		port map (
			clk => clk, rst => rst,
			cfg_p					=> cfg_p,
			cfg_sum_type 			=> cfg_sum_type,
			cfg_samples				=> cfg_samples,
			cfg_tinc				=> cfg_tinc,
			cfg_vmax				=> cfg_vmax,
			cfg_vmin				=> cfg_vmin,
			cfg_depth				=> cfg_depth,
			cfg_omega				=> cfg_omega,
			cfg_weo					=> cfg_weo,
			cfg_use_abs_err			=> cfg_use_abs_err,
			cfg_use_rel_err			=> cfg_use_rel_err,
			cfg_abs_err 			=> cfg_abs_err,
			cfg_rel_err 			=> cfg_rel_err,
			cfg_smax				=> cfg_smax,
			cfg_resolution			=> cfg_resolution,
			cfg_damping				=> cfg_damping,
			cfg_offset				=> cfg_offset,
			--axis for starting weights (cfg)
			cfg_weight_vec			=> cfg_weight_vec,
			--input itself
			axis_in_s_d				=> axis_v2d_core_d,
			axis_in_s_full_coord	=> axis_v2d_core_coord,
			axis_in_s_valid			=> axis_v2d_core_valid,
			axis_in_s_ready			=> axis_v2d_core_ready,
			--output
			axis_out_mqi_d			=> axis_core_d2v_d,
			axis_out_mqi_ready		=> axis_core_d2v_ready,
			axis_out_mqi_valid		=> axis_core_d2v_valid
		);
		
		
	d2v: entity work.sample_rearrange
		port map ( 
			clk => clk, rst => rst,
			finished => open,
			cfg_max_x				=> cfg_max_x,
			cfg_max_y				=> cfg_max_y,
			cfg_max_z 				=> cfg_max_z,	
			cfg_max_t				=> cfg_max_t,
			cfg_min_preload_value 	=> cfg_min_preload_value,
			cfg_max_preload_value 	=> cfg_max_preload_value,
			axis_input_d			=> axis_core_d2v_d,
			axis_input_ready		=> axis_core_d2v_ready,
			axis_input_valid		=> axis_core_d2v_valid,
			axis_output_d			=> axis_out_mqi_d,
			axis_output_coord 		=> axis_out_mqi_full_coord,
			axis_output_last		=> open,
			axis_output_valid		=> axis_out_mqi_valid,
			axis_output_ready		=> axis_out_mqi_ready
		);
	update_axis_out_mqi_coord: process(axis_out_mqi_full_coord) begin
		axis_out_mqi_coord <= F_CB2STDLV(F_STDLV2C(axis_out_mqi_full_coord).bounds);
	end process;
	
	
	--test stuff
	--pragma synthesis_off
	TEST_CHECK_INPUT_SAMPLES: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			SKIP => 0,
			FILE_NUMBER => 21
		)
		port map (
			clk => clk, rst => rst, 
			valid => axis_v2d_core_valid,
			ready => axis_v2d_core_ready,
			data  => axis_v2d_core_d
		);
	--pragma synthesis_on
end Behavioral;
