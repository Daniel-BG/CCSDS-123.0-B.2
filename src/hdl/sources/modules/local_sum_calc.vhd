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

entity local_sum_calc is
	port (
		cfg_sum_type 		: in local_sum_t;
		axis_in_w 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_nw 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_n 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_ne	 		: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_ready 		: out std_logic;
		axis_in_valid 		: in std_logic;
		axis_in_coord 		: in coordinate_bounds_array_t;
		axis_out_w			: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_n			: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_nw			: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_ls 		: out std_logic_vector(CONST_LSUM_BITS-1 downto 0);
		axis_out_ready 		: in std_logic;
		axis_out_valid 		: out std_logic;
		axis_out_coord		: out coordinate_bounds_array_t
	);
end local_sum_calc;

architecture Behavioral of local_sum_calc is

begin

	axis_out_w <= axis_in_w;
	axis_out_n <= axis_in_n;
	axis_out_nw <= axis_in_nw;
	axis_out_coord <= axis_in_coord;
	axis_out_valid <= axis_in_valid;
	axis_in_ready <= axis_out_ready;

	calc_ls: process(cfg_sum_type, axis_in_coord, axis_in_w, axis_in_n, axis_in_ne, axis_in_nw)
	begin
		--calculate output
		if cfg_sum_type = WIDE_NEIGHBOR_ORIENTED then
			if STDLV2CB(axis_in_coord).first_y = '0' and STDLV2CB(axis_in_coord).first_x = '0' and STDLV2CB(axis_in_coord).last_x = '0' then
				axis_out_ls <= std_logic_vector(
						resize(unsigned(axis_in_w),CONST_LSUM_BITS)  +
						resize(unsigned(axis_in_n),CONST_LSUM_BITS) + 
						resize(unsigned(axis_in_ne),CONST_LSUM_BITS) + 
						resize(unsigned(axis_in_nw),CONST_LSUM_BITS)
					);
			elsif STDLV2CB(axis_in_coord).first_y = '1' and STDLV2CB(axis_in_coord).first_x = '0' then
				axis_out_ls <= std_logic_vector(
						resize(unsigned(axis_in_w & "00"), CONST_LSUM_BITS)
					);
			elsif STDLV2CB(axis_in_coord).first_y = '0' and STDLV2CB(axis_in_coord).first_x = '1' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(axis_in_n & "0"),CONST_LSUM_BITS) + 
					resize(unsigned(axis_in_ne & "0"),CONST_LSUM_BITS)
				);
			elsif STDLV2CB(axis_in_coord).first_y = '0' and STDLV2CB(axis_in_coord).last_x = '1' then
				axis_out_ls <= std_logic_vector(
						resize(unsigned(axis_in_w),CONST_LSUM_BITS)  +
						resize(unsigned(axis_in_n & "0"),CONST_LSUM_BITS) + 
						resize(unsigned(axis_in_nw),CONST_LSUM_BITS)
					);
			else --t = 0
				axis_out_ls <= (others => '0');
			end if;
		elsif cfg_sum_type = WIDE_COLUMN_ORIENTED then
			if STDLV2CB(axis_in_coord).first_y = '0' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(axis_in_n & "00"), CONST_LSUM_BITS)
				);
			elsif STDLV2CB(axis_in_coord).first_y = '1' and STDLV2CB(axis_in_coord).first_x = '0' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(axis_in_w & "00"), CONST_LSUM_BITS)
				);
			else --t = 0
				axis_out_ls <= (others => '0');
			end if;
		end if;
		
	end process;
	
end Behavioral;