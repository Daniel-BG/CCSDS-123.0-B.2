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
	generic (
		DATA_WIDTH: integer := 16
	);
	port (
		clk, rst			: in std_logic;
		cfg_sum_type 		: in local_sum_t;
		axis_in_w 			: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_in_nw 			: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_in_n 			: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_in_ne	 		: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_in_ready 		: out std_logic;
		axis_in_valid 		: in std_logic;
		axis_in_coord_d 	: in coordinate_bounds_t;
		axis_in_coord_ready : out std_logic;
		axis_in_coord_valid : in std_logic;
		axis_out_d 			: out std_logic_vector(LSUM_WIDTH(DATA_WIDTH)-1 downto 0);
		axis_out_ready 		: in std_logic;
		axis_out_valid 		: out std_logic
	);
end local_sum_calc;

architecture Behavioral of local_sum_calc is
	type state_t is (IDLE, COORD_LOADED);
	signal state_curr, state_next: state_t;
	
	signal saved_coord, next_saved_coord: coordinate_bounds_t;
begin

	seq: process(clk, rst)
	begin
		if rst = '1' then
			state_curr <= IDLE;
			saved_coord <= (others => '0');
		elsif rising_edge(clk) then
			state_curr <= state_next;
			saved_coord <= next_saved_coord;
		end if;
	end process;
	
	
	comb: process(state_curr, axis_in_coord_valid, axis_out_ready, axis_in_valid, axis_in_coord_d, saved_coord, cfg_sum_type, axis_in_w, axis_in_n, axis_in_ne, axis_in_nw)
	begin
		axis_in_coord_ready <= '0';
		next_saved_coord <= saved_coord;
		axis_in_ready <= '0';
		axis_out_valid <= '0';
		state_next <= state_curr;
		
		--calculate state
		if state_curr = IDLE then
			axis_in_coord_ready <= '1';
			if (axis_in_coord_valid = '1') then
				next_saved_coord <= axis_in_coord_d;
				state_next <= COORD_LOADED;
			end if;
		elsif state_curr = COORD_LOADED then
			axis_in_ready <= axis_out_ready;
			axis_out_valid <= axis_in_valid;
			if axis_out_ready = '1' and axis_in_valid = '1' then
				axis_in_coord_ready <= '1';
				if (axis_in_coord_valid = '1') then
					next_saved_coord <= axis_in_coord_d;
					state_next <= COORD_LOADED;
				else
					state_next <= IDLE;
				end if;
			end if;
		end if;
		
		--calculate output
		if cfg_sum_type = WIDE_NEIGHBOR_ORIENTED then
			if saved_coord.first_y = '0' and saved_coord.first_x = '0' and saved_coord.last_x = '0' then
				axis_out_d <= std_logic_vector(
						resize(unsigned(axis_in_w),LSUM_WIDTH(DATA_WIDTH))  +
						resize(unsigned(axis_in_n),LSUM_WIDTH(DATA_WIDTH)) + 
						resize(unsigned(axis_in_ne),LSUM_WIDTH(DATA_WIDTH)) + 
						resize(unsigned(axis_in_nw),LSUM_WIDTH(DATA_WIDTH))
					);
			elsif saved_coord.first_y = '1' and saved_coord.first_x = '0' then
				axis_out_d <= std_logic_vector(
						resize(unsigned(axis_in_w & "00"), LSUM_WIDTH(DATA_WIDTH))
					);
			elsif saved_coord.first_y = '0' and saved_coord.first_x = '1' then
				axis_out_d <= std_logic_vector(
					resize(unsigned(axis_in_n & "0"),LSUM_WIDTH(DATA_WIDTH)) + 
					resize(unsigned(axis_in_ne & "0"),LSUM_WIDTH(DATA_WIDTH))
				);
			elsif saved_coord.first_y = '0' and saved_coord.last_x = '1' then
				axis_out_d <= std_logic_vector(
						resize(unsigned(axis_in_w),LSUM_WIDTH(DATA_WIDTH))  +
						resize(unsigned(axis_in_n & "0"),LSUM_WIDTH(DATA_WIDTH)) + 
						resize(unsigned(axis_in_nw),LSUM_WIDTH(DATA_WIDTH))
					);
			else --t = 0
				axis_out_d <= (others => '0');
			end if;
		elsif cfg_sum_type = WIDE_COLUMN_ORIENTED then
			if saved_coord.first_y = '0' then
				axis_out_d <= std_logic_vector(
					resize(unsigned(axis_in_n & "00"), LSUM_WIDTH(DATA_WIDTH))
				);
			elsif saved_coord.first_y = '1' and saved_coord.first_x = '0' then
				axis_out_d <= std_logic_vector(
					resize(unsigned(axis_in_w & "00"), LSUM_WIDTH(DATA_WIDTH))
				);
			else --t = 0
				axis_out_d <= (others => '0');
			end if;
		end if;
	end process;
end Behavioral;
