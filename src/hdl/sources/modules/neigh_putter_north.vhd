----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2021 12:36:27
-- Design Name: 
-- Module Name: neigh_putter_north - Behavioral
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

entity neigh_putter_north is
	Port ( 
		clk, rst		: in std_logic;
		axis_in_d		: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_coord	: in coordinate_bounds_array_t;
		axis_in_valid	: in std_logic;
		axis_in_ready	: out std_logic;
		axis_out_d		: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_valid	: out std_logic;
		axis_out_ready	: in std_logic
	);
end neigh_putter_north;

architecture Behavioral of neigh_putter_north is
	signal axis_in_flag: std_logic_vector(0 downto 0);
begin

	axis_in_flag(0) <= '0' when STDLV2CB(axis_in_coord).last_y = '0' or STDLV2CB(axis_in_coord).last_x = '1' or
								STDLV2CB(axis_in_coord).first_y = '0' or STDLV2CB(axis_in_coord).last_x = '0'
						 else '1';
	
	filter: entity work.AXIS_FILTER 
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			ELIMINATE_ON_UP => true,
			LATCH => false
		)
		Port map (
			clk => clk, rst	=> rst,
			input_valid		=> axis_in_valid,
			input_ready		=> axis_in_ready,
			input_data		=> axis_in_d,
			flag_valid		=> axis_in_valid,
			flag_ready		=> open,
			flag_data		=> axis_in_flag,
			--to output axi ports
			output_valid	=> axis_out_valid,
			output_ready	=> axis_out_ready,
			output_data		=> axis_out_d
		);

end Behavioral;
