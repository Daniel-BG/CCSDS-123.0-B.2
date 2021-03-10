----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.03.2021 09:18:41
-- Design Name: 
-- Module Name: predictor - Behavioral
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
use work.ccsds_data_structures.all;


entity predictor is
	generic (
		DATA_WIDTH: integer := 16
	);
	port (
		axis_output_d			: in std_logic_vector(DATA_WIDTH - 1 downto 0); --make sure we got enough space
		axis_output_flags 		: in coordinate_bounds_array_t; --stdlv
		axis_output_last		: in std_logic;
		axis_output_valid		: in std_logic;
		axis_output_ready		: out std_logic
	);
end predictor;

architecture Behavioral of predictor is

begin


end Behavioral;
