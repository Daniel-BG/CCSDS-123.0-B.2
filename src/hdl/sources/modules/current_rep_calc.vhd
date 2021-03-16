----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2021 11:26:54
-- Design Name: 
-- Module Name: current_rep_calc - Behavioral
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

entity current_rep_calc is
	Port ( 
		clk, rst			: in std_logic;
		axis_s_d			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_s_valid		: in std_logic;
		axis_s_ready		: out std_logic;
		axis_drsr_d			: in std_logic_vector(CONST_DRSR_BITS - 1 downto 0);
		axis_drsr_coord		: in coordinate_bounds_array_t;
		axis_drsr_valid 	: in std_logic;
		axis_drsr_ready 	: out std_logic;
		axis_out_cr_d   	: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_cr_valid 	: out std_logic;
		axis_out_cr_ready	: in std_logic;
		axis_out_cr_coord	: out coordinate_bounds_array_t
	);
end current_rep_calc;

architecture Behavioral of current_rep_calc is

	signal axis_out_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_out_drsr: std_logic_vector(CONST_DRSR_BITS - 1 downto 0);
	signal axis_out_coord: coordinate_bounds_array_t;

begin

	sync: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_MAX_DATA_WIDTH,
			DATA_WIDTH_1 => CONST_DRSR_BITS,
			LATCH		 => false,
			USER_WIDTH 	 => coordinate_bounds_array_t'length,
			USER_POLICY  => PASS_ONE
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid	=> axis_s_valid,
			input_0_ready 	=> axis_s_ready,
			input_0_data	=> axis_s_d,
			input_1_valid	=> axis_drsr_valid,
			input_1_ready	=> axis_drsr_ready,
			input_1_data 	=> axis_drsr_d,
			input_1_user 	=> axis_drsr_coord,
			--to output axi ports
			output_valid	=> axis_out_cr_valid,
			output_ready	=> axis_out_cr_ready,
			output_data_0	=> axis_out_d,
			output_data_1	=> axis_out_drsr,
			output_user		=> axis_out_coord
		);
		axis_out_cr_coord <= axis_out_coord;
		axis_out_cr_d <= axis_out_d when STDLV2CB(axis_out_coord).first_x = '1' and STDLV2CB(axis_out_coord).first_y = '1' else
			 std_logic_vector(resize(shift_right(unsigned(axis_out_drsr) + 1, 1), CONST_MAX_DATA_WIDTH));


end Behavioral;
