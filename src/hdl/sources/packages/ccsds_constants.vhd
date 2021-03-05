----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.03.2021 10:35:20
-- Design Name: 
-- Module Name: constants - Behavioral
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
use work.ccsds_math_functions.all;

package ccsds_constants is
	--IMAGE CONSTANTS

	--FIXED CONSTANTS
	constant CONST_MAX_X: integer := 512;
	constant CONST_MAX_Y: integer := 512;
	constant CONST_MAX_Z: integer := 512;  
	
	--DERIVED CONSTANTS
	constant CONST_MAX_T: integer := CONST_MAX_Y * CONST_MAX_X;
	
	constant CONST_MAX_X_BITS: integer := BITS(CONST_MAX_X);
	constant CONST_MAX_Y_BITS: integer := BITS(CONST_MAX_Y);
	constant CONST_MAX_Z_BITS: integer := BITS(CONST_MAX_Z);
	constant CONST_MAX_T_BITS: integer := BITS(CONST_MAX_T);
	
	--ALGORITM CONSTANTS
	constant CONST_MAX_D: integer := 16;
	constant CONST_OUT_BYTES: integer := 4;
	

end ccsds_constants;

