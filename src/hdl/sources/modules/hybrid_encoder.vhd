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
use ieee.numeric_std.all;

entity hybrid_encoder is
	Port ( 
		clk, rst				: in std_logic;
		cfg_initial_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_final_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_gamma_star			: in std_logic_vector(CONST_MAX_GAMMA_STAR_BITS - 1 downto 0);
		cfg_max_z 				: in std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
		cfg_ihra				: in std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
		cfg_u_max				: in std_logic_vector(CONST_U_MAX_BITS - 1 downto 0);
		cfg_depth				: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		axis_in_mqi_d			: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_mqi_ready		: out std_logic;
		axis_in_mqi_valid		: in std_logic;
		axis_in_mqi_coord		: in coordinate_bounds_array_t;
		axis_out_code			: out std_logic_vector(CONST_OUTPUT_CODE_LENGTH - 1 downto 0);
		axis_out_length			: out std_logic_vector(CONST_OUTPUT_CODE_LENGTH_BITS - 1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t;
		axis_out_valid			: out std_logic;
		axis_out_ready			: in std_logic;
		axis_out_last 			: out std_logic
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
	signal axis_tu_cg_input_symbol	: std_logic_vector(CONST_INPUT_SYMBOL_BITS - 1 downto 0);
	signal axis_tu_cg_code_quant	: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_tu_cg_is_tree		: std_logic_vector(0 downto 0);
	signal axis_tu_cg_cw_bits 		: std_logic_vector(CONST_CODEWORD_BITS - 1 downto 0);
	signal axis_tu_cg_cw_length		: std_logic_vector(CONST_CODEWORD_LENGTH_BITS - 1 downto 0);
	signal axis_tu_cg_ihe			: std_logic;
	signal axis_tu_cg_flush_bit		: flush_bit_t;
	signal axis_tu_cg_last			: std_logic;

	--accumulators that need to be flushed
	signal axis_flush_hra_valid, axis_flush_hra_ready: std_logic;
	signal axis_flush_hra_d: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);

	type flushing_fsm_state_t is (RESET, WORKING, FLUSHING_ACC, LAST_BIT, FINISHED);
	signal state_curr, state_next: flushing_fsm_state_t;
	signal flush_index, flush_index_next: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal inner_reset: std_logic;
	
	signal axis_out_code_pre	: std_logic_vector(CONST_OUTPUT_CODE_LENGTH - 1 downto 0);
	signal axis_out_length_pre	: std_logic_vector(CONST_OUTPUT_CODE_LENGTH_BITS - 1 downto 0);
	signal axis_out_coord_pre	: coordinate_bounds_array_t;
	signal axis_out_valid_pre	: std_logic;
	signal axis_out_ready_pre	: std_logic;
	signal axis_out_last_pre 	: std_logic;

begin


	acc_update_stage: entity work.hybrid_encoder_acc_update_stage
		Port map ( 
			clk => clk, rst	=> inner_reset,
			cfg_initial_counter		=> cfg_initial_counter,
			cfg_final_counter		=> cfg_final_counter,
			cfg_ihra				=> cfg_ihra,
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
			axis_out_cnt			=> axis_au_tu_cnt,
			axis_out_flush_hra_valid=> axis_flush_hra_valid,
			axis_out_flush_hra_ready=> axis_flush_hra_ready,
			axis_out_flush_hra_d 	=> axis_flush_hra_d
		);
		
	table_update_stage: entity work.hybrid_encoder_table_update_stage
		Port map ( 
			clk => clk, rst => inner_reset,
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
			axis_out_flush_bit		=> axis_tu_cg_flush_bit,
			axis_out_last			=> axis_tu_cg_last
		);

	code_gen_stage: entity work.hybrid_encoder_code_gen_stage 
		Port map ( 
			clk => clk, rst => inner_reset,
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
			axis_in_last			=> axis_tu_cg_last,
			axis_out_code			=> axis_out_code_pre,
			axis_out_length			=> axis_out_length_pre,
			axis_out_coord			=> axis_out_coord_pre,
			axis_out_valid			=> axis_out_valid_pre,
			axis_out_ready			=> axis_out_ready_pre,
			axis_out_last 			=> axis_out_last_pre
		);

	output_ctrl_seq: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state_curr <= RESET;
				flush_index <= (others => '0');
			else
				state_curr <= STATE_NEXT;
				flush_index <= flush_index_next;
			end if;
		end if;
	end process;

	output_ctrl_comb: process(state_curr, flush_index,
			axis_out_code_pre, axis_out_length_pre,axis_out_coord_pre, axis_out_valid_pre, axis_out_ready, axis_out_last_pre,
			axis_flush_hra_valid, axis_flush_hra_d,
			cfg_gamma_star, cfg_depth, cfg_max_z) 
	begin
		state_next <= state_curr;
		flush_index_next <= flush_index;
			
		axis_out_code 		<= (others => '0');
		axis_out_length 	<= (others => '0');
		axis_out_coord 		<= (others => '0');
		axis_out_last 		<= '0';
		axis_out_valid 		<= '0';
		axis_out_ready_pre 	<= '0';

		axis_flush_hra_ready <= '0';

		inner_reset <= '0';
		if state_curr = RESET then
			inner_reset <= '1';
			state_next <= WORKING;
		elsif state_curr = WORKING then
			axis_out_code 		<= axis_out_code_pre;
			axis_out_length 	<= axis_out_length_pre;
			axis_out_coord 		<= axis_out_coord_pre;
			axis_out_last 		<= '0';
			axis_out_valid 		<= axis_out_valid_pre;
			axis_out_ready_pre 	<= axis_out_ready;

			if axis_out_last_pre = '1' and axis_out_valid_pre = '1' and axis_out_ready = '1' then
				state_next <= FLUSHING_ACC;
			end if;
		elsif state_curr = FLUSHING_ACC then
			axis_out_code 		<= std_logic_vector(resize(unsigned(axis_flush_hra_d), axis_out_code'length));
			axis_out_length 	<= std_logic_vector(resize(unsigned(cfg_gamma_star), axis_out_length'length) + resize(unsigned(cfg_depth), axis_out_length'length) + to_unsigned(2, axis_out_length'length));
			axis_out_coord 		<= "000111"; --first first first last last last
			axis_out_last 		<= '0';
			axis_out_valid 		<= axis_flush_hra_valid;
			axis_flush_hra_ready<= axis_out_ready;

			if axis_flush_hra_valid = '1' and axis_out_ready = '1' then
				if unsigned(flush_index) < unsigned(cfg_max_z) then
					flush_index_next <= std_logic_vector(unsigned(flush_index) + 1);
				else
					state_next <= LAST_BIT;
				end if;
			end if;
		elsif state_curr = LAST_BIT then
			axis_out_code 		<= std_logic_vector(to_unsigned(1, axis_out_code'length));
			axis_out_length 	<= std_logic_vector(to_unsigned(1, axis_out_length'length));
			axis_out_coord 		<= "000111"; --first first first last last last
			axis_out_last 		<= '1';
			axis_out_valid 		<= '1';
			if axis_out_ready = '1' then
				state_next <= FINISHED;
			end if;
		elsif state_curr = FINISHED then
			--
		end if;
	end process;


end Behavioral;
