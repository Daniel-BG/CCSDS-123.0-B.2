----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2021 10:46:01
-- Design Name: 
-- Module Name: weight_module - Behavioral
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
use work.ccsds_constants.all;
use work.ccsds_data_structures.all;

entity weight_module is
	Port ( 
		clk, rst				: in std_logic;
		--cfgs
		cfg_samples				: in std_logic_vector(CONST_MAX_SAMPLES_BITS - 1 downto 0);
		cfg_tinc				: in std_logic_vector(CONST_TINC_BITS - 1 downto 0);
		cfg_vmax, cfg_vmin		: in std_logic_vector(CONST_VMINMAX_BITS - 1 downto 0);
		cfg_depth				: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		cfg_omega				: in std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
		cfg_weo					: in std_logic_vector(CONST_WEO_BITS - 1 downto 0);
		--axis for starting weights (cfg)
--		cfg_weight_vec			: in std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
		--axis for coordinate 
		axis_in_coord_d			: in coordinate_bounds_array_t;
		axis_in_coord_valid		: in std_logic;
		axis_in_coord_ready		: out std_logic;
		--axis for wuse coordinate
		axis_in_wuse_coord_t	: in std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
		axis_in_wuse_coord_valid: in std_logic;
		axis_in_wuse_coord_ready: out std_logic;
		--axis for difference vector (update)
		axis_in_dv_ready		: out std_logic;
		axis_in_dv_valid		: in std_logic;
		axis_in_dv_d			: in std_logic_vector(CONST_DIFFVEC_BITS - 1 downto 0);
		axis_in_dv_coord		: in coordinate_bounds_array_t;
		--axis for drpe
		axis_drpe_d				: in STD_LOGIC_VECTOR(CONST_DRPE_BITS - 1 downto 0);
		axis_drpe_ready			: out std_logic;
		axis_drpe_valid			: in std_logic;
		--output weight vector
		axis_out_wv_d			: out std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
		axis_out_wv_valid		: out std_logic;
		axis_out_wv_ready		: in std_logic
	);
end weight_module;

architecture Behavioral of weight_module is
	--signal for queues
	signal axis_swq_wret_ready, axis_swq_wret_valid: std_logic;
	signal axis_swq_wret_d: std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
	signal axis_wqp_swq_ready, axis_wqp_swq_valid: std_logic;
	signal axis_wqp_swq_d: std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);

	--wuse outputs
	signal axis_wuse_wu_ready, axis_wuse_wu_valid: std_logic;
	signal axis_wuse_wu_d: std_logic_vector(CONST_WUSE_BITS - 1 downto 0);
	signal axis_wuse_wu_l_ready, axis_wuse_wu_l_valid: std_logic;
	signal axis_wuse_wu_l_d: std_logic_vector(CONST_WUSE_BITS - 1 downto 0);
	
	--weight retrieval
	signal axis_wret_ws_d: std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
	signal axis_wret_ws_valid, axis_wret_ws_ready: std_logic;
	
	--weight update queue
	signal axis_ws_wuq_valid, axis_ws_wuq_ready: std_logic;
	signal axis_ws_wuq_d: std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
	signal axis_wuq_wu_valid, axis_wuq_wu_ready: std_logic;
	signal axis_wuq_wu_d: std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
	
	--weight update to weight queue putter
	signal axis_wu_wqp_ready, axis_wu_wqp_valid: std_logic;
	signal axis_wu_wqp_d: std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
	signal axis_wu_wqp_coord: coordinate_bounds_array_t;
	
	--helpers
	signal axis_in_coord_cond: std_logic;
	
	--default weights
	signal cfg_weight_vec: std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);

	--
	signal inner_reset: std_logic;
begin

	reset_replicator: entity work.reset_replicator
		port map (
			clk => clk, rst => rst,
			rst_out => inner_reset
		);

		
	saved_weight_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_WEIGHTVEC_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_wqp_swq_valid,
			input_ready => axis_wqp_swq_ready,
			input_data	=> axis_wqp_swq_d,
			output_ready=> axis_swq_wret_ready,
			output_data	=> axis_swq_wret_d,
			output_valid=> axis_swq_wret_valid,
			flag_almost_full => open, flag_almost_empty => open
		);
		
	update_axis_in_coord_cond: process(axis_in_coord_d) begin
		if F_STDLV2CB(axis_in_coord_d).first_x = '1' and F_STDLV2CB(axis_in_coord_d).first_y = '1' then
			axis_in_coord_cond <= '0';
		else 
			axis_in_coord_cond <= '1';
		end if;
	end process;
	
	gen_default_weights_dir: for i in CONST_MAX_C - 1 downto CONST_MAX_P generate
		cfg_weight_vec(CONST_MAX_WEIGHT_BITS*(i+1) - 1 downto CONST_MAX_WEIGHT_BITS*i) <= (others => '0'); 
	end generate;
	gen_default_weights_central: for i in CONST_MAX_P - 1 downto 0 generate
		cfg_weight_vec(CONST_MAX_WEIGHT_BITS*(i+1) - 1 downto CONST_MAX_WEIGHT_BITS*i) <= std_logic_vector(to_unsigned(7*(2**19) / (2**(3*(CONST_MAX_P - i))) , CONST_MAX_WEIGHT_BITS));
	end generate;
	weight_retrieval: entity work.axis_conditioned_selector
		generic map (
			DATA_WIDTH => CONST_WEIGHTVEC_BITS
		)
		port map ( 
			clk => clk, rst => inner_reset,
			axis_in_cond			=> axis_in_coord_cond,
			axis_in_cond_valid		=> axis_in_coord_valid,
			axis_in_cond_ready		=> axis_in_coord_ready,
			axis_in_data_0_d		=> cfg_weight_vec,
			axis_in_data_0_valid	=> '1',
			axis_in_data_0_ready	=> open,
			axis_in_data_1_d		=> axis_swq_wret_d,
			axis_in_data_1_valid	=> axis_swq_wret_valid,
			axis_in_data_1_ready	=> axis_swq_wret_ready,
			axis_out_data_d			=> axis_wret_ws_d,
			axis_out_data_valid		=> axis_wret_ws_valid,
			axis_out_data_ready		=> axis_wret_ws_ready
		);

	weight_vec_splitter: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH => CONST_WEIGHTVEC_BITS
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_wret_ws_valid,
			input_data		=> axis_wret_ws_d,
			input_ready		=> axis_wret_ws_ready,
			--to output axi ports
			output_0_valid	=> axis_out_wv_valid,
			output_0_data	=> axis_out_wv_d,
			output_0_ready	=> axis_out_wv_ready,
			output_1_valid	=> axis_ws_wuq_valid,
			output_1_data	=> axis_ws_wuq_d,
			output_1_ready	=> axis_ws_wuq_ready
		);
		
	weight_update_queue: entity work.AXIS_FIFO 
		Generic map (
			DATA_WIDTH => CONST_WEIGHTVEC_BITS,
			FIFO_DEPTH => 64
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_valid	=> axis_ws_wuq_valid,
			input_ready => axis_ws_wuq_ready,
			input_data	=> axis_ws_wuq_d,
			output_ready=> axis_wuq_wu_ready,
			output_data	=> axis_wuq_wu_d,
			output_valid=> axis_wuq_wu_valid,
			flag_almost_full => open, flag_almost_empty => open
		);

	wuse_calc: entity work.wuse_calc 
		Port map ( 
			clk => clk, rst => inner_reset,
			cfg_samples			=> cfg_samples,
			cfg_tinc			=> cfg_tinc,
			cfg_vmax			=> cfg_vmax,
			cfg_vmin			=> cfg_vmin,
			cfg_depth			=> cfg_depth,
			cfg_omega			=> cfg_omega,
			axis_in_coord_t		=> axis_in_wuse_coord_t,
			axis_in_coord_valid	=> axis_in_wuse_coord_valid,
			axis_in_coord_ready	=> axis_in_wuse_coord_ready,
			axis_out_wuse_ready	=> axis_wuse_wu_ready,
			axis_out_wuse_valid	=> axis_wuse_wu_valid,
			axis_out_wuse_d		=> axis_wuse_wu_d
		);
		
	wuse_latch: entity work.AXIS_LATCHED_CONNECTION
		Generic map (
			DATA_WIDTH => CONST_WUSE_BITS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_data	=> axis_wuse_wu_d,
			input_ready => axis_wuse_wu_ready,
			input_valid => axis_wuse_wu_valid,
			output_data	=> axis_wuse_wu_l_d,
			output_ready=> axis_wuse_wu_l_ready,
			output_valid=> axis_wuse_wu_l_valid
		);

	weight_update: entity work.wu_calc
		Port map ( 
			clk => clk, rst => inner_reset,
			cfg_weo				=> cfg_weo,
			cfg_omega			=> cfg_omega,
			axis_dv_d			=> axis_in_dv_d,
			axis_dv_ready		=> axis_in_dv_ready,
			axis_dv_valid 		=> axis_in_dv_valid,
			axis_dv_coord 		=> axis_in_dv_coord,
			axis_wv_d			=> axis_wuq_wu_d,
			axis_wv_ready		=> axis_wuq_wu_ready,
			axis_wv_valid 		=> axis_wuq_wu_valid,
			axis_wuse_d			=> axis_wuse_wu_l_d,
			axis_wuse_ready		=> axis_wuse_wu_l_ready,
			axis_wuse_valid 	=> axis_wuse_wu_l_valid,
			axis_drpe_d			=> axis_drpe_d,
			axis_drpe_ready		=> axis_drpe_ready,
			axis_drpe_valid 	=> axis_drpe_valid,
			axis_out_wv_ready	=> axis_wu_wqp_ready,
			axis_out_wv_valid 	=> axis_wu_wqp_valid,
			axis_out_wv_d		=> axis_wu_wqp_d,
			axis_out_wv_coord	=> axis_wu_wqp_coord
		);
		
	weight_putter: entity work.weight_putter
		Port map ( 
			clk => clk, rst	=> inner_reset,
			axis_in_d		=> axis_wu_wqp_d,
			axis_in_coord	=> axis_wu_wqp_coord,
			axis_in_valid	=> axis_wu_wqp_valid,
			axis_in_ready	=> axis_wu_wqp_ready,
			axis_out_d		=> axis_wqp_swq_d,
			axis_out_valid	=> axis_wqp_swq_valid,
			axis_out_ready	=> axis_wqp_swq_ready
		);

	--pragma synthesis_off
	gen_test: if (TEST_GEN_ENABLE) generate
	TEST_CHECK_WU: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_WUSE_BITS,
			SKIP => 0,
			FILE_NUMBER => 26
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_wuse_wu_valid,
			ready => axis_wuse_wu_ready,
			data  => axis_wuse_wu_d
		);
	end generate gen_test;
	--pragma synthesis_on
end Behavioral;

	--`define CONST_GOLDEN_NUM_DIAG_W			25
