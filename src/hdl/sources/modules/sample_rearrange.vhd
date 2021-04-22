----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.03.2021 12:38:18
-- Design Name: 
-- Module Name: ccsds_123b2_core - Behavioral
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
use work.am_data_types.all;
use ieee.numeric_std.all;

entity sample_rearrange is
	generic (
		RELOCATION_MODE 		: RELOCATION_MODE_T := VERTICAL_TO_DIAGONAL 
	);
	port ( 
		clk, rst 				: in std_logic;
		finished 				: out std_logic;
		cfg_max_x				: in std_logic_vector(CONST_MAX_X_VALUE_BITS - 1 downto 0);
		cfg_max_y				: in std_logic_vector(CONST_MAX_Y_VALUE_BITS - 1 downto 0);
		cfg_max_z 				: in std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);	
		cfg_max_t				: in std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
		cfg_min_preload_value 	: in std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);
		cfg_max_preload_value 	: in std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);
		axis_input_d			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_input_ready		: out std_logic;
		axis_input_valid		: in std_logic;
		axis_output_d			: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0); --make sure we got enough space
		axis_output_coord 		: out coordinate_array_t; --stdlv
		axis_output_last		: out std_logic;
		axis_output_valid		: out std_logic;
		axis_output_ready		: in std_logic
	);
end sample_rearrange;

architecture Behavioral of sample_rearrange is

	type rearrange_state_t is (ST_WORKING, ST_FINISHED);
	signal state_curr, state_next: rearrange_state_t;	
	
	--input coordinate creator
	signal input_coord_gen_finished		: std_logic;
	signal axis_input_coord_valid, axis_input_coord_ready, axis_input_coord_last: std_logic;
	signal axis_input_coord_z			: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal axis_input_coord_tz			: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	
	--signals for synchronizer from input coord and input data
	signal axis_rel_coord_gen_valid		: std_logic;
	signal axis_rel_coord_gen_ready		: std_logic;
	signal axis_rel_coord_gen_last		: std_logic;
	signal axis_rel_coord_gen_data 		: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_rel_coord_gen_data_z	: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal axis_rel_coord_gen_data_tz	: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	
	--diagonal coordinate generator for the input relocator
	signal input_coord_gen_diag_finished: std_logic;
	signal axis_diag_coord_gen_valid 	: std_logic;
	signal axis_diag_coord_gen_ready 	: std_logic;
	signal axis_diag_coord_gen_last 	: std_logic;
	signal axis_diag_coord_gen_data_z	: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal axis_diag_coord_gen_data_t 	: std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
	signal axis_diag_coord_gen_data_tz 	: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	
	--diagonal coordinate generator for the flag generator (easier to have two
	--diagonal generators instead of a splitter. Similar resources but no sync required
	signal flag_coord_gen_diag_finished: std_logic;
	signal axis_flag_coord_gen_valid 	: std_logic;
	signal axis_flag_coord_gen_ready 	: std_logic;
	signal axis_flag_coord_gen_last 	: std_logic;
	signal axis_flag_coord_gen_data_z	: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal axis_flag_coord_gen_data_t 	: std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
	signal axis_flag_coord_gen_data_tz 	: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal axis_flag_coord_gen_data_t_z, axis_flag_coord_t_z: std_logic_vector(CONST_MAX_T_VALUE_BITS + CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	
	--output from relocator
	signal sample_relocator_finished: std_logic;
	signal axis_reloc_d		: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_reloc_ready	: std_logic;
	signal axis_reloc_valid	: std_logic;
	signal axis_reloc_last	: std_logic;
	
	--cfg plus one to generate divisions
	signal cfg_max_x_plus_one: std_logic_vector(CONST_MAX_X_VALUE_BITS + 1 - 1 downto 0);
	--signals coming from the divisor before the flagging
	signal axis_flag_coord_y: std_logic_vector(CONST_MAX_Y_VALUE_BITS - 1 downto 0);
	signal axis_flag_coord_y_pre: std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
	signal axis_flag_coord_x_pre: std_logic_vector(CONST_MAX_X_VALUE_BITS + 1 - 1 downto 0);
	signal axis_flag_coord_x: std_logic_vector(CONST_MAX_X_VALUE_BITS - 1 downto 0);
	signal axis_flag_coord_ready, axis_flag_coord_valid, axis_flag_coord_last: std_logic;
	signal axis_flag_coord_z: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal axis_flag_coord_t: std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
	signal axis_flag_coord_cpa: coordinate_position_t;	
	signal axis_flag_coord_cpa_stdlv: coordinate_position_array_t;
	
	--signals from the flag generation module
	signal axis_flag_ready, axis_flag_valid, axis_flag_last: std_logic;
	signal axis_flag_flags: coordinate_bounds_array_t;
	signal axis_flag_cpa: coordinate_position_array_t;
	signal axis_flag_fullcoord: coordinate_t;
	signal axis_flag_fullcoord_stdlv: coordinate_array_t;
			
begin
	
	seq: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state_curr <= ST_WORKING;
			else
				state_curr <= state_next;
			end if;
		end if;
	end process;
	
	comb: process(state_curr, input_coord_gen_diag_finished, sample_relocator_finished, flag_coord_gen_diag_finished, input_coord_gen_finished)
	begin
		finished <= '0';
		state_next <= state_curr;
		
		if state_curr = ST_WORKING then
			if input_coord_gen_diag_finished = '1' and input_coord_gen_finished = '1'
					and sample_relocator_finished = '1' and flag_coord_gen_diag_finished = '1' then
				state_next <= ST_FINISHED;
			end if;
		elsif state_curr = ST_FINISHED then
			finished <= '1';
		end if;
	end process;
	
	gen_v2d: if RELOCATION_MODE = VERTICAL_TO_DIAGONAL generate
		input_coord_gen: entity work.coord_gen_vertical
			port map (
				--control signals 
				clk => clk, rst => rst,
				finished => input_coord_gen_finished,
				--control inputs
				cfg_max_z => cfg_max_z,
				cfg_max_t => cfg_max_t,
				--output bus
				axis_out_valid	=> axis_input_coord_valid,
				axis_out_ready 	=> axis_input_coord_ready,
				axis_out_last  	=> axis_input_coord_last,
				axis_out_data_z	=> axis_input_coord_z,
				axis_out_data_t	=> open,
				axis_out_data_tz=> axis_input_coord_tz
			);
			
		input_coord_gen_new: entity work.coord_gen_diagonal
			port map (
				clk => clk, rst => rst,
				finished => input_coord_gen_diag_finished,
				--control inputs
				cfg_max_z => cfg_max_z,
				cfg_max_t => cfg_max_t,
				--output bus
				axis_out_valid 	=> axis_diag_coord_gen_valid,
				axis_out_ready 	=> axis_diag_coord_gen_ready,
				axis_out_last  	=> axis_diag_coord_gen_last,
				axis_out_data_z	=> axis_diag_coord_gen_data_z,
				axis_out_data_t	=> axis_diag_coord_gen_data_t,
				axis_out_data_tz=> axis_diag_coord_gen_data_tz
		);
		
		flag_coord_gen_new: entity work.coord_gen_diagonal
			port map (
				clk => clk, rst => rst, 
				finished => flag_coord_gen_diag_finished,
				--control inputs
				cfg_max_z => cfg_max_z,
				cfg_max_t => cfg_max_t,
				--output bus
				axis_out_valid 	=> axis_flag_coord_gen_valid,
				axis_out_ready 	=> axis_flag_coord_gen_ready,
				axis_out_last  	=> axis_flag_coord_gen_last,
				axis_out_data_z	=> axis_flag_coord_gen_data_z,
				axis_out_data_t	=> axis_flag_coord_gen_data_t,
				axis_out_data_tz=> axis_flag_coord_gen_data_tz
			);
	end generate;
	gen_d2v: if RELOCATION_MODE = DIAGONAL_TO_VERTICAL generate
		input_coord_gen: entity work.coord_gen_diagonal
			port map (
				--control signals 
				clk => clk, rst => rst,
				finished => input_coord_gen_finished,
				--control inputs
				cfg_max_z => cfg_max_z,
				cfg_max_t => cfg_max_t,
				--output bus
				axis_out_valid	=> axis_input_coord_valid,
				axis_out_ready 	=> axis_input_coord_ready,
				axis_out_last  	=> axis_input_coord_last,
				axis_out_data_z	=> axis_input_coord_z,
				axis_out_data_t	=> open,
				axis_out_data_tz=> axis_input_coord_tz
			);
			
		input_coord_gen_new: entity work.coord_gen_vertical
			port map (
				clk => clk, rst => rst,
				finished => input_coord_gen_diag_finished,
				--control inputs
				cfg_max_z => cfg_max_z,
				cfg_max_t => cfg_max_t,
				--output bus
				axis_out_valid 	=> axis_diag_coord_gen_valid,
				axis_out_ready 	=> axis_diag_coord_gen_ready,
				axis_out_last  	=> axis_diag_coord_gen_last,
				axis_out_data_z	=> axis_diag_coord_gen_data_z,
				axis_out_data_t	=> axis_diag_coord_gen_data_t,
				axis_out_data_tz=> axis_diag_coord_gen_data_tz
		);
		
		flag_coord_gen_new: entity work.coord_gen_vertical
			port map (
				clk => clk, rst => rst, 
				finished => flag_coord_gen_diag_finished,
				--control inputs
				cfg_max_z => cfg_max_z,
				cfg_max_t => cfg_max_t,
				--output bus
				axis_out_valid 	=> axis_flag_coord_gen_valid,
				axis_out_ready 	=> axis_flag_coord_gen_ready,
				axis_out_last  	=> axis_flag_coord_gen_last,
				axis_out_data_z	=> axis_flag_coord_gen_data_z,
				axis_out_data_t	=> axis_flag_coord_gen_data_t,
				axis_out_data_tz=> axis_flag_coord_gen_data_tz
			);
	end generate;
		
	input_coord_sample_sync: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_MAX_DATA_WIDTH,
			DATA_WIDTH_1 => CONST_MAX_Z_VALUE_BITS,
			LATCH => true,
			USER_WIDTH => CONST_MAX_Z_VALUE_BITS,
			USER_POLICY => PASS_ONE,
			LAST_POLICY => PASS_ONE
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_input_valid,
			input_0_ready => axis_input_ready,
			input_0_data  => axis_input_d,
			input_1_valid => axis_input_coord_valid,
			input_1_ready => axis_input_coord_ready,
			input_1_data  => axis_input_coord_z,
			input_1_last  => axis_input_coord_last,
			input_1_user  => axis_input_coord_tz,
			--to output axi ports
			output_valid  => axis_rel_coord_gen_valid,
			output_ready  => axis_rel_coord_gen_ready,
			output_data_0 => axis_rel_coord_gen_data,
			output_data_1 => axis_rel_coord_gen_data_z,
			output_last	  => axis_rel_coord_gen_last,
			output_user   => axis_rel_coord_gen_data_tz
		);
	
	relocator: entity work.sample_relocator 
		generic map (
			MAX_SIDE_LOG => CONST_MAX_Z_VALUE_BITS,
			DATA_WIDTH   => CONST_MAX_DATA_WIDTH
		)
		port map (
			--control signals 
			clk => clk, rst => rst,
			finished => sample_relocator_finished,
			--control inputs
			cfg_min_preload_value => cfg_min_preload_value,
			cfg_max_preload_value => cfg_max_preload_value,
			--axis bus for input coordinates (write to here)
			axis_input_coord_d => axis_rel_coord_gen_data,
			axis_input_coord_x => axis_rel_coord_gen_data_tz,
			axis_input_coord_z => axis_rel_coord_gen_data_z,
			axis_input_coord_ready => axis_rel_coord_gen_ready,
			axis_input_coord_valid => axis_rel_coord_gen_valid,
			axis_input_coord_last  => axis_rel_coord_gen_last,
			--diagonal coordinates for reordering
			axis_output_coord_x => axis_diag_coord_gen_data_tz,
			axis_output_coord_z => axis_diag_coord_gen_data_z,
			axis_output_coord_ready => axis_diag_coord_gen_ready,
			axis_output_coord_valid => axis_diag_coord_gen_valid,
			axis_output_coord_last => axis_diag_coord_gen_last,
			--axis bus to output the data (read from output_coord)
			axis_output_data_d => axis_reloc_d,
			axis_output_data_ready => axis_reloc_ready,
			axis_output_data_valid => axis_reloc_valid,
			axis_output_data_last => axis_reloc_last
		);
		
	axis_flag_coord_gen_data_t_z <= axis_flag_coord_gen_data_t & axis_flag_coord_gen_data_z;
	cfg_max_x_plus_one <= std_logic_vector(("0" & unsigned(cfg_max_x)) + 1);
	xy_coord_gen: entity work.axis_segmented_unsigned_divider
		generic map (
			DIVIDEND_WIDTH => CONST_MAX_T_VALUE_BITS,
			DIVISOR_WIDTH => CONST_MAX_X_VALUE_BITS + 1,
			LAST_POLICY => PASS_ZERO,
			USER_WIDTH => CONST_MAX_T_VALUE_BITS + CONST_MAX_Z_VALUE_BITS,
			USER_POLICY => PASS_ZERO
		)
		port map ( 
			clk => clk, rst => rst,
			axis_dividend_data 		=> axis_flag_coord_gen_data_t,
			axis_dividend_ready		=> axis_flag_coord_gen_ready,
			axis_dividend_valid		=> axis_flag_coord_gen_valid,
			axis_dividend_last		=> axis_flag_coord_gen_last,
			axis_dividend_user  	=> axis_flag_coord_gen_data_t_z,
			axis_divisor_data		=> cfg_max_x_plus_one,
			axis_divisor_ready  	=> open,
			axis_divisor_valid  	=> '1',
			axis_divisor_last   	=> '0',
			axis_output_quotient 	=> axis_flag_coord_y_pre,
			axis_output_remainder 	=> axis_flag_coord_x_pre,
			axis_output_ready 	  	=> axis_flag_coord_ready,
			axis_output_valid 	  	=> axis_flag_coord_valid,
			axis_output_last 	  	=> axis_flag_coord_last,
			axis_output_user 	  	=> axis_flag_coord_t_z
		);
	axis_flag_coord_y <= axis_flag_coord_y_pre(axis_flag_coord_y'range);
	axis_flag_coord_x <= axis_flag_coord_x_pre(axis_flag_coord_x'range);
	axis_flag_coord_z <= axis_flag_coord_t_z(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	axis_flag_coord_t <= axis_flag_coord_t_z(axis_flag_coord_t_z'high downto CONST_MAX_Z_VALUE_BITS);
	
	axis_flag_coord_cpa.x <= axis_flag_coord_x;
	axis_flag_coord_cpa.y <= axis_flag_coord_y;
	axis_flag_coord_cpa.z <= axis_flag_coord_z;
	axis_flag_coord_cpa.t <= axis_flag_coord_t;
		
	update_flag_coord_array: process(axis_flag_coord_cpa) begin
		axis_flag_coord_cpa_stdlv <= F_CP2STDLV(axis_flag_coord_cpa);
	end process;
	flagger: entity work.flag_gen 
		port map (
			cfg_max_x			=> cfg_max_x,
			cfg_max_y			=> cfg_max_y,
			cfg_max_z			=> cfg_max_z,
			axis_input_x		=> axis_flag_coord_x,
			axis_input_y		=> axis_flag_coord_y,
			axis_input_z		=> axis_flag_coord_z,
			axis_input_ready	=> axis_flag_coord_ready,
			axis_input_valid	=> axis_flag_coord_valid,
			axis_input_last 	=> axis_flag_coord_last,
			axis_input_cpa		=> axis_flag_coord_cpa_stdlv,
			axis_output_ready	=> axis_flag_ready,
			axis_output_valid 	=> axis_flag_valid,
			axis_output_last 	=> axis_flag_last,
			axis_output_flags 	=> axis_flag_flags,
			axis_output_cpa 	=> axis_flag_cpa 
		);
	
	update_axis_flag_fullcoord_array: process(axis_flag_fullcoord) begin
		axis_flag_fullcoord_stdlv <= F_C2STDLV(axis_flag_fullcoord);
	end process;
	update_axis_flag_fullcoord: process(axis_flag_cpa, axis_flag_flags) begin
		axis_flag_fullcoord.position 	<= F_STDLV2CP(axis_flag_cpa);
		axis_flag_fullcoord.bounds 		<= F_STDLV2CB(axis_flag_flags);
	end process;
	output_sync: entity work.axis_synchronizer_2	
		generic map (
			DATA_WIDTH_0 => CONST_MAX_DATA_WIDTH,
			DATA_WIDTH_1 => coordinate_array_t'length,
			LATCH => true,
			LAST_POLICY => PASS_ZERO
		)
		port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_reloc_valid,
			input_0_ready => axis_reloc_ready,
			input_0_data  => axis_reloc_d,
			input_0_last  => axis_reloc_last,
			input_1_valid => axis_flag_valid,
			input_1_ready => axis_flag_ready,
			input_1_data  => axis_flag_fullcoord_stdlv,
			input_1_last  => axis_flag_last,
			--to output axi ports
			output_valid  => axis_output_valid,
			output_ready  => axis_output_ready,
			output_data_0 => axis_output_d,
			output_data_1 => axis_output_coord,
			output_last	  => axis_output_last
		);
		
end Behavioral;
