----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.04.2021 09:43:07
-- Design Name: 
-- Module Name: hybrid_encoder - Behavioral
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

entity hybrid_encoder is
	Port ( 
		clk, rst				: in std_logic;
		cfg_initial_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_final_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_axis_in_ihra_d		: in std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
		cfg_axis_in_ihra_valid	: in std_logic;
		cfg_axis_in_ihra_ready	: out std_logic;
		cfg_u_max				: in std_logic_vector(CONST_U_MAX_BITS - 1 downto 0);
		cfg_depth				: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		axis_in_mqi_d			: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_mqi_ready		: out std_logic;
		axis_in_mqi_valid		: in std_logic;
		axis_in_mqi_coord		: in coordinate_bounds_array_t;
		axis_out_code			: out std_logic_vector(63 downto 0);
		axis_out_length			: out std_logic_vector(6 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t;
		axis_out_valid			: out std_logic;
		axis_out_ready			: in std_logic
	);
end hybrid_encoder;

architecture Behavioral of hybrid_encoder is
	--from acc update to table update
	--synchronized counter + accumulator output
	signal axis_au_tu_valid			: std_logic;
	signal axis_au_tu_ready			: std_logic;
	signal axis_au_tu_hra			: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
	signal axis_au_tu_flush_bit		: flush_bit_t;
	signal axis_au_tu_mqi			: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_au_tu_coord			: coordinate_bounds_array_t;
	signal axis_au_tu_cnt			: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	
	--from table update to code gen
	signal axis_tu_cg_ready 		: std_logic; 
	signal axis_tu_cg_valid			: std_logic;
	signal axis_tu_cg_mqi			: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_tu_cg_coord			: coordinate_bounds_array_t;
	signal axis_tu_cg_k				: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal axis_tu_cg_input_symbol	: std_logic_vector(3 downto 0);
	signal axis_tu_cg_code_quant	: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_tu_cg_is_tree		: std_logic_vector(0 downto 0);
	signal axis_tu_cg_cw_bits 		: std_logic_vector(CONST_CODEWORD_BITS - 1 downto 0);
	signal axis_tu_cg_cw_length		: std_logic_vector(CONST_CODEWORD_LENGTH_BITS - 1 downto 0);
	signal axis_tu_cg_ihe			: std_logic;
	signal axis_tu_cg_flush_bit		: flush_bit_t;
begin


	acc_update_stage: entity work.hybrid_encoder_acc_update_stage
		Port map ( 
			clk => clk, rst	=> rst,
			cfg_initial_counter		=> cfg_initial_counter,
			cfg_final_counter		=> cfg_final_counter,
			cfg_axis_in_ihra_d		=> cfg_axis_in_ihra_d,
			cfg_axis_in_ihra_valid	=> cfg_axis_in_ihra_valid,
			cfg_axis_in_ihra_ready	=> cfg_axis_in_ihra_ready,
			axis_in_mqi_d			=> axis_in_mqi_d,
			axis_in_mqi_ready		=> axis_in_mqi_ready,
			axis_in_mqi_valid		=> axis_in_mqi_valid,
			axis_in_mqi_coord		=> axis_in_mqi_coord,
			--synchronized counter + accumulator output
			axis_out_valid			=> axis_au_tu_valid,
			axis_out_ready			=> axis_au_tu_ready,
			axis_out_hra			=> axis_au_tu_hra,
			axis_out_flush_bit		=> axis_au_tu_flush_bit,
			axis_out_mqi			=> axis_au_tu_mqi,
			axis_out_coord			=> axis_au_tu_coord,
			axis_out_cnt			=> axis_au_tu_cnt
		);
		
	table_update_stage: entity work.hybrid_encoder_table_update_stage
		Port map ( 
			clk => clk, rst => rst,
			axis_in_valid			=> axis_au_tu_valid,
			axis_in_ready			=> axis_au_tu_ready,
			axis_in_hra				=> axis_au_tu_hra,
			axis_in_flush_bit		=> axis_au_tu_flush_bit,
			axis_in_mqi				=> axis_au_tu_mqi,
			axis_in_coord			=> axis_au_tu_coord,
			axis_in_cnt				=> axis_au_tu_cnt,
			--output signals
			axis_out_ready 			=> axis_tu_cg_ready,
			axis_out_valid			=> axis_tu_cg_valid,
			axis_out_mqi			=> axis_tu_cg_mqi,
			axis_out_coord			=> axis_tu_cg_coord,
			axis_out_k				=> axis_tu_cg_k,
			axis_out_input_symbol	=> axis_tu_cg_input_symbol,
			axis_out_code_quant		=> axis_tu_cg_code_quant,
			axis_out_is_tree		=> axis_tu_cg_is_tree,
			axis_out_cw_bits 		=> axis_tu_cg_cw_bits,
			axis_out_cw_length		=> axis_tu_cg_cw_length,
			axis_out_ihe			=> axis_tu_cg_ihe,
			axis_out_flush_bit		=> axis_tu_cg_flush_bit
		);

	code_gen_stage: entity work.hybrid_encoder_code_gen_stage 
		Port map ( 
			clk => clk, rst => rst,
			--configs
			cfg_u_max				=> cfg_u_max,
			cfg_depth				=> cfg_depth,
			--output signals
			axis_in_ready 			=> axis_tu_cg_ready,
			axis_in_valid			=> axis_tu_cg_valid,
			axis_in_mqi				=> axis_tu_cg_mqi,
			axis_in_coord			=> axis_tu_cg_coord,
			axis_in_k				=> axis_tu_cg_k,
			axis_in_input_symbol	=> axis_tu_cg_input_symbol,
			axis_in_code_quant		=> axis_tu_cg_code_quant,
			axis_in_is_tree			=> axis_tu_cg_is_tree,
			axis_in_cw_bits 		=> axis_tu_cg_cw_bits,
			axis_in_cw_length		=> axis_tu_cg_cw_length,
			axis_in_ihe				=> axis_tu_cg_ihe,
			axis_in_flush_bit		=> axis_tu_cg_flush_bit,
			axis_out_code			=> axis_out_code,
			axis_out_length			=> axis_out_length,
			axis_out_coord			=> axis_out_coord,
			axis_out_valid			=> axis_out_valid,
			axis_out_ready			=> axis_out_ready
		);
end Behavioral;
