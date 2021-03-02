----------------------------------------------------------------------------------
-- Company: UCM
-- Engineer: Daniel Báscones
-- 
-- Create Date: 02.03.2021 10:16:10
-- Design Name: 
-- Module Name: coord_gen_diagonal - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Generate coordinates in a diagonal pattern on three axis.
-- module will receive max bounds and will start counting on (0,0,0), then 
-- move diagonally with diagonals that have a fixed Y, if the diagonal goes to the X bound
-- it then wraps around to the next Y. For a 3x3x3 cube:
--
-- 4 7 10   13 16 19    22 25 27
-- 2 5 8    11 14 17    20 23 26
-- 1 3 6    9  12 15    18 21 24
--
-- It will generate outputs for Z (band) and T(Y*MAX_X+X) on an AXIS bus
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
use work.math_functions.all;
use work.data_structures.all;
use work.constants.all;


use ieee.numeric_std.all;


--module can be improved by having the first position of the next diagonal precalculated so that, 
--when reaching the last sample of a diagonal, calculations are not needed
--also maxZ - 1 and maxT - 1 can be precalculated
entity coord_gen_diagonal is
	generic (
		MAX_COORD_Z: integer := CONST_MAX_Z;
		MAX_COORD_T: integer := CONST_MAX_T
	);
	port (
		--control signals 
		clk, rst, start : in std_logic;
		finished: out std_logic;
		--control inputs
		max_z: in unsigned(BITS(MAX_COORD_Z) - 1 downto 0);
		max_t: in unsigned(BITS(MAX_COORD_T) - 1 downto 0);
		--output bus
		axis_out_valid: out std_logic;
		axis_out_ready: in std_logic;
		axis_out_last: out std_logic;
		axis_out_data_z: out unsigned(BITS(MAX_COORD_Z) - 1 downto 0);
		axis_out_data_t: out unsigned(BITS(MAX_COORD_T) - 1 downto 0)
	);
end coord_gen_diagonal;

architecture Behavioral of coord_gen_diagonal is

	type state_t is (ST_IDLE, ST_WORKING, ST_FINISHED);
	signal state_curr, state_next: state_t;
	
	signal saved_max_z, next_saved_max_z: unsigned(BITS(MAX_COORD_Z) - 1 downto 0);
	signal saved_max_t, next_saved_max_t: unsigned(BITS(MAX_COORD_T) - 1 downto 0);
	
	signal z_curr, z_next: unsigned(BITS(MAX_COORD_Z) - 1 downto 0);
	signal t_curr, t_next: unsigned(BITS(MAX_COORD_T) - 1 downto 0);
	 

begin

	seq: process(clk, rst, state_next) 
	begin
		if rst = '1' then
			state_curr <= ST_IDLE;
			saved_max_z <= (others => '0');
			saved_max_t <= (others => '0');
			z_curr <= (others => '0');
			t_curr <= (others => '0');
		elsif rising_edge(clk) then
			state_curr <= state_next;
			saved_max_z <= next_saved_max_z;
			saved_max_t <= next_saved_max_t;
			z_curr <= z_next;
			t_curr <= t_next;
		end if;
	end process;
	
	
	comb: process(state_curr, saved_max_z, saved_max_t, z_curr, t_curr, max_z, max_t, axis_out_ready, start)
	
		variable z: unsigned(BITS(MAX_COORD_Z) - 1 downto 0);
		variable t: unsigned(BITS(MAX_COORD_T) - 1 downto 0);
		
		variable last: boolean;
	
	begin
		--default values for registers
		state_next <= state_curr;
		next_saved_max_z <= saved_max_z;
		next_saved_max_t <= saved_max_t;
		z_next <= z_curr;
		t_next <= t_curr;
		--default values for AXIS bus and other outputs
		axis_out_valid <= '0';
		axis_out_last <= '0';
		axis_out_data_z <= z_curr;
		axis_out_data_t <= t_curr;
		finished <= '0';
		--starting variable values
		z := (others => '0');
		t := (others => '0');
		last := false;

		if state_curr = ST_IDLE then
			if (start = '1') then
				state_next <= ST_WORKING;
				next_saved_max_z <= max_z;
				next_saved_max_t <= max_t;
			end if;
		elsif state_curr = ST_WORKING then
			z := z_curr;
			t := t_curr;
			if (z = 0) then
				if (t < saved_max_z - 1) then  --first diagonals
					z := resize(t + 1, BITS(MAX_COORD_Z));
					t := (others => '0');
				else
					z := saved_max_z - 1;
					t := t - saved_max_z + 2;
				end if;
			elsif (t = saved_max_t - 1) then
				if (z = saved_max_z - 1) then -- last sample
					last := true;
					axis_out_last <= '1';
				else --last diagonals
					t := t + z - saved_max_z + 2;
					z := saved_max_z - 1;
				end if;
			else
				z := z - 1;
				t := t + 1;
			end if;
			
			--update coords only on AXIS transaction
			axis_out_valid <= '1';
			if axis_out_ready = '1' then
				z_next <= z;
				t_next <= t;
				
				if (last) then
					state_next <= ST_FINISHED;
				end if;
			end if;
		else -- finished
			finished <= '1';
		end if;
	
	end process;


end Behavioral;
