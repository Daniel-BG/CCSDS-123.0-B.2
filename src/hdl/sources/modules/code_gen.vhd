----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.03.2021 16:59:38
-- Design Name: 
-- Module Name: code_gen - Behavioral
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
use ieee.numeric_std.all;

entity code_gen is
	Port ( 
		cfg_u_max				: in std_logic_vector(CONST_U_MAX_BITS - 1 downto 0);
		cfg_depth				: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		axis_in_valid			: in std_logic;
		axis_in_ready			: out std_logic;
		axis_in_mqi				: in std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_in_k				: in std_logic_vector(CONST_MAX_K_BITS - 1 downto 0);
		axis_in_coord			: in coordinate_bounds_array_t;
		axis_out_code			: out std_logic_vector(CONST_MAX_CODE_LENGTH - 1 downto 0);
		axis_out_length			: out std_logic_vector(CONST_MAX_CODE_LENGTH_BITS - 1 downto 0);
		axis_out_coord			: out coordinate_bounds_array_t;
		axis_out_valid			: out std_logic;
		axis_out_ready			: in std_logic
	);
end code_gen;

architecture Behavioral of code_gen is

	signal and_mask, or_mask: std_logic_vector(CONST_MAX_CODE_LENGTH - 1 downto 0);

begin
	axis_out_valid <= axis_in_valid;
	axis_in_ready <= axis_out_ready;
	axis_out_coord <= axis_in_coord;
	axis_out_code <= (std_logic_vector(resize(unsigned(axis_in_mqi), CONST_MAX_CODE_LENGTH)) and and_mask) or or_mask;
	
	gen_out: process(axis_in_mqi, axis_in_k, cfg_u_max)
	begin
		if shift_right(unsigned(axis_in_mqi), to_integer(unsigned(axis_in_k))) < unsigned(cfg_u_max) then
			and_mask <= std_logic_vector(shift_left(to_signed(-1, and_mask'length), to_integer(unsigned(axis_in_k))));
			or_mask  <= std_logic_vector(shift_left(to_unsigned(1, or_mask'length), to_integer(unsigned(axis_in_k))));
			axis_out_length <= std_logic_vector(resize(shift_right(unsigned(axis_in_mqi), to_integer(unsigned(axis_in_k))) + 1 + unsigned(axis_in_k), CONST_MAX_CODE_LENGTH_BITS));
		else
			and_mask <= (others => '0');
			or_mask  <= (others => '0');
			axis_out_length <= std_logic_vector(resize(unsigned(cfg_u_max) + unsigned(cfg_depth), CONST_MAX_CODE_LENGTH_BITS));
		end if;
	end process;

end Behavioral;
