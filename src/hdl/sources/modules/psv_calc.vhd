----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 10:35:38
-- Design Name: 
-- Module Name: psv_calc - Behavioral
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

entity psv_calc is
	Port (
		axis_in_drpsv_d 	: in std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
		axis_in_drpsv_ready	: out std_logic;
		axis_in_drpsv_valid	: in std_logic;
		axis_in_drpsv_coord : in coordinate_bounds_array_t;
		axis_out_psv_d 		: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_psv_ready	: in std_logic;
		axis_out_psv_valid	: out std_logic;
		axis_out_psv_coord 	: out coordinate_bounds_array_t
	);
end psv_calc;

architecture Behavioral of psv_calc is
begin
	
	axis_in_drpsv_ready <= axis_out_psv_ready;
	axis_out_psv_valid <= axis_in_drpsv_valid;
	axis_out_psv_d <= axis_in_drpsv_d(axis_out_psv_d'high downto 0);
	axis_out_psv_coord <= axis_in_drpsv_coord;

end Behavioral;
