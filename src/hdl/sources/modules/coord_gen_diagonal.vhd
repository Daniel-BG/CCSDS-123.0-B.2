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
use work.ccsds_math_functions.all;
use work.ccsds_data_structures.all;
use work.ccsds_constants.all;

use ieee.numeric_std.all;


--module can be improved by having the first position of the next diagonal precalculated so that, 
--when reaching the last sample of a diagonal, calculations are not needed
entity coord_gen_diagonal is
	port (
		--control signals 
		clk, rst: in std_logic;
		finished: out std_logic;
		--control inputs
		cfg_max_z: in std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
		cfg_max_t: in std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
		--output bus
		axis_out_valid: out std_logic;
		axis_out_ready: in std_logic;
		axis_out_last: out std_logic;
		axis_out_data_z: out std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
		axis_out_data_t: out std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
		axis_out_data_tz: out std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0)
	);
end coord_gen_diagonal;

architecture Behavioral of coord_gen_diagonal is

	type state_t is (ST_IDLE, ST_WORKING, ST_FINISHED);
	signal state_curr, state_next: state_t;
		
	signal z_curr, z_next: unsigned(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal tz_curr, tz_next: unsigned(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal t_curr, t_next: unsigned(CONST_MAX_T_VALUE_BITS - 1 downto 0);
	 
	signal cfg_max_z_m1, cfg_max_z_m1_next: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
begin

	seq: process(clk, rst, state_next) 
	begin
		if rst = '1' then
			state_curr <= ST_IDLE;
			z_curr <= (others => '0');
			t_curr <= (others => '0');
			tz_curr<= (others => '0');
			cfg_max_z_m1 <= (others => '0');
		elsif rising_edge(clk) then
			state_curr <= state_next;
			z_curr <= z_next;
			t_curr <= t_next;
			tz_curr<= tz_next;
			cfg_max_z_m1 <= cfg_max_z_m1_next;
		end if;
	end process;
	
	
	comb: process(state_curr, z_curr, t_curr, tz_curr, cfg_max_z, cfg_max_t, axis_out_ready)
	
		variable z, tz: unsigned(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
		variable t: unsigned(CONST_MAX_T_VALUE_BITS - 1 downto 0);
		
		variable last: boolean;
	
	begin
		--default values for registers
		state_next <= state_curr;
		z_next <= z_curr;
		t_next <= t_curr;
		tz_next <= tz_curr;
		--default values for AXIS bus and other outputs
		axis_out_valid <= '0';
		axis_out_last <= '0';
		axis_out_data_z <= std_logic_vector(z_curr);
		axis_out_data_t <= std_logic_vector(t_curr);
		axis_out_data_tz <= std_logic_vector(tz_curr);
		finished <= '0';
		--starting variable values
		z := (others => '0');
		t := (others => '0');
		tz:= (others => '0');
		last := false;
		--saved cfg values
		cfg_max_z_m1_next <= cfg_max_z_m1;

		if state_curr = ST_IDLE then
			--precalculate cfgmaxz - 1 and cfgmaxt - 1
			cfg_max_z_m1_next <= std_logic_vector(unsigned(cfg_max_z) - 1);
			state_next <= ST_WORKING;
		elsif state_curr = ST_WORKING then
			z := z_curr;
			t := t_curr;
			tz:= tz_curr;
			if (z = 0) then
				if (t < unsigned(cfg_max_z)) then  --first diagonals
					z := resize(t + 1, CONST_MAX_Z_VALUE_BITS);
					t := (others => '0');
					tz:= (others => '0');
				else
					z := unsigned(cfg_max_z);
					t := t - unsigned(cfg_max_z_m1);
					if tz = unsigned(cfg_max_z) then
						tz := (tz'range => '0') + 1;
					elsif tz = unsigned(cfg_max_z_m1) then
						tz := (others => '0');
					else
						tz := tz + 2;
					end if;
				end if;
			elsif (t = unsigned(cfg_max_t)) then
				if (z = unsigned(cfg_max_z)) then -- last sample
					last := true;
					axis_out_last <= '1';
				else --last diagonals
					t := t + z - unsigned(cfg_max_z_m1);
					if (tz + z < unsigned(cfg_max_z_m1)) then
						tz := tz + z + 2;
					else 
						tz := tz + z - unsigned(cfg_max_z_m1);	
					end if;
					z := unsigned(cfg_max_z);
				end if;
			else
				z := z - 1;
				t := t + 1;
				if tz = unsigned(cfg_max_z) then
					tz := (others => '0');
				else
					tz := tz + 1;
				end if;
			end if;
			
			--update coords only on AXIS transaction
			axis_out_valid <= '1';
			if axis_out_ready = '1' then
				z_next <= z;
				t_next <= t;
				tz_next <= tz;
				
				if (last) then
					state_next <= ST_FINISHED;
				end if;
			end if;
		else -- finished
			finished <= '1';
		end if;
	
	end process;


end Behavioral;
