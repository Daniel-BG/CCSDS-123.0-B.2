----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 11:52:26
-- Design Name: 
-- Module Name: mev_calc - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.am_functions.all;
use work.ccsds_constants.all;
use work.ccsds_data_structures.all;
use work.am_data_types.all;

--made for global ABS and REL errors
--to change to local (depending on bands), two additional axis ports are needed for both the relative and absolute errors
--then, both of them need to feed from an axis_conditioned_selector to take from the input queue, and then from the buffer queue
entity mev_calc is
	Port ( 
		clk, rst 			: in std_logic;
		cfg_use_abs_err		: in std_logic;
		cfg_use_rel_err		: in std_logic;
		cfg_abs_err 		: in std_logic_vector(CONST_ABS_ERR_BITS - 1 downto 0);
		cfg_rel_err 		: in std_logic_vector(CONST_REL_ERR_BITS - 1 downto 0);
		axis_in_psv_valid	: in std_logic;
		axis_in_psv_ready	: out std_logic;
		axis_in_psv_d		: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_psv_coord	: in coordinate_bounds_array_t;
		axis_out_mev_d 		: out std_logic_vector(CONST_MEV_BITS - 1 downto 0);
		axis_out_mev_valid 	: out std_logic;
		axis_out_mev_ready 	: in std_logic
	);
end mev_calc;

architecture Behavioral of mev_calc is
	signal rel_err_out: std_logic_vector(CONST_REL_ERR_BITS + CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal rel_err_out_shifted: std_logic_vector(CONST_REL_ERR_BITS - 1 downto 0);
	signal rel_err_valid, rel_err_ready: std_logic;
	signal rel_err_coord: coordinate_bounds_array_t;
	
	
begin


	calc_rel_err: entity work.AXIS_MULTIPLIER
		generic map (
			DATA_WIDTH_0	=> CONST_REL_ERR_BITS,
			DATA_WIDTH_1	=> CONST_MAX_DATA_WIDTH,
			OUTPUT_WIDTH 	=> CONST_REL_ERR_BITS + CONST_MAX_DATA_WIDTH,
			SIGN_EXTEND_0	=> false,
			SIGN_EXTEND_1	=> false,
			SIGNED_OP	 	=> false,
			DESIRED_STAGES  => 3,
			USER_WIDTH 		=> coordinate_bounds_array_t'length,
			USER_POLICY 	=> PASS_ONE
		)
		port map(
			clk => clk, rst => rst,
			input_0_data	=> cfg_rel_err,
			input_0_valid	=> '1',
			input_0_ready	=> open,
			input_1_data	=> axis_in_psv_d,
			input_1_valid	=> axis_in_psv_valid,
			input_1_ready	=> axis_in_psv_ready,
			input_1_user    => axis_in_psv_coord,
			output_data		=> rel_err_out,
			output_valid	=> rel_err_valid,
			output_ready	=> rel_err_ready,
			output_user 	=> rel_err_coord
		);
		
		rel_err_out_shifted <= rel_err_out(rel_err_out'high downto CONST_MAX_DATA_WIDTH);
		
		comb: process(rel_err_out_shifted, cfg_abs_err, axis_out_mev_ready, rel_err_valid, cfg_use_abs_err, cfg_use_rel_err)
		begin
			axis_out_mev_valid <= rel_err_valid;
			rel_err_ready <= axis_out_mev_ready;
			
			if STDLV2CB(rel_err_coord).first_x = '1' and STDLV2CB(rel_err_coord).first_y = '1' then
				axis_out_mev_d <= (others => '0');
			elsif cfg_use_abs_err = '1' and cfg_use_rel_err = '1' then
				--take minimum
				if resize(unsigned(cfg_abs_err), CONST_MAX_DATA_WIDTH) < resize(unsigned(rel_err_out_shifted), CONST_MAX_DATA_WIDTH) then
					axis_out_mev_d <= std_logic_vector(resize(unsigned(cfg_abs_err), CONST_MAX_DATA_WIDTH));
				else
					axis_out_mev_d <= std_logic_vector(resize(unsigned(rel_err_out_shifted), CONST_MAX_DATA_WIDTH));
				end if;
			elsif cfg_use_abs_err = '1' then
				axis_out_mev_d <= std_logic_vector(resize(unsigned(cfg_abs_err), CONST_MAX_DATA_WIDTH));
			elsif cfg_use_rel_err = '1' then
				axis_out_mev_d <= std_logic_vector(resize(unsigned(rel_err_out_shifted), CONST_MAX_DATA_WIDTH));
			else
				axis_out_mev_d <= (others => '0');
			end if;
		end process;
		


end Behavioral;