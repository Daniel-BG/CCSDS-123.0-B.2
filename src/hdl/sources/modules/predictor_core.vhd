----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.03.2021 09:18:41
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
use work.ccsds_data_structures.all;
use work.ccsds_constants.all;
use work.am_data_types.all;
use ieee.numeric_std.all;

entity predictor_core is
	port (
		clk, rst				: in std_logic;
		cfg_p					: in std_logic_vector(CONST_MAX_P_WIDTH_BITS - 1 downto 0);
		cfg_full_prediction		: in std_logic;
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
		--axis for starting weights (cfg)
--		cfg_weight_vec			: in std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
		--input itself
		axis_in_s_d				: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0); --make sure we got enough space
		axis_in_s_full_coord	: in coordinate_array_t; --stdlv
		axis_in_s_valid			: in std_logic;
		axis_in_s_ready			: out std_logic;
		--output
		axis_out_mqi_d			: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_mqi_ready		: in std_logic;
		axis_out_mqi_valid		: out std_logic
	);
end predictor_core;

architecture Behavioral of predictor_core is
	signal inner_reset: std_logic;

	--input splitter signals
	--from input splitter to neighbor retrieval
	signal axis_is_nrcs_valid, axis_is_nrcs_ready: std_logic;
	signal axis_is_nrcs_full_coord: coordinate_array_t;
	signal axis_is_nrcs_coord: coordinate_bounds_array_t;
	--from input splitter to sample splitter
	signal axis_is_ss_valid, axis_is_ss_ready: std_logic;
	signal axis_is_ss_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0); 
	--from input splitter to coord splitter
	signal axis_is_cs_valid, axis_is_cs_ready: std_logic;
	signal axis_is_cs_full_coord: coordinate_array_t;
	--from input splitter to first pixel queue putter
	signal axis_is_fpp_valid, axis_is_fpp_ready: std_logic;
	signal axis_is_fpp_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0); 
	signal axis_is_fpp_full_coord: coordinate_array_t;
	signal axis_is_fpp_coord: coordinate_bounds_array_t;
	
	--sample splitter
	signal axis_ss_sprq_valid, axis_ss_sprq_ready: std_logic;
	signal axis_ss_sprq_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_ss_scrq_valid, axis_ss_scrq_ready: std_logic;
	signal axis_ss_scrq_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	
	--sample queues
	signal axis_sprq_pr_ready, axis_sprq_pr_valid: std_logic;
	signal axis_sprq_pr_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_scrq_cr_ready, axis_scrq_cr_valid: std_logic;
	signal axis_scrq_cr_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	
	--coordinate splitter
	signal axis_cqs_cqdq_valid, axis_cqs_cqdq_ready: std_logic;
	signal axis_cqs_cqdq_coord: coordinate_bounds_array_t;
	signal axis_cqs_cqdq_full_coord: coordinate_array_t;
	signal axis_cqs_cqwq_valid, axis_cqs_cqwq_ready: std_logic;
	signal axis_cqs_cqwq_coord: coordinate_bounds_array_t;
	signal axis_cqs_cqwq_full_coord: coordinate_array_t;
	signal axis_cqs_cqwuseq_valid, axis_cqs_cqwuseq_ready: std_logic;
	signal axis_cqs_cqwuseq_full_coord: coordinate_array_t; 
	signal axis_cqs_cqwuseq_t: std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
	
	--coordinate queues
	signal axis_cqdq_dqsy_ready, axis_cqdq_dqsy_valid: std_logic;
	signal axis_cqdq_dqsy_d: coordinate_bounds_array_t; 
	signal axis_cqwq_wu_coord: coordinate_bounds_array_t;
	signal axis_cqwq_wu_valid, axis_cqwq_wu_ready: std_logic;
	signal axis_cqwuseq_wu_t: std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
	signal axis_cqwuseq_wu_valid, axis_cqwuseq_wu_ready: std_logic;
	
	--from first pixel queue putter to first pixel queue
	signal axis_fpp_fpq_valid, axis_fpp_fpq_ready: std_logic;
	signal axis_fpp_fpq_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	--from first pixel queue to drpsv
	signal axis_fpq_drpsv_valid, axis_fpq_drpsv_ready: std_logic;
	signal axis_fpq_drpsv_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	
	--from current representative splitter to neighbor retrieval
	signal axis_crs_nr_valid, axis_crs_nr_ready: std_logic;
	signal axis_crs_nr_coord: coordinate_bounds_array_t;
	signal axis_crs_nr_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	--from neighbor retrieval to local sum
	signal axis_nr_ls_valid, axis_nr_ls_ready: std_logic;
	signal axis_nr_ls_w, axis_nr_ls_wd, axis_nr_ls_n, axis_nr_ls_nw, axis_nr_ls_ne: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nr_ls_coord: coordinate_bounds_array_t;
	
	--ls to lss
	signal axis_ls_lss_d: std_logic_vector(CONST_MAX_DATA_WIDTH*3 + CONST_LSUM_BITS - 1 downto 0);
	signal axis_ls_lss_w, axis_ls_lss_n, axis_ls_lss_nw: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_ls_lss_ls:  std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
	signal axis_ls_lss_ready, axis_ls_lss_valid: std_logic;
	signal axis_ls_lss_coord: coordinate_bounds_array_t;
	
	--lss to dd and lsq
	signal axis_lss_dd_d: std_logic_vector(CONST_MAX_DATA_WIDTH*3 + CONST_LSUM_BITS - 1 downto 0);
	signal axis_lss_dd_w, axis_lss_dd_n, axis_lss_dd_nw: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_lss_dd_ls:  std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
	signal axis_lss_dd_ready, axis_lss_dd_valid: std_logic;
	signal axis_lss_dd_coord: coordinate_bounds_array_t;
	signal axis_lss_lshrpsvq_valid, axis_lss_lshrpsvq_ready: std_logic;
	signal axis_lss_lshrpsvq_d: std_logic_vector(CONST_MAX_DATA_WIDTH*3 + CONST_LSUM_BITS - 1 downto 0);
	signal axis_lss_lshrpsvq_ls: std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
	signal axis_lss_lscdq_valid, axis_lss_lscdq_ready: std_logic;
	signal axis_lss_lscdq_d: std_logic_vector(CONST_MAX_DATA_WIDTH*3 + CONST_LSUM_BITS - 1 downto 0);
	signal axis_lss_lscdq_ls: std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
	
	--local sum queues
	signal axis_lshrpsvq_hrpsv_ready,axis_lshrpsvq_hrpsv_valid: std_logic;
	signal axis_lshrpsvq_hrpsv_d: std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
	signal axis_lscdq_cd_ready,axis_lscdq_cd_valid: std_logic;
	signal axis_lscdq_cd_d: std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
	
	--dd to dvsy
	signal axis_dd_dqsy_nd_pre, axis_dd_dqsy_nwd_pre, axis_dd_dqsy_wd_pre: std_logic_vector(CONST_LDIF_BITS - 1 downto 0); 
	signal axis_dd_dqsy_nd, axis_dd_dqsy_nwd, axis_dd_dqsy_wd: std_logic_vector(CONST_LDIF_BITS - 1 downto 0); 
	signal axis_dd_dqsy_ready, axis_dd_dqsy_valid: std_logic;
	signal axis_dd_dqsy_coord: coordinate_bounds_array_t;
	
	--current diff to diff queue system
	signal axis_cd_dqsy_d: std_logic_vector(CONST_LDIF_BITS - 1 downto 0);
	signal axis_cd_dqsy_ready,axis_cd_dqsy_valid : std_logic;
	signal axis_cd_dqsy_coord: coordinate_bounds_array_t;
	
	--diff queue system to output splitter
	signal axis_dqsy_dvs_d: std_logic_vector(CONST_DIFFVEC_BITS - 1 downto 0);
	signal axis_dqsy_dvs_coord: coordinate_bounds_array_t;
	signal axis_dqsy_dvs_ready,axis_dqsy_dvs_valid: std_logic;
	
	--diff vector splitter to its outputs
	signal axis_dvs_dot_d, axis_dvs_dot_d_filtered: std_logic_vector(CONST_DIFFVEC_BITS - 1 downto 0);
	signal axis_dvs_dot_coord: coordinate_bounds_array_t;
	signal axis_dvs_dot_valid, axis_dvs_dot_ready: std_logic;
	signal axis_dvs_dvq_d: std_logic_vector(CONST_DIFFVEC_BITS - 1 downto 0);
	signal axis_dvs_dvq_coord: coordinate_bounds_array_t;
	signal axis_dvs_dvq_valid, axis_dvs_dvq_ready: std_logic;
	
	--diff vector queue for weight update
	signal axis_dvq_wu_ready, axis_dvq_wu_valid: std_logic;
	signal axis_dvq_wu_coord: coordinate_bounds_array_t;
	signal axis_dvq_wu_d: std_logic_vector(CONST_DIFFVEC_BITS - 1 downto 0);
	 
	--weight ret to dot product
	signal axis_wret_dot_d: std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
	signal axis_wret_dot_valid, axis_wret_dot_ready: std_logic;
	
	--drpe to weight
	signal axis_drpe_wu_d: std_logic_vector(CONST_DRPE_BITS - 1 downto 0);
	signal axis_drpe_wu_ready, axis_drpe_wu_valid: std_logic;
	
	--pcld
	signal axis_pcld_hrpsv_d: std_logic_vector(CONST_PCLD_BITS - 1 downto 0);
	signal axis_pcld_hrpsv_ready, axis_pcld_hrpsv_valid: std_logic;
	signal axis_pcld_hrpsv_coord: coordinate_bounds_array_t;
	
	--hrpsv to hrpsvs
	signal axis_hrpsv_hrpsvs_d: std_logic_vector(CONST_HRPSV_BITS - 1 downto 0);
	signal axis_hrpsv_hrpsvs_valid, axis_hrpsv_hrpsvs_ready: std_logic;
	signal axis_hrpsv_hrpsvs_coord: coordinate_bounds_array_t;
	
	--hrpsvs to outputs
	signal axis_hrpsvs_hrpsvq_valid,axis_hrpsvs_hrpsvq_ready: std_logic;
	signal axis_hrpsvs_hrpsvq_d: std_logic_vector(CONST_HRPSV_BITS - 1 downto 0);
	signal axis_hrpsvs_drpsv_valid, axis_hrpsvs_drpsv_ready: std_logic;
	signal axis_hrpsvs_drpsv_d: std_logic_vector(CONST_HRPSV_BITS - 1 downto 0);
	signal axis_hrpsvs_drpsv_coord: coordinate_bounds_array_t;
	
	--hrpsvq to drsr
	signal axis_hrpsvq_drsr_ready, axis_hrpsvq_drsr_valid: std_logic;
	signal axis_hrpsvq_drsr_data: std_logic_vector(CONST_HRPSV_BITS - 1 downto 0);
	
	--drpsv to drpsvs
	signal axis_drpsv_drpsvs_d: std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
	signal axis_drpsv_drpsvs_ready, axis_drpsv_drpsvs_valid: std_logic;
	signal axis_drpsv_drpsvs_coord: coordinate_bounds_array_t;
	
	--drpsvs to others
	signal axis_drpsvs_drpsvmqiq_valid, axis_drpsvs_drpsvmqiq_ready: std_logic;
	signal axis_drpsvs_drpsvmqiq_d: std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
	signal axis_drpsvs_drpsvdrpeq_valid, axis_drpsvs_drpsvdrpeq_ready: std_logic;
	signal axis_drpsvs_drpsvdrpeq_d: std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
	signal axis_drpsvs_psv_valid, axis_drpsvs_psv_ready: std_logic;
	signal axis_drpsvs_psv_d: std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
	signal axis_drpsvs_psv_coord: coordinate_bounds_array_t; 
	
	--drpsvq to mqi and drpe
	signal axis_drpsvq_mqi_ready, axis_drpsvq_mqi_valid: std_logic;
	signal axis_drpsvq_mqi_data: std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
	signal axis_drpsvq_drpe_ready, axis_drpsvq_drpe_valid: std_logic;
	signal axis_drpsvq_drpe_data: std_logic_vector(CONST_DRPSV_BITS - 1 downto 0); 
			
	--psv to psvs
	signal axis_psv_psvs_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_psv_psvs_ready, axis_psv_psvs_valid: std_logic;
	signal axis_psv_psvs_coord: coordinate_bounds_array_t;
	
	--psvs signals
	signal axis_psvs_pr_valid, axis_psvs_pr_ready: std_logic;
	signal axis_psvs_pr_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_psvs_pr_coord: coordinate_bounds_array_t;
	signal axis_psvs_mev_valid,axis_psvs_mev_ready: std_logic;
	signal axis_psvs_mev_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_psvs_mev_coord: coordinate_bounds_array_t;
	signal axis_psvs_psvtq_ready, axis_psvs_psvtq_valid: std_logic;
	signal axis_psvs_psvtq_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_psvs_psvcqbcq_valid,axis_psvs_psvcqbcq_ready: std_logic;
	signal axis_psvs_psvcqbcq_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);

	--psv queue for cqbc
	signal axis_psvcqbcq_cqbc_ready, axis_psvcqbcq_cqbc_valid: std_logic;
	signal axis_psvcqbcq_cqbc_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	
	--psv queue for theta
	signal axis_psvtq_t_ready, axis_psvtq_t_valid: std_logic;
	signal axis_psvtq_t_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	
	--pr to prq (wait for mev to be calculated)
	signal axis_pr_prq_d: std_logic_vector(CONST_PR_BITS - 1 downto 0);
	signal axis_pr_prq_valid, axis_pr_prq_ready: std_logic;
	signal axis_pr_prq_coord: coordinate_bounds_array_t;
	
	--prq to qi
	signal axis_prq_qi_d: std_logic_vector(CONST_PR_BITS - 1 downto 0);
	signal axis_prq_qi_valid, axis_prq_qi_ready: std_logic;
	signal axis_prq_qi_coord: coordinate_bounds_array_t;
	
	--mev to mevs
	signal axis_mev_mevs_d: std_logic_vector(CONST_MEV_BITS - 1 downto 0);
	signal axis_mev_mevs_valid, axis_mev_mevs_ready: std_logic;
	
	--mevs to outputs
	signal axis_mevs_qi_valid,axis_mevs_qi_ready: std_logic;
	signal axis_mevs_qi_d : std_logic_vector(CONST_MEV_BITS - 1 downto 0);
	signal axis_mevs_mevcqbcq_valid,axis_mevs_mevcqbcq_ready: std_logic;
	signal axis_mevs_mevcqbcq_d: std_logic_vector(CONST_MEV_BITS - 1 downto 0);
	signal axis_mevs_mevdrsrq_valid,axis_mevs_mevdrsrq_ready: std_logic;
	signal axis_mevs_mevdrsrq_d: std_logic_vector(CONST_MEV_BITS - 1 downto 0);
	signal axis_mevs_t_valid,axis_mevs_t_ready: std_logic;
	signal axis_mevs_t_data: std_logic_vector(CONST_MEV_BITS - 1 downto 0);
	
	--mev queues
	signal axis_mevdrsrq_drsr_ready, axis_mevdrsrq_drsr_valid: std_logic;
	signal axis_mevdrsrq_drsr_d: std_logic_vector(CONST_MEV_BITS - 1 downto 0);
	signal axis_mevcqbcq_cqbc_ready, axis_mevcqbcq_cqbc_valid: std_logic;
	signal axis_mevcqbcq_cqbc_d: std_logic_vector(CONST_MEV_BITS - 1 downto 0);
	
	--qi output
	signal axis_qi_qis_d: std_logic_vector(CONST_QI_BITS - 1 downto 0);
	signal axis_qi_qis_valid, axis_qi_qis_ready: std_logic;
	signal axis_qi_qis_coord: coordinate_bounds_array_t;
	
	--qi splitter (mqi and cqbc will read directly, drsr needs queue)
	signal axis_qis_mqi_d: std_logic_vector(CONST_QI_BITS - 1 downto 0);
	signal axis_qis_mqi_ready, axis_qis_mqi_valid: std_logic;
	signal axis_qis_cqbc_d: std_logic_vector(CONST_QI_BITS - 1 downto 0);
	signal axis_qis_cqbc_ready, axis_qis_cqbc_valid: std_logic;
	signal axis_qis_cqbc_coord: coordinate_bounds_array_t;
	signal axis_qis_qiq_d: std_logic_vector(CONST_QI_BITS - 1 downto 0);
	signal axis_qis_qiq_ready, axis_qis_qiq_valid: std_logic;
	
	--qi queue
	signal axis_qiq_drsr_ready, axis_qiq_drsr_valid: std_logic;
	signal axis_qiq_drsr_d: std_logic_vector(CONST_QI_BITS - 1 downto 0);
	
	--cqbc to splitter
	signal axis_cqbc_cqbcs_d: std_logic_vector(CONST_CQBC_BITS - 1 downto 0);
	signal axis_cqbc_cqbcs_ready, axis_cqbc_cqbcs_valid: std_logic;
	signal axis_cqbc_cqbcs_coord: coordinate_bounds_array_t;
	
	--cqbc splitter
	signal axis_cqbcs_drsr_valid,axis_cqbcs_drsr_ready: std_logic;
	signal axis_cqbcs_drsr_d: std_logic_vector(CONST_CQBC_BITS - 1 downto 0);
	signal axis_cqbcs_drsr_coord: coordinate_bounds_array_t;
	signal axis_cqbcs_cqbcq_valid,axis_cqbcs_cqbcq_ready : std_logic;
	signal axis_cqbcs_cqbcq_d: std_logic_vector(CONST_CQBC_BITS - 1 downto 0);
	
	--cqbc queue
	signal axis_cqbcq_drpe_ready,axis_cqbcq_drpe_valid: std_logic;
	signal axis_cqbcq_drpe_d: std_logic_vector(CONST_CQBC_BITS - 1 downto 0);
	
	--drsr to drsrs
	signal axis_drsr_cr_d: std_logic_vector(CONST_DRSR_BITS - 1 downto 0);
	signal axis_drsr_cr_valid,axis_drsr_cr_ready: std_logic;
	signal axis_drsr_cr_coord: coordinate_bounds_array_t;
	
	--cr to crs
	signal axis_cr_crs_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_cr_crs_valid, axis_cr_crs_ready: std_logic;
	signal axis_cr_crs_coord: coordinate_bounds_array_t;
	
	--crs to crsoutputs
	signal axis_crs_cd_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_crs_cd_valid, axis_crs_cd_ready: std_logic;
	signal axis_crs_cd_coord: coordinate_bounds_array_t;
	
	--theta and theta queue
	signal axis_t_tq_valid,axis_t_tq_ready: std_logic;
	signal axis_t_tq_d: std_logic_vector(CONST_THETA_BITS - 1 downto 0);
	signal axis_tq_mqi_ready, axis_tq_mqi_valid: std_logic;
	signal axis_tq_mqi_d: std_logic_vector(CONST_THETA_BITS - 1 downto 0);
begin

	reset_replicator: entity work.reset_replicator
		port map (
			clk => clk, rst => rst,
			rst_out => inner_reset
		);

	input_splitter: entity work.AXIS_SPLITTER_4
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			USER_WIDTH => coordinate_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_in_s_valid,
			input_data		=> axis_in_s_d,
			input_ready		=> axis_in_s_ready,
			input_user		=> axis_in_s_full_coord,
			--to output axi ports
			output_0_valid	=> axis_is_nrcs_valid,
			output_0_data	=> open,
			output_0_ready	=> axis_is_nrcs_ready,
			output_0_user	=> axis_is_nrcs_full_coord,
			output_1_valid	=> axis_is_ss_valid,
			output_1_data	=> axis_is_ss_d,
			output_1_ready	=> axis_is_ss_ready,
			output_1_user	=> open,
			output_2_valid	=> axis_is_fpp_valid,
			output_2_data	=> axis_is_fpp_d,
			output_2_ready	=> axis_is_fpp_ready,
			output_2_user	=> axis_is_fpp_full_coord,
			output_3_valid	=> axis_is_cs_valid,
			output_3_data	=> open,
			output_3_ready	=> axis_is_cs_ready,
			output_3_user	=> axis_is_cs_full_coord
		);
		
	sample_splitter: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_is_ss_valid,
			input_data		=> axis_is_ss_d,
			input_ready		=> axis_is_ss_ready,
			--to output axi ports
			output_0_valid	=> axis_ss_sprq_valid,
			output_0_data	=> axis_ss_sprq_d,
			output_0_ready	=> axis_ss_sprq_ready,
			output_1_valid	=> axis_ss_scrq_valid,
			output_1_data	=> axis_ss_scrq_d,
			output_1_ready	=> axis_ss_scrq_ready
		);
		
	sample_queue_prediction_res: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_ss_sprq_valid,
			input_ready => axis_ss_sprq_ready,
			input_data	=> axis_ss_sprq_d,
			output_ready=> axis_sprq_pr_ready,
			output_data	=> axis_sprq_pr_d,
			output_valid=> axis_sprq_pr_valid
		);

	sample_queue_curr_repr: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_ss_scrq_valid,
			input_ready => axis_ss_scrq_ready,
			input_data	=> axis_ss_scrq_d,
			output_ready=> axis_scrq_cr_ready,
			output_data	=> axis_scrq_cr_d,
			output_valid=> axis_scrq_cr_valid
		);
		
	coord_queues_splitter: entity work.AXIS_SPLITTER_3
		Generic map (
			DATA_WIDTH => coordinate_array_t'length
		)
		Port map (
			clk => clk, rst => inner_reset,
			--to input axi port
			input_valid		=> axis_is_cs_valid,
			input_data		=> axis_is_cs_full_coord,
			input_ready		=> axis_is_cs_ready,
			--to output axi ports
			output_0_valid	=> axis_cqs_cqdq_valid,
			output_0_data	=> axis_cqs_cqdq_full_coord,
			output_0_ready	=> axis_cqs_cqdq_ready,
			output_1_valid	=> axis_cqs_cqwq_valid,
			output_1_data	=> axis_cqs_cqwq_full_coord,
			output_1_ready	=> axis_cqs_cqwq_ready,
			output_2_valid	=> axis_cqs_cqwuseq_valid,
			output_2_data	=> axis_cqs_cqwuseq_full_coord,
			output_2_ready	=> axis_cqs_cqwuseq_ready
		);
		
	update_axis_cqs_cqdq: process(axis_cqs_cqdq_full_coord) begin
		axis_cqs_cqdq_coord <= F_CB2STDLV(F_STDLV2C(axis_cqs_cqdq_full_coord).bounds);
	end process;
	coord_queue_diff_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => coordinate_bounds_array_t'length,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_cqs_cqdq_valid,
			input_ready => axis_cqs_cqdq_ready,
			input_data	=> axis_cqs_cqdq_coord,
			output_ready=> axis_cqdq_dqsy_ready,
			output_data	=> axis_cqdq_dqsy_d,
			output_valid=> axis_cqdq_dqsy_valid,
			flag_almost_full => open, flag_almost_empty => open
		);
			
	update_axis_is_fpp: process(axis_is_fpp_full_coord) begin
		axis_is_fpp_coord <= F_CB2STDLV(F_STDLV2C(axis_is_fpp_full_coord).bounds);
	end process;
	first_pixel_queue_filler: entity work.first_pixel_queue_filler
		Port map (
			clk => clk, rst	=> inner_reset, 
			cfg_p => cfg_p,
			axis_in_sample_d	=> axis_is_fpp_d,
			axis_in_sample_coord=> axis_is_fpp_coord,	
			axis_in_sample_valid=> axis_is_fpp_valid,
			axis_in_sample_ready=> axis_is_fpp_ready,
			axis_out_fpq_d 		=> axis_fpp_fpq_d,
			axis_out_fpq_ready	=> axis_fpp_fpq_ready,
			axis_out_fpq_valid	=> axis_fpp_fpq_valid
		);
		
	first_pixel_data_latch: entity work.AXIS_LATCHED_CONNECTION
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_ready => axis_fpp_fpq_ready,
			input_valid => axis_fpp_fpq_valid,
			input_data  => axis_fpp_fpq_d,
			output_ready=> axis_fpq_drpsv_ready,
			output_valid=> axis_fpq_drpsv_valid,
			output_data => axis_fpq_drpsv_d
		);

	update_axis_is_nrcs: process(axis_is_nrcs_full_coord) begin
		axis_is_nrcs_coord <= F_CB2STDLV(F_STDLV2C(axis_is_nrcs_full_coord).bounds);
	end process;
	sample_rep_queue_system: entity work.sample_rep_queue_system
		Port map (
			clk => clk, rst	=> inner_reset,
			--input coordinate
			axis_in_coord_valid		=> axis_is_nrcs_valid,
			axis_in_coord_d 		=> axis_is_nrcs_coord,
			axis_in_coord_ready		=> axis_is_nrcs_ready,
			--input sample from current representative
			axis_in_cr_d			=> axis_crs_nr_d,
			axis_in_cr_coord		=> axis_crs_nr_coord,
			axis_in_cr_valid		=> axis_crs_nr_valid,
			axis_in_cr_ready		=> axis_crs_nr_ready,
			--output synchronized neighborhood
			axis_out_w				=> axis_nr_ls_w,
			axis_out_wd				=> axis_nr_ls_wd,
			axis_out_n				=> axis_nr_ls_n,
			axis_out_ne				=> axis_nr_ls_ne,
			axis_out_nw				=> axis_nr_ls_nw,
			axis_out_ready			=> axis_nr_ls_ready,
			axis_out_valid			=> axis_nr_ls_valid,
			axis_out_coord			=> axis_nr_ls_coord
		);
		
	local_sum: entity work.local_sum_calc
		port map (
			clk => clk, rst => inner_reset,
			cfg_wide_sum		=> cfg_wide_sum,
			cfg_neighbor_sum	=> cfg_neighbor_sum,
			cfg_smid 			=> cfg_smid,
			axis_in_w 			=> axis_nr_ls_w,
			axis_in_wd 			=> axis_nr_ls_wd,
			axis_in_nw 			=> axis_nr_ls_nw,
			axis_in_n 			=> axis_nr_ls_n,
			axis_in_ne	 		=> axis_nr_ls_ne,
			axis_in_ready 		=> axis_nr_ls_ready,
			axis_in_valid 		=> axis_nr_ls_valid,
			axis_in_coord 		=> axis_nr_ls_coord,
			axis_out_w			=> axis_ls_lss_w,
			axis_out_n			=> axis_ls_lss_n,
			axis_out_nw			=> axis_ls_lss_nw,
			axis_out_ls 		=> axis_ls_lss_ls,
			axis_out_ready 		=> axis_ls_lss_ready,
			axis_out_valid 		=> axis_ls_lss_valid,
			axis_out_coord		=> axis_ls_lss_coord
		);
		
	axis_ls_lss_d <= axis_ls_lss_w & axis_ls_lss_n & axis_ls_lss_nw & axis_ls_lss_ls;
	local_sum_splitter: entity work.AXIS_SPLITTER_3
		Generic map (
			DATA_WIDTH => 3*CONST_MAX_DATA_WIDTH + CONST_LSUM_BITS,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_ls_lss_valid,
			input_data		=> axis_ls_lss_d,
			input_ready		=> axis_ls_lss_ready,
			input_user		=> axis_ls_lss_coord,
			--to output axi ports
			output_0_valid	=> axis_lss_dd_valid,
			output_0_data	=> axis_lss_dd_d,
			output_0_ready	=> axis_lss_dd_ready,
			output_0_user 	=> axis_lss_dd_coord,
			output_1_valid	=> axis_lss_lshrpsvq_valid,
			output_1_data	=> axis_lss_lshrpsvq_d,
			output_1_ready	=> axis_lss_lshrpsvq_ready,
			output_2_valid	=> axis_lss_lscdq_valid,
			output_2_data	=> axis_lss_lscdq_d,
			output_2_ready	=> axis_lss_lscdq_ready
		);
	axis_lss_lscdq_ls <= axis_lss_lscdq_d(CONST_LSUM_BITS - 1 downto 0);
	axis_lss_lshrpsvq_ls <= axis_lss_lshrpsvq_d(CONST_LSUM_BITS - 1 downto 0);
	
	local_sum_queue_hrpsv: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_LSUM_BITS,
			FIFO_DEPTH => 8
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_lss_lshrpsvq_valid,
			input_ready => axis_lss_lshrpsvq_ready,
			input_data	=> axis_lss_lshrpsvq_ls,
			output_ready=> axis_lshrpsvq_hrpsv_ready,
			output_data	=> axis_lshrpsvq_hrpsv_d,
			output_valid=> axis_lshrpsvq_hrpsv_valid,
			flag_almost_full => open, flag_almost_empty => open
		);
		
	local_sum_queue_cd: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_LSUM_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_lss_lscdq_valid,
			input_ready => axis_lss_lscdq_ready,
			input_data	=> axis_lss_lscdq_ls,
			output_ready=> axis_lscdq_cd_ready,
			output_data	=> axis_lscdq_cd_d,
			output_valid=> axis_lscdq_cd_valid,
			flag_almost_full => open, flag_almost_empty => open
		);
	
		
	axis_lss_dd_w 	<= axis_lss_dd_d(CONST_LSUM_BITS+CONST_MAX_DATA_WIDTH*3 - 1 downto CONST_LSUM_BITS+CONST_MAX_DATA_WIDTH*2);
	axis_lss_dd_n 	<= axis_lss_dd_d(CONST_LSUM_BITS+CONST_MAX_DATA_WIDTH*2 - 1 downto CONST_LSUM_BITS+CONST_MAX_DATA_WIDTH);
	axis_lss_dd_nw 	<= axis_lss_dd_d(CONST_LSUM_BITS+CONST_MAX_DATA_WIDTH - 1 downto CONST_LSUM_BITS);
	axis_lss_dd_ls	<= axis_lss_dd_d(CONST_LSUM_BITS - 1 downto 0);
	local_difference: entity work.local_difference_calc
		port map (
			axis_in_w 			=> axis_lss_dd_w,
			axis_in_nw 			=> axis_lss_dd_nw,
			axis_in_n 			=> axis_lss_dd_n,
			axis_in_ls 			=> axis_lss_dd_ls,
			axis_in_ready 		=> axis_lss_dd_ready,
			axis_in_valid 		=> axis_lss_dd_valid,
			axis_in_coord 		=> axis_lss_dd_coord,
			axis_out_nd 		=> axis_dd_dqsy_nd_pre,
			axis_out_nwd 		=> axis_dd_dqsy_nwd_pre,
			axis_out_wd 		=> axis_dd_dqsy_wd_pre,
			axis_out_ready 		=> axis_dd_dqsy_ready,
			axis_out_valid 		=> axis_dd_dqsy_valid,
			axis_out_coord		=> axis_dd_dqsy_coord
		);
	filter_output_diffs: process(axis_dd_dqsy_nd_pre, axis_dd_dqsy_nwd_pre, axis_dd_dqsy_wd_pre, cfg_full_prediction) begin
		if cfg_full_prediction = '1' then
			axis_dd_dqsy_nd <= axis_dd_dqsy_nd_pre;
			axis_dd_dqsy_nwd <= axis_dd_dqsy_nwd_pre;
			axis_dd_dqsy_wd <= axis_dd_dqsy_wd_pre;
		else
			axis_dd_dqsy_nd <= (others => '0');
			axis_dd_dqsy_nwd <= (others => '0');
			axis_dd_dqsy_wd <= (others => '0');
		end if;
	end process;
		
	diff_queue_system: entity work.difference_queue_system
		Port map ( 
			clk => clk, rst => inner_reset,
			axis_in_coord_d			=> axis_cqdq_dqsy_d,
			axis_in_coord_ready		=> axis_cqdq_dqsy_ready,
			axis_in_coord_valid		=> axis_cqdq_dqsy_valid,
			axis_in_dd_nd 			=> axis_dd_dqsy_nd,
			axis_in_dd_nwd	 		=> axis_dd_dqsy_nwd,
			axis_in_dd_wd 			=> axis_dd_dqsy_wd,
			axis_in_dd_ready 		=> axis_dd_dqsy_ready,
			axis_in_dd_valid 		=> axis_dd_dqsy_valid,
			axis_in_dd_coord		=> axis_dd_dqsy_coord,
			axis_in_cd_d			=> axis_cd_dqsy_d,
			axis_in_cd_ready 		=> axis_cd_dqsy_ready,
			axis_in_cd_valid 		=> axis_cd_dqsy_valid,
			axis_in_cd_coord		=> axis_cd_dqsy_coord,
			axis_out_d				=> axis_dqsy_dvs_d,
			axis_out_coord			=> axis_dqsy_dvs_coord,
			axis_out_ready			=> axis_dqsy_dvs_ready,
			axis_out_valid			=> axis_dqsy_dvs_valid
		);
		
	diff_vec_splitter: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH => CONST_DIFFVEC_BITS,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			input_valid		=> axis_dqsy_dvs_valid,
			input_data		=> axis_dqsy_dvs_d,
			input_ready		=> axis_dqsy_dvs_ready,
			input_user		=> axis_dqsy_dvs_coord,
			output_0_valid	=> axis_dvs_dot_valid,
			output_0_data	=> axis_dvs_dot_d,
			output_0_ready	=> axis_dvs_dot_ready,
			output_0_user	=> axis_dvs_dot_coord,
			output_1_valid	=> axis_dvs_dvq_valid,
			output_1_data	=> axis_dvs_dvq_d,
			output_1_ready	=> axis_dvs_dvq_ready,
			output_1_user   => axis_dvs_dvq_coord
		);
		
	diff_vec_queue_wu: entity work.AXIS_FIFO_SWRAP
		Generic map (
			DATA_WIDTH => CONST_DIFFVEC_BITS,
			FIFO_DEPTH => 64,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_dvs_dvq_valid,
			input_ready => axis_dvs_dvq_ready,
			input_data	=> axis_dvs_dvq_d,
			input_user  => axis_dvs_dvq_coord,
			output_ready=> axis_dvq_wu_ready,
			output_data	=> axis_dvq_wu_d,
			output_valid=> axis_dvq_wu_valid,
			output_user => axis_dvq_wu_coord,
			flag_almost_full => open, flag_almost_empty => open
		);
		
	update_axis_cqs_cqwq: process(axis_cqs_cqwq_full_coord) begin
		axis_cqs_cqwq_coord <= F_CB2STDLV(F_STDLV2C(axis_cqs_cqwq_full_coord).bounds);
	end process;
	coord_queue_wret_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => coordinate_bounds_array_t'length,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_cqs_cqwq_valid,
			input_ready => axis_cqs_cqwq_ready,
			input_data	=> axis_cqs_cqwq_coord,
			output_ready=> axis_cqwq_wu_ready,
			output_data	=> axis_cqwq_wu_coord,
			output_valid=> axis_cqwq_wu_valid,
			flag_almost_full => open, flag_almost_empty => open
		);

	update_axis_cqs_cqwuseq_t: process(axis_cqs_cqwuseq_full_coord) begin
		axis_cqs_cqwuseq_t <= F_STDLV2C(axis_cqs_cqwuseq_full_coord).position.t;
	end process;
	coord_queue_wuse_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_MAX_T_VALUE_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_cqs_cqwuseq_valid,
			input_ready => axis_cqs_cqwuseq_ready,
			input_data	=> axis_cqs_cqwuseq_t,
			output_ready=> axis_cqwuseq_wu_ready,
			output_data	=> axis_cqwuseq_wu_t,
			output_valid=> axis_cqwuseq_wu_valid,
			flag_almost_full => open, flag_almost_empty => open
		);
			
	weight_retrieval_and_update: entity work.weight_module
		Port map ( 
			clk => clk, rst => inner_reset,
			cfg_samples				=> cfg_samples,
			cfg_tinc				=> cfg_tinc,
			cfg_vmax				=> cfg_vmax,
			cfg_vmin				=> cfg_vmin,
			cfg_depth				=> cfg_depth,
			cfg_omega				=> cfg_omega,
			cfg_weo					=> cfg_weo,
--			cfg_weight_vec			=> cfg_weight_vec,
			--axis for coordinate 
			axis_in_coord_d			=> axis_cqwq_wu_coord,
			axis_in_coord_valid		=> axis_cqwq_wu_valid,
			axis_in_coord_ready		=> axis_cqwq_wu_ready,
			--axis for wuse coordinate
			axis_in_wuse_coord_t	=> axis_cqwuseq_wu_t,
			axis_in_wuse_coord_valid=> axis_cqwuseq_wu_valid,
			axis_in_wuse_coord_ready=> axis_cqwuseq_wu_ready,
			--axis for difference vector (update)
			axis_in_dv_ready		=> axis_dvq_wu_ready,
			axis_in_dv_valid		=> axis_dvq_wu_valid,
			axis_in_dv_d			=> axis_dvq_wu_d,
			axis_in_dv_coord		=> axis_dvq_wu_coord,
			--axis for drpe
			axis_drpe_d				=> axis_drpe_wu_d,
			axis_drpe_ready			=> axis_drpe_wu_ready,
			axis_drpe_valid			=> axis_drpe_wu_valid,
			--output weight vector
			axis_out_wv_d			=> axis_wret_dot_d,
			axis_out_wv_valid		=> axis_wret_dot_valid,
			axis_out_wv_ready		=> axis_wret_dot_ready
		);
		
	--assign axis_dvs_dot_d_filtered
	filter_diff_vector : process(cfg_p, cfg_full_prediction, axis_dvs_dot_d)
	begin
		--axis_out_d <= axis_out_dird & axis_out_cld;
		if cfg_full_prediction = '1' then
			axis_dvs_dot_d_filtered(CONST_DIFFVEC_BITS - 1 downto CONST_CLDVEC_BITS) <= axis_dvs_dot_d(CONST_DIFFVEC_BITS - 1 downto CONST_CLDVEC_BITS);
		else
			axis_dvs_dot_d_filtered(CONST_DIFFVEC_BITS - 1 downto CONST_CLDVEC_BITS) <= (others => '0');
		end if;
		assign_cld : for i in 0 to CONST_MAX_P - 1 loop
			if to_integer(unsigned(cfg_p)) > i then
				axis_dvs_dot_d_filtered(CONST_CLDVEC_BITS - 1 - CONST_LDIF_BITS*(i) downto CONST_CLDVEC_BITS - CONST_LDIF_BITS*(i+1)) <= axis_dvs_dot_d(CONST_CLDVEC_BITS - 1 - CONST_LDIF_BITS*(i) downto CONST_CLDVEC_BITS - CONST_LDIF_BITS*(i+1));
			else
				axis_dvs_dot_d_filtered(CONST_CLDVEC_BITS - 1 - CONST_LDIF_BITS*(i) downto CONST_CLDVEC_BITS - CONST_LDIF_BITS*(i+1)) <= (others => '0');
			end if;
		end loop;
	end process ; -- filter_diff_vector
	--end assignment
	predicted_central_local_diff: entity work.axis_dotprod
		generic map (
			VECTOR_LENGTH => CONST_MAX_C,
			VECTOR_LENGTH_LOG => CONST_MAX_C_BITS,
			INPUT_A_DATA_WIDTH => CONST_LDIF_BITS,
			INPUT_B_DATA_WIDTH => CONST_MAX_WEIGHT_BITS,
			LAST_POLICY		=> PASS_ZERO,
			USER_WIDTH		=> coordinate_bounds_array_t'length,
			USER_POLICY 	=> PASS_ZERO
		)
		port map ( 
			clk => clk, rst => inner_reset,
			axis_input_a_d		=> axis_dvs_dot_d_filtered,
			axis_input_a_ready	=> axis_dvs_dot_ready,
			axis_input_a_valid  => axis_dvs_dot_valid,
			axis_input_a_user	=> axis_dvs_dot_coord,
			axis_input_b_d 		=> axis_wret_dot_d,
			axis_input_b_ready 	=> axis_wret_dot_ready,
			axis_input_b_valid 	=> axis_wret_dot_valid,
			axis_output_d		=> axis_pcld_hrpsv_d,
			axis_output_ready	=> axis_pcld_hrpsv_ready,
			axis_output_valid	=> axis_pcld_hrpsv_valid,
			axis_output_user	=> axis_pcld_hrpsv_coord
		);
		
	hrpsv_calc: entity work.hrpsv_calc
		Port map ( 
			clk => clk, rst => inner_reset,
			cfg_smax				=> cfg_smax,
			cfg_omega				=> cfg_omega, 
			axis_in_pcd_d			=> axis_pcld_hrpsv_d,
			axis_in_pcd_valid		=> axis_pcld_hrpsv_valid,
			axis_in_pcd_ready		=> axis_pcld_hrpsv_ready,
			axis_in_pcd_coord		=> axis_pcld_hrpsv_coord,
			axis_in_lsum_d			=> axis_lshrpsvq_hrpsv_d,
			axis_in_lsum_valid		=> axis_lshrpsvq_hrpsv_valid,
			axis_in_lsum_ready		=> axis_lshrpsvq_hrpsv_ready,
			axis_out_hrpsv_d		=> axis_hrpsv_hrpsvs_d,
			axis_out_hrpsv_valid	=> axis_hrpsv_hrpsvs_valid,
			axis_out_hrpsv_ready	=> axis_hrpsv_hrpsvs_ready,
			axis_out_hrpsv_coord	=> axis_hrpsv_hrpsvs_coord 
		);
		
	hrpsv_splitter: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH => CONST_HRPSV_BITS,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_hrpsv_hrpsvs_valid,
			input_data		=> axis_hrpsv_hrpsvs_d,
			input_ready		=> axis_hrpsv_hrpsvs_ready,
			input_user		=> axis_hrpsv_hrpsvs_coord,
			--to output axi ports
			output_0_valid	=> axis_hrpsvs_hrpsvq_valid,
			output_0_data	=> axis_hrpsvs_hrpsvq_d,
			output_0_ready	=> axis_hrpsvs_hrpsvq_ready,
			output_1_valid	=> axis_hrpsvs_drpsv_valid,
			output_1_data	=> axis_hrpsvs_drpsv_d,
			output_1_ready	=> axis_hrpsvs_drpsv_ready,
			output_1_user   => axis_hrpsvs_drpsv_coord
		);
		
	hrpsv_queue: entity work.axis_fifo_latched 
		Generic map (
			DATA_WIDTH => CONST_HRPSV_BITS,
			FIFO_DEPTH => 64
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_hrpsvs_hrpsvq_valid,
			input_ready => axis_hrpsvs_hrpsvq_ready,
			input_data	=> axis_hrpsvs_hrpsvq_d,
			output_ready=> axis_hrpsvq_drsr_ready,
			output_data	=> axis_hrpsvq_drsr_data,
			output_valid=> axis_hrpsvq_drsr_valid
		);
		
	drpsv_calc: entity work.drpsv_calc
		Port map (
			clk => clk, rst => inner_reset, 
			cfg_pred_bands 			=> cfg_p,
			cfg_in_data_width_log	=> cfg_depth,
			cfg_in_weight_width_log	=> cfg_omega,
			axis_in_hrpsv_d			=> axis_hrpsvs_drpsv_d,	
			axis_in_hrpsv_valid 	=> axis_hrpsvs_drpsv_valid,
			axis_in_hrpsv_ready 	=> axis_hrpsvs_drpsv_ready,
			axis_in_hrpsv_coord 	=> axis_hrpsvs_drpsv_coord,
			axis_in_fpq_d 			=> axis_fpq_drpsv_d,
			axis_in_fpq_valid 		=> axis_fpq_drpsv_valid,
			axis_in_fpq_ready 		=> axis_fpq_drpsv_ready,
			axis_out_drpsv_d 		=> axis_drpsv_drpsvs_d,
			axis_out_drpsv_ready	=> axis_drpsv_drpsvs_ready,
			axis_out_drpsv_valid	=> axis_drpsv_drpsvs_valid,
			axis_out_drpsv_coord	=> axis_drpsv_drpsvs_coord
		);
		
	drpsv_splitter: entity work.AXIS_SPLITTER_3
		Generic map (
			DATA_WIDTH => CONST_DRPSV_BITS,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_drpsv_drpsvs_valid,
			input_data		=> axis_drpsv_drpsvs_d,
			input_ready		=> axis_drpsv_drpsvs_ready,
			input_user		=> axis_drpsv_drpsvs_coord,
			--to output axi ports
			output_0_valid	=> axis_drpsvs_drpsvmqiq_valid,
			output_0_data	=> axis_drpsvs_drpsvmqiq_d,
			output_0_ready	=> axis_drpsvs_drpsvmqiq_ready,
			output_1_valid	=> axis_drpsvs_psv_valid,
			output_1_data	=> axis_drpsvs_psv_d,
			output_1_ready	=> axis_drpsvs_psv_ready,
			output_1_user   => axis_drpsvs_psv_coord,
			output_2_valid  => axis_drpsvs_drpsvdrpeq_valid,
			output_2_ready  => axis_drpsvs_drpsvdrpeq_ready,
			output_2_data   => axis_drpsvs_drpsvdrpeq_d
		);
		
	drpsv_mqi_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_DRPSV_BITS,
			FIFO_DEPTH => 32
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_valid	=> axis_drpsvs_drpsvmqiq_valid,
			input_ready => axis_drpsvs_drpsvmqiq_ready,
			input_data	=> axis_drpsvs_drpsvmqiq_d,
			output_ready=> axis_drpsvq_mqi_ready,
			output_data	=> axis_drpsvq_mqi_data,
			output_valid=> axis_drpsvq_mqi_valid
		);
		
	drpsv_drpe_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_DRPSV_BITS,
			FIFO_DEPTH => 32
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_valid	=> axis_drpsvs_drpsvdrpeq_valid,
			input_ready => axis_drpsvs_drpsvdrpeq_ready,
			input_data	=> axis_drpsvs_drpsvdrpeq_d,
			output_ready=> axis_drpsvq_drpe_ready,
			output_data	=> axis_drpsvq_drpe_data,
			output_valid=> axis_drpsvq_drpe_valid
		);
		
	psv_calc: entity work.psv_calc
		Port map (
			axis_in_drpsv_d 	=> axis_drpsvs_psv_d,
			axis_in_drpsv_ready	=> axis_drpsvs_psv_ready,
			axis_in_drpsv_valid	=> axis_drpsvs_psv_valid,
			axis_in_drpsv_coord => axis_drpsvs_psv_coord,
			axis_out_psv_d 		=> axis_psv_psvs_d,
			axis_out_psv_ready	=> axis_psv_psvs_ready,
			axis_out_psv_valid	=> axis_psv_psvs_valid,
			axis_out_psv_coord 	=> axis_psv_psvs_coord
		);
		
	psv_splitter: entity work.AXIS_SPLITTER_4
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_psv_psvs_valid,
			input_data		=> axis_psv_psvs_d,
			input_ready		=> axis_psv_psvs_ready,
			input_user		=> axis_psv_psvs_coord,
			--to output axi ports
			output_0_valid	=> axis_psvs_pr_valid,
			output_0_data	=> axis_psvs_pr_d,
			output_0_ready	=> axis_psvs_pr_ready,
			output_0_user	=> axis_psvs_pr_coord,
			output_1_valid	=> axis_psvs_mev_valid,
			output_1_data	=> axis_psvs_mev_d,
			output_1_ready	=> axis_psvs_mev_ready,
			output_1_user   => axis_psvs_mev_coord,
			output_2_valid	=> axis_psvs_psvtq_valid,
			output_2_data	=> axis_psvs_psvtq_d,
			output_2_ready	=> axis_psvs_psvtq_ready,
			output_3_valid	=> axis_psvs_psvcqbcq_valid,
			output_3_data	=> axis_psvs_psvcqbcq_d,
			output_3_ready	=> axis_psvs_psvcqbcq_ready
		);
		
	psvcqbcq_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			FIFO_DEPTH => 32
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_valid	=> axis_psvs_psvcqbcq_valid,
			input_ready => axis_psvs_psvcqbcq_ready,
			input_data	=> axis_psvs_psvcqbcq_d,
			output_ready=> axis_psvcqbcq_cqbc_ready,
			output_data	=> axis_psvcqbcq_cqbc_d,
			output_valid=> axis_psvcqbcq_cqbc_valid
		);

	psvtq_queue: entity work.AXIS_FIFO_SWRAP
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			FIFO_DEPTH => 8
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_psvs_psvtq_valid,
			input_ready => axis_psvs_psvtq_ready,
			input_data	=> axis_psvs_psvtq_d,
			output_ready=> axis_psvtq_t_ready,
			output_data	=> axis_psvtq_t_d,
			output_valid=> axis_psvtq_t_valid
		);
		
	prediction_residual_calc: entity work.pr_calc
		Port map ( 
			clk => clk, rst => inner_reset,
			axis_in_sample_d	=> axis_sprq_pr_d,
			axis_in_sample_valid=> axis_sprq_pr_valid,
			axis_in_sample_ready=> axis_sprq_pr_ready,
			axis_in_psv_d		=> axis_psvs_pr_d,
			axis_in_psv_valid	=> axis_psvs_pr_valid,
			axis_in_psv_ready	=> axis_psvs_pr_ready,
			axis_in_psv_coord	=> axis_psvs_pr_coord,
			axis_out_pr_d		=> axis_pr_prq_d,
			axis_out_pr_valid	=> axis_pr_prq_valid,
			axis_out_pr_ready	=> axis_pr_prq_ready,
			axis_out_pr_coord	=> axis_pr_prq_coord
		);
		
	prediction_residual_queue: entity work.AXIS_FIFO_SWRAP
		Generic map (
			DATA_WIDTH => CONST_PR_BITS,
			FIFO_DEPTH => 4,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_pr_prq_valid,
			input_ready => axis_pr_prq_ready,
			input_data	=> axis_pr_prq_d,
			input_user  => axis_pr_prq_coord,
			output_ready=> axis_prq_qi_ready,
			output_data	=> axis_prq_qi_d,
			output_valid=> axis_prq_qi_valid,
			output_user => axis_prq_qi_coord
		);
			
	mev_calc: entity work.mev_calc
		Port map ( 
			clk => clk, rst => inner_reset,
			cfg_use_abs_err		=> cfg_use_abs_err,
			cfg_use_rel_err		=> cfg_use_rel_err,
			cfg_abs_err 		=> cfg_abs_err,
			cfg_rel_err 		=> cfg_rel_err,
			axis_in_psv_valid	=> axis_psvs_mev_valid,
			axis_in_psv_ready	=> axis_psvs_mev_ready,
			axis_in_psv_d		=> axis_psvs_mev_d,
			axis_in_psv_coord 	=> axis_psvs_mev_coord,
			axis_out_mev_d 		=> axis_mev_mevs_d,
			axis_out_mev_valid 	=> axis_mev_mevs_valid,
			axis_out_mev_ready 	=> axis_mev_mevs_ready
		);
		
	mev_splitter: entity work.AXIS_SPLITTER_4
		Generic map (
			DATA_WIDTH => CONST_MEV_BITS
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			input_valid		=> axis_mev_mevs_valid,
			input_data		=> axis_mev_mevs_d,
			input_ready		=> axis_mev_mevs_ready,
			output_0_valid	=> axis_mevs_qi_valid,
			output_0_data	=> axis_mevs_qi_d,
			output_0_ready	=> axis_mevs_qi_ready,
			output_1_valid	=> axis_mevs_mevcqbcq_valid,
			output_1_data	=> axis_mevs_mevcqbcq_d,
			output_1_ready	=> axis_mevs_mevcqbcq_ready,
			output_2_valid	=> axis_mevs_mevdrsrq_valid,
			output_2_data	=> axis_mevs_mevdrsrq_d,
			output_2_ready	=> axis_mevs_mevdrsrq_ready,
			output_3_valid	=> axis_mevs_t_valid,
			output_3_data	=> axis_mevs_t_data,
			output_3_ready	=> axis_mevs_t_ready
		);
		
	mev_drsr_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_MEV_BITS,
			FIFO_DEPTH => 32
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_valid	=> axis_mevs_mevdrsrq_valid,
			input_ready => axis_mevs_mevdrsrq_ready,
			input_data	=> axis_mevs_mevdrsrq_d,
			output_ready=> axis_mevdrsrq_drsr_ready,
			output_data	=> axis_mevdrsrq_drsr_d,
			output_valid=> axis_mevdrsrq_drsr_valid
		);	
		
	mev_cqbc_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_MEV_BITS,
			FIFO_DEPTH => 32
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_valid	=> axis_mevs_mevcqbcq_valid,
			input_ready => axis_mevs_mevcqbcq_ready,
			input_data	=> axis_mevs_mevcqbcq_d,
			output_ready=> axis_mevcqbcq_cqbc_ready,
			output_data	=> axis_mevcqbcq_cqbc_d,
			output_valid=> axis_mevcqbcq_cqbc_valid
		);		
		
	quantized_index_calc: entity work.qi_calc
		Port map ( 
			clk => clk, rst => inner_reset,
			axis_in_pr_d 		=> axis_prq_qi_d,
			axis_in_pr_coord	=> axis_prq_qi_coord,
			axis_in_pr_valid	=> axis_prq_qi_valid,
			axis_in_pr_ready	=> axis_prq_qi_ready,
			axis_in_mev_d 		=> axis_mevs_qi_d,
			axis_in_mev_valid	=> axis_mevs_qi_valid,
			axis_in_mev_ready	=> axis_mevs_qi_ready,
			axis_out_qi_d 		=> axis_qi_qis_d,
			axis_out_qi_valid	=> axis_qi_qis_valid,
			axis_out_qi_ready 	=> axis_qi_qis_ready,
			axis_out_qi_coord	=> axis_qi_qis_coord
		);
		
	qi_splitter: entity work.AXIS_SPLITTER_3
		Generic map (
			DATA_WIDTH => CONST_QI_BITS,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_qi_qis_valid,
			input_data		=> axis_qi_qis_d,
			input_ready		=> axis_qi_qis_ready,
			input_user 		=> axis_qi_qis_coord,
			--to output axi ports
			output_0_valid	=> axis_qis_mqi_valid,
			output_0_data	=> axis_qis_mqi_d,
			output_0_ready	=> axis_qis_mqi_ready,
			output_1_valid	=> axis_qis_cqbc_valid,
			output_1_data	=> axis_qis_cqbc_d,
			output_1_ready	=> axis_qis_cqbc_ready,
			output_1_user 	=> axis_qis_cqbc_coord,
			output_2_valid	=> axis_qis_qiq_valid,
			output_2_data	=> axis_qis_qiq_d,
			output_2_ready	=> axis_qis_qiq_ready
		);
		
	qi_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_QI_BITS,
			FIFO_DEPTH => 8
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_valid	=> axis_qis_qiq_valid,
			input_ready => axis_qis_qiq_ready,
			input_data	=> axis_qis_qiq_d,
			output_ready=> axis_qiq_drsr_ready,
			output_data	=> axis_qiq_drsr_d,
			output_valid=> axis_qiq_drsr_valid
		);	
		
	cqbc_calc: entity work.cqbc_calc
		Port map ( 
			clk => clk, rst => inner_reset,
			cfg_smax			=> cfg_smax,
			axis_in_psv_d		=> axis_psvcqbcq_cqbc_d,
			axis_in_psv_valid	=> axis_psvcqbcq_cqbc_valid,
			axis_in_psv_ready	=> axis_psvcqbcq_cqbc_ready,
			axis_in_qi_d		=> axis_qis_cqbc_d,
			axis_in_qi_valid	=> axis_qis_cqbc_valid,
			axis_in_qi_ready	=> axis_qis_cqbc_ready,
			axis_in_qi_coord	=> axis_qis_cqbc_coord,
			axis_in_mev_d		=> axis_mevcqbcq_cqbc_d,
			axis_in_mev_valid	=> axis_mevcqbcq_cqbc_valid,
			axis_in_mev_ready	=> axis_mevcqbcq_cqbc_ready,
			axis_out_cqbc_d		=> axis_cqbc_cqbcs_d,
			axis_out_cqbc_ready	=> axis_cqbc_cqbcs_ready,
			axis_out_cqbc_valid	=> axis_cqbc_cqbcs_valid,
			axis_out_cqbc_coord => axis_cqbc_cqbcs_coord
		);
		
	cqbc_splitter: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH => CONST_CQBC_BITS,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			input_valid		=> axis_cqbc_cqbcs_valid,
			input_data		=> axis_cqbc_cqbcs_d,
			input_ready		=> axis_cqbc_cqbcs_ready,
			input_user 		=> axis_cqbc_cqbcs_coord,
			output_0_valid	=> axis_cqbcs_drsr_valid,
			output_0_data	=> axis_cqbcs_drsr_d,
			output_0_ready	=> axis_cqbcs_drsr_ready,
			output_0_user 	=> axis_cqbcs_drsr_coord,
			output_1_valid	=> axis_cqbcq_drpe_valid,
			output_1_data	=> axis_cqbcq_drpe_d,
			output_1_ready	=> axis_cqbcq_drpe_ready
		);
			
--	cqbc_queue: entity work.AXIS_FIFO 
--		Generic map (
--			DATA_WIDTH => CONST_CQBC_BITS,
--			FIFO_DEPTH => CONST_MAX_BANDS
--		)
--		Port map (
--			clk => clk, rst => inner_reset,
--			input_valid	=> axis_cqbcs_cqbcq_valid,
--			input_ready => axis_cqbcs_cqbcq_ready,
--			input_data	=> axis_cqbcs_cqbcq_d,
--			output_ready=> axis_cqbcq_drpe_ready,
--			output_data	=> axis_cqbcq_drpe_d,
--			output_valid=> axis_cqbcq_drpe_valid
--		);	
		
	drsr_calc: entity work.drsr_calc 
		port map ( 
			clk => clk, rst	=> inner_reset,
			cfg_resolution		=> cfg_resolution,
			cfg_damping			=> cfg_damping,
			cfg_offset			=> cfg_offset,
			cfg_omega 			=> cfg_omega,
			axis_in_cqbc_d		=> axis_cqbcs_drsr_d,
			axis_in_cqbc_valid  => axis_cqbcs_drsr_valid,
			axis_in_cqbc_ready	=> axis_cqbcs_drsr_ready,
			axis_in_cqbc_coord	=> axis_cqbcs_drsr_coord,
			axis_in_qi_d		=> axis_qiq_drsr_d,
			axis_in_qi_valid 	=> axis_qiq_drsr_valid,
			axis_in_qi_ready	=> axis_qiq_drsr_ready,
			axis_in_mev_d		=> axis_mevdrsrq_drsr_d,
			axis_in_mev_valid	=> axis_mevdrsrq_drsr_valid,
			axis_in_mev_ready	=> axis_mevdrsrq_drsr_ready,
			axis_in_hrpsv_d		=> axis_hrpsvq_drsr_data,
			axis_in_hrpsv_valid => axis_hrpsvq_drsr_valid,
			axis_in_hrpsv_ready	=> axis_hrpsvq_drsr_ready,
			axis_out_drsr_d		=> axis_drsr_cr_d,
			axis_out_drsr_valid => axis_drsr_cr_valid,
			axis_out_drsr_ready => axis_drsr_cr_ready,
			axis_out_drsr_coord => axis_drsr_cr_coord
		);

	drpe_calc: entity work.drpe_calc
	port map( 
		clk => clk, rst => inner_reset,
		axis_in_cqbc_d		=> axis_cqbcq_drpe_d,
		axis_in_cqbc_valid  => axis_cqbcq_drpe_valid,
		axis_in_cqbc_ready	=> axis_cqbcq_drpe_ready,
		axis_in_drpsv_d 	=> axis_drpsvq_drpe_data,
		axis_in_drpsv_ready => axis_drpsvq_drpe_ready,
		axis_in_drpsv_valid => axis_drpsvq_drpe_valid,
		axis_out_drpe_valid => axis_drpe_wu_valid,
		axis_out_drpe_ready => axis_drpe_wu_ready,
		axis_out_drpe_d		=> axis_drpe_wu_d
	);
	
	curre_repp_calc: entity work.current_rep_calc
		Port map ( 
			clk => clk, rst	=> inner_reset,
			axis_s_d			=> axis_scrq_cr_d,
			axis_s_valid		=> axis_scrq_cr_valid,
			axis_s_ready		=> axis_scrq_cr_ready,
			axis_drsr_d			=> axis_drsr_cr_d,
			axis_drsr_coord		=> axis_drsr_cr_coord,
			axis_drsr_valid 	=> axis_drsr_cr_valid,
			axis_drsr_ready 	=> axis_drsr_cr_ready,
			axis_out_cr_d   	=> axis_cr_crs_d,
			axis_out_cr_valid 	=> axis_cr_crs_valid,
			axis_out_cr_ready	=> axis_cr_crs_ready,
			axis_out_cr_coord	=> axis_cr_crs_coord
		);
		
	cr_splitter: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			input_valid		=> axis_cr_crs_valid,
			input_data		=> axis_cr_crs_d,
			input_ready		=> axis_cr_crs_ready,
			input_user 		=> axis_cr_crs_coord,
			output_0_valid	=> axis_crs_cd_valid,
			output_0_data	=> axis_crs_cd_d,
			output_0_ready	=> axis_crs_cd_ready,
			output_0_user 	=> axis_crs_cd_coord,
			output_1_valid	=> axis_crs_nr_valid,
			output_1_data	=> axis_crs_nr_d,
			output_1_ready	=> axis_crs_nr_ready,
			output_1_user   => axis_crs_nr_coord
		);
		
	current_diff_calc: entity work.current_diff_calc
		Port map ( 
			clk => clk, rst	=> inner_reset,
			axis_repr_d			=> axis_crs_cd_d,
			axis_repr_valid		=> axis_crs_cd_valid,
			axis_repr_ready		=> axis_crs_cd_ready,
			axis_repr_coord		=> axis_crs_cd_coord,
			axis_ls_d			=> axis_lscdq_cd_d,
			axis_ls_valid		=> axis_lscdq_cd_valid,
			axis_ls_ready		=> axis_lscdq_cd_ready,
			axis_out_cd_d		=> axis_cd_dqsy_d,
			axis_out_cd_valid	=> axis_cd_dqsy_valid,
			axis_out_cd_ready	=> axis_cd_dqsy_ready,
			axis_out_cd_coord	=> axis_cd_dqsy_coord
		);

	theta_calc: entity work.theta_calc
		Port map ( 
			clk => clk, rst	=> inner_reset,
			cfg_smax			=> cfg_smax,
			axis_in_psv_d		=> axis_psvtq_t_d,
			axis_in_psv_valid	=> axis_psvtq_t_valid,
			axis_in_psv_ready	=> axis_psvtq_t_ready,
			axis_in_mev_d		=> axis_mevs_t_data,
			axis_in_mev_valid	=> axis_mevs_t_valid,
			axis_in_mev_ready	=> axis_mevs_t_ready,
			axis_out_theta_d	=> axis_t_tq_d,
			axis_out_theta_valid=> axis_t_tq_valid,
			axis_out_theta_ready=> axis_t_tq_ready
		);
		
	theta_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_THETA_BITS,
			FIFO_DEPTH => 4
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_valid	=> axis_t_tq_valid,
			input_ready => axis_t_tq_ready,
			input_data	=> axis_t_tq_d,
			output_ready=> axis_tq_mqi_ready,
			output_data	=> axis_tq_mqi_d,
			output_valid=> axis_tq_mqi_valid
		);	
		
	mqi_calc: entity work.mqi_calc
	Port map ( 
		clk => clk, rst => inner_reset,
		axis_in_drpsv_d		=> axis_drpsvq_mqi_data,
		axis_in_drpsv_valid	=> axis_drpsvq_mqi_valid,
		axis_in_drpsv_ready	=> axis_drpsvq_mqi_ready,
		axis_in_theta_d		=> axis_tq_mqi_d,
		axis_in_theta_valid	=> axis_tq_mqi_valid,
		axis_in_theta_ready	=> axis_tq_mqi_ready,
		axis_in_qi_d		=> axis_qis_mqi_d,
		axis_in_qi_valid	=> axis_qis_mqi_valid,
		axis_in_qi_ready	=> axis_qis_mqi_ready,
		axis_out_mqi_d		=> axis_out_mqi_d,
		axis_out_mqi_ready	=> axis_out_mqi_ready,
		axis_out_mqi_valid	=> axis_out_mqi_valid
	);
	
	--test stuff
	--pragma synthesis_off
gen_test: if (TEST_GEN_ENABLE) generate
	TEST_CHECK_NORTH_DIFF: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_LDIF_BITS,
			SKIP => 0,
			FILE_NUMBER => 36
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_dd_dqsy_valid,
			ready => axis_dd_dqsy_ready,
			data  => axis_dd_dqsy_nd
		);
		
	TEST_CHECK_WEST_DIFF: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_LDIF_BITS,
			SKIP => 0,
			FILE_NUMBER => 35
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_dd_dqsy_valid,
			ready => axis_dd_dqsy_ready,
			data  => axis_dd_dqsy_wd
		);
		
	TEST_CHECK_NORTHWEST_DIFF: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_LDIF_BITS,
			SKIP => 0,
			FILE_NUMBER => 34
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_dd_dqsy_valid,
			ready => axis_dd_dqsy_ready,
			data  => axis_dd_dqsy_nwd
		);
		
	TEST_CHECK_DRPSV: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_DRPSV_BITS,
			SKIP => 0,
			FILE_NUMBER => 22
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_drpsv_drpsvs_valid,
			ready => axis_drpsv_drpsvs_ready,
			data  => axis_drpsv_drpsvs_d
		);
		
	TEST_CHECK_PSV: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			SKIP => 0,
			FILE_NUMBER => 23
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_psv_psvs_valid,
			ready => axis_psv_psvs_ready,
			data  => axis_psv_psvs_d
		);
		
	TEST_CHECK_PR: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_PR_BITS,
			SKIP => 0,
			FILE_NUMBER => 24
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_pr_prq_valid,
			ready => axis_pr_prq_ready,
			data  => axis_pr_prq_d
		);
		
	TEST_CHECK_DRPE: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_DRPE_BITS,
			SKIP => 0,
			FILE_NUMBER => 27
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_drpe_wu_valid,
			ready => axis_drpe_wu_ready,
			data  => axis_drpe_wu_d
		);
		
	TEST_CHECK_DRSR: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_DRSR_BITS,
			SKIP => 0,
			FILE_NUMBER => 28
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_drsr_cr_valid,
			ready => axis_drsr_cr_ready,
			data  => axis_drsr_cr_d
		);
		
	TEST_CHECK_CQBC: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_CQBC_BITS,
			SKIP => 0,
			FILE_NUMBER => 29
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_cqbc_cqbcs_valid,
			ready => axis_cqbc_cqbcs_ready,
			data  => axis_cqbc_cqbcs_d
		);
		
	TEST_CHECK_MEV: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MEV_BITS,
			SKIP => 0,
			FILE_NUMBER => 30
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_mev_mevs_valid,
			ready => axis_mev_mevs_ready,
			data  => axis_mev_mevs_d
		);
		
	TEST_CHECK_HRPSV: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_HRPSV_BITS,
			SKIP => 0,
			FILE_NUMBER => 31
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_hrpsv_hrpsvs_valid,
			ready => axis_hrpsv_hrpsvs_ready,
			data  => axis_hrpsv_hrpsvs_d
		);
		
	TEST_CHECK_PCLD: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_PCLD_BITS,
			SKIP => 0,
			FILE_NUMBER => 32
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_pcld_hrpsv_valid,
			ready => axis_pcld_hrpsv_ready,
			data  => axis_pcld_hrpsv_d
		);
		
	TEST_CHECK_CD: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_LDIF_BITS,
			SKIP => 0,
			FILE_NUMBER => 33
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_cd_dqsy_valid,
			ready => axis_cd_dqsy_ready,
			data  => axis_cd_dqsy_d
		);
		
	TEST_CHECK_LSUM: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_LSUM_BITS,
			SKIP => 0,
			FILE_NUMBER => 37
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_ls_lss_valid,
			ready => axis_ls_lss_ready,
			data  => axis_ls_lss_ls
		);
		
	TEST_CHECK_QI: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_QI_BITS,
			SKIP => 0,
			FILE_NUMBER => 38
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_qi_qis_valid,
			ready => axis_qi_qis_ready,
			data  => axis_qi_qis_d
		);
		
	TEST_CHECK_SR: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			SKIP => 0,
			FILE_NUMBER => 39
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_cr_crs_valid,
			ready => axis_cr_crs_ready,
			data  => axis_cr_crs_d
		);
		
	TEST_CHECK_THETA: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_THETA_BITS,
			SKIP => 0,
			FILE_NUMBER => 40
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_t_tq_valid,
			ready => axis_t_tq_ready,
			data  => axis_t_tq_d
		);
		
	TEST_CHECK_NR: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			SKIP => 0,
			FILE_NUMBER => 45
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_nr_ls_valid,
			ready => axis_nr_ls_ready,
			data  => axis_nr_ls_n
		);

	TEST_CHECK_NWR: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			SKIP => 0,
			FILE_NUMBER => 43
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_nr_ls_valid,
			ready => axis_nr_ls_ready,
			data  => axis_nr_ls_nw
		);

	TEST_CHECK_NER: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			SKIP => 0,
			FILE_NUMBER => 44
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_nr_ls_valid,
			ready => axis_nr_ls_ready,
			data  => axis_nr_ls_ne
		);

	TEST_CHECK_WR: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			SKIP => 0,
			FILE_NUMBER => 42
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_nr_ls_valid,
			ready => axis_nr_ls_ready,
			data  => axis_nr_ls_w
		);
		
	TEST_CHECK_WDR: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			SKIP => 0,
			FILE_NUMBER => 46
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_nr_ls_valid,
			ready => axis_nr_ls_ready,
			data  => axis_nr_ls_wd
		);
end generate gen_test;
--pragma synthesis_on
end Behavioral;

	