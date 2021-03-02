----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.03.2021 10:29:44
-- Design Name: 
-- Module Name: data_structures - Behavioral
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
use work.constants.all;
use work.math_functions.all;

package data_structures is
	--coordinate type
	type coordinate_bounds_t is record
		first_line: std_logic;
		first_sample: std_logic;
		first_band: std_logic;
		last_line: std_logic;
		last_sample: std_logic;
		last_band: std_logic;	
	end record coordinate_bounds_t;
	
	type coordinate_position_t is record
		x: std_logic_vector (BITS(CONST_MAX_X) - 1 downto 0);
		y: std_logic_vector (BITS(CONST_MAX_Y) - 1 downto 0);
		z: std_logic_vector (BITS(CONST_MAX_Z) - 1 downto 0);
		t: std_logic_vector (BITS(CONST_MAX_T) - 1 downto 0);
	end record coordinate_position_t;

	type coordinate_t is record
		bounds: coordinate_bounds_t;
		position: coordinate_position_t;
	end record coordinate_t;

end data_structures;
