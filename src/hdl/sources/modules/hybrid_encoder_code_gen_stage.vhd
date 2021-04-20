----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.04.2021 17:22:41
-- Design Name: 
-- Module Name: hybrid_encoder_code_gen_stage - Behavioral
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
use work.ccsds_math_functions.all;
use ieee.numeric_std.all;

entity hybrid_encoder_code_gen_stage is
	Port ( 
		clk, rst				: in std_logic;
		--configs
		cfg_u_max				: in std_logic_vector(CONST_U_MAX_BITS - 1 downto 0);
		cfg_depth				: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		--output signals
		axis_in_ready 			: out std_logic; 
		axis_in_valid			: in std_logic;
		axis_in_mqi				: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_coord			: in coordinate_bounds_array_t;
		axis_in_k				: in std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
		axis_in_input_symbol	: in std_logic_vector(CONST_INPUT_SYMBOL_BITS - 1 downto 0);
		axis_in_code_quant		: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_is_tree			: in std_logic_vector(0 downto 0);
		axis_in_cw_bits 		: in std_logic_vector(CONST_CODEWORD_BITS - 1 downto 0);
		axis_in_cw_length		: in std_logic_vector(CONST_CODEWORD_LENGTH_BITS - 1 downto 0);
		axis_in_ihe				: in std_logic;
		axis_in_flush_bit		: in flush_bit_t;
		axis_in_last			: in std_logic;
		axis_out_code			: out std_logic_vector(CONST_OUTPUT_CODE_LENGTH-1 downto 0);
		axis_out_length			: out std_logic_vector(CONST_OUTPUT_CODE_LENGTH_BITS-1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t;
		axis_out_valid			: out std_logic;
		axis_out_ready			: in std_logic;
		axis_out_last			: out std_logic
	);
end hybrid_encoder_code_gen_stage;

architecture Behavioral of hybrid_encoder_code_gen_stage is
	--allow space for 1 extra bit from accumulator + maximum reverse golomb code + codeword (all could be output in a single cycle)
	constant CONST_CODE_LENGTH: integer := 1 + CONST_MAX_CODE_LENGTH + CONST_CODEWORD_BITS; -- up to 1 + 64 + 21 = 86;
	constant CONST_CODE_BITS: integer := bits(CONST_CODE_LENGTH);

	--process on input stream
	signal axis_in_code: std_logic_vector(CONST_CODE_LENGTH - 1 downto 0);
	signal axis_in_code_length: std_logic_vector(CONST_CODE_BITS - 1 downto 0);
	signal axis_in_code_gol: std_logic;
	signal axis_in_gol_param: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal axis_in_gol_code: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_in_code_cw: std_logic;
	signal axis_in_threshold: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal axis_in_threshold_under_umax: std_logic;
	
	--first latch data
	signal fs_code: std_logic_vector(CONST_CODE_LENGTH - 1 downto 0);
	signal fs_ready, fs_valid, fs_last: std_logic;
	signal fs_code_length: std_logic_vector(CONST_CODE_BITS - 1 downto 0);
	signal fs_code_gol: std_logic;
	signal fs_gol_param: std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
	signal fs_gol_code: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal fs_code_cw: std_logic;
	signal fs_cw_bits: std_logic_vector(CONST_CODEWORD_BITS - 1 downto 0);
	signal fs_cw_length: std_logic_vector(CONST_CODEWORD_LENGTH_BITS - 1 downto 0);
	signal fs_updated_code_length: std_logic_vector(CONST_CODE_BITS - 1 downto 0);
	signal fs_updated_code: std_logic_vector(CONST_CODE_LENGTH - 1 downto 0);
	signal fs_coord: coordinate_bounds_array_t;
	signal fs_threshold: std_logic_vector(CONST_MQI_BITS - 1 downto 0);
	signal fs_threshold_under_umax: std_logic;
	
	--second stage
	signal ss_code: std_logic_vector(CONST_CODE_LENGTH - 1 downto 0);
	signal ss_ready, ss_valid, ss_last: std_logic;
	signal ss_code_length: std_logic_vector(CONST_CODE_BITS - 1 downto 0);
	signal ss_code_cw: std_logic;
	signal ss_cw_bits: std_logic_vector(CONST_CODEWORD_BITS - 1 downto 0);
	signal ss_cw_length: std_logic_vector(CONST_CODEWORD_LENGTH_BITS - 1 downto 0);
	signal ss_updated_code_length: std_logic_vector(CONST_CODE_BITS - 1 downto 0);
	signal ss_updated_code: std_logic_vector(CONST_CODE_LENGTH - 1 downto 0);
	signal ss_coord: coordinate_bounds_array_t;
	
	--big code latch
	signal bc_code: std_logic_vector(CONST_CODE_LENGTH - 1 downto 0);
	signal bc_ready, bc_valid, bc_last: std_logic;
	signal bc_code_length: std_logic_vector(CONST_CODE_BITS - 1 downto 0);
	signal bc_coord: coordinate_bounds_array_t;
	
	--state machine to output big codes correctly
	type output_fsm_t is (BOTTOM_64, TOP_64);
	signal state_curr, state_next: output_fsm_t;
begin
	
	preprocess_and_select: process(axis_in_flush_bit, axis_in_ihe, axis_in_k, axis_in_mqi, axis_in_input_symbol, axis_in_code_quant, axis_in_is_tree,
			axis_in_gol_code, axis_in_gol_param, axis_in_threshold, cfg_u_max)
	begin
		if (axis_in_flush_bit(1) = '1') then
			axis_in_code_length <= (0 => '1', others => '0');
			axis_in_code <= (0 => axis_in_flush_bit(0), others => '0');
		else
			axis_in_code_length <= (others => '0');
			axis_in_code <= (others => '0');
		end if;
		--do we golomb code?
		axis_in_code_gol <= '0';	
		axis_in_gol_param <= (others => '0');
		axis_in_gol_code <= (others => '0');
		axis_in_code_cw <= '0';	
		if axis_in_ihe = '1' then
			axis_in_code_gol <= '1';
			axis_in_gol_param <= axis_in_k;
			axis_in_gol_code <= axis_in_mqi;	
		else
			if (axis_in_input_symbol = CONST_INPUT_SYMBOL_X) then
				axis_in_code_gol <= '1';
				axis_in_gol_param <= (others => '0');
				axis_in_gol_code <= axis_in_code_quant;
			end if;
			if axis_in_is_tree(0) = '0' then
				axis_in_code_cw <= '1';
			end if;
		end if;
		axis_in_threshold <= std_logic_vector(shift_right(unsigned(axis_in_gol_code), to_integer(unsigned(axis_in_gol_param))));
		if (unsigned(axis_in_threshold) < unsigned(cfg_u_max)) then
			axis_in_threshold_under_umax <= '1';
		else
			axis_in_threshold_under_umax <= '0';
		end if;
	end process;

	fs_latch: entity work.AXIS_DATA_LATCH 
		Generic map (
			DATA_WIDTH => CONST_CODE_LENGTH,
			USER_WIDTH => 1 + CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data	=> axis_in_code,
			input_ready => axis_in_ready,
			input_valid => axis_in_valid,
			input_user(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_in_threshold_under_umax,
			input_user(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_in_threshold,
			input_user(coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_in_coord,
			input_user(CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_in_code_length,
			input_user(CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_in_code_gol,
			input_user(CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_in_gol_param,
			input_user(CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_in_gol_code,
			input_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => axis_in_code_cw,
			input_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_LENGTH_BITS)  => axis_in_cw_bits,
			input_user(CONST_CODEWORD_LENGTH_BITS - 1 downto 0)  => axis_in_cw_length,
			input_last => axis_in_last,
			output_data	=> fs_code,
			output_ready=> fs_ready,
			output_valid=> fs_valid,
			output_user(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_threshold_under_umax,
			output_user(CONST_MQI_BITS + coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_threshold,
			output_user(coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_coord,
			output_user(CONST_CODE_BITS + 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_code_length,
			output_user(CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_code_gol,
			output_user(CONST_MAX_K_BITS + CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_gol_param,
			output_user(CONST_MQI_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_gol_code,
			output_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_code_cw,
			output_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_LENGTH_BITS)  => fs_cw_bits,
			output_user(CONST_CODEWORD_LENGTH_BITS - 1 downto 0)  => fs_cw_length,
			output_last => fs_last
		);

	golomb_code: process(fs_code_length, fs_code, fs_code_gol, fs_gol_code, fs_gol_param, cfg_u_max, cfg_depth, fs_threshold_under_umax, fs_threshold)
		variable add_code_length: unsigned(CONST_CODE_BITS - 1 downto 0); --0 to 86 (up to 127 OK)
		variable code_length: unsigned(CONST_CODE_BITS - 1 downto 0); --0 to 86 (up to 127 OK)
		variable code: unsigned(CONST_CODE_LENGTH - 1 downto 0);
		variable temp: unsigned(CONST_CODE_LENGTH - 1 downto 0);
		variable temp_mask: unsigned(CONST_CODE_LENGTH - 1 downto 0);
	begin
		code_length := unsigned(fs_code_length);
		code := unsigned(fs_code);
		
		if fs_code_gol = '1' then
			if fs_threshold_under_umax = '1' then
				add_code_length := 1 + unsigned(fs_gol_param) + resize(unsigned(fs_threshold), CONST_CODE_BITS);
				temp_mask := (others => '1');
				temp_mask := not shift_left(temp_mask, to_integer(add_code_length));
				temp := resize(unsigned(fs_gol_code) & "1", CONST_CODE_LENGTH);
				temp := shift_left(temp, to_integer(unsigned(fs_threshold(CONST_U_MAX_BITS - 1 downto 0))));
				temp := temp and temp_mask;
				
				code := shift_left(code, to_integer(add_code_length)) or temp;
				code_length := code_length + add_code_length;
			else
				code_length := code_length + unsigned(cfg_u_max) + unsigned(cfg_depth);
				code := shift_left(shift_left(code, to_integer(unsigned(cfg_depth))) or resize(unsigned(fs_gol_code), code'length), to_integer(unsigned(cfg_u_max)));
			end if;
		end if;
		
		fs_updated_code_length <= std_logic_vector(code_length);
		fs_updated_code <= std_logic_vector(code);
	end process;
	
	ss_latch: entity work.AXIS_DATA_LATCH 
		Generic map (
			DATA_WIDTH => CONST_CODE_LENGTH,
			USER_WIDTH => coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data	=> fs_updated_code,
			input_ready => fs_ready,
			input_valid => fs_valid,
			input_user(coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODE_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_coord,
			input_user(CONST_CODE_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_updated_code_length,
			input_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => fs_code_cw,
			input_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_LENGTH_BITS)  => fs_cw_bits,
			input_user(CONST_CODEWORD_LENGTH_BITS - 1 downto 0)  => fs_cw_length,
			input_last => fs_last,
			output_data	=> ss_code,
			output_ready=> ss_ready,
			output_valid=> ss_valid,
			output_user(coordinate_bounds_array_t'length + CONST_CODE_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODE_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ss_coord,
			output_user(CONST_CODE_BITS + 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto 1 + CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ss_code_length,
			output_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS)  => ss_code_cw,
			output_user(CONST_CODEWORD_BITS + CONST_CODEWORD_LENGTH_BITS - 1 downto CONST_CODEWORD_LENGTH_BITS)  => ss_cw_bits,
			output_user(CONST_CODEWORD_LENGTH_BITS - 1 downto 0)  => ss_cw_length,
			output_last	=> ss_last
		);
		
	add_final_cw: process(ss_code_length, ss_code, ss_cw_length, ss_cw_bits, ss_code_cw)
	begin
		if ss_code_cw = '1' then
			ss_updated_code_length <= std_logic_vector(unsigned(ss_code_length) + unsigned(ss_cw_length));
			ss_updated_code <= std_logic_vector(shift_left(unsigned(ss_code), to_integer(unsigned(ss_cw_length))) or resize(unsigned(ss_cw_bits), CONST_CODE_LENGTH));
		else
			ss_updated_code_length <= ss_code_length;
			ss_updated_code <= ss_code;
		end if;
	end process;	
	
	big_code_bits_latch: entity work.AXIS_LATCHED_CONNECTION
		Generic map (
			DATA_WIDTH => CONST_CODE_LENGTH,
			USER_WIDTH => CONST_CODE_BITS + coordinate_bounds_array_t'length
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data =>  ss_updated_code,
			input_ready => ss_ready,
			input_valid => ss_valid,
			input_user(CONST_CODE_BITS + coordinate_bounds_array_t'length - 1 downto coordinate_bounds_array_t'length) => ss_updated_code_length,
			input_user(coordinate_bounds_array_t'length - 1 downto 0)  => ss_coord,
			input_last	=> ss_last,
			output_data	=> bc_code,
			output_ready=> bc_ready,
			output_valid=> bc_valid,
			output_user(CONST_CODE_BITS + coordinate_bounds_array_t'length - 1 downto coordinate_bounds_array_t'length) => bc_code_length,
			output_user(coordinate_bounds_array_t'length - 1 downto 0) => bc_coord,
			output_last => bc_last
		);
		
	seq: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state_curr <= BOTTOM_64;
			else
				state_curr <= state_next;
			end if;
		end if;
	end process;
	
	comb: process(state_curr, bc_code, bc_code_length, bc_valid, axis_out_ready, bc_coord, bc_last)
	begin
		state_next <= state_curr;
		axis_out_coord <= bc_coord;
		axis_out_last <= bc_last;
		
		if state_curr = BOTTOM_64 then
			if unsigned(bc_code_length) <= CONST_OUTPUT_CODE_LENGTH then
				axis_out_code <= bc_code(CONST_OUTPUT_CODE_LENGTH-1 downto 0);
				axis_out_length <= bc_code_length;
				axis_out_valid <= bc_valid;
				bc_ready <= axis_out_ready;
			else
				axis_out_code <= bc_code(CONST_OUTPUT_CODE_LENGTH-1 downto 0);
				axis_out_length <= std_logic_vector(to_unsigned(CONST_OUTPUT_CODE_LENGTH, axis_out_length'length));
				axis_out_valid <= bc_valid;
				bc_ready <= '0'; --dont want to make this guy think it's over
				axis_out_last <= '0';
				if bc_valid = '1' and axis_out_ready = '1' then
					state_next <= TOP_64;
				end if;
			end if;
		elsif state_curr = TOP_64 then
			axis_out_code <= std_logic_vector(resize(shift_right(unsigned(bc_code), CONST_OUTPUT_CODE_LENGTH), CONST_OUTPUT_CODE_LENGTH));
			axis_out_length <= std_logic_vector(unsigned(bc_code_length) - CONST_OUTPUT_CODE_LENGTH);
			axis_out_valid <= bc_valid;
			bc_ready <= axis_out_ready;
			if bc_valid = '1' and axis_out_ready = '1' then
				state_next <= BOTTOM_64;
			end if;
		end if;
	end process;

end Behavioral;