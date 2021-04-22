----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2021 07:48:51
-- Design Name: 
-- Module Name: wu_calc - Behavioral
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

--weights are not updated for t=0. Nonetheless, we perform the calculations since the queues will be full. We then throw away the result
entity wu_calc is
	Port ( 
		clk, rst			: in std_logic;
		cfg_weo				: in std_logic_vector(CONST_WEO_BITS - 1 downto 0);
		cfg_omega			: in std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
		axis_dv_d			: in std_logic_vector(CONST_DIFFVEC_BITS - 1 downto 0);
		axis_dv_ready		: out std_logic;
		axis_dv_valid 		: in std_logic;
		axis_dv_coord 		: in coordinate_bounds_array_t;
		axis_wv_d			: in std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
		axis_wv_ready		: out std_logic;
		axis_wv_valid 		: in std_logic;
		axis_wuse_d			: in std_logic_vector(CONST_WUSE_BITS - 1 downto 0);
		axis_wuse_ready		: out std_logic;
		axis_wuse_valid 	: in std_logic;
		axis_drpe_d			: in std_logic_vector(CONST_DRPE_BITS - 1 downto 0);
		axis_drpe_ready		: out std_logic;
		axis_drpe_valid 	: in std_logic;
		axis_out_wv_ready	: in std_logic;
		axis_out_wv_valid 	: out std_logic;
		axis_out_wv_d		: out std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
		axis_out_wv_coord	: out coordinate_bounds_array_t
	);
end wu_calc;

architecture Behavioral of wu_calc is
	--first stage, join drpe and dv for multiplication
	signal axis_dv_d_filtered: std_logic_vector(CONST_DIFFVEC_BITS - 1 downto 0);
	signal joint_drpe_dv_valid, joint_drpe_dv_ready: std_logic;
	signal joint_drpe_dv_drpe: std_logic_vector(CONST_DRPE_BITS - 1 downto 0);
	signal joint_drpe_dv_dv: std_logic_vector(CONST_DIFFVEC_BITS - 1 downto 0);
	type mult_out_data_t is array(0 to CONST_MAX_C - 1) of std_logic_vector(CONST_LDIF_BITS - 1 downto 0);
	signal joint_drpe_dv_data: mult_out_data_t;
	signal joint_drpe_dv_coord: coordinate_bounds_array_t;
	
	--second stage, shift by exponent
	subtype stage_ctrl_signals_t is std_logic_vector(CONST_MAX_C - 1 downto 0);
	signal mult_exp_syncers_ready, axis_wuse_ready_vec: stage_ctrl_signals_t;
	signal exponent: std_logic_vector(CONST_WUSE_BITS - 1 downto 0);
	signal joint_pre_add_valid, joint_pre_add_ready: stage_ctrl_signals_t;
	type wuse_array_t is array(0 to CONST_MAX_C - 1) of std_logic_vector(CONST_WUSE_BITS - 1 downto 0);
	signal joint_pre_add_exp, joint_pre_add_minus: wuse_array_t;
	signal joint_pre_add_mult: mult_out_data_t;
	type coord_arr_t is array(0 to CONST_MAX_C - 1) of coordinate_bounds_array_t;
	signal joint_pre_add_coord: coord_arr_t;
	signal joint_pre_add_mult_use_left: stage_ctrl_signals_t;
	type addreg_t is array(0 to CONST_MAX_C - 1) of std_logic_vector(CONST_W_UPDATE_BITS - 1 downto 0);
	signal joint_pre_add_mult_shifted_left, joint_pre_add_mult_shifted_right: addreg_t;
	
	--substage here
	signal joint_add_valid, joint_add_ready: stage_ctrl_signals_t;
	signal joint_add_mult_shifted_left, joint_add_mult_shifted_right: addreg_t;
	signal joint_add_mult_use_left: stage_ctrl_signals_t;
	signal joint_add_coord: coord_arr_t;
	
	
	signal weight_addval, weight_addval_halved: addreg_t;
	
	--last stage, update weight by adding the previous result, and clamping
	signal axis_wv_ready_vec: stage_ctrl_signals_t;
	signal joint_unclamped_valid, joint_unclamped_ready: stage_ctrl_signals_t;
	type weight_arr_t is array(0 to CONST_MAX_C - 1) of std_logic_vector(CONST_MAX_WEIGHT_BITS - 1 downto 0);
	signal joint_unclamped_weight: weight_arr_t;
	signal joint_unclamped_addval, joint_unclamped_finalres: addreg_t;
	signal joint_unclamped_coord: coord_arr_t;
	signal omega_min, omega_max: std_logic_vector(CONST_MAX_WEIGHT_BITS - 1 downto 0);
	
begin
	update_axis_dv_d_filtered: process(axis_dv_coord, axis_dv_d) begin
		if F_STDLV2CB(axis_dv_coord).first_x = '1' and F_STDLV2CB(axis_dv_coord).first_y = '1' then
			axis_dv_d_filtered <= (others => '0');
		else
			axis_dv_d_filtered <= axis_dv_d;
		end if;
	end process;
	sync_drpe_diff: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_DRPE_BITS,
			DATA_WIDTH_1 => CONST_DIFFVEC_BITS,
			LATCH		 => true,
			USER_WIDTH   => coordinate_bounds_array_t'length,
			USER_POLICY  => PASS_ONE
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_drpe_valid,
			input_0_ready => axis_drpe_ready,
			input_0_data  => axis_drpe_d,
			input_1_valid => axis_dv_valid,
			input_1_ready => axis_dv_ready,
			input_1_data  => axis_dv_d_filtered,
			input_1_user  => axis_dv_coord,
			--to output axi ports
			output_valid  => joint_drpe_dv_valid,
			output_ready  => joint_drpe_dv_ready, 
			output_data_0 => joint_drpe_dv_drpe,
			output_data_1 => joint_drpe_dv_dv,
			output_user   => joint_drpe_dv_coord
		);
		
	gen_drpe_diff_multipliers: for i in 0 to CONST_MAX_C - 1 generate
		joint_drpe_dv_data(i) <= joint_drpe_dv_dv(CONST_LDIF_BITS*(i+1) - 1 downto CONST_LDIF_BITS*i) when joint_drpe_dv_drpe(joint_drpe_dv_drpe'high) = '0'
			else std_logic_vector(-signed(joint_drpe_dv_dv(CONST_LDIF_BITS*(i+1) - 1 downto CONST_LDIF_BITS*i)));
	end generate;
	joint_drpe_dv_ready <= mult_exp_syncers_ready(0);
	
	exponent <= std_logic_vector(signed(axis_wuse_d) + signed(cfg_weo));
	mult_exp_syncers: for i in 0 to CONST_MAX_C - 1 generate
		syncer: entity work.AXIS_SYNCHRONIZER_2
			Generic map (
				DATA_WIDTH_0 => CONST_WUSE_BITS,
				DATA_WIDTH_1 => CONST_LDIF_BITS,
				LATCH		 => true,
				USER_WIDTH 	 => coordinate_bounds_array_t'length,
				USER_POLICY  => PASS_ONE
			)
			Port map (
				clk => clk, rst => rst,
				--to input axi port
				input_0_valid => axis_wuse_valid,
				input_0_ready => axis_wuse_ready_vec(i),
				input_0_data  => exponent,
				input_1_valid => joint_drpe_dv_valid,
				input_1_ready => mult_exp_syncers_ready(i),
				input_1_data  => joint_drpe_dv_data(i),
				input_1_user  => joint_drpe_dv_coord,
				--to output axi ports
				output_valid  => joint_pre_add_valid(i),
				output_ready  => joint_pre_add_ready(i), 
				output_data_0 => joint_pre_add_exp(i),
				output_data_1 => joint_pre_add_mult(i),
				output_user   => joint_pre_add_coord(i)
			);
		
		joint_pre_add_minus(i) <= std_logic_vector(- signed (joint_pre_add_exp(i)));
		joint_pre_add_mult_shifted_left(i) 	<= std_logic_vector(shift_left (resize(signed(joint_pre_add_mult(i)), CONST_W_UPDATE_BITS), to_integer(unsigned(joint_pre_add_minus(i)))));
		joint_pre_add_mult_shifted_right(i) <= std_logic_vector(shift_right(resize(signed(joint_pre_add_mult(i)), CONST_W_UPDATE_BITS), to_integer(unsigned(joint_pre_add_exp(i)))));
		gen_flag: process(joint_pre_add_exp)
		begin
			if signed(joint_pre_add_exp(i)) < 0 then
				joint_pre_add_mult_use_left(i) <= '1';
			else
				joint_pre_add_mult_use_left(i) <= '0';
			end if;
		end process;
		
		latch_mult_exp: entity work.AXIS_LATCHED_CONNECTION
			Generic map (
				DATA_WIDTH => CONST_W_UPDATE_BITS*2,
				USER_WIDTH => coordinate_bounds_array_t'length
			)
			Port map (
				clk => clk, rst => rst,
				input_ready => joint_pre_add_ready(i),
				input_valid => joint_pre_add_valid(i),
				input_data(CONST_W_UPDATE_BITS*2 - 1 downto CONST_W_UPDATE_BITS)  =>  joint_pre_add_mult_shifted_left(i),
				input_data(CONST_W_UPDATE_BITS - 1 downto 0)  =>  joint_pre_add_mult_shifted_right(i),
				input_last  => joint_pre_add_mult_use_left(i),
				input_user  => joint_pre_add_coord(i),
				output_ready=> joint_add_ready(i),
				output_valid=> joint_add_valid(i),
				output_data(CONST_W_UPDATE_BITS*2 - 1 downto CONST_W_UPDATE_BITS)  =>  joint_add_mult_shifted_left(i),
				output_data(CONST_W_UPDATE_BITS - 1 downto 0)  =>  joint_add_mult_shifted_right(i),
				output_last => joint_add_mult_use_left(i),
				output_user => joint_add_coord(i)
			);
		
		weight_addval(i) <= 
			std_logic_vector(1 + signed(joint_add_mult_shifted_left(i)))
			when joint_add_mult_use_left(i) = '1' else
			std_logic_vector(1 + signed(joint_add_mult_shifted_right(i)));
			
		weight_addval_halved(i) <= weight_addval(i)(CONST_W_UPDATE_BITS-1) & weight_addval(i)(CONST_W_UPDATE_BITS-1 downto 1);
	end generate;
	axis_wuse_ready <= axis_wuse_ready_vec(0);


	omega_min <= std_logic_vector(- shift_left(to_signed(1, CONST_MAX_WEIGHT_BITS), to_integer(unsigned(cfg_omega))+2));
	omega_max <= std_logic_vector(shift_left(to_signed(1, CONST_MAX_WEIGHT_BITS), to_integer(unsigned(cfg_omega))+2) - 1);
	final_sync: for i in 0 to CONST_MAX_C - 1 generate
		clamped_syncer: entity work.AXIS_SYNCHRONIZER_2
			Generic map (
				DATA_WIDTH_0 => CONST_MAX_WEIGHT_BITS,
				DATA_WIDTH_1 => CONST_W_UPDATE_BITS,
				LATCH		 => true,
				USER_WIDTH   => coordinate_bounds_array_t'length,
				USER_POLICY  => PASS_ONE
			)
			Port map (
				clk => clk, rst => rst,
				--to input axi port
				input_0_valid => axis_wv_valid,
				input_0_ready => axis_wv_ready_vec(i),
				input_0_data  => axis_wv_d(CONST_MAX_WEIGHT_BITS*(i+1) - 1 downto CONST_MAX_WEIGHT_BITS*i),
				input_1_valid => joint_add_valid(i),
				input_1_ready => joint_add_ready(i),
				input_1_data  => weight_addval_halved(i),
				input_1_user  => joint_add_coord(i),
				--to output axi ports
				output_valid  => joint_unclamped_valid(i),
				output_ready  => joint_unclamped_ready(i),
				output_data_0 => joint_unclamped_weight(i),
				output_data_1 => joint_unclamped_addval(i),
				output_user   => joint_unclamped_coord(i)
			);
		joint_unclamped_ready(i) <= axis_out_wv_ready;
		joint_unclamped_finalres(i) <= std_logic_vector(signed(joint_unclamped_addval(i)) + signed(joint_unclamped_weight(i)));
	
		axis_out_wv_d(CONST_MAX_WEIGHT_BITS*(i+1)-1 downto CONST_MAX_WEIGHT_BITS*i) <=
			omega_min when signed(joint_unclamped_finalres(i)) < signed(omega_min) else
			omega_max when signed(joint_unclamped_finalres(i)) > signed(omega_max) else
			std_logic_vector(resize(signed(joint_unclamped_finalres(i)), CONST_MAX_WEIGHT_BITS));	
	end generate;
	
	axis_wv_ready <= axis_wv_ready_vec(0);
	axis_out_wv_valid <= joint_unclamped_valid(0);
	axis_out_wv_coord <= joint_unclamped_coord(0);
	

	
	
	
	
end Behavioral;
