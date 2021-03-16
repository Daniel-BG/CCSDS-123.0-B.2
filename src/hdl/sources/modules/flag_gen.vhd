----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.03.2021 11:54:45
-- Design Name: 
-- Module Name: flag_gen - Behavioral
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
use work.ccsds_data_structures.all;
use work.ccsds_constants.all;

entity flag_gen is
	port (
		cfg_max_x				: in std_logic_vector(CONST_MAX_X_BITS - 1 downto 0);
		cfg_max_y				: in std_logic_vector(CONST_MAX_Y_BITS - 1 downto 0);
		cfg_max_z				: in std_logic_vector(CONST_MAX_Z_BITS - 1 downto 0);
		axis_input_x			: in std_logic_vector(CONST_MAX_X_BITS - 1 downto 0);
		axis_input_y			: in std_logic_vector(CONST_MAX_Y_BITS - 1 downto 0);
		axis_input_z			: in std_logic_vector(CONST_MAX_Z_BITS - 1 downto 0);
		axis_input_ready		: out std_logic;
		axis_input_valid		: in std_logic;
		axis_input_last 		: in std_logic;
		axis_output_ready		: in std_logic;
		axis_output_valid 		: out std_logic;
		axis_output_last 		: out std_logic;
		axis_output_flags 		: out coordinate_bounds_array_t
	);
end flag_gen;

architecture Behavioral of flag_gen is
	
	signal axis_output_last_x 		: std_logic;
	signal axis_output_first_x		: std_logic;
	signal axis_output_last_y 		: std_logic;
	signal axis_output_first_y		: std_logic;
	signal axis_output_last_z 		: std_logic;
	signal axis_output_first_z		: std_logic;
	
	
begin

	axis_output_valid <= axis_input_valid;
	axis_input_ready  <= axis_output_ready;
	
	
	axis_output_first_x <= '1' when axis_input_x = (axis_input_x'range => '0') else '0';
	axis_output_last_x  <= '1' when axis_input_x = cfg_max_x else '0';
	axis_output_first_y <= '1' when axis_input_y = (axis_input_y'range => '0') else '0';
	axis_output_last_y  <= '1' when axis_input_y = cfg_max_y else '0';
	axis_output_first_z <= '1' when axis_input_z = (axis_input_z'range => '0') else '0';
	axis_output_last_z  <= '1' when axis_input_z = cfg_max_z else '0';
	
	axis_output_flags <= axis_output_first_x & axis_output_first_y & axis_output_first_z & axis_output_last_x & axis_output_last_y & axis_output_last_z;
	
	axis_output_last <= axis_input_last;
	

end Behavioral;
