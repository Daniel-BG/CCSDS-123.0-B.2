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
use work.ccsds_constants.all;
use work.ccsds_math_functions.all;

package ccsds_data_structures is
	--coordinate type
	type coordinate_bounds_t is record
		first_x: std_logic;
		first_y: std_logic;
		first_z: std_logic;
		last_x: std_logic;
		last_y: std_logic;
		last_z: std_logic;	
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
	
	
	subtype coordinate_bounds_array_t is std_logic_vector(5 downto 0);
	function CB2STDLV(cb: coordinate_bounds_t) return coordinate_bounds_array_t;
	function STDLV2CB(stdlv: coordinate_bounds_array_t) return coordinate_bounds_t;

end ccsds_data_structures;


package body ccsds_data_structures is
	--actual function bodies
	function CB2STDLV(cb: coordinate_bounds_t) return coordinate_bounds_array_t is
		variable stdlv: coordinate_bounds_array_t;
	begin
		stdlv := cb.first_x & cb.first_y & cb.first_z & cb.last_x & cb.last_y & cb.last_z;
		return stdlv;
	end function;
	
	function STDLV2CB(stdlv: coordinate_bounds_array_t) return coordinate_bounds_t is
		variable cb: coordinate_bounds_t;
	begin
		cb.first_x := stdlv(5);
		cb.first_y := stdlv(4);
		cb.first_z := stdlv(3);
		cb.last_x  := stdlv(2);
		cb.last_y  := stdlv(1);
		cb.last_z  := stdlv(0);
		return cb;
	end function;

end ccsds_data_structures;