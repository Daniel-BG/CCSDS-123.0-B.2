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
		axis_in_mqi				: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_coord			: in coordinate_bounds_array_t;
		axis_in_counter			: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		axis_in_ready			: out std_logic;
		axis_in_valid			: in std_logic;
		axis_in_iacc_d			: in std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
		axis_in_iacc_valid		: in std_logic;
		axis_in_iacc_ready		: out std_logic;
		axis_out_valid			: out std_logic;
		axis_out_ready			: in std_logic;
		axis_out_mqi			: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_k				: out std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t
	);
end accumulator;

architecture Behavioral of accumulator is
	--modified input stream
	signal axis_in_cond: std_logic;
	signal axis_in_cond_user: std_logic_vector(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto 0);
	
	--iacc queue
	signal axis_in_iaccq_d			: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_in_iaccq_valid		: std_logic;
	signal axis_in_iaccq_ready		: std_logic;
	
	--synced input stream
	signal axis_synced_acc: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_synced_valid, axis_synced_ready: std_logic;
	signal axis_synced_user: std_logic_vector(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto 0);
	--signal axis_synced_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	--signal axis_synced_coord: coordinate_bounds_array_t;
	--signal axis_synced_counter: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	
	--splitter
	signal axis_acc_lb_acc: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_acc_lb_valid, axis_acc_lb_ready: std_logic;
	signal axis_acc_lb_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_acc_lb_counter: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_acc_lb_newacc: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	
	signal axis_precalc_pm_acc: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_precalc_pm_valid, axis_precalc_pm_ready: std_logic;
	signal axis_precalc_pm_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_precalc_pm_counter: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_precalc_pm_coord: coordinate_bounds_array_t;
	signal axis_precalc_pm_k: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal axis_precalc_pm_user: std_logic_vector(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto 0);
	
	
	signal axis_precalc_acc: std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_precalc_valid, axis_precalc_ready: std_logic;
	signal axis_precalc_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_precalc_counter: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal axis_precalc_cnt_times_49: std_logic_vector(CONST_MAX_COUNTER_BITS + 6 - 1 downto 0);
	signal axis_precalc_coord: coordinate_bounds_array_t;
	signal axis_precalc_k: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal axis_precalc_user: std_logic_vector(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto 0);
	
	--fifo
	signal axis_sacc_d : std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
	signal axis_sacc_valid, axis_sacc_ready	: std_logic;

	
begin


	axis_in_cond <= '0' when STDLV2CB(axis_in_coord).first_x = '1' and STDLV2CB(axis_in_coord).first_y = '1' else '1';
	axis_in_cond_user <= axis_in_mqi & axis_in_coord & axis_in_counter;
	
	input_acc_queue: entity work.AXIS_FIFO
		Generic map (
			DATA_WIDTH => CONST_MAX_ACC_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk	=> clk, rst => rst,
			input_valid		=> axis_in_iacc_valid,
			input_ready		=> axis_in_iacc_ready,
			input_data		=> axis_in_iacc_d,
			--out axi port
			output_ready	=> axis_in_iaccq_ready,
			output_data		=> axis_in_iaccq_d,
			output_valid	=> axis_in_iaccq_valid
		);

	input_selector: entity work.axis_conditioned_selector
		generic map (
			DATA_WIDTH 	=> CONST_MAX_ACC_BITS,
			USER_WIDTH	=> CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS
		)
		port map ( 
			clk => clk, rst => rst,
			axis_in_cond	   		=> axis_in_cond,
			axis_in_cond_valid 		=> axis_in_valid,
			axis_in_cond_ready 		=> axis_in_ready,
			axis_in_cond_user  		=> axis_in_cond_user,
			axis_in_data_0_d   		=> axis_in_iaccq_d,
			axis_in_data_0_valid	=> axis_in_iaccq_valid,
			axis_in_data_0_ready	=> axis_in_iaccq_ready,
			axis_in_data_1_d		=> axis_sacc_d,
			axis_in_data_1_valid	=> axis_sacc_valid,
			axis_in_data_1_ready	=> axis_sacc_ready,
			axis_out_data_d			=> axis_synced_acc,
			axis_out_data_valid		=> axis_synced_valid,
			axis_out_data_ready		=> axis_synced_ready,
			axis_out_data_user		=> axis_synced_user
		);
		
	splitter: entity work.AXIS_SPLITTER_2
		Generic map (
			DATA_WIDTH 	=> CONST_MAX_ACC_BITS,
			USER_WIDTH	=> CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS
		)
		Port map (
			clk => clk, rst	=> rst,
			--to input axi port
			input_valid		=> axis_synced_valid,
			input_data		=> axis_synced_acc,
			input_ready		=> axis_synced_ready,
			input_user		=> axis_synced_user,
			--to output axi ports
			output_0_valid	=> axis_acc_lb_valid,
			output_0_data	=> axis_acc_lb_acc,
			output_0_ready	=> axis_acc_lb_ready,
			output_0_user(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS)	=> axis_acc_lb_mqi,
			output_0_user(coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => open,
			output_0_user(CONST_MAX_COUNTER_BITS - 1 downto 0)	=> axis_acc_lb_counter,
			output_1_valid	=> axis_precalc_pm_valid,
			output_1_data	=> axis_precalc_pm_acc,
			output_1_ready	=> axis_precalc_pm_ready,
			output_1_user 	=> axis_precalc_pm_user
			--output_1_user(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS) => axis_precalc_mqi,
			--output_1_user(coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS) => axis_precalc_coord,
			--output_1_user(CONST_MAX_COUNTER_BITS - 1 downto 0) => axis_precalc_counter
		);
		
		
	axis_precalc_pm_counter <= axis_precalc_pm_user(CONST_MAX_COUNTER_BITS - 1 downto 0);
	mult_by_49: entity work.AXIS_MULTIPLIER
		Generic map (
			DATA_WIDTH_0		=> axis_precalc_pm_counter'length,
			DATA_WIDTH_1		=> 6,
			SIGNED_0			=> false,
			SIGNED_1			=> false,
			USER_WIDTH			=> axis_precalc_pm_acc'length + axis_precalc_pm_user'length,
			USER_POLICY 		=> PASS_ZERO,
			STAGES_AFTER_SYNC	=> 3
		)
		Port map (
			clk => clk, rst => rst,
			input_0_data	=> axis_precalc_pm_counter,
			input_0_valid	=> axis_precalc_pm_valid,
			input_0_ready	=> axis_precalc_pm_ready,
			input_0_user(axis_precalc_pm_acc'length + axis_precalc_pm_user'length - 1 downto axis_precalc_pm_user'length) => axis_precalc_pm_acc,
			input_0_user(axis_precalc_pm_user'high downto 0)    => axis_precalc_pm_user,
			input_1_data	=> "110001",
			input_1_valid	=> '1',
			input_1_ready	=> open,
			output_data		=> axis_precalc_cnt_times_49,
			output_valid	=> axis_precalc_valid,
			output_ready	=> axis_precalc_ready,
			output_user(axis_precalc_pm_acc'length + axis_precalc_pm_user'length - 1 downto axis_precalc_pm_user'length) => axis_precalc_acc,
			output_user(axis_precalc_pm_user'high downto 0)    => axis_precalc_user
		);
	axis_precalc_mqi <= axis_precalc_user(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS);
	axis_precalc_coord <= axis_precalc_user(coordinate_bounds_array_t'length + CONST_MAX_COUNTER_BITS - 1 downto CONST_MAX_COUNTER_BITS);
	axis_precalc_counter <= axis_precalc_user(CONST_MAX_COUNTER_BITS - 1 downto 0);
	
	--parameter calculation for output
	k_calc: process(axis_precalc_counter, axis_precalc_acc, axis_precalc_cnt_times_49)
		variable new_k: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	begin
		new_k := (others => '0');
		for i in 1 to CONST_MAX_DATA_WIDTH - 2 loop
			if (resize(unsigned(axis_precalc_counter), axis_precalc_acc'length)*(2**i) <= unsigned(axis_precalc_acc) + resize(unsigned(axis_precalc_cnt_times_49), axis_precalc_acc'length)/(2**7)) then
				new_k := std_logic_vector(to_unsigned(i, new_k'length));
			end if;
		end loop;
		axis_precalc_k <= new_k;
	end process;
	
	axis_out_valid <= axis_precalc_valid;
	axis_precalc_ready <= axis_out_ready;
	axis_out_k <= axis_precalc_k;
	axis_out_mqi <= axis_precalc_mqi;
	axis_out_coord <= axis_precalc_coord;
	
	--next accumulator calculation
	calc_newacc: process(axis_acc_lb_counter, cfg_final_counter,
			axis_acc_lb_acc, axis_acc_lb_mqi)
	begin
		if unsigned(axis_acc_lb_counter) < unsigned(cfg_final_counter) then
			axis_acc_lb_newacc <= std_logic_vector(unsigned(axis_acc_lb_acc) + unsigned(axis_acc_lb_mqi));
		else
			axis_acc_lb_newacc <= std_logic_vector((unsigned(axis_acc_lb_acc) + unsigned(axis_acc_lb_mqi) + 1) / 2);
		end if;
		
	end process;
	
	acc_fifo: entity work.AXIS_FIFO
		Generic map (
			DATA_WIDTH => CONST_MAX_ACC_BITS,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk	=> clk, rst => rst,
			input_valid		=> axis_acc_lb_valid,
			input_ready		=> axis_acc_lb_ready,
			input_data		=> axis_acc_lb_newacc,
			--out axi port
			output_ready	=> axis_sacc_ready,
			output_data		=> axis_sacc_d,
			output_valid	=> axis_sacc_valid
		);

end Behavioral;
