----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.03.2021 12:38:18
-- Design Name: 
-- Module Name: ccsds_123b2_core - Behavioral
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

entity ccsds_123b2_core is
	generic (
		USE_HYBRID_CODER		: boolean := true
	);
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
		axis_out_ready			: in std_logic
	);
end ccsds_123b2_core;

architecture Behavioral of ccsds_123b2_core is
	signal axis_pred_enc_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_pred_enc_ready, axis_pred_enc_valid: std_logic;
	signal axis_pred_enc_coord: coordinate_bounds_array_t;
			
	signal axis_enc_alg_code: std_logic_vector(CONST_OUTPUT_CODE_LENGTH - 1 downto 0);
	signal axis_enc_alg_length: std_logic_vector(CONST_OUTPUT_CODE_LENGTH_BITS - 1 downto 0);
	signal axis_enc_alg_valid, axis_enc_alg_ready, axis_enc_alg_last: std_logic;
begin

	cfg_check: process(cfg_p, cfg_tinc)
	begin
		cfg_error <= (others => '0');
		if unsigned(cfg_p) > CONST_MAX_P then
			cfg_error(31) <= '1';
		end if;
		if unsigned(cfg_samples) > CONST_MAX_SAMPLES or unsigned(cfg_samples) /= unsigned(cfg_max_x) + 1 then
			cfg_error(30) <= '1';
		end if;
		if unsigned(cfg_tinc) < CONST_TINC_MIN or unsigned(cfg_tinc) > CONST_TINC_MAX then
			cfg_error(29) <= '1';
		end if;
		if signed(cfg_vmin) < CONST_VMIN or signed(cfg_vmin) >= signed(cfg_vmax) or signed(cfg_vmax) > CONST_VMAX then
			cfg_error(28) <= '1';
		end if;
		if unsigned(cfg_depth) > CONST_MAX_DATA_WIDTH then
			cfg_error(27) <= '1';
		end if;
		if unsigned(cfg_omega) < CONST_MIN_OMEGA or unsigned(cfg_omega) > CONST_MAX_OMEGA then
			cfg_error(26) <= '1';
		end if;
		if signed(cfg_weo) < CONST_WEO_MIN or signed(cfg_weo) > CONST_WEO_MAX then
			cfg_error(25) <= '1';
		end if;
		if 	(unsigned(cfg_depth)  > 16 and unsigned(cfg_abs_err) > (2**16-1)) or 
			(unsigned(cfg_depth) <= 16 and unsigned(cfg_abs_err) > shift_right(unsigned(cfg_smax), 1)) then
			cfg_error(24) <= '1';
		end if;
		if 	(unsigned(cfg_depth)  > 16 and unsigned(cfg_rel_err) > (2**16-1)) or 
			(unsigned(cfg_depth) <= 16 and unsigned(cfg_rel_err) > shift_right(unsigned(cfg_smax), 1)) then
			cfg_error(23) <= '1';
		end if;
		if unsigned(cfg_resolution) > CONST_MAX_RES_VAL then
			cfg_error(22) <= '1';
		end if;
		if unsigned(cfg_damping) > (shift_left(to_unsigned(1, cfg_damping'length), to_integer(unsigned(cfg_resolution))) - 1) then
			cfg_error(21) <= '1';
		end if;
		if unsigned(cfg_offset)  > (shift_left(to_unsigned(1, cfg_damping'length), to_integer(unsigned(cfg_resolution))) - 1) then
			cfg_error(20) <= '1';
		end if;
		if unsigned(cfg_max_x) > CONST_MAX_X_VALUE then
			cfg_error(19) <= '1';
		end if;
		if unsigned(cfg_max_y) > CONST_MAX_Y_VALUE then
			cfg_error(18) <= '1';
		end if;
		if unsigned(cfg_max_z) > CONST_MAX_Z_VALUE then
			cfg_error(17) <= '1';
		end if;
		if unsigned(cfg_max_t) > CONST_MAX_T_VALUE then
			cfg_error(16) <= '1';
		end if;
		if unsigned(cfg_initial_counter) < 2**CONST_MIN_GAMMA_ZERO or unsigned(cfg_initial_counter) > 2**CONST_MIN_GAMMA_ZERO then
			cfg_error(15) <= '1';
		end if;
		if 	unsigned(cfg_final_counter) < (unsigned(cfg_initial_counter) & "0") or
			unsigned(cfg_final_counter) < 2**4 - 1 or
			unsigned(cfg_final_counter) > 2**CONST_MAX_GAMMA_STAR - 1 then
			cfg_error(14) <= '1';
		end if;
		if unsigned(cfg_final_counter) /= shift_left(to_unsigned(1, cfg_final_counter'length), to_integer(unsigned(cfg_gamma_star))) - 1 then
			cfg_error(13) <= '1';
		end if;
		if unsigned(cfg_u_max) < CONST_U_MAX_MIN or unsigned(cfg_u_max) > CONST_U_MAX_MAX then
			cfg_error(12) <= '1';
		end if;

	end process;


	predictor: entity work.predictor
		port map (
			clk => clk, rst => rst,
			--core config
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
			--relocators config
			cfg_max_x				=> cfg_max_x,
			cfg_max_y				=> cfg_max_y,
			cfg_max_z 				=> cfg_max_z,	 
			cfg_max_t				=> cfg_max_t,
			cfg_min_preload_value 	=> cfg_min_preload_value,
			cfg_max_preload_value 	=> cfg_max_preload_value,
			--axis for starting weights (cfg)
--			cfg_weight_vec			=> cfg_weight_vec,
			--input itself
			axis_in_s_d				=> axis_in_s_d,
			axis_in_s_valid			=> axis_in_s_valid,
			axis_in_s_ready			=> axis_in_s_ready,
			--output
			axis_out_mqi_d			=> axis_pred_enc_mqi,
			axis_out_mqi_ready		=> axis_pred_enc_ready,
			axis_out_mqi_valid		=> axis_pred_enc_valid,
			axis_out_mqi_coord		=> axis_pred_enc_coord
		);
		
	encoder: entity work.encoder_bypass
		generic map (
			USE_HYBRID_CODER => USE_HYBRID_CODER
		)
		Port map ( 
			clk => clk, rst => rst,
			cfg_initial_counter		=> cfg_initial_counter,
			cfg_final_counter		=> cfg_final_counter,
			cfg_u_max				=> cfg_u_max,
			cfg_depth 				=> cfg_depth,
			cfg_iacc				=> cfg_iacc,
			cfg_gamma_star			=> cfg_gamma_star,
			cfg_max_z				=> cfg_max_z,
			axis_in_mqi_d			=> axis_pred_enc_mqi,
			axis_in_mqi_ready		=> axis_pred_enc_ready,
			axis_in_mqi_valid		=> axis_pred_enc_valid,
			axis_in_mqi_coord		=> axis_pred_enc_coord,
			axis_out_code			=> axis_enc_alg_code,
			axis_out_length			=> axis_enc_alg_length,
			axis_out_coord			=> open,
			axis_out_valid			=> axis_enc_alg_valid,
			axis_out_ready			=> axis_enc_alg_ready,
			axis_out_last 			=> axis_enc_alg_last
		);
	
	assert axis_enc_alg_code'length <= 64 report "The aligner does not support codes bigger than 64, change it" severity failure;
	
	aligner: entity work.code_aligner
		Port map ( 
			clk => clk, rst => rst,
			axis_in_code		=> axis_enc_alg_code,
			axis_in_length		=> axis_enc_alg_length,
			axis_in_valid		=> axis_enc_alg_valid,
			axis_in_last		=> axis_enc_alg_last,
			axis_in_ready		=> axis_enc_alg_ready,
			axis_out_data		=> axis_out_data,
			axis_out_valid		=> axis_out_valid,
			axis_out_last		=> axis_out_last,
			axis_out_ready		=> axis_out_ready
		);
		
	--pragma synthesis_off
	TEST_CHECK_MQI_REORDERED: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MQI_BITS,
			SKIP => 0,
			FILE_NUMBER => 20
		)
		port map (
			clk => clk, rst => rst, 
			valid => axis_pred_enc_valid,
			ready => axis_pred_enc_ready,
			data  => axis_pred_enc_mqi
		);
	--pragma synthesis_on
		
end Behavioral;
