----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2021 17:45:26
-- Design Name: 
-- Module Name: encoder - Behavioral
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

entity encoder is
	Port ( 
		clk, rst				: in std_logic;
		cfg_initial_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_final_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_u_max				: in std_logic_vector(CONST_U_MAX_BITS - 1 downto 0);
		cfg_depth				: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		cfg_iacc				: in std_logic_vector(CONST_MAX_ACC_BITS - 1 downto 0);
		axis_in_mqi_d			: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_mqi_ready		: out std_logic;
		axis_in_mqi_valid		: in std_logic;
		axis_in_mqi_coord		: in coordinate_bounds_array_t;
		axis_out_code			: out std_logic_vector(CONST_OUTPUT_CODE_LENGTH - 1 downto 0);
		axis_out_length			: out std_logic_vector(CONST_OUTPUT_CODE_LENGTH_BITS - 1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t;
		axis_out_valid			: out std_logic;
		axis_out_ready			: in std_logic;
		axis_out_last			: out std_logic
	);
end encoder;

architecture Behavioral of encoder is
	signal axis_cnt_acc_mqi		: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_cnt_acc_ready	: std_logic;
	signal axis_cnt_acc_valid	: std_logic;
	signal axis_cnt_acc_coord	: coordinate_bounds_array_t;
	signal axis_cnt_acc_counter	: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	
	signal axis_acc_cg_valid, axis_acc_cg_ready: std_logic;
	signal axis_acc_cg_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_acc_cg_k: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal axis_acc_cg_coord: coordinate_bounds_array_t;
	
	signal axis_acc_cg_l_valid, axis_acc_cg_l_ready: std_logic;
	signal axis_acc_cg_l_mqi: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_acc_cg_l_k: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal axis_acc_cg_l_coord: coordinate_bounds_array_t;
	
	signal axis_out_code_raw: std_logic_vector(CONST_MAX_CODE_LENGTH - 1 downto 0);
	signal axis_out_length_raw: std_logic_vector(CONST_MAX_CODE_LENGTH_BITS - 1 downto 0);
	signal axis_out_coord_raw: coordinate_bounds_array_t;
	
begin

	counter: entity work.counter
		Port map (
			clk => clk, rst => rst,
			cfg_initial_counter		=> cfg_initial_counter,
			cfg_final_counter		=> cfg_final_counter,
			axis_in_mqi_d			=> axis_in_mqi_d,
			axis_in_mqi_ready		=> axis_in_mqi_ready,
			axis_in_mqi_valid		=> axis_in_mqi_valid,
			axis_in_mqi_coord		=> axis_in_mqi_coord,
			axis_out_mqi			=> axis_cnt_acc_mqi,
			axis_out_coord			=> axis_cnt_acc_coord,
			axis_out_counter		=> axis_cnt_acc_counter,
			axis_out_ready			=> axis_cnt_acc_ready,
			axis_out_valid			=> axis_cnt_acc_valid
		);

	accumulator: entity work.accumulator
		Port map ( 
			clk => clk, rst => rst,
			cfg_final_counter		=> cfg_final_counter,
			cfg_iacc				=> cfg_iacc, 
			axis_in_mqi				=> axis_cnt_acc_mqi,
			axis_in_coord			=> axis_cnt_acc_coord,
			axis_in_counter			=> axis_cnt_acc_counter,
			axis_in_ready			=> axis_cnt_acc_ready,
			axis_in_valid			=> axis_cnt_acc_valid,
			axis_out_valid			=> axis_acc_cg_valid,
			axis_out_ready			=> axis_acc_cg_ready,
			axis_out_mqi			=> axis_acc_cg_mqi,
			axis_out_k				=> axis_acc_cg_k,
			axis_out_coord			=> axis_acc_cg_coord
		);
		
	acc2cglatch: entity work.AXIS_DATA_LATCH
		Generic map (
			DATA_WIDTH => CONST_MQI_BITS,
			USER_WIDTH => CONST_MAX_K_BITS + coordinate_bounds_array_t'length 
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data	=> axis_acc_cg_mqi,
			input_ready => axis_acc_cg_ready,
			input_valid => axis_acc_cg_valid,
			input_user(CONST_MAX_K_BITS + coordinate_bounds_array_t'length - 1 downto coordinate_bounds_array_t'length)	=> axis_acc_cg_k,
			input_user(coordinate_bounds_array_t'length - 1 downto 0) => axis_acc_cg_coord,
			output_data	=> axis_acc_cg_l_mqi,
			output_ready=> axis_acc_cg_l_valid,
			output_valid=> axis_acc_cg_l_valid,
			output_user(CONST_MAX_K_BITS + coordinate_bounds_array_t'length - 1 downto coordinate_bounds_array_t'length) => axis_acc_cg_l_k,
			output_user(coordinate_bounds_array_t'length - 1 downto 0) => axis_acc_cg_l_coord
		);
			
	code_gen: entity work.code_gen
		Port map ( 
			cfg_u_max				=> cfg_u_max,
			cfg_depth 				=> cfg_depth,
			axis_in_valid			=> axis_acc_cg_l_valid,
			axis_in_ready			=> axis_acc_cg_l_ready,
			axis_in_mqi				=> axis_acc_cg_l_mqi,
			axis_in_k				=> axis_acc_cg_l_k,
			axis_in_coord			=> axis_acc_cg_l_coord,
			axis_out_code			=> axis_out_code_raw,
			axis_out_length			=> axis_out_length_raw,
			axis_out_coord			=> axis_out_coord_raw,
			axis_out_valid			=> axis_out_valid,
			axis_out_ready			=> axis_out_ready
		);
		
	axis_out_code 	<= std_logic_vector(resize(unsigned(axis_out_code_raw), axis_out_code'length));
	axis_out_length <= std_logic_vector(resize(unsigned(axis_out_length_raw), axis_out_length'length));
	axis_out_coord  <= axis_out_coord_raw;
	update_axis_out_last: process(axis_out_coord_raw) begin
		if 		F_STDLV2CB(axis_out_coord_raw).last_x = '1' 
				and F_STDLV2CB(axis_out_coord_raw).last_y = '1'
				and F_STDLV2CB(axis_out_coord_raw).last_z = '1' then
			axis_out_last <= '1';
		else
			axis_out_last <= '0';
		end if;  
	end process;

end Behavioral;
