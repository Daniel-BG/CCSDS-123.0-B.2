----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.04.2021 08:53:57
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
use ieee.numeric_std.all;
use work.ccsds_constants.all;
use work.ccsds_data_structures.all;
use work.am_data_types.all;

entity hybrid_encoder_acc_update_stage is
	Port ( 
		clk, rst				: in std_logic;
		cfg_initial_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_final_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_ihra				: in std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
		axis_in_mqi_d			: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_mqi_ready		: out std_logic;
		axis_in_mqi_valid		: in std_logic;
		axis_in_mqi_coord		: in coordinate_bounds_array_t;
		--synchronized counter + accumulator output
		axis_out_valid			: out std_logic;
		axis_out_ready			: in std_logic;
		axis_out_hra			: out std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
		axis_out_flush_bit		: out flush_bit_t;
		axis_out_mqi			: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t;
		axis_out_cnt			: out std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		--output for flushing
		axis_out_flush_hra_valid: out std_logic;
		axis_out_flush_hra_ready: in std_logic;
		axis_out_flush_hra_d 	: out std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0)
	);
end hybrid_encoder_acc_update_stage;

architecture Behavioral of hybrid_encoder_acc_update_stage is
	--from first counter to hracc retrieval
	signal axis_cnt_hraret_mqi			: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_cnt_hraret_ready		: std_logic;
	signal axis_cnt_hraret_valid		: std_logic;
	signal axis_cnt_hraret_coord		: coordinate_bounds_array_t;
	signal axis_cnt_hraret_counter		: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	
	--shra queue
	signal axis_shraq_d: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
	signal axis_shraq_valid, axis_shraq_ready: std_logic;
	
	--condition for selection
	signal axis_in_cond: std_logic;
	--to first bit out flag generation pre_latch
	signal axis_ar_fbo_pl_hra: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
	signal axis_ar_fbo_pl_valid, axis_ar_fbo_pl_ready: std_logic;
	signal axis_ar_fbo_pl_coord: coordinate_bounds_array_t;
	signal axis_ar_fbo_pl_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_ar_fbo_pl_cnt: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	--to first bit out flag generation
	signal axis_ar_fbo_hra: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
	signal axis_ar_fbo_valid, axis_ar_fbo_ready: std_logic;
	signal axis_ar_fbo_coord: coordinate_bounds_array_t;
	signal axis_ar_fbo_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_ar_fbo_cnt: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	
	--to hraumulator update
	signal axis_fbo_hrau_hra: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
	signal axis_fbo_hrau_valid, axis_fbo_hrau_ready: std_logic;
	signal axis_fbo_hrau_coord: coordinate_bounds_array_t;
	signal axis_fbo_hrau_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_fbo_hrau_hra_flush_bit: flush_bit_t; -- 1 is flag, 0 is bit
	
	--hra splitter
	signal axis_hrau_hraq_valid, axis_hrau_hraq_ready: std_logic;
	signal axis_hrau_hraq_hra: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
	signal axis_hrau_caccs_valid, axis_hrau_caccs_ready: std_logic;
	signal axis_hrau_caccs_hra: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0); 
	signal axis_hrau_caccs_flush_bit: flush_bit_t;
	signal axis_hrau_caccs_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_hrau_caccs_coord: coordinate_bounds_array_t;
	
	--t+1 counter
	signal cfg_initial_counter_p_1	: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);

	--flush HRA
	signal flush_hra_enable: std_logic;

	--for testing purposes
	signal axis_out_cnt_pre	: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_out_valid_pre : std_logic;


	signal inner_reset: std_logic;
begin
	
	reset_replicator: entity work.reset_replicator
		port map (
			clk => clk, rst => rst,
			rst_out => inner_reset
		);

	counter_t: entity work.counter
		Port map (
			clk => clk, rst => inner_reset,
			cfg_initial_counter		=> cfg_initial_counter,
			cfg_final_counter		=> cfg_final_counter,
			axis_in_mqi_d			=> axis_in_mqi_d,
			axis_in_mqi_ready		=> axis_in_mqi_ready,
			axis_in_mqi_valid		=> axis_in_mqi_valid,
			axis_in_mqi_coord		=> axis_in_mqi_coord,
			axis_out_mqi			=> axis_cnt_hraret_mqi,
			axis_out_coord			=> axis_cnt_hraret_coord,
			axis_out_counter		=> axis_cnt_hraret_counter,
			axis_out_ready			=> axis_cnt_hraret_ready,
			axis_out_valid			=> axis_cnt_hraret_valid
		);
		
	saved_hra_fifo: entity work.AXIS_FIFO
		Generic map (
			DATA_WIDTH => CONST_MAX_HR_ACC_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk	=> clk, rst => inner_reset,
			input_valid		=> axis_hrau_hraq_valid,
			input_ready		=> axis_hrau_hraq_ready,
			input_data		=> axis_hrau_hraq_hra,
			output_ready	=> axis_shraq_ready,
			output_data		=> axis_shraq_d,
			output_valid	=> axis_shraq_valid
		);
		
	update_axis_in_cond: process(clk) begin
		if rising_edge(clk) then
			if inner_reset = '1' then
				axis_in_cond <= '0';
			else
				if F_STDLV2CB(axis_cnt_hraret_coord).last_z = '1' then --end of a pixel
					if axis_cnt_hraret_valid = '1' and axis_cnt_hraret_ready = '1' then --when the transaction is made, check other coords
						if F_STDLV2CB(axis_cnt_hraret_coord).last_x = '1' and F_STDLV2CB(axis_cnt_hraret_coord).last_y = '1' then
							axis_in_cond <= '0'; --if we are on the last pixel of all, reset to zero
						else
							axis_in_cond <= '1'; --if we are on any other pixel, reset to 1 to pipe hret
						end if;
					end if ;
				end if;
			end if;
		end if;
	end process;
	hra_retrieval: entity work.axis_conditioned_selector
		generic map (
			DATA_WIDTH 	=> CONST_MAX_HR_ACC_BITS,
			USER_WIDTH	=> coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS
		)
		port map ( 
			clk => clk, rst => inner_reset,
			axis_in_cond	   		=> axis_in_cond,
			axis_in_cond_valid 		=> axis_cnt_hraret_valid,
			axis_in_cond_ready 		=> axis_cnt_hraret_ready,
			axis_in_cond_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS) => axis_cnt_hraret_coord,
			axis_in_cond_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_cnt_hraret_mqi,
			axis_in_cond_user(CONST_MAX_COUNTER_BITS - 1 downto 0) => axis_cnt_hraret_counter,
			axis_in_data_0_d   		=> cfg_ihra,
			axis_in_data_0_valid	=> '1',
			axis_in_data_0_ready	=> open,
			axis_in_data_1_d		=> axis_shraq_d,
			axis_in_data_1_valid	=> axis_shraq_valid,
			axis_in_data_1_ready	=> axis_shraq_ready,
			axis_out_data_d			=> axis_ar_fbo_pl_hra,
			axis_out_data_valid		=> axis_ar_fbo_pl_valid,
			axis_out_data_ready		=> axis_ar_fbo_pl_ready,
			axis_out_data_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS) => axis_ar_fbo_pl_coord,
			axis_out_data_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_ar_fbo_pl_mqi,
			axis_out_data_user(CONST_MAX_COUNTER_BITS - 1 downto 0)	=> axis_ar_fbo_pl_cnt
		);
		
	ar_latch: entity work.AXIS_DATA_LATCH
		Generic map (
			DATA_WIDTH => CONST_MAX_HR_ACC_BITS,
			USER_WIDTH => coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS
		)
		Port map ( 
			clk => clk, rst => inner_reset,
			input_data	=> axis_ar_fbo_pl_hra,
			input_ready => axis_ar_fbo_pl_ready,
			input_valid => axis_ar_fbo_pl_valid,
			input_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS) => axis_ar_fbo_pl_coord,
			input_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_ar_fbo_pl_mqi,
			input_user(CONST_MAX_COUNTER_BITS - 1 downto 0)	=> axis_ar_fbo_pl_cnt,
			output_data	=> axis_ar_fbo_hra,
			output_ready => axis_ar_fbo_ready,
			output_valid => axis_ar_fbo_valid,
			output_user(coordinate_bounds_array_t'length + CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MQI_BITS + CONST_MAX_COUNTER_BITS) => axis_ar_fbo_coord,
			output_user(CONST_MQI_BITS + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_ar_fbo_mqi,
			output_user(CONST_MAX_COUNTER_BITS - 1 downto 0)	=> axis_ar_fbo_cnt
		);
		
	create_flag_and_update_hra: process(axis_ar_fbo_valid, axis_fbo_hrau_ready, axis_ar_fbo_hra, axis_ar_fbo_cnt, cfg_final_counter, axis_ar_fbo_mqi, axis_ar_fbo_coord)
	begin
		axis_ar_fbo_ready <= axis_fbo_hrau_ready;
		axis_fbo_hrau_valid <= axis_ar_fbo_valid;
		axis_fbo_hrau_hra_flush_bit(0) <= axis_ar_fbo_hra(0);
		if (axis_ar_fbo_cnt = cfg_final_counter) then
			axis_fbo_hrau_hra_flush_bit(1) <= '1';
			axis_fbo_hrau_hra <= std_logic_vector(shift_right(unsigned(axis_ar_fbo_hra) + unsigned(unsigned(axis_ar_fbo_mqi) & "00") + 1, 1)); 
		else
			axis_fbo_hrau_hra_flush_bit(1) <= '0';
			axis_fbo_hrau_hra <= std_logic_vector(unsigned(axis_ar_fbo_hra) + unsigned(unsigned(axis_ar_fbo_mqi) & "00"));
		end if;
		
		axis_fbo_hrau_mqi <= axis_ar_fbo_mqi;
		axis_fbo_hrau_coord <= axis_ar_fbo_coord;
	end process;
	
	hrau_splitter: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH => CONST_MAX_HR_ACC_BITS,
			USER_WIDTH => flush_bit_t'length + CONST_MQI_BITS + coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> inner_reset,
			--to input axi port
			input_valid		=> axis_fbo_hrau_valid,
			input_data		=> axis_fbo_hrau_hra,
			input_ready		=> axis_fbo_hrau_ready,
			input_user(flush_bit_t'length + CONST_MQI_BITS + coordinate_bounds_array_t'length - 1 downto CONST_MQI_BITS + coordinate_bounds_array_t'length) => axis_fbo_hrau_hra_flush_bit,
			input_user(CONST_MQI_BITS + coordinate_bounds_array_t'length - 1 downto coordinate_bounds_array_t'length) => axis_fbo_hrau_mqi,
			input_user(coordinate_bounds_array_t'length - 1 downto 0) => axis_fbo_hrau_coord,
			--to output axi ports
			output_0_valid	=> axis_hrau_hraq_valid,
			output_0_data	=> axis_hrau_hraq_hra,
			output_0_ready	=> axis_hrau_hraq_ready,
			output_1_valid	=> axis_hrau_caccs_valid,
			output_1_data	=> axis_hrau_caccs_hra,
			output_1_ready	=> axis_hrau_caccs_ready,
			output_1_user(flush_bit_t'length + CONST_MQI_BITS + coordinate_bounds_array_t'length - 1 downto CONST_MQI_BITS + coordinate_bounds_array_t'length) => axis_hrau_caccs_flush_bit,
			output_1_user(CONST_MQI_BITS + coordinate_bounds_array_t'length - 1 downto coordinate_bounds_array_t'length)	=> axis_hrau_caccs_mqi,
			output_1_user(coordinate_bounds_array_t'length - 1 downto 0)	=> axis_hrau_caccs_coord
		);

	--counter plus one calculation and multiplier and those things
	cfg_initial_counter_p_1 <= std_logic_vector(unsigned(cfg_initial_counter) +  1);
	counter_t_p_1: entity work.counter
		generic map (
			USER_WIDTH => flush_bit_t'length + CONST_MAX_HR_ACC_BITS
		)
		Port map (
			clk => clk, rst => inner_reset,
			cfg_initial_counter		=> cfg_initial_counter_p_1,
			cfg_final_counter		=> cfg_final_counter,
			axis_in_mqi_d			=> axis_hrau_caccs_mqi,
			axis_in_mqi_ready		=> axis_hrau_caccs_ready,
			axis_in_mqi_valid		=> axis_hrau_caccs_valid,
			axis_in_mqi_coord		=> axis_hrau_caccs_coord,
			axis_in_mqi_user(flush_bit_t'length + CONST_MAX_HR_ACC_BITS - 1 downto CONST_MAX_HR_ACC_BITS) => axis_hrau_caccs_flush_bit,
			axis_in_mqi_user(CONST_MAX_HR_ACC_BITS - 1 downto 0) => axis_hrau_caccs_hra,
			axis_out_mqi			=> axis_out_mqi,
			axis_out_coord			=> axis_out_coord,
			axis_out_counter		=> axis_out_cnt_pre,
			axis_out_ready			=> axis_out_ready,
			axis_out_valid			=> axis_out_valid_pre,
			axis_out_user(flush_bit_t'length + CONST_MAX_HR_ACC_BITS - 1 downto CONST_MAX_HR_ACC_BITS) => axis_out_flush_bit,
			axis_out_user(CONST_MAX_HR_ACC_BITS - 1 downto 0) => axis_out_hra
		);
	axis_out_cnt <= axis_out_cnt_pre;
	axis_out_valid <= axis_out_valid_pre;

	flush_hra_enable <= axis_hrau_caccs_valid and axis_hrau_caccs_ready and F_STDLV2CB(axis_hrau_caccs_coord).last_x and F_STDLV2CB(axis_hrau_caccs_coord).last_y;
	flush_hra_fifo: entity work.AXIS_FIFO
		Generic map (
			DATA_WIDTH => CONST_MAX_HR_ACC_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk	=> clk, rst => inner_reset,
			input_valid		=> flush_hra_enable,
			input_ready		=> open,
			input_data		=> axis_hrau_caccs_hra,
			output_ready	=> axis_out_flush_hra_ready,
			output_data		=> axis_out_flush_hra_d,
			output_valid	=> axis_out_flush_hra_valid
		);

	--pragma synthesis_off
gen_test: if (TEST_GEN_ENABLE) generate
	TEST_ACCUMULATOR: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_HR_ACC_BITS,
			SKIP => 0,
			FILE_NUMBER => 100
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_fbo_hrau_valid,
			ready => axis_fbo_hrau_ready,
			data  => axis_fbo_hrau_hra
		);

	TEST_COUNTER: entity work.checker_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_COUNTER_BITS,
			SKIP => 0,
			FILE_NUMBER => 101
		)
		port map (
			clk => clk, rst => inner_reset, 
			valid => axis_out_valid_pre,
			ready => axis_out_ready,
			data  => axis_out_cnt_pre
		);		
end generate gen_test;
	--pragma synthesis_on
	
end Behavioral;
