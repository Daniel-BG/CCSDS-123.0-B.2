----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.04.2021 13:15:06
-- Design Name: 
-- Module Name: hybrid_encoder_table_update_stage - Behavioral
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

entity hybrid_encoder_table_update_stage is
	Port ( 
		clk, rst				: in std_logic;
		axis_in_valid			: in std_logic;
		axis_in_ready			: out std_logic;
		axis_in_hra				: in std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
		axis_in_flush_bit		: in flush_bit_t;
		axis_in_mqi				: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_coord			: in coordinate_bounds_array_t;
		axis_in_cnt				: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		--output signals
		axis_out_ready 			: in std_logic; 
		axis_out_valid			: out std_logic;
		axis_out_mqi			: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t;
		axis_out_k				: out std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
		axis_out_input_symbol	: out std_logic_vector(CONST_INPUT_SYMBOL_BITS - 1 downto 0);
		axis_out_code_quant		: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_is_tree		: out std_logic_vector(0 downto 0);
		axis_out_cw_bits 		: out std_logic_vector(CONST_CODEWORD_BITS - 1 downto 0);
		axis_out_cw_length		: out std_logic_vector(CONST_CODEWORD_LENGTH_BITS - 1 downto 0);
		axis_out_ihe			: out std_logic;
		axis_out_flush_bit		: out flush_bit_t;
		axis_out_last			: out std_logic
	);
end hybrid_encoder_table_update_stage;

architecture Behavioral of hybrid_encoder_table_update_stage is
	constant FIRST_STAGE_MULTIPLIER_NUMBER_OF_STAGES: integer := 2;

	--first stage signals
	signal axis_in_ready_buf: std_logic;
	signal transaction_at_mult_input, transaction_at_mult_output: std_logic;
	signal fs_comp				: std_logic_vector(CONST_MAX_HR_ACC_BITS downto 0);
	signal fs_hra				: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
	signal fs_flush_bit			: flush_bit_t;
	signal fs_mqi				: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal fs_coord				: coordinate_bounds_array_t;
	signal fs_cnt				: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal fs_ready, fs_valid	: std_logic;
	signal fs_ihe				: std_logic;
	signal fs_code_index		: std_logic_vector(CONST_CODE_INDEX_BITS - 1 downto 0);
	signal fs_cnt_t_49			: std_logic_vector(CONST_MAX_COUNTER_BITS + 6 - 1 downto 0);
	
	--first stage latch
	signal fsl_comp				: std_logic_vector(CONST_MAX_HR_ACC_BITS downto 0);
	signal fsl_flush_bit			: flush_bit_t;
	signal fsl_mqi				: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal fsl_coord				: coordinate_bounds_array_t;
	signal fsl_cnt				: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal fsl_ready, fsl_valid	: std_logic;
	signal fsl_k					: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal fsl_ihe				: std_logic;
	signal fsl_code_index		: std_logic_vector(CONST_CODE_INDEX_BITS - 1 downto 0);

	type cnt_t_t_array is array(0 to CONST_LE_TABLE_COUNT - 1) of std_logic_vector(CONST_MAX_COUNTER_BITS + threshold_value_t'length - 1 downto 0);
	signal fs_cnt_array: cnt_t_t_array;

	--second stage signals
	signal ss_valid, ss_ready	: std_logic;
	signal ss_k					: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal ss_ihe				: std_logic;
	signal ss_code_index		: std_logic_vector(CONST_CODE_INDEX_BITS - 1 downto 0);
	signal ss_mqi				: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal ss_coord				: coordinate_bounds_array_t;
	signal ss_flush_bit			: flush_bit_t;
	signal ss_input_symbol		: std_logic_vector(CONST_INPUT_SYMBOL_BITS - 1 downto 0);
	
	--filtered second stage signals (through fsm)
	signal fss_valid, fss_ready	: std_logic;
	signal fss_last				: std_logic;
	signal fss_k				: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal fss_ihe				: std_logic;
	signal fss_code_index		: std_logic_vector(CONST_CODE_INDEX_BITS - 1 downto 0);
	signal fss_mqi				: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal fss_coord			: coordinate_bounds_array_t;
	signal fss_flush_bit		: flush_bit_t;
	signal fss_code_table_addr	: std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
	signal fss_input_symbol		: std_logic_vector(CONST_INPUT_SYMBOL_BITS - 1 downto 0);

	--code rom
	signal code_rom_enable 		: std_logic;
	
	--table flushing fsm between second and third stage
	type table_flushing_fsm_state_t is (RESET, WORKING, FLUSHING_LEC, FINISHED);
	signal tf_state_curr, tf_state_next: table_flushing_fsm_state_t;
	signal tf_flush_index, tf_flush_index_next: std_logic_vector(CONST_CODE_INDEX_BITS - 1 downto 0);
	
	--third stage signals
	type ts_code_table_enties_t is array(0 to CONST_INPUT_SYMBOL_AMOUNT - 1) of std_logic_vector(CONST_LOW_ENTROPY_TABLE_ENTRY_BITS - 1 downto 0);
	signal ts_code_table_entries: ts_code_table_enties_t;
	signal ts_selected_table_entry: std_logic_vector(CONST_LOW_ENTROPY_TABLE_ENTRY_BITS - 1 downto 0);
	signal ts_mqi				: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal ts_coord				: coordinate_bounds_array_t;
	signal ts_ready, ts_valid	: std_logic;
	signal ts_last				: std_logic;
	signal ts_flush_bit			: flush_bit_t;
	signal ts_code_index		: std_logic_vector(CONST_CODE_INDEX_BITS - 1 downto 0);
	signal ts_input_symbol		: std_logic_vector(CONST_INPUT_SYMBOL_BITS - 1 downto 0);
	signal ts_code_table_addr	: std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
	signal ts_ihe				: std_logic;
	signal ts_cw_bits 			: std_logic_vector(CONST_CODEWORD_BITS - 1 downto 0);
	signal ts_cw_length 		: std_logic_vector(CONST_CODEWORD_LENGTH_BITS - 1 downto 0);
	signal ts_is_tree			: std_logic_vector(0 downto 0);
	signal ts_k					: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal ts_code_quant		: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	--third stage back to second
	signal ts_at_wren 			: std_logic;
	signal ts_at_next_addr		: std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
			
	--for testing
	signal ts_ihe_stdlv: std_logic_vector(0 downto 0);
	
	signal inner_reset: std_logic;		
begin
	axis_in_ready <= axis_in_ready_buf;

	--first we need 16 multipliers to multiply the counter by the threshold value
	--the first multiplier carries the other signals
	multiply_zero: entity work.AXIS_MULTIPLIER
		Generic map (
			DATA_WIDTH_0 		=> CONST_MAX_COUNTER_BITS,
			DATA_WIDTH_1 		=> threshold_value_t'length,
			SIGNED_0	 		=> false,
			SIGNED_1			=> false,
			USER_WIDTH			=> coordinate_bounds_array_t'length + flush_bit_t'length + CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS,
			STAGES_AFTER_SYNC	=> FIRST_STAGE_MULTIPLIER_NUMBER_OF_STAGES
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_0_data	=> axis_in_cnt,
			input_0_valid	=> axis_in_valid,
			input_0_ready	=> axis_in_ready_buf,
			input_0_user(coordinate_bounds_array_t'length + flush_bit_t'length + CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto flush_bit_t'length + CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => axis_in_coord,
			input_0_user(flush_bit_t'length + CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => axis_in_flush_bit,
			input_0_user(CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => axis_in_hra,
			input_0_user(CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MQI_BITS) => axis_in_cnt,
			input_0_user(CONST_MQI_BITS - 1 downto 0) => axis_in_mqi,
			input_1_data	=> CONST_THRESHOLD_TABLE(0),
			input_1_valid	=> '1',
			input_1_ready	=> open,
			output_data		=> fs_cnt_array(0),
			output_valid	=> fs_valid,
			output_ready	=> fs_ready,
			output_user(coordinate_bounds_array_t'length + flush_bit_t'length + CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto flush_bit_t'length + CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => fs_coord,
			output_user(flush_bit_t'length + CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => fs_flush_bit,
			output_user(CONST_MAX_HR_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => fs_hra,
			output_user(CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MQI_BITS) => fs_cnt,
			output_user(CONST_MQI_BITS - 1 downto 0) => fs_mqi
		);
		
	--15 other multipliers just multiply
	transaction_at_mult_input <= axis_in_valid and axis_in_ready_buf;
	transaction_at_mult_output <= fs_valid and fs_ready;
	gen_multipliers: for i in 1 to CONST_LE_TABLE_COUNT - 1 generate
		multiply_i: entity work.AXIS_MULTIPLIER
			Generic map (
				DATA_WIDTH_0 		=> CONST_MAX_COUNTER_BITS,
				DATA_WIDTH_1 		=> threshold_value_t'length,
				SIGNED_0	 		=> false,
				SIGNED_1			=> false,
				STAGES_AFTER_SYNC	=> FIRST_STAGE_MULTIPLIER_NUMBER_OF_STAGES
			)
			Port map (
				clk => clk, rst => inner_reset,
				input_0_data	=> axis_in_cnt,
				input_0_valid	=> transaction_at_mult_input,
				input_0_ready	=> open,
				input_1_data	=> CONST_THRESHOLD_TABLE(i),
				input_1_valid	=> '1',
				input_1_ready	=> open,
				output_data		=> fs_cnt_array(i),
				output_valid	=> open,
				output_ready	=> transaction_at_mult_output
			);
	end generate;
	--mutliplier for cnt*49 (k calc later)
	multiply_cnt_t_49: entity work.AXIS_MULTIPLIER
		Generic map (
			DATA_WIDTH_0 		=> CONST_MAX_COUNTER_BITS,
			DATA_WIDTH_1 		=> 6,
			SIGNED_0	 		=> false,
			SIGNED_1			=> false,
			STAGES_AFTER_SYNC	=> FIRST_STAGE_MULTIPLIER_NUMBER_OF_STAGES
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_0_data	=> axis_in_cnt,
			input_0_valid	=> transaction_at_mult_input,
			input_0_ready	=> open,
			input_1_data	=> "110001",
			input_1_valid	=> '1',
			input_1_ready	=> open,
			output_data		=> fs_cnt_t_49,
			output_valid	=> open,
			output_ready	=> transaction_at_mult_output
		);


	--parameter calculation for output of first stage
	k_comp_calc: process(fs_hra, fs_cnt_t_49)
	begin
		fs_comp <= std_logic_vector(resize(unsigned(fs_hra) + shift_right(unsigned(fs_cnt_t_49), 5), fs_comp'length));
	end process;
	
	condition_calc: process(fs_cnt_array, fs_hra)
	begin
		if (shift_left(resize(unsigned(fs_hra), CONST_MAX_HR_ACC_BITS + 14), 14) >= resize(unsigned(fs_cnt_array(0)),  CONST_MAX_HR_ACC_BITS + 14)) then
			fs_ihe <= '1';
		else
			fs_ihe <= '0';
		end if;
	end process;
	
	codeIndex_calc: process(fs_hra, fs_cnt_array)
		variable code_index: std_logic_vector(CONST_CODE_INDEX_BITS - 1 downto 0);
	begin
		code_index := (others => '0');
		ci_loop: for i in 0 to CONST_LE_TABLE_COUNT - 1 loop
			if (shift_left(resize(unsigned(fs_hra), CONST_MAX_HR_ACC_BITS + 14), 14) < resize(unsigned(fs_cnt_array(i)),  CONST_MAX_HR_ACC_BITS + 14)) then
				code_index := std_logic_vector(to_unsigned(i, CONST_CODE_INDEX_BITS));
			else
				exit ci_loop;
			end if;
		end loop;
		fs_code_index <= code_index;
	end process;

	fs_latch: entity work.AXIS_DATA_LATCH 
		Generic map (
			DATA_WIDTH => fs_comp'length + fs_mqi'length + fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_data (fs_comp'length + fs_mqi'length + fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length - 1 downto fs_mqi'length + fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length)	=> fs_comp,
			input_data (				 fs_mqi'length + fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length - 1 downto 				 fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length)	=> fs_mqi,
			input_data (								 fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length - 1 downto 								 fs_flush_bit'length + fs_coord'length + fs_code_index'length)	=> fs_cnt,
			input_data (												 fs_flush_bit'length + fs_coord'length + fs_code_index'length - 1 downto 				   					  				   fs_coord'length + fs_code_index'length)	=> fs_flush_bit,
			input_data (													  				   fs_coord'length + fs_code_index'length - 1 downto 				   														 fs_code_index'length)	=> fs_coord,
			input_data (																						 fs_code_index'length - 1 downto 				   										   				   				 	0)	=> fs_code_index,
			input_ready => fs_ready,
			input_valid => fs_valid,
			input_last  => fs_ihe,
			output_data(fs_comp'length + fs_mqi'length + fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length - 1 downto fs_mqi'length + fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length)	=> fsl_comp,
			output_data(				 fs_mqi'length + fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length - 1 downto 				 fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length)	=> fsl_mqi,
			output_data(								 fs_cnt'length + fs_flush_bit'length + fs_coord'length + fs_code_index'length - 1 downto 								 fs_flush_bit'length + fs_coord'length + fs_code_index'length)	=> fsl_cnt,
			output_data(												 fs_flush_bit'length + fs_coord'length + fs_code_index'length - 1 downto 				   					  				   fs_coord'length + fs_code_index'length)	=> fsl_flush_bit,
			output_data(													  				   fs_coord'length + fs_code_index'length - 1 downto 				   														 fs_code_index'length)	=> fsl_coord,
			output_data(																						 fs_code_index'length - 1 downto 				   										   				   				 	0)	=> fsl_code_index,
			output_ready=> fsl_ready,
			output_valid=> fsl_valid,
			output_last => fsl_ihe
		);

	--parameter calculation for output of first stage
	k_calc: process(fsl_cnt, fsl_comp)
		variable new_k: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	begin
		new_k := std_logic_vector(to_unsigned(1, new_k'length));
		for i in 1 to CONST_MAX_DATA_WIDTH - 3 loop
			if shift_left(resize(unsigned(fsl_cnt), CONST_MAX_HR_ACC_BITS + 1), i+1+2) <= unsigned(fsl_comp) then
				new_k := std_logic_vector(to_unsigned(i+1, new_k'length));
			end if;
		end loop;
		fsl_k <= new_k;
	end process;

	
	--second stage: k, codeIndex and condition calculated
	ss_latch: entity work.AXIS_LATCHED_CONNECTION 
		Generic map (
			DATA_WIDTH => CONST_MQI_BITS,
			USER_WIDTH => flush_bit_t'length + CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_data	=> fsl_mqi,
			input_ready => fsl_ready,
			input_valid => fsl_valid,
			input_user(flush_bit_t'length + CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS - 1 downto CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS) => fsl_flush_bit,
			input_user(CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS - 1 downto coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS) => fsl_k,
			input_user(coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS - 1 downto CONST_CODE_INDEX_BITS) => fsl_coord,
			input_user(CONST_CODE_INDEX_BITS - 1 downto 0) => fsl_code_index,
			input_last  => fsl_ihe,
			output_data	=> ss_mqi,
			output_ready=> ss_ready,
			output_valid=> ss_valid,
			output_user(flush_bit_t'length + CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS - 1 downto CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS) => ss_flush_bit,
			output_user(CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS - 1 downto coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS) => ss_k,
			output_user(coordinate_bounds_array_t'length + CONST_CODE_INDEX_BITS - 1 downto CONST_CODE_INDEX_BITS) => ss_coord,
			output_user(CONST_CODE_INDEX_BITS - 1 downto 0) => ss_code_index,
			output_last => ss_ihe
		);
		
	--calc input symbol , very important
	input_symbol_calc: process(ss_mqi, ss_code_index)
	begin
		if (unsigned(ss_mqi) <= unsigned(CONST_INPUT_SYMBOL_LIMIT(to_integer(unsigned(ss_code_index))))) then
			ss_input_symbol <= std_logic_vector(resize(unsigned(ss_mqi), CONST_INPUT_SYMBOL_BITS));
		else
			ss_input_symbol <= CONST_INPUT_SYMBOL_X;
		end if;
	end process;
		
	--FSM to control the flushing of tables
	table_flushing_fsm_seq: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				tf_state_curr <= RESET;
				tf_flush_index <= (others => '0');
			else
				tf_state_curr <= tf_state_next;
				tf_flush_index <= tf_flush_index_next;
			end if;
		end if;
	end process;
	
	table_flushing_fsm_comb: process(tf_state_curr, tf_state_next, 
			ss_k, ss_ihe, ss_code_index, ss_mqi, ss_coord, ss_flush_bit, ss_input_symbol, ss_valid,
			fss_ready,
			tf_flush_index)
	begin
		--default control signals
		fss_valid 			<= '0';
		ss_ready 			<= '0';
		fss_last 			<= '0';
		--default pipe values
		fss_k				<= ss_k;
		fss_ihe				<= ss_ihe;
		fss_code_index		<= ss_code_index;
		fss_mqi				<= ss_mqi;
		fss_coord			<= ss_coord;
		fss_flush_bit		<= ss_flush_bit;
		fss_input_symbol 	<= ss_input_symbol;
		
		tf_state_next <= tf_state_curr;
		tf_flush_index_next <= tf_flush_index;

		inner_reset <= '0';
		if tf_state_curr = RESET then
			inner_reset <= '1';
			tf_state_next <= WORKING;
		elsif tf_state_curr = WORKING then
			fss_valid <= ss_valid;
			ss_ready <= fss_ready;
			if (ss_valid = '1' and fss_ready = '1' and F_STDLV2CB(ss_coord).last_x = '1' and F_STDLV2CB(ss_coord).last_y = '1' and F_STDLV2CB(ss_coord).last_z = '1') then
				tf_state_next <= FLUSHING_LEC;
				tf_flush_index_next <= (others => '0');
			end if;
		elsif tf_state_curr = FLUSHING_LEC then
			fss_valid <= '1';
			if (fss_ready = '1') then
				if tf_flush_index = std_logic_vector(to_unsigned(CONST_LE_TABLE_COUNT - 1, CONST_CODE_INDEX_BITS)) then
					fss_last <= '1';
					tf_state_next <= FINISHED;
				else
					tf_flush_index_next <= std_logic_vector(unsigned(tf_flush_index) + 1);
				end if;
			end if;
			--set values to output only codeword
--			fss_k				<= ss_k; 					--dont care value, keep previous
			fss_ihe 			<= '0'; 					--force low entropy
			fss_code_index		<= tf_flush_index;			--get the table with the current flush index
--			fss_mqi				<= ss_mqi; 					--dont care value, keep previous
			fss_coord			<= "000111";				--keep last coordinate
			fss_flush_bit		<= (others => '0'); 		--force no flush bit
			fss_input_symbol 	<= CONST_INPUT_SYMBOL_FLUSH;--from the current table, read the flush symbol
		elsif tf_state_curr = FINISHED then
			--do nothing, we are finished until reset
			--signals are disconnected
		end if;
	end process;

	--things start to get FUNKEY in the intra SECOND_TO_THIRD stage modules
	active_address_table: entity work.hybrid_encoder_active_table_address_table
		Port map ( 
			clk => clk, rst => inner_reset,
			read_index => fss_code_index,
			read_addr => fss_code_table_addr,
			write_enable => ts_at_wren,
			write_index => ts_code_index,
			write_addr => ts_at_next_addr
		);
	
	--third stage latch
	ts_latch: entity work.AXIS_DATA_LATCH 
		Generic map (
			DATA_WIDTH => CONST_MQI_BITS,
			USER_WIDTH => 1 + CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_data => fss_mqi,
			input_ready => fss_ready,
			input_valid => fss_valid,
			input_user(1 + CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1)  => fss_ihe,
			input_user(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS)  => fss_code_table_addr,
			input_user(coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS)  => fss_coord,
			input_user(CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS)  => fss_k,
			input_user(flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS)  => fss_flush_bit,
			input_user(CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto CONST_INPUT_SYMBOL_BITS)  => fss_code_index,
			input_user(CONST_INPUT_SYMBOL_BITS - 1 downto 0)  => fss_input_symbol,
			input_last  => fss_last,
			output_data	=> ts_mqi,
			output_ready=> ts_ready,
			output_valid=> ts_valid,
			output_user(1 + CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1)  => ts_ihe,
			output_user(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS)  => ts_code_table_addr,
			output_user(coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS)  => ts_coord,
			output_user(CONST_MAX_K_BITS + flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS)  => ts_k,
			output_user(flush_bit_t'length + CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS)  => ts_flush_bit,
			output_user(CONST_CODE_INDEX_BITS + CONST_INPUT_SYMBOL_BITS - 1 downto CONST_INPUT_SYMBOL_BITS)  => ts_code_index,
			output_user(CONST_INPUT_SYMBOL_BITS - 1 downto 0)  => ts_input_symbol,
			output_last => ts_last
		);
		
	--code table ROM
	code_rom_enable <= fss_ready and fss_valid;
	code_rom: entity work.code_table_clocked_rom
		Port map ( 
			clk => clk, rst => inner_reset,
			enable => code_rom_enable,
			addr_table_entry => fss_code_table_addr,
			addr_input_symbol => fss_input_symbol,
			data => ts_selected_table_entry
		);
	
	process_table_entry: process(ts_selected_table_entry, ts_code_index, ts_valid, ts_ready, ts_ihe)
	begin
		ts_at_wren <= ts_valid and ts_ready and (not ts_ihe); --only write when it is low entropy and the pipeline moves
		ts_is_tree <= ts_selected_table_entry(ts_selected_table_entry'high downto ts_selected_table_entry'high);
		ts_at_next_addr <= ts_selected_table_entry(ts_at_next_addr'high downto 0);
		ts_cw_bits <= ts_selected_table_entry(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + CONST_CODEWORD_BITS - 1 downto CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS);
		ts_cw_length <= ts_selected_table_entry(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + CONST_CODEWORD_LENGTH_BITS + CONST_CODEWORD_BITS - 1 downto CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + CONST_CODEWORD_BITS);
	end process;

	--calc code quantity (in case input symbol is X)
	code_quant_calc: process(ts_mqi, ts_code_index)
	begin
		ts_code_quant <= std_logic_vector(unsigned(ts_mqi) - unsigned(CONST_INPUT_SYMBOL_LIMIT(to_integer(unsigned(ts_code_index)))) - 1);
	end process;
	
	
	--fourth stage latch (Fourth stage generates the final outputs)
	--third stage latch
	fourth_stage_latch: entity work.AXIS_LATCHED_CONNECTION
		Generic map (
			DATA_WIDTH => CONST_MQI_BITS,
			USER_WIDTH => 1 + flush_bit_t'length + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_data => ts_mqi,
			input_ready => ts_ready,
			input_valid => ts_valid,
			input_user(1 + flush_bit_t'length + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1) => ts_ihe,
			input_user(flush_bit_t'length + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto coordinate_bounds_array_t'length + CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_flush_bit,
			input_user(coordinate_bounds_array_t'length + CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_coord, 
			input_user(CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_k,
			input_user(CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_input_symbol,
			input_user(CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_code_quant,
			input_user(1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_is_tree,
			input_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_LENGTH_BITS)  => ts_cw_bits,
			input_user(CONST_CODEWORD_LENGTH_BITS - 1 downto 0)  => ts_cw_length,
			input_last  => ts_last,
			output_data	=> axis_out_mqi,
			output_ready=> axis_out_ready,
			output_valid=> axis_out_valid,
			output_user(1 + flush_bit_t'length + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1)  => axis_out_ihe,
			output_user(flush_bit_t'length + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto coordinate_bounds_array_t'length + CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_flush_bit,
			output_user(coordinate_bounds_array_t'length + CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_coord,
			output_user(CONST_MAX_K_BITS + CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_k,
			output_user(CONST_INPUT_SYMBOL_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_input_symbol,
			output_user(CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_code_quant,
			output_user(1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_is_tree,
			output_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_LENGTH_BITS)  => axis_out_cw_bits,
			output_user(CONST_CODEWORD_LENGTH_BITS - 1 downto 0)  => axis_out_cw_length,
			output_last => axis_out_last
		);
		

	--pragma synthesis_off
	TEST_CHECK_CTID: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => ts_code_table_addr'length,
			SKIP => 0,
			FILE_NUMBER => 112
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_code_table_addr
		);

	TEST_CHECK_NTID: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => ts_at_next_addr'length,
			SKIP => 0,
			FILE_NUMBER => 102
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_at_next_addr
		);

	TEST_CHECK_ISTREE: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => 1,
			SKIP => 0,
			FILE_NUMBER => 103
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_is_tree
		);

	TEST_CHECK_FLUSHBIT: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => ts_flush_bit'length,
			SKIP => 0,
			FILE_NUMBER => 104
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_flush_bit
		);

	TEST_CHECK_INPUT_SYMBOL: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => ts_input_symbol'length,
			SKIP => 0,
			FILE_NUMBER => 105
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_input_symbol
		);

	ts_ihe_stdlv(0) <= ts_ihe;
	TEST_CHECK_IS_HIGH_ENTROPY: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => 1,
			SKIP => 0,
			FILE_NUMBER => 106
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_ihe_stdlv
		);

	TEST_CHECK_CODE_QUANT: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => ts_code_quant'length,
			SKIP => 0,
			FILE_NUMBER => 107
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_code_quant
		);

	TEST_CHECK_CODE_INDEX: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => ts_code_index'length,
			SKIP => 0,
			FILE_NUMBER => 108
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_code_index
		);

	TEST_CHECK_K: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => ts_k'length,
			SKIP => 0,
			FILE_NUMBER => 109
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_k
		);

	TEST_CHECK_CWB: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => ts_cw_length'length,
			SKIP => 0,
			FILE_NUMBER => 110
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_cw_length
		);

	TEST_CHECK_CWV: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => ts_cw_bits'length,
			SKIP => 0,
			FILE_NUMBER => 111
		)
		port map (
			clk => clk, rst => rst, 
			valid => ts_valid,
			ready => ts_ready,
			data  => ts_cw_bits
		);
	--pragma synthesis_on

end Behavioral;
