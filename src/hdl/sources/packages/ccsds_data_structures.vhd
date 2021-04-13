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
		x: std_logic_vector (BITS(CONST_MAX_X_VALUE) - 1 downto 0);
		y: std_logic_vector (BITS(CONST_MAX_Y_VALUE) - 1 downto 0);
		z: std_logic_vector (BITS(CONST_MAX_Z_VALUE) - 1 downto 0);
		t: std_logic_vector (BITS(CONST_MAX_T_VALUE) - 1 downto 0);
	end record coordinate_position_t;

	type coordinate_t is record
		bounds: coordinate_bounds_t;
		position: coordinate_position_t;
	end record coordinate_t;
	
	
	subtype coordinate_bounds_array_t is std_logic_vector(5 downto 0);
	function CB2STDLV(cb: coordinate_bounds_t) return coordinate_bounds_array_t;
	function STDLV2CB(stdlv: coordinate_bounds_array_t) return coordinate_bounds_t;
	subtype coordinate_position_array_t is std_logic_vector(BITS(CONST_MAX_X_VALUE)+ BITS(CONST_MAX_Y_VALUE) + BITS(CONST_MAX_Z_VALUE) + BITS(CONST_MAX_T_VALUE) - 1 downto 0);
	function CP2STDLV(cp: coordinate_position_t) return coordinate_position_array_t;
	function STDLV2CP(stdlv: coordinate_position_array_t) return coordinate_position_t;
	subtype coordinate_array_t is std_logic_vector(BITS(CONST_MAX_X_VALUE)+ BITS(CONST_MAX_Y_VALUE) + BITS(CONST_MAX_Z_VALUE) + BITS(CONST_MAX_T_VALUE) + 6 - 1 downto 0);
	function C2STDLV(ca: coordinate_t) return coordinate_array_t;
	function STDLV2C(stdlv: coordinate_array_t) return coordinate_t;
	
	--first is if it flushes (1) second is the bit itself
	subtype flush_bit_t is std_logic_vector (1 downto 0);  

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
	
	
	function CP2STDLV(cp: coordinate_position_t) return coordinate_position_array_t is
		variable stdlv: coordinate_position_array_t;
	begin
		stdlv := cp.x & cp.y & cp.z & cp.t;
		return stdlv;
	end function;
	
	function STDLV2CP(stdlv: coordinate_position_array_t) return coordinate_position_t is
		variable cp: coordinate_position_t;
	begin
		cp.x := stdlv(stdlv'high downto stdlv'high + 1 - BITS(CONST_MAX_X_VALUE));
		cp.y := stdlv(stdlv'high - BITS(CONST_MAX_X_VALUE) downto stdlv'high + 1 - BITS(CONST_MAX_X_VALUE) - BITS(CONST_MAX_Y_VALUE));
		cp.z := stdlv(BITS(CONST_MAX_Z_VALUE) + BITS(CONST_MAX_T_VALUE) - 1 downto BITS(CONST_MAX_T_VALUE));
		cp.t := stdlv(BITS(CONST_MAX_T_VALUE) - 1 downto 0);
		return cp;
	end function;
	
	
	function C2STDLV(ca: coordinate_t) return coordinate_array_t is
		variable stdlv: coordinate_array_t;
	begin
		stdlv := CP2STDLV(ca.position) & CB2STDLV(ca.bounds);
		return stdlv;
	end function;
	
	function STDLV2C(stdlv: coordinate_array_t) return coordinate_t is
		variable c: coordinate_t;
	begin
		c.position := STDLV2CP(stdlv(stdlv'high downto coordinate_bounds_array_t'length));
		c.bounds := STDLV2CB(stdlv(coordinate_bounds_array_t'length - 1 downto 0));
		return c;
	end function;

end ccsds_data_structures;