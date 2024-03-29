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
		clk, rst 			: in std_logic;
		cfg_wide_sum		: in std_logic;
		cfg_neighbor_sum	: in std_logic;
		cfg_smid 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_w 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_wd 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
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
 	signal cfg_smid_reg: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
 	signal cfg_wide_sum_reg, cfg_neighbor_sum_reg: std_logic;
begin

	identifier : process (rst, clk)
	begin
		if (rising_edge(clk)) then
			if rst = '1' then
				cfg_smid_reg <= cfg_smid;
				cfg_wide_sum_reg <= cfg_wide_sum;
				cfg_neighbor_sum_reg <= cfg_neighbor_sum;
			end if;
		end if;
	end process identifier;


	axis_out_w <= axis_in_w;
	axis_out_n <= axis_in_n;
	axis_out_nw <= axis_in_nw;
	axis_out_coord <= axis_in_coord;
	axis_out_valid <= axis_in_valid;
	axis_in_ready <= axis_out_ready;

	calc_ls: process(cfg_smid_reg, cfg_wide_sum_reg, cfg_neighbor_sum_reg, axis_in_coord, axis_in_w, axis_in_n, axis_in_ne, axis_in_nw, axis_in_wd)
	begin
		--calculate output
		if cfg_wide_sum_reg = '1' and cfg_neighbor_sum_reg = '1' then --WIDE NEIGHBOR
			if F_STDLV2CB(axis_in_coord).first_y = '0' and F_STDLV2CB(axis_in_coord).first_x = '0' and F_STDLV2CB(axis_in_coord).last_x = '0' then
				axis_out_ls <= std_logic_vector(
						resize(unsigned(axis_in_w),CONST_LSUM_BITS)  +
						resize(unsigned(axis_in_n),CONST_LSUM_BITS) + 
						resize(unsigned(axis_in_ne),CONST_LSUM_BITS) + 
						resize(unsigned(axis_in_nw),CONST_LSUM_BITS)
					);
			elsif F_STDLV2CB(axis_in_coord).first_y = '1' and F_STDLV2CB(axis_in_coord).first_x = '0' then
				axis_out_ls <= std_logic_vector(
						resize(unsigned(unsigned(axis_in_w) & "00"), CONST_LSUM_BITS)
					);
			elsif F_STDLV2CB(axis_in_coord).first_y = '0' and F_STDLV2CB(axis_in_coord).first_x = '1' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_n) & "0"),CONST_LSUM_BITS) + 
					resize(unsigned(unsigned(axis_in_ne) & "0"),CONST_LSUM_BITS)
				);
			elsif F_STDLV2CB(axis_in_coord).first_y = '0' and F_STDLV2CB(axis_in_coord).last_x = '1' then
				axis_out_ls <= std_logic_vector(
						resize(unsigned(axis_in_w), CONST_LSUM_BITS)  +
						resize(unsigned(unsigned(axis_in_n) & "0"),CONST_LSUM_BITS) + 
						resize(unsigned(axis_in_nw),CONST_LSUM_BITS)
					);
			else --t = 0
				axis_out_ls <= (others => '0');
			end if;
		elsif cfg_wide_sum_reg = '1' and cfg_neighbor_sum_reg = '0' then --WIDE COLUMN
			if F_STDLV2CB(axis_in_coord).first_y = '0' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_n) & "00"), CONST_LSUM_BITS)
				);
			elsif F_STDLV2CB(axis_in_coord).first_y = '1' and F_STDLV2CB(axis_in_coord).first_x = '0' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_w) & "00"), CONST_LSUM_BITS)
				);
			else --t = 0
				axis_out_ls <= (others => '0');
			end if;
		elsif cfg_wide_sum_reg = '0' and cfg_neighbor_sum_reg = '1' then --NARROW NEIGHBOR
			if F_STDLV2CB(axis_in_coord).first_y = '0' and F_STDLV2CB(axis_in_coord).first_x = '0' and F_STDLV2CB(axis_in_coord).last_x = '0' then
				axis_out_ls <= std_logic_vector(
						resize(unsigned(axis_in_ne), CONST_LSUM_BITS)  +
						resize(unsigned(unsigned(axis_in_n) & "0"),CONST_LSUM_BITS) + 
						resize(unsigned(axis_in_nw),CONST_LSUM_BITS)
					);
			elsif F_STDLV2CB(axis_in_coord).first_y = '1' and F_STDLV2CB(axis_in_coord).first_x = '0' and F_STDLV2CB(axis_in_coord).first_z = '0' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_wd) & "00"), CONST_LSUM_BITS)
				);
			elsif F_STDLV2CB(axis_in_coord).first_y = '0' and F_STDLV2CB(axis_in_coord).first_x = '1' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_n) & "0"),CONST_LSUM_BITS) + 
					resize(unsigned(unsigned(axis_in_ne) & "0"),CONST_LSUM_BITS)
				);
			elsif F_STDLV2CB(axis_in_coord).first_y = '0' and F_STDLV2CB(axis_in_coord).last_x = '1' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_n) & "0"),CONST_LSUM_BITS) + 
					resize(unsigned(unsigned(axis_in_nw) & "0"),CONST_LSUM_BITS)
				);
			elsif F_STDLV2CB(axis_in_coord).first_y = '1' and F_STDLV2CB(axis_in_coord).first_x = '0' and F_STDLV2CB(axis_in_coord).first_z = '1' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(cfg_smid_reg) & "00"), CONST_LSUM_BITS)
				);
			else
				axis_out_ls <= (others => '0');
			end if;
		else -- cfg_wide_sum_reg = '0' and cfg_neighbor_sum_reg = '0' then --NARROW COLUMN
			if F_STDLV2CB(axis_in_coord).first_y = '0' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_n) & "00"), CONST_LSUM_BITS)
				);
			elsif F_STDLV2CB(axis_in_coord).first_y = '1' and F_STDLV2CB(axis_in_coord).first_x = '0' and F_STDLV2CB(axis_in_coord).first_z = '0' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(axis_in_wd) & "00"), CONST_LSUM_BITS)
				);
			elsif F_STDLV2CB(axis_in_coord).first_y = '1' and F_STDLV2CB(axis_in_coord).first_x = '0' and F_STDLV2CB(axis_in_coord).first_z = '1' then
				axis_out_ls <= std_logic_vector(
					resize(unsigned(unsigned(cfg_smid_reg) & "00"), CONST_LSUM_BITS)
				);
			else
				axis_out_ls <= (others => '0');
			end if;
		end if;
		
	end process;
	
end Behavioral;