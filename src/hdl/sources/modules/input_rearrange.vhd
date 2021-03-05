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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity input_rearrange is
	generic (
		MAX_X_WIDTH: integer := 10;
		MAX_Y_WIDTH: integer := 8;
		MAX_Z_WIDTH: integer := 9;
		MAX_T_WIDTH: integer := 18;
		DATA_WIDTH: integer := CONST_MAX_D
	);
	port ( 
		clk, rst 				: in std_logic;
		finished 				: out std_logic;
		cfg_max_x				: in std_logic_vector(MAX_X_WIDTH - 1 downto 0);
		cfg_max_y				: in std_logic_vector(MAX_Y_WIDTH - 1 downto 0);
		cfg_max_z 				: in std_logic_vector(MAX_Z_WIDTH - 1 downto 0);	
		cfg_max_t				: in std_logic_vector(MAX_T_WIDTH - 1 downto 0);
		cfg_min_preload_value 	: in std_logic_vector(MAX_Z_WIDTH*2 - 1 downto 0);
		cfg_max_preload_value 	: in std_logic_vector(MAX_Z_WIDTH*2 - 1 downto 0);
		axis_input_d			: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_input_ready		: out std_logic;
		axis_input_valid		: in std_logic;
		axis_output_d			: out std_logic_vector(DATA_WIDTH - 1 downto 0); --make sure we got enough space
		axis_output_flags 		: out coordinate_bounds_array_t; --stdlv
		axis_output_last		: out std_logic;
		axis_output_valid		: out std_logic;
		axis_output_ready		: in std_logic
	);
end input_rearrange;

architecture Behavioral of input_rearrange is

	type rearrange_state_t is (ST_WORKING, ST_FINISHED);
	signal state_curr, state_next: rearrange_state_t;	
	
	
	--square coordinate generator for the input relocator
	signal rel_coord_gen_finished: std_logic;
	signal axis_rel_coord_gen_valid		: std_logic;
	signal axis_rel_coord_gen_ready		: std_logic;
	signal axis_rel_coord_gen_last		: std_logic;
	signal axis_rel_coord_gen_data 		: std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal axis_rel_coord_gen_data_z	: std_logic_vector(MAX_Z_WIDTH - 1 downto 0);
	signal axis_rel_coord_gen_data_tz	: std_logic_vector(MAX_Z_WIDTH - 1 downto 0);
	
	--diagonal coordinate generator for the input relocator
	signal input_coord_gen_diag_finished: std_logic;
	signal axis_diag_coord_gen_valid 	: std_logic;
	signal axis_diag_coord_gen_ready 	: std_logic;
	signal axis_diag_coord_gen_last 	: std_logic;
	signal axis_diag_coord_gen_data_z	: std_logic_vector(MAX_Z_WIDTH - 1 downto 0);
	signal axis_diag_coord_gen_data_t 	: std_logic_vector(MAX_T_WIDTH - 1 downto 0);
	signal axis_diag_coord_gen_data_tz 	: std_logic_vector(MAX_Z_WIDTH - 1 downto 0);
	
	--diagonal coordinate generator for the flag generator (easier to have two
	--diagonal generators instead of a splitter. Similar resources but no sync required
	signal flag_coord_gen_diag_finished: std_logic;
	signal axis_flag_coord_gen_valid 	: std_logic;
	signal axis_flag_coord_gen_ready 	: std_logic;
	signal axis_flag_coord_gen_last 	: std_logic;
	signal axis_flag_coord_gen_data_z	: std_logic_vector(MAX_Z_WIDTH - 1 downto 0);
	signal axis_flag_coord_gen_data_t 	: std_logic_vector(MAX_T_WIDTH - 1 downto 0);
	signal axis_flag_coord_gen_data_tz 	: std_logic_vector(MAX_Z_WIDTH - 1 downto 0);
	
	--output from relocator
	signal sample_relocator_finished: std_logic;
	signal axis_reloc_d		: std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal axis_reloc_ready	: std_logic;
	signal axis_reloc_valid	: std_logic;
	signal axis_reloc_last	: std_logic;
	
	--signals coming from the divisor before the flagging
	signal axis_flag_coord_y: std_logic_vector(MAX_Y_WIDTH - 1 downto 0);
	signal axis_flag_coord_y_pre: std_logic_vector(MAX_T_WIDTH - 1 downto 0);
	signal axis_flag_coord_x: std_logic_vector(MAX_X_WIDTH - 1 downto 0);
	signal axis_flag_coord_ready, axis_flag_coord_valid, axis_flag_coord_last: std_logic;
	signal axis_flag_coord_z: std_logic_vector(MAX_Z_WIDTH - 1 downto 0);
	
	--signals from the flag generation module
	signal axis_flag_ready, axis_flag_valid, axis_flag_last: std_logic;
	signal axis_flag_flags: coordinate_bounds_array_t;
			
begin
	
	seq: process(clk, rst)
	begin
		if rst = '1' then
			state_curr <= ST_WORKING;
		elsif rising_edge(clk) then
			state_curr <= state_next;
		end if;
	end process;
	
	comb: process(state_curr, rel_coord_gen_finished, input_coord_gen_diag_finished, sample_relocator_finished, flag_coord_gen_diag_finished)
	begin
		finished <= '0';
		state_next <= state_curr;
		
		if state_curr = ST_WORKING then
			if rel_coord_gen_finished = '1' and input_coord_gen_diag_finished = '1' 
					and sample_relocator_finished = '1' and flag_coord_gen_diag_finished = '1' then
				state_next <= ST_FINISHED;
			end if;
		elsif state_curr = ST_FINISHED then
			finished <= '1';
		end if;
	end process;
	
	
	
	input_vertical_reloc_coord_gen: entity work.coord_gen_vertical_reloc	
		generic map (
			MAX_COORD_T_WIDTH => MAX_T_WIDTH,
			MAX_COORD_Z_WIDTH => MAX_Z_WIDTH,
			DATA_WIDTH => DATA_WIDTH
		)
		port map (
			--control signals 
			clk => clk, rst => rst,
			finished => rel_coord_gen_finished,
			--control inputs
			cfg_max_z => cfg_max_z,
			cfg_max_t => cfg_max_t,
			--input bus
			axis_in_data		=> axis_input_d,
			axis_in_ready 		=> axis_input_ready,
			axis_in_valid 		=> axis_input_valid,
			--output bus
			axis_out_valid 		=> axis_rel_coord_gen_valid,
			axis_out_ready 		=> axis_rel_coord_gen_ready,
			axis_out_last  		=> axis_rel_coord_gen_last,
			axis_out_data 		=> axis_rel_coord_gen_data,
			axis_out_data_z		=> axis_rel_coord_gen_data_z,
			axis_out_data_tz	=> axis_rel_coord_gen_data_tz
		);
	
	
	input_coord_gen_diagonal: entity work.coord_gen_diagonal
		generic map (
			MAX_COORD_Z_WIDTH => MAX_Z_WIDTH,
			MAX_COORD_T_WIDTH => MAX_T_WIDTH
		)
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

	
	relocator: entity work.sample_relocator 
		generic map (
			MAX_SIDE_LOG => MAX_Z_WIDTH,
			DATA_WIDTH   => DATA_WIDTH
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
		
		
	flag_coord_gen_diagonal: entity work.coord_gen_diagonal
		generic map (
			MAX_COORD_Z_WIDTH => MAX_Z_WIDTH,
			MAX_COORD_T_WIDTH => MAX_T_WIDTH
		)
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
		
	xy_coord_gen: entity work.axis_segmented_unsigned_divider
		generic map (
			DIVIDEND_WIDTH => MAX_T_WIDTH,
			DIVISOR_WIDTH => MAX_X_WIDTH,
			LAST_POLICY => PASS_ZERO,
			USER_WIDTH => MAX_Z_WIDTH,
			USER_POLICY => PASS_ZERO
		)
		port map ( 
			clk => clk, rst => rst,
			axis_dividend_data 		=> axis_flag_coord_gen_data_t,
			axis_dividend_ready		=> axis_flag_coord_gen_ready,
			axis_dividend_valid		=> axis_flag_coord_gen_valid,
			axis_dividend_last		=> axis_flag_coord_gen_last,
			axis_dividend_user  	=> std_logic_vector(axis_flag_coord_gen_data_z),
			axis_divisor_data		=> cfg_max_x,
			axis_divisor_ready  	=> open,
			axis_divisor_valid  	=> '1',
			axis_divisor_last   	=> '0',
			axis_output_quotient 	=> axis_flag_coord_y_pre,
			axis_output_remainder 	=> axis_flag_coord_x,
			axis_output_ready 	  	=> axis_flag_coord_ready,
			axis_output_valid 	  	=> axis_flag_coord_valid,
			axis_output_last 	  	=> axis_flag_coord_last,
			axis_output_user 	  	=> axis_flag_coord_z
		);
	axis_flag_coord_y <= axis_flag_coord_y_pre(axis_flag_coord_y'length - 1 downto 0);
		
		
	flagger: entity work.flag_gen 
		generic map (
			MAX_X_WIDTH => MAX_X_WIDTH,
			MAX_Y_WIDTH => MAX_Y_WIDTH,
			MAX_Z_WIDTH => MAX_Z_WIDTH
		)
		port map (
			cfg_max_x			=> cfg_max_x,
			cfg_max_y			=> cfg_max_y,
			cfg_max_z			=> cfg_max_z,
			axis_input_x		=> axis_flag_coord_x,
			axis_input_y		=> axis_flag_coord_y,
			axis_input_z		=> std_logic_vector(axis_flag_coord_z),
			axis_input_ready	=> axis_flag_coord_ready,
			axis_input_valid	=> axis_flag_coord_valid,
			axis_input_last 	=> axis_flag_coord_last,
			axis_output_ready	=> axis_flag_ready,
			axis_output_valid 	=> axis_flag_valid,
			axis_output_last 	=> axis_flag_last,
			axis_output_flags 	=> axis_flag_flags
		);
		
	output_sync: entity work.axis_synchronizer_2	
		generic map (
			DATA_WIDTH_0 => DATA_WIDTH,
			DATA_WIDTH_1 => coordinate_bounds_array_t'length,
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
			input_1_data  => axis_flag_flags,
			input_1_last  => axis_flag_last,
			--to output axi ports
			output_valid  => axis_output_valid,
			output_ready  => axis_output_ready,
			output_data_0 => axis_output_d,
			output_data_1 => axis_output_flags,
			output_last	  => axis_output_last
		);
		
end Behavioral;
