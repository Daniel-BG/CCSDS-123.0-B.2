----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2021 11:46:16
-- Design Name: 
-- Module Name: current_diff_calc - Behavioral
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

entity current_diff_calc is
	Port ( 
		clk, rst			: in std_logic;
		axis_repr_d			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_repr_valid		: in std_logic;
		axis_repr_ready		: out std_logic;
		axis_repr_coord		: in coordinate_bounds_array_t;
		axis_ls_d			: in std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
		axis_ls_valid		: in std_logic;
		axis_ls_ready		: out std_logic;
		axis_out_cd_d		: out std_logic_vector(CONST_LDIF_BITS - 1 downto 0);
		axis_out_cd_valid	: out std_logic;
		axis_out_cd_ready	: in std_logic;
		axis_out_cd_coord	: out coordinate_bounds_array_t
	);
end current_diff_calc;

architecture Behavioral of current_diff_calc is
	signal axis_out_repr: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_out_ls: std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
	signal axis_out_coord: coordinate_bounds_array_t;
begin

	sync: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_MAX_DATA_WIDTH,
			DATA_WIDTH_1 => CONST_LSUM_BITS,
			LATCH		 => false,
			USER_WIDTH	 => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_repr_valid,
			input_0_ready => axis_repr_ready,
			input_0_data  => axis_repr_d,
			input_0_user  => axis_repr_coord,
			input_1_valid => axis_ls_valid,
			input_1_ready => axis_ls_ready,
			input_1_data  => axis_ls_d,
			--to output axi ports
			output_valid  => axis_out_cd_valid,
			output_ready  => axis_out_cd_ready,
			output_data_0 => axis_out_repr,
			output_data_1 => axis_out_ls,
			output_user	  => axis_out_coord
		);
		axis_out_cd_coord <= axis_out_coord;
		axis_out_cd_d <= std_logic_vector(signed("000" & unsigned(axis_out_repr)) - signed("0" & unsigned(axis_out_ls)));

end Behavioral;
