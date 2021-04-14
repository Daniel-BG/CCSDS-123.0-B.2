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
		axis_out_input_symbol	: out std_logic_vector(3 downto 0);
		axis_out_code_quant		: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_is_tree		: out std_logic_vector(0 downto 0);
		axis_out_cw_bits 		: out std_logic_vector(CONST_CODEWORD_BITS - 1 downto 0);
		axis_out_cw_length		: out std_logic_vector(CONST_CODEWORD_LENGTH_BITS - 1 downto 0);
		axis_out_ihe			: out std_logic;
		axis_out_flush_bit		: out flush_bit_t
	);
end hybrid_encoder_table_update_stage;

architecture Behavioral of hybrid_encoder_table_update_stage is
	constant FIRST_STAGE_MULTIPLIER_NUMBER_OF_STAGES: integer := 2;
	constant CODE_INDEX_BITS: integer := 4;

	--first stage signals
	signal axis_in_ready_buf: std_logic;
	signal transaction_at_mult_input, transaction_at_mult_output: std_logic;
	signal fs_hra				: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
	signal fs_flush_bit			: flush_bit_t;
	signal fs_mqi				: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal fs_coord				: coordinate_bounds_array_t;
	signal fs_cnt				: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal fs_ready, fs_valid	: std_logic;
	signal fs_k					: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal fs_ihe				: std_logic;
	signal fs_code_index		: std_logic_vector(3 downto 0);

	type cnt_t_t_array is array(0 to 15) of std_logic_vector(CONST_MAX_COUNTER_BITS + threshold_value_t'length - 1 downto 0);
	signal fs_cnt_array: cnt_t_t_array;

	--second stage signals
	signal ss_valid, ss_ready	: std_logic;
	signal ss_k					: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal ss_ihe				: std_logic;
	signal ss_code_index		: std_logic_vector(3 downto 0);
	signal ss_mqi				: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal ss_coord				: coordinate_bounds_array_t;
	signal ss_flush_bit			: flush_bit_t;
	signal ss_code_table_addr	: std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
	signal ss_input_symbol		: std_logic_vector(3 downto 0);
	
	--third stage signals
	type ts_code_table_enties_t is array(0 to 13) of std_logic_vector(31 downto 0);
	signal ts_code_table_entries: ts_code_table_enties_t;
	signal ts_selected_table_entry: std_logic_vector(31 downto 0);
	signal ts_mqi				: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal ts_coord				: coordinate_bounds_array_t;
	signal ts_ready, ts_valid	: std_logic;
	signal ts_flush_bit			: flush_bit_t;
	signal ts_code_index		: std_logic_vector(3 downto 0);
	signal ts_input_symbol		: std_logic_vector(3 downto 0);
	signal ts_code_table_addr	: std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
	signal ts_code_table_data	: bin_table_t;
	signal ts_ihe				: std_logic;
	signal ts_cw_bits 			: std_logic_vector(CONST_CODEWORD_BITS - 1 downto 0);
	signal ts_cw_length 		: std_logic_vector(CONST_CODEWORD_LENGTH_BITS - 1 downto 0);
	signal ts_is_tree			: std_logic_vector(0 downto 0);
	signal ts_k					: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal ts_code_quant		: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	--third stage back to second
	signal ts_at_wren 			: std_logic;
	signal ts_at_next_addr		: std_logic_vector(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS - 1 downto 0);
			

			
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
			clk => clk, rst => rst,
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
	gen_multipliers: for i in 1 to 15 generate
		multiply_i: entity work.AXIS_MULTIPLIER
			Generic map (
				DATA_WIDTH_0 		=> CONST_MAX_COUNTER_BITS,
				DATA_WIDTH_1 		=> threshold_value_t'length,
				SIGNED_0	 		=> false,
				SIGNED_1			=> false,
				STAGES_AFTER_SYNC	=> FIRST_STAGE_MULTIPLIER_NUMBER_OF_STAGES
			)
			Port map (
				clk => clk, rst => rst,
				input_0_data	=> axis_in_cnt,
				input_0_valid	=> transaction_at_mult_input,
				input_0_ready	=> open,
				input_1_data	=> CONST_THRESHOLD_TABLE(i),
				input_1_valid	=> '1',
				input_1_ready	=> open,
				output_data		=> fs_cnt_array(i),
				output_valid	=> open,
				output_ready	=> transaction_at_mult_input
			);
	end generate;

	--parameter calculation for output of first stage
	k_calc: process(fs_cnt, fs_hra)
		variable new_k: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	begin
		new_k := (others => '0');
		for i in 1 to CONST_MAX_DATA_WIDTH - 2 loop
			if shift_left(resize(unsigned(fs_cnt), CONST_MAX_HR_ACC_BITS + 1), i) <= unsigned(fs_hra) then
				new_k := std_logic_vector(to_unsigned(i, new_k'length));
			end if;
		end loop;
		fs_k <= new_k;
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
		variable code_index: std_logic_vector(CODE_INDEX_BITS - 1 downto 0);
	begin
		code_index := (others => '0');
		ci_loop: for i in 0 to 2**CODE_INDEX_BITS-1 loop
			if (shift_left(resize(unsigned(fs_hra), CONST_MAX_HR_ACC_BITS + 14), 14) < resize(unsigned(fs_cnt_array(i)),  CONST_MAX_HR_ACC_BITS + 14)) then
				code_index := std_logic_vector(to_unsigned(i, CODE_INDEX_BITS));
			else
				exit ci_loop;
			end if;
		end loop;
		fs_code_index <= code_index;
	end process;

	
	--second stage: k, codeIndex and condition calculated
	ss_latch: entity work.AXIS_DATA_LATCH 
		Generic map (
			DATA_WIDTH => CONST_MQI_BITS,
			USER_WIDTH => flush_bit_t'length + CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CODE_INDEX_BITS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data	=> fs_mqi,
			input_ready => fs_ready,
			input_valid => fs_valid,
			input_user(flush_bit_t'length + CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CODE_INDEX_BITS - 1 downto CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CODE_INDEX_BITS) => fs_flush_bit,
			input_user(CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CODE_INDEX_BITS - 1 downto coordinate_bounds_array_t'length + CODE_INDEX_BITS) => fs_k,
			input_user(coordinate_bounds_array_t'length + CODE_INDEX_BITS - 1 downto CODE_INDEX_BITS) => fs_coord,
			input_user(CODE_INDEX_BITS - 1 downto 0) => fs_code_index,
			input_last  => fs_ihe,
			output_data	=> ss_mqi,
			output_ready=> ss_ready,
			output_valid=> ss_valid,
			output_user(flush_bit_t'length + CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CODE_INDEX_BITS - 1 downto CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CODE_INDEX_BITS) => ss_flush_bit,
			output_user(CONST_MAX_K_BITS + coordinate_bounds_array_t'length + CODE_INDEX_BITS - 1 downto coordinate_bounds_array_t'length + CODE_INDEX_BITS) => ss_k,
			output_user(coordinate_bounds_array_t'length + CODE_INDEX_BITS - 1 downto CODE_INDEX_BITS) => ss_coord,
			output_user(CODE_INDEX_BITS - 1 downto 0) => ss_code_index,
			output_last => ss_ihe
		);

	--things start to get FUNKEY in the intra SECOND_TO_THIRD stage modules
	active_address_table: entity work.hybrid_encoder_active_table_address_table
		Port map ( 
			clk => clk, rst => rst,
			read_index => ss_code_index,
			read_addr => ss_code_table_addr,
			write_enable => ts_at_wren,
			write_index => ts_code_index,
			write_addr => ts_at_next_addr
		);
	
	--calc input symbol , very important
	input_symbol_calc: process(ss_mqi, ss_code_index)
	begin
		if (unsigned(ss_mqi) <= unsigned(CONST_INPUT_SYMBOL_LIMIT(to_integer(unsigned(ss_code_index))))) then
			ss_input_symbol <= std_logic_vector(resize(unsigned(ss_mqi), 4));
		else
			ss_input_symbol <= CONST_INPUT_SYMBOL_X;
		end if;
	end process;

	
	
	--third stage latch
	ts_latch: entity work.AXIS_DATA_LATCH 
		Generic map (
			DATA_WIDTH => CONST_MQI_BITS,
			USER_WIDTH => CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data => ss_mqi,
			input_ready => ss_ready,
			input_valid => ss_valid,
			input_user(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4 - 1 downto coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4)  => ss_code_table_addr,
			input_user(coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4 - 1 downto CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4)  => ss_coord,
			input_user(CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4 - 1 downto flush_bit_t'length + 4 + 4)  => ss_k,
			input_user(flush_bit_t'length + 4 + 4 - 1 downto 4 + 4)  => ss_flush_bit,
			input_user(4 + 4 - 1 downto 4)  => ss_code_index,
			input_user(4 - 1 downto 0)  => ss_input_symbol,
			input_last  => ss_ihe,
			output_data	=> ts_mqi,
			output_ready=> ts_ready,
			output_valid=> ts_valid,
			output_user(CONST_LOW_ENTROPY_CODING_TABLE_ADDRESS_BITS + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4 - 1 downto coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4)  => ts_code_table_addr,
			output_user(coordinate_bounds_array_t'length + CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4 - 1 downto CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4)  => ts_coord,
			output_user(CONST_MAX_K_BITS + flush_bit_t'length + 4 + 4 - 1 downto flush_bit_t'length + 4 + 4)  => ts_k,
			output_user(flush_bit_t'length + 4 + 4 - 1 downto 4 + 4)  => ts_flush_bit,
			output_user(4 + 4 - 1 downto 4)  => ts_code_index,
			output_user(4 - 1 downto 0) => ts_input_symbol,
			output_last => ts_ihe
		);
		
	--code table ROM
	code_rom: entity work.code_table_rom
		Port map ( 
			addr => ts_code_table_addr,
			data => ts_code_table_data
		);
		
	assign_ts_table_entries: process(ts_code_table_data)
	begin
		for i in 0 to 13 loop
			ts_code_table_entries(i) <= ts_code_table_data(32*15 - (i+1)*32 - 1 downto 32*15 - (i+2)*32);
		end loop;
	end process;
		
	ts_selected_table_entry <= ts_code_table_entries(to_integer(unsigned(ts_input_symbol)));
	
	process_table_entry: process(ts_selected_table_entry, ts_code_index, ts_valid, ts_ready, ts_ihe)
	begin
		ts_at_wren <= ts_valid and ts_ready and (not ts_ihe); --only write when it is low entropy and the pipeline moves
		if (ts_selected_table_entry(ts_selected_table_entry'high) = '1') then
			--it is a terminal codeword, reset to previous
			ts_at_next_addr <= std_logic_vector(resize(unsigned(ts_code_index), ts_at_next_addr'length));
			ts_is_tree <= "0";
		else
			--it is still a tree
			ts_at_next_addr <= ts_selected_table_entry(ts_at_next_addr'high downto 0);
			ts_is_tree <= "1";
		end if;
		ts_cw_bits <= ts_selected_table_entry(CONST_CODEWORD_BITS - 1 downto 0);
		ts_cw_length <= ts_selected_table_entry(CONST_CODEWORD_LENGTH_BITS + CONST_CODEWORD_BITS - 1 downto CONST_CODEWORD_BITS);
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
			USER_WIDTH => flush_bit_t'length + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data => ts_mqi,
			input_ready => ts_ready,
			input_valid => ts_valid,
			input_user(flush_bit_t'length + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto coordinate_bounds_array_t'length + CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_flush_bit,
			input_user(coordinate_bounds_array_t'length + CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_coord, 
			input_user(CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_k,
			input_user(4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_input_symbol,
			input_user(CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_code_quant,
			input_user(1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ts_is_tree,
			input_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_LENGTH_BITS)  => ts_cw_bits,
			input_user(CONST_CODEWORD_LENGTH_BITS - 1 downto 0)  => ts_cw_length,
			input_last  => ts_ihe,
			output_data	=> axis_out_mqi,
			output_ready=> axis_out_ready,
			output_valid=> axis_out_valid,
			output_user(flush_bit_t'length + coordinate_bounds_array_t'length + CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto coordinate_bounds_array_t'length + CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_flush_bit,
			output_user(coordinate_bounds_array_t'length + CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_coord,
			output_user(CONST_MAX_K_BITS + 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_k,
			output_user(4 + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_input_symbol,
			output_user(CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_code_quant,
			output_user(1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_out_is_tree,
			output_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_LENGTH_BITS)  => axis_out_cw_bits,
			output_user(CONST_CODEWORD_LENGTH_BITS - 1 downto 0)  => axis_out_cw_length,
			output_last => axis_out_ihe
		);
		



end Behavioral;
