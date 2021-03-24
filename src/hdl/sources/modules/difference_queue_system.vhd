----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2021 09:36:42
-- Design Name: 
-- Module Name: difference_queue_system - Behavioral
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
use work.am_data_types.all;

entity difference_queue_system is
	Port ( 
		clk, rst				: in std_logic;
		axis_in_coord_d			: in coordinate_bounds_array_t;
		axis_in_coord_ready		: out std_logic;
		axis_in_coord_valid		: in std_logic;
		axis_in_dd_nd 			: in std_logic_vector(CONST_LDIF_BITS-1 downto 0);
		axis_in_dd_nwd	 		: in std_logic_vector(CONST_LDIF_BITS-1 downto 0);
		axis_in_dd_wd 			: in std_logic_vector(CONST_LDIF_BITS-1 downto 0);
		axis_in_dd_ready 		: out std_logic;
		axis_in_dd_valid 		: in std_logic;
		axis_in_dd_coord		: in coordinate_bounds_array_t;
		axis_in_cd_d			: in std_logic_vector(CONST_LDIF_BITS-1 downto 0);
		axis_in_cd_ready 		: out std_logic;
		axis_in_cd_valid 		: in std_logic;
		axis_in_cd_coord		: in coordinate_bounds_array_t;
		axis_out_d				: out std_logic_vector(CONST_DIFFVEC_BITS - 1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t;
		axis_out_ready			: in std_logic;
		axis_out_valid			: out std_logic
	);
end difference_queue_system;

architecture Behavioral of difference_queue_system is
	--signals for the difference queue (only for central local differences)
	signal axis_dq_dvr_d: std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
	signal axis_dq_dvr_valid, axis_dq_dvr_ready: std_logic;
	signal axis_dp_dq_d: std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
	signal axis_dp_dq_valid, axis_dp_dq_ready: std_logic;
	--diff vector retrieval to diff splitter
	signal axis_dvr_ds_d: std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
	signal axis_dvr_ds_valid, axis_dvr_ds_ready: std_logic;
	--diff splitter to outputs
	signal axis_ds_dq2_d: std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
	signal axis_ds_dq2_valid, axis_ds_dq2_ready: std_logic;
	signal axis_ds_dsy_d: std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
	signal axis_ds_dsy_valid, axis_ds_dsy_ready: std_logic;
	--diff queue 2 to dp
	signal axis_dq2_dp_d: std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
	signal axis_dq2_dp_valid, axis_dq2_dp_ready: std_logic;
	
	--helper signals
	signal axis_out_cld: std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
	signal axis_out_dird: std_logic_vector(CONST_DIRDIFFVEC_BITS - 1 downto 0); 
	signal axis_in_dd_ddv: std_logic_vector(CONST_DIRDIFFVEC_BITS - 1 downto 0);
begin

	cld_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_CLDVEC_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_valid	=> axis_dp_dq_valid,
			input_ready => axis_dp_dq_ready,
			input_data	=> axis_dp_dq_d,
			output_ready=> axis_dq_dvr_ready,
			output_data	=> axis_dq_dvr_d,
			output_valid=> axis_dq_dvr_valid,
			flag_almost_full => open, flag_almost_empty => open
		);

	cld_vec_ret: entity work.diff_vec_retrieval
		port map ( 
			clk => clk, rst => rst,
			axis_in_coord_d			=> axis_in_coord_d,
			axis_in_coord_valid		=> axis_in_coord_valid,
			axis_in_coord_ready		=> axis_in_coord_ready,
			axis_in_data_d			=> axis_dq_dvr_d,
			axis_in_data_valid		=> axis_dq_dvr_valid,
			axis_in_data_ready		=> axis_dq_dvr_ready,
			axis_out_data_d			=> axis_dvr_ds_d,
			axis_out_data_valid		=> axis_dvr_ds_valid,
			axis_out_data_ready		=> axis_dvr_ds_ready
		);
		
	cld_split: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH => CONST_CLDVEC_BITS
		)
		Port map (
			clk => clk, rst	=> rst,
			input_valid		=> axis_dvr_ds_valid,
			input_data		=> axis_dvr_ds_d,
			input_ready		=> axis_dvr_ds_ready,
			output_0_valid	=> axis_ds_dq2_valid,
			output_0_data	=> axis_ds_dq2_d,
			output_0_ready	=> axis_ds_dq2_ready,
			output_1_valid	=> axis_ds_dsy_valid,
			output_1_data	=> axis_ds_dsy_d,
			output_1_ready	=> axis_ds_dsy_ready
		);
		
	cld_queue2: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_CLDVEC_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_valid	=> axis_ds_dq2_valid,
			input_ready => axis_ds_dq2_ready,
			input_data	=> axis_ds_dq2_d,
			output_ready=> axis_dq2_dp_ready,
			output_data	=> axis_dq2_dp_d,
			output_valid=> axis_dq2_dp_valid,
			flag_almost_full => open, flag_almost_empty => open
		);
		
	diff_putter: entity work.diff_putter 
		Port map ( 
			clk => clk, rst => rst,
			axis_diffs_d		=> axis_dq2_dp_d,
			axis_diffs_valid	=> axis_dq2_dp_valid,
			axis_diffs_ready	=> axis_dq2_dp_ready,
			axis_cdif_d			=> axis_in_cd_d,
			axis_cdif_coord		=> axis_in_cd_coord,
			axis_cdif_valid		=> axis_in_cd_valid,
			axis_cdif_ready		=> axis_in_cd_ready,
			axis_out_diffs_d	=> axis_dp_dq_d,
			axis_out_diffs_valid=> axis_dp_dq_valid,
			axis_out_diffs_ready=> axis_dp_dq_ready
		);
		
	axis_in_dd_ddv <= axis_in_dd_nd & axis_in_dd_wd & axis_in_dd_nwd;
	out_sync: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_CLDVEC_BITS,
			DATA_WIDTH_1 => CONST_DIRDIFFVEC_BITS,
			LATCH => false,
			USER_WIDTH => coordinate_bounds_array_t'length,
			USER_POLICY => PASS_ONE
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid=> axis_ds_dsy_valid,
			input_0_ready=> axis_ds_dsy_ready,
			input_0_data => axis_ds_dsy_d,
			input_1_valid=> axis_in_dd_valid,
			input_1_ready=> axis_in_dd_ready,
			input_1_data => axis_in_dd_ddv,
			input_1_user => axis_in_dd_coord,
			--to output axi ports
			output_valid => axis_out_valid,
			output_ready => axis_out_ready,
			output_data_0=> axis_out_cld,
			output_data_1=> axis_out_dird,
			output_user	 => axis_out_coord
		);
		axis_out_d <= axis_out_dird & axis_out_cld;
	
end Behavioral;
