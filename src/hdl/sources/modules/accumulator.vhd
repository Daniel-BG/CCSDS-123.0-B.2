----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2021 14:20:40
-- Design Name: 
-- Module Name: accumulator - Behavioral
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
use work.am_data_types.all;

entity accumulator is
	Port ( 
		clk, rst				: in std_logic;
		cfg_final_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_iacc				: in std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
		axis_in_mqi				: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_coord			: in coordinate_bounds_array_t;
		axis_in_counter			: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		axis_in_ready			: out std_logic;
		axis_in_valid			: in std_logic;
		axis_out_valid			: out std_logic;
		axis_out_ready			: in std_logic;
		axis_out_mqi			: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_k				: out std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t
	);
end accumulator;

architecture Behavioral of accumulator is
	--condition for selection
	signal axis_in_cond: std_logic;
	
	--sacc queue
	signal axis_na_saq_d: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_na_saq_valid, axis_na_saq_ready: std_logic;
	signal axis_na_saq_latched_d: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_na_saq_latched_valid, axis_na_saq_latched_ready: std_logic;
	signal axis_saccq_d: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_saccq_valid, axis_saccq_ready: std_logic;
	
	--acc retrieval split
	signal axis_ar_ars_acc: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_ar_ars_valid, axis_ar_ars_ready: std_logic;
	signal axis_ar_ars_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_ar_ars_cnt: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_ar_ars_coord: coordinate_bounds_array_t;
	signal axis_ars_na_acc: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_ars_na_valid, axis_ars_na_ready: std_logic;
	signal axis_ars_na_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_ars_na_cnt: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_ars_na_coord: coordinate_bounds_array_t;
	signal axis_ars_t49_acc: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_ars_t49_valid, axis_ars_t49_ready: std_logic;
	signal axis_ars_t49_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_ars_t49_cnt: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_ars_t49_coord: coordinate_bounds_array_t;

	--after x49 multiplication
	signal axis_t49_cmpg_ct49: std_logic_vector(CONST_MAX_COUNTER_BITS + 6 - 1 downto 0);
	signal axis_t49_cmpg_valid, axis_t49_cmpg_ready: std_logic;
	signal axis_t49_cmpg_acc: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_t49_cmpg_cnt: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_t49_cmpg_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_t49_cmpg_ct49sb7: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_t49_cmpg_coord: coordinate_bounds_array_t;
	
	--k generation
	signal axis_cmpg_kgen_cmpv: std_logic_vector(CONST_MAX_ACC_BITS + 1 - 1 downto 0);
	signal axis_cmpg_kgen_valid, axis_cmpg_kgen_ready: std_logic;
	signal axis_cmpg_kgen_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_cmpg_kgen_cnt: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_cmpg_kgen_coord: coordinate_bounds_array_t;
	
	--inner signals
	signal inner_reset			: std_logic;
begin

	reset_replicator: entity work.reset_replicator
		port map (
			clk => clk, rst => rst,
			rst_out => inner_reset
		);
		
	saved_acc_data_latch: entity work.AXIS_DATA_LATCH 
		Generic map (
			DATA_WIDTH => axis_na_saq_d'length
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_data	=> axis_na_saq_d,
			input_ready => axis_na_saq_ready,
			input_valid => axis_na_saq_valid,
			output_data	=> axis_na_saq_latched_d,
			output_ready=> axis_na_saq_latched_ready,
			output_valid=> axis_na_saq_latched_valid
		);
		
	saved_acc_fifo: entity work.AXIS_FIFO
		Generic map (
			DATA_WIDTH => CONST_MAX_ACC_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk	=> clk, rst => inner_reset,
			input_valid		=> axis_na_saq_latched_valid,
			input_ready		=> axis_na_saq_latched_ready,
			input_data		=> axis_na_saq_latched_d,
			output_ready	=> axis_saccq_ready,
			output_data		=> axis_saccq_d,
			output_valid	=> axis_saccq_valid
		);

	update_axis_in_cond: process(axis_in_coord) begin
		if F_STDLV2CB(axis_in_coord).first_x = '1' and F_STDLV2CB(axis_in_coord).first_y = '1' then
			axis_in_cond <= '0';
		else
			axis_in_cond <= '1';
		end if;
	end process;
	acc_retrieval: entity work.axis_conditioned_selector
		generic map (
			DATA_WIDTH 	=> CONST_MAX_ACC_BITS,
			USER_WIDTH	=> coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS
		)
		port map ( 
			clk => clk, rst => inner_reset,
			axis_in_cond	   		=> axis_in_cond,
			axis_in_cond_valid 		=> axis_in_valid,
			axis_in_cond_ready 		=> axis_in_ready,
			axis_in_cond_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS) => axis_in_coord,
			axis_in_cond_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_in_mqi,
			axis_in_cond_user(CONST_MAX_COUNTER_BITS - 1 downto 0) => axis_in_counter,
			axis_in_data_0_d   		=> cfg_iacc,
			axis_in_data_0_valid	=> '1',
			axis_in_data_0_ready	=> open,
			axis_in_data_1_d		=> axis_saccq_d,
			axis_in_data_1_valid	=> axis_saccq_valid,
			axis_in_data_1_ready	=> axis_saccq_ready,
			axis_out_data_d			=> axis_ar_ars_acc,
			axis_out_data_valid		=> axis_ar_ars_valid,
			axis_out_data_ready		=> axis_ar_ars_ready,
			axis_out_data_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS) => axis_ar_ars_coord,
			axis_out_data_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_ar_ars_mqi,
			axis_out_data_user(CONST_MAX_COUNTER_BITS - 1 downto 0)	=> axis_ar_ars_cnt
		);
		
	acc_split: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH 	=> CONST_MAX_ACC_BITS,
			USER_WIDTH	=> coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_ar_ars_valid,
			input_data		=> axis_ar_ars_acc,
			input_ready		=> axis_ar_ars_ready,
			input_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS) => axis_ar_ars_coord,
			input_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_ar_ars_mqi,
			input_user(CONST_MAX_COUNTER_BITS - 1 downto 0)	=> axis_ar_ars_cnt,
			--to output axi ports
			output_0_valid		=> axis_ars_na_valid,
			output_0_data		=> axis_ars_na_acc,
			output_0_ready		=> axis_ars_na_ready,
			output_0_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS) => axis_ars_na_coord,
			output_0_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_ars_na_mqi,
			output_0_user(CONST_MAX_COUNTER_BITS - 1 downto 0)	=> axis_ars_na_cnt,
			output_1_valid		=> axis_ars_t49_valid,
			output_1_data		=> axis_ars_t49_acc,
			output_1_ready		=> axis_ars_t49_ready,
			output_1_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS) => axis_ars_t49_coord,
			output_1_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_ars_t49_mqi,
			output_1_user(CONST_MAX_COUNTER_BITS - 1 downto 0)	=> axis_ars_t49_cnt
		);
		
	update_acc: process(axis_ars_na_valid, axis_na_saq_ready,
			cfg_final_counter, axis_ars_na_cnt, axis_ars_na_acc, axis_ars_na_mqi)
	begin
		axis_na_saq_valid <= axis_ars_na_valid;
		axis_ars_na_ready <= axis_na_saq_ready;
		
		if unsigned(axis_ars_na_cnt) = unsigned(cfg_final_counter) then
			axis_na_saq_d <= std_logic_vector((unsigned(axis_ars_na_acc) + unsigned(axis_ars_na_mqi) + 1) / 2);
		else
			axis_na_saq_d <= std_logic_vector(unsigned(axis_ars_na_acc) + unsigned(axis_ars_na_mqi));
		end if;	
	end process;
		
	mult_by_49: entity work.AXIS_MULTIPLIER
		Generic map (
			DATA_WIDTH_0		=> CONST_MAX_COUNTER_BITS, 
			DATA_WIDTH_1		=> 6,
			SIGNED_0			=> false,
			SIGNED_1			=> false,
			USER_WIDTH			=> coordinate_bounds_array_t'length + CONST_MAX_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS, 
			USER_POLICY 		=> PASS_ZERO,
			STAGES_AFTER_SYNC	=> 2
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_0_data	=> axis_ars_t49_cnt,
			input_0_valid	=> axis_ars_t49_valid,
			input_0_ready	=> axis_ars_t49_ready,
			input_0_user(coordinate_bounds_array_t'length + CONST_MAX_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MAX_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => axis_ars_t49_coord,
			input_0_user(CONST_MAX_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => axis_ars_t49_acc,
			input_0_user(CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MQI_BITS) => axis_ars_t49_cnt,
			input_0_user(CONST_MQI_BITS - 1 downto 0) => axis_ars_t49_mqi,
			input_1_data	=> "110001",
			input_1_valid	=> '1',
			input_1_ready	=> open,
			output_data		=> axis_t49_cmpg_ct49,
			output_valid	=> axis_t49_cmpg_valid,
			output_ready	=> axis_t49_cmpg_ready,
			output_user(coordinate_bounds_array_t'length + CONST_MAX_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MAX_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => axis_t49_cmpg_coord,
			output_user(CONST_MAX_ACC_BITS + CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MAX_COUNTER_BITS + CONST_MQI_BITS) => axis_t49_cmpg_acc,
			output_user(CONST_MAX_COUNTER_BITS + CONST_MQI_BITS - 1 downto CONST_MQI_BITS) => axis_t49_cmpg_cnt,
			output_user(CONST_MQI_BITS - 1 downto 0) => axis_t49_cmpg_mqi
		);
	axis_t49_cmpg_ct49sb7 <= std_logic_vector(resize(shift_right(unsigned(axis_t49_cmpg_ct49), 7), CONST_MAX_COUNTER_BITS));
		
	create_comp: entity work.AXIS_ARITHMETIC_OP 
		Generic map (
			DATA_WIDTH_0 => CONST_MAX_ACC_BITS,
			DATA_WIDTH_1 => CONST_MAX_COUNTER_BITS,
			OUTPUT_DATA_WIDTH => CONST_MAX_ACC_BITS + 1,
			IS_ADD => true,
			SIGN_EXTEND_0	=> false,
			SIGN_EXTEND_1	=> false,
			SIGNED_OP		=> false,
			LATCH_INPUT_SYNC=> false,
			USER_WIDTH		=> coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS,
			USER_POLICY		=> PASS_ZERO
		)
		Port map (
			clk => clk, rst => inner_reset,
			input_0_data	=> axis_t49_cmpg_acc,
			input_0_valid	=> axis_t49_cmpg_valid,
			input_0_ready	=> axis_t49_cmpg_ready,
			input_0_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS)  => axis_t49_cmpg_coord,
			input_0_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS)  => axis_t49_cmpg_mqi,
			input_0_user(CONST_MAX_COUNTER_BITS - 1 downto 0)  => axis_t49_cmpg_cnt,
			input_1_data	=> axis_t49_cmpg_ct49sb7,
			input_1_valid	=> axis_t49_cmpg_valid,
			input_1_ready	=> open,
			output_data		=> axis_cmpg_kgen_cmpv,
			output_valid	=> axis_cmpg_kgen_valid,
			output_ready	=> axis_cmpg_kgen_ready,
			output_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS)  => axis_cmpg_kgen_coord,
			output_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS)  => axis_cmpg_kgen_mqi,
			output_user(CONST_MAX_COUNTER_BITS - 1 downto 0)  => axis_cmpg_kgen_cnt
		);

	--parameter calculation for output
	k_calc: process(axis_cmpg_kgen_cmpv, axis_cmpg_kgen_cnt, axis_cmpg_kgen_valid, axis_out_ready, axis_cmpg_kgen_mqi, axis_cmpg_kgen_coord)
		variable new_k: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	begin
		new_k := (others => '0');
		for i in 1 to CONST_MAX_DATA_WIDTH - 2 loop
			if shift_left(resize(unsigned(axis_cmpg_kgen_cnt), CONST_MAX_ACC_BITS + 1), i) <= unsigned(axis_cmpg_kgen_cmpv) then
				new_k := std_logic_vector(to_unsigned(i, new_k'length));
			end if;
		end loop;
		axis_out_k <= new_k;
		
		axis_out_valid <= axis_cmpg_kgen_valid;
		axis_cmpg_kgen_ready <= axis_out_ready;
		axis_out_mqi <= axis_cmpg_kgen_mqi;
		axis_out_coord <= axis_cmpg_kgen_coord;
	end process;
	


end Behavioral;
