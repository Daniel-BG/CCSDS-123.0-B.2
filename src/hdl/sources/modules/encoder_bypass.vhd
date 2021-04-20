----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.04.2021 12:55:38
-- Design Name: 
-- Module Name: encoder_bypass - Behavioral
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

entity encoder_bypass is
	generic (
		USE_HYBRID_CODER		: boolean := true
	);
	Port ( 
		clk, rst				: in std_logic;
		cfg_initial_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_final_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_iacc				: in std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
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
		axis_out_last			: out std_logic
	);
end encoder_bypass;

architecture Behavioral of encoder_bypass is
	--latch output
	signal latched_mqi_d				: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal latched_mqi_ready			: std_logic;
	signal latched_mqi_valid			: std_logic;
	signal latched_mqi_coord			: coordinate_bounds_array_t;
	
	--input to coder (hybrid or normal)
	signal coder_axis_in_mqi_d			: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal coder_axis_in_mqi_ready		: std_logic;
	signal coder_axis_in_mqi_valid		: std_logic;
	signal coder_axis_in_mqi_coord		: coordinate_bounds_array_t;
	signal coder_axis_out_code			: std_logic_vector(63 downto 0);
	signal coder_axis_out_length		: std_logic_vector(6 downto 0);
	signal coder_axis_out_coord			: coordinate_bounds_array_t;
	signal coder_axis_out_valid			: std_logic;
	signal coder_axis_out_ready			: std_logic;
	signal coder_axis_out_last			: std_logic;
	
	--output latch input
	signal olatch_in_code				: std_logic_vector(CONST_OUTPUT_CODE_LENGTH - 1 downto 0);
	signal olatch_in_length				: std_logic_vector(CONST_OUTPUT_CODE_LENGTH_BITS - 1 downto 0);
	signal olatch_in_coord				: coordinate_bounds_array_t;
	signal olatch_in_valid				: std_logic;
	signal olatch_in_ready				: std_logic;
	signal olatch_in_last				: std_logic;
	
	
	--fsm control
	type state_t is (FIRST_PIXEL, OTHER_PIXELS); 
	signal state_curr, state_next: state_t;
begin

	input_latch: entity work.AXIS_DATA_LATCH 
		Generic map (
			DATA_WIDTH => CONST_MQI_BITS,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data	=> axis_in_mqi_d,
			input_ready => axis_in_mqi_ready,
			input_valid => axis_in_mqi_valid,
			input_user 	=> axis_in_mqi_coord,
			output_data	=> latched_mqi_d,
			output_ready=> latched_mqi_ready,
			output_valid=> latched_mqi_valid,
			output_user => latched_mqi_coord
		);
		
	bypass_seq: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state_curr <= FIRST_PIXEL;
			else
				state_curr <= state_next;
			end if; 
		end if;
	end process;
		
	bypass_logic: process(latched_mqi_coord, latched_mqi_d, latched_mqi_valid,
			olatch_in_ready, 
			coder_axis_in_mqi_ready,
			coder_axis_out_code,
			coder_axis_out_length,
			coder_axis_out_coord,
			coder_axis_out_valid,
			coder_axis_out_last,
			cfg_depth,
			state_curr)
	begin
		state_next <= state_curr;
	
		if state_curr = FIRST_PIXEL then
			--bypass since we are on the first pixel
			olatch_in_code		<= std_logic_vector(resize(unsigned(latched_mqi_d), olatch_in_code'length));
			olatch_in_length	<= std_logic_vector(resize(unsigned(cfg_depth), olatch_in_length'length));
			olatch_in_coord		<= latched_mqi_coord;
			olatch_in_valid		<= latched_mqi_valid;
			olatch_in_last 		<= '0';
			latched_mqi_ready 	<= olatch_in_ready;
			
			--defaults for non-used signals
			coder_axis_in_mqi_d     <= (others => '0');
			coder_axis_in_mqi_valid <= '0';
			coder_axis_out_ready    <= '0';
			coder_axis_in_mqi_coord <= (others => '0');
			
			if STDLV2CB(latched_mqi_coord).first_x = '1' and STDLV2CB(latched_mqi_coord).first_y = '1' and STDLV2CB(latched_mqi_coord).last_z = '1' then
				if latched_mqi_valid = '1' and olatch_in_ready = '1' then
					state_next <= OTHER_PIXELS; --we found the end of the first pixel, now on to the encoder
				end if;
			end if;
		elsif state_curr = OTHER_PIXELS then
			--pipe input latch to coders
			coder_axis_in_mqi_d     <= latched_mqi_d;
			latched_mqi_ready 		<= coder_axis_in_mqi_ready;
			coder_axis_in_mqi_valid <= latched_mqi_valid;
			coder_axis_in_mqi_coord <= latched_mqi_coord;
			--pipe output latch
			olatch_in_code		<= coder_axis_out_code;
			olatch_in_length	<= coder_axis_out_length;
			olatch_in_coord		<= coder_axis_out_coord;
			olatch_in_valid		<= coder_axis_out_valid;
			olatch_in_last 		<= coder_axis_out_last;
			coder_axis_out_ready<= olatch_in_ready;
		end if;
	end process;

	gen_normal_coder: if not USE_HYBRID_CODER generate 
		encoder: entity work.encoder
			Port map ( 
				clk => clk, rst => rst,
				cfg_initial_counter		=> cfg_initial_counter,
				cfg_final_counter		=> cfg_final_counter,
				cfg_u_max				=> cfg_u_max,
				cfg_depth 				=> cfg_depth,
				cfg_iacc				=> cfg_iacc(CONST_MAX_ACC_BITS - 1 downto 0),
				axis_in_mqi_d			=> coder_axis_in_mqi_d,
				axis_in_mqi_ready		=> coder_axis_in_mqi_ready,
				axis_in_mqi_valid		=> coder_axis_in_mqi_valid,
				axis_in_mqi_coord		=> coder_axis_in_mqi_coord,
				axis_out_code			=> coder_axis_out_code,
				axis_out_length			=> coder_axis_out_length,
				axis_out_coord			=> coder_axis_out_coord,
				axis_out_valid			=> coder_axis_out_valid,
				axis_out_ready			=> coder_axis_out_ready,
				axis_out_last			=> coder_axis_out_last
			);
	end generate;
	
	gen_hybrid_coder: if USE_HYBRID_CODER generate 
		encoder: entity work.hybrid_encoder
			Port map ( 
				clk => clk, rst	=> rst,
				cfg_initial_counter		=> cfg_initial_counter,
				cfg_final_counter		=> cfg_final_counter,
				cfg_ihra				=> cfg_iacc,
				cfg_u_max				=> cfg_u_max,
				cfg_depth				=> cfg_depth,
				axis_in_mqi_d			=> coder_axis_in_mqi_d,
				axis_in_mqi_ready		=> coder_axis_in_mqi_ready,
				axis_in_mqi_valid		=> coder_axis_in_mqi_valid,
				axis_in_mqi_coord		=> coder_axis_in_mqi_coord,
				axis_out_code			=> coder_axis_out_code,
				axis_out_length			=> coder_axis_out_length,
				axis_out_coord			=> coder_axis_out_coord,
				axis_out_valid			=> coder_axis_out_valid,
				axis_out_ready			=> coder_axis_out_ready,
				axis_out_last			=> coder_axis_out_last
			);
	end generate;
	
	
	output_latch: entity work.AXIS_DATA_LATCH 
		Generic map (
			DATA_WIDTH => CONST_OUTPUT_CODE_LENGTH + CONST_OUTPUT_CODE_LENGTH_BITS + coordinate_bounds_array_t'length
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data(CONST_OUTPUT_CODE_LENGTH + CONST_OUTPUT_CODE_LENGTH_BITS + coordinate_bounds_array_t'length - 1 downto CONST_OUTPUT_CODE_LENGTH_BITS + coordinate_bounds_array_t'length)	=> olatch_in_code,
			input_data(CONST_OUTPUT_CODE_LENGTH_BITS + coordinate_bounds_array_t'length - 1 downto coordinate_bounds_array_t'length)	=> olatch_in_length,
			input_data(coordinate_bounds_array_t'length - 1 downto 0)	=> olatch_in_coord,
			input_ready => olatch_in_ready,
			input_valid => olatch_in_valid,
			input_last  => olatch_in_last,
			output_data(CONST_OUTPUT_CODE_LENGTH + CONST_OUTPUT_CODE_LENGTH_BITS + coordinate_bounds_array_t'length - 1 downto CONST_OUTPUT_CODE_LENGTH_BITS + coordinate_bounds_array_t'length)	=> axis_out_code,
			output_data(CONST_OUTPUT_CODE_LENGTH_BITS + coordinate_bounds_array_t'length - 1 downto coordinate_bounds_array_t'length)	=> axis_out_length,
			output_data(coordinate_bounds_array_t'length - 1 downto 0)	=> axis_out_coord,
			output_ready=> axis_out_ready,
			output_valid=> axis_out_valid,
			output_last => axis_out_last
		);

end Behavioral;
