----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.03.2021 10:22:21
-- Design Name: 
-- Module Name: math_functions - Behavioral
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

package ccsds_math_functions is
	--headers
	function BITS(invalue: integer) return integer;
	function MAX(a, b: integer) return integer;
	function MIN(a, b: integer) return integer;

end package ccsds_math_functions;

package body ccsds_math_functions is
	--actual function bodies
	function BITS(invalue: integer) return integer is
		variable i: integer := 1;
	begin
		while i <= 32 loop
			if invalue <= 2**i - 1 then
				return i;
			end if;
			i := i + 1;
		end loop;
		return -1;
	end function;
	
		
	function MAX(a, b: integer) return integer is
	begin
		if a > b then
			return a;
		else
			return b;
		end if;
	end function;
	
	function MIN(a, b: integer) return integer is
	begin
		if a < b then
			return a;
		else
			return b;
		end if;
	end function;

end ccsds_math_functions;