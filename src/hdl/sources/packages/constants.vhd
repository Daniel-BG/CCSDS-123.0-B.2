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

package constants is
	--FIXED CONSTANTS
	constant CONST_MAX_X: integer := 512;
	constant CONST_MAX_Y: integer := 512;
	constant CONST_MAX_Z: integer := 512;  
	
	
	--DERIVED CONSTANTS
	constant CONST_MAX_T: integer := CONST_MAX_Y * CONST_MAX_X;

end constants;

