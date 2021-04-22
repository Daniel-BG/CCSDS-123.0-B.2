----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.03.2021 09:19:04
-- Design Name: 
-- Module Name: local_sum_calc - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.ccsds_data_structures.all;
use work.ccsds_constants.all;

entity local_difference_calc is
	port (
		axis_in_w 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_nw 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_n 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_ls 			: in std_logic_vector(CONST_LSUM_BITS - 1 downto 0);
		axis_in_ready 		: out std_logic;
		axis_in_valid 		: in std_logic;
		axis_in_coord 		: in coordinate_bounds_array_t;
		axis_out_nd 		: out std_logic_vector(CONST_LDIF_BITS-1 downto 0);
		axis_out_nwd 		: out std_logic_vector(CONST_LDIF_BITS-1 downto 0);
		axis_out_wd 		: out std_logic_vector(CONST_LDIF_BITS-1 downto 0);
		axis_out_ready 		: in std_logic;
		axis_out_valid 		: out std_logic;
		axis_out_coord		: out coordinate_bounds_array_t
	);
end local_difference_calc;

architecture Behavioral of local_difference_calc is
begin

	axis_out_valid <= axis_in_valid;
	axis_in_ready <= axis_out_ready;
	axis_out_coord <= axis_in_coord;
	
	comb: process(axis_in_coord, axis_in_n, axis_in_nw, axis_in_w, axis_in_ls)
	begin
		--calculate output
		if F_STDLV2CB(axis_in_coord).first_x = '0' and F_STDLV2CB(axis_in_coord).first_y = '0' then
			axis_out_nd <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_n) & "00"),CONST_LDIF_BITS)  -
					resize(unsigned(axis_in_ls),CONST_LDIF_BITS)
				);
			axis_out_wd <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_w) & "00"),CONST_LDIF_BITS)  -
					resize(unsigned(axis_in_ls),CONST_LDIF_BITS)
				);
			axis_out_nwd <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_nw) & "00"),CONST_LDIF_BITS)  -
					resize(unsigned(axis_in_ls),CONST_LDIF_BITS)
				);
		elsif F_STDLV2CB(axis_in_coord).first_x = '1' and F_STDLV2CB(axis_in_coord).first_y = '0' then
			axis_out_nd <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_n) & "00"),CONST_LDIF_BITS)  -
					resize(unsigned(axis_in_ls),CONST_LDIF_BITS)
				);
			axis_out_wd <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_n) & "00"),CONST_LDIF_BITS)  -
					resize(unsigned(axis_in_ls),CONST_LDIF_BITS)
				);
			axis_out_nwd <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_n) & "00"),CONST_LDIF_BITS)  -
					resize(unsigned(axis_in_ls),CONST_LDIF_BITS)
				);
		else
			axis_out_nd 	<= (others => '0');
			axis_out_wd 	<= (others => '0');
			axis_out_nwd 	<= (others => '0');
		end if;
	
	end process;
end Behavioral;