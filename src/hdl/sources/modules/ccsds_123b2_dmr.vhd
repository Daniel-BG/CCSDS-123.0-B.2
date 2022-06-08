----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.02.2022 09:21:23
-- Design Name: 
-- Module Name: ccsds_123b2_dmr - Behavioral
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

entity ccsds_123b2_dmr is
	port ( 
		clk, rst				: in std_logic;
		--core config
		cfg_full_prediction		: in std_logic;
		cfg_p					: in std_logic_vector(CONST_MAX_P_WIDTH_BITS - 1 downto 0);
		cfg_wide_sum			: in std_logic;
		cfg_neighbor_sum		: in std_logic;
		cfg_smid 				: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
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
--		cfg_weight_vec			: in std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
		--encoder things
		cfg_initial_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_final_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_gamma_star			: in std_logic_vector(CONST_MAX_GAMMA_STAR_BITS - 1 downto 0);
		cfg_u_max				: in std_logic_vector(CONST_U_MAX_BITS - 1 downto 0);
		cfg_iacc				: in std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
		--cfg error out
		cfg_error				: out std_logic_vector(31 downto 0);

		--input port
		axis_in_s_d				: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_s_valid			: in std_logic;
		axis_in_s_ready			: out std_logic;
		--output port
		axis_out_data			: out std_logic_vector(63 downto 0);
		axis_out_valid			: out std_logic;
		axis_out_last			: out std_logic;
		axis_out_ready			: in std_logic;
		--dmr_output
		dmr_error_0, dmr_error_1: out std_logic
	);
end ccsds_123b2_dmr;

architecture Behavioral of ccsds_123b2_dmr is
	--inner reset
	signal inner_reset: std_logic;
	--input splitter buses
	signal axis_in_0_s_valid, axis_in_0_s_ready, axis_in_1_s_valid, axis_in_1_s_ready: std_logic;
	signal axis_in_0_s_d, axis_in_1_s_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	--output buses
	signal axis_out_0_data, axis_out_1_data: std_logic_vector(63 downto 0);
	signal axis_out_0_valid, axis_out_0_last, axis_out_0_ready, axis_out_1_valid, axis_out_1_last, axis_out_1_ready: std_logic;
	signal output_bus_0, output_bus_1: std_logic_vector(65 downto 0);
begin

	reset_replicator: entity work.reset_replicator
		port map (
			clk => clk, rst => rst,
			rst_out => inner_reset
		);

input_splitter: entity work.AXIS_SPLITTER_2 
	Generic map (
		DATA_WIDTH => CONST_MAX_DATA_WIDTH
	)
	Port map (
		clk 			=> clk,
		rst				=> inner_reset,
		--to input axi port
		input_valid		=> axis_in_s_valid,
		input_data		=> axis_in_s_d,
		input_ready		=> axis_in_s_ready,
		--to output axi ports
		output_0_valid	=> axis_in_0_s_valid,
		output_0_data	=> axis_in_0_s_d,
		output_0_ready	=> axis_in_0_s_ready,
		output_0_last 	=> open,
		output_0_user	=> open,
		output_1_valid	=> axis_in_1_s_valid,
		output_1_data	=> axis_in_1_s_d,
		output_1_ready	=> axis_in_1_s_ready,
		output_1_last 	=> open,
		output_1_user	=> open
	);

core_0: entity work.ccsds_123b2_core
	port map ( 
		clk 					=> clk,
		rst 					=> inner_reset,
		cfg_full_prediction		=> cfg_full_prediction,
		cfg_p					=> cfg_p,
		cfg_wide_sum			=> cfg_wide_sum,
		cfg_neighbor_sum		=> cfg_neighbor_sum,
		cfg_smid 				=> cfg_smid,
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
		--relocators config
		cfg_max_x				=> cfg_max_x,
		cfg_max_y				=> cfg_max_y,
		cfg_max_z 				=> cfg_max_z,	
		cfg_max_t				=> cfg_max_t,
		cfg_min_preload_value 	=> cfg_min_preload_value,
		cfg_max_preload_value 	=> cfg_max_preload_value,
		--encoder things
		cfg_initial_counter		=> cfg_initial_counter,
		cfg_final_counter		=> cfg_final_counter,
		cfg_gamma_star			=> cfg_gamma_star,
		cfg_u_max				=> cfg_u_max,
		cfg_iacc				=> cfg_iacc,
		--cfg error out
		cfg_error				=> cfg_error,
		--input port
		axis_in_s_d				=> axis_in_0_s_d,
		axis_in_s_valid			=> axis_in_0_s_valid,
		axis_in_s_ready			=> axis_in_0_s_ready,
		--output port
		axis_out_data			=> axis_out_0_data,
		axis_out_valid			=> axis_out_0_valid,
		axis_out_last			=> axis_out_0_last,
		axis_out_ready			=> axis_out_0_ready
	);
	
core_1: entity work.ccsds_123b2_core
	port map ( 
		clk 					=> clk,
		rst 					=> inner_reset,
		cfg_full_prediction		=> cfg_full_prediction,
		cfg_p					=> cfg_p,
		cfg_wide_sum			=> cfg_wide_sum,
		cfg_neighbor_sum		=> cfg_neighbor_sum,
		cfg_smid 				=> cfg_smid,
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
		--relocators config
		cfg_max_x				=> cfg_max_x,
		cfg_max_y				=> cfg_max_y,
		cfg_max_z 				=> cfg_max_z,	
		cfg_max_t				=> cfg_max_t,
		cfg_min_preload_value 	=> cfg_min_preload_value,
		cfg_max_preload_value 	=> cfg_max_preload_value,
		--encoder things
		cfg_initial_counter		=> cfg_initial_counter,
		cfg_final_counter		=> cfg_final_counter,
		cfg_gamma_star			=> cfg_gamma_star,
		cfg_u_max				=> cfg_u_max,
		cfg_iacc				=> cfg_iacc,
		--cfg error out
		cfg_error				=> open,
		--input port
		axis_in_s_d				=> axis_in_1_s_d,
		axis_in_s_valid			=> axis_in_1_s_valid,
		axis_in_s_ready			=> axis_in_1_s_ready,
		--output port
		axis_out_data			=> axis_out_1_data,
		axis_out_valid			=> axis_out_1_valid,
		axis_out_last			=> axis_out_1_last,
		axis_out_ready			=> axis_out_1_ready
	);
	
--map output to core 0
axis_out_data <= axis_out_0_data;
axis_out_valid <= axis_out_0_valid;
axis_out_last <= axis_out_0_last;
axis_out_0_ready <= axis_out_ready;
--map output request to core 1
axis_out_1_ready <= axis_out_ready;



--checkers:
output_bus_0 <= axis_out_0_data & axis_out_0_valid & axis_out_0_last;
output_bus_1 <= axis_out_1_data & axis_out_1_valid & axis_out_1_last;

checker_0: entity work.equality_checker
	generic map (BITS => axis_out_data'length+2)
	port map (clk => clk, rst => inner_reset,
		bits_0 => output_bus_0,
		bits_1 => output_bus_1,
		error => dmr_error_0);

checker_1: entity work.equality_checker
	generic map (BITS => axis_out_data'length+2)
	port map (clk => clk, rst => inner_reset,
		bits_1 => output_bus_0,
		bits_0 => output_bus_1,
		error => dmr_error_1);


end Behavioral;
