----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.03.2021 13:12:45
-- Design Name: 
-- Module Name: coord_gen_vertical - Behavioral
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

entity coord_gen_vertical_reloc is
	generic (
		MAX_COORD_T_WIDTH: integer := 9;
		MAX_COORD_Z_WIDTH: integer := 9;
		DATA_WIDTH: integer := 16
	);
	port (
		--control signals 
		clk, rst: in std_logic;
		finished: out std_logic;
		--control inputs
		cfg_max_z: in std_logic_vector(MAX_COORD_Z_WIDTH - 1 downto 0);
		cfg_max_t: in std_logic_vector(MAX_COORD_T_WIDTH - 1 downto 0);
		--input bus
		axis_in_data: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_in_ready: out std_logic;
		axis_in_valid: in std_logic;
		--output bus
		axis_out_valid: out std_logic;
		axis_out_ready: in std_logic;
		axis_out_last: out std_logic;
		axis_out_data: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_out_data_z: out std_logic_vector(MAX_COORD_Z_WIDTH - 1 downto 0);
		axis_out_data_tz: out std_logic_vector(MAX_COORD_Z_WIDTH - 1 downto 0)
	);
end coord_gen_vertical_reloc;

architecture Behavioral of coord_gen_vertical_reloc is
	type state_t is (ST_WORKING, ST_FINISHED);
	signal state_curr, state_next : state_t;
	
	signal z_curr, z_next: unsigned(MAX_COORD_Z_WIDTH - 1 downto 0);
	signal t_curr, t_next: unsigned(MAX_COORD_T_WIDTH - 1 downto 0);
	signal tz_curr, tz_next: unsigned(MAX_COORD_Z_WIDTH - 1 downto 0);
	
	
begin

	seq: process(clk, rst)
	begin
		if rst = '1' then
			state_curr <= ST_WORKING;
			z_curr <= (others => '0');
			t_curr <= (others => '0');
			tz_curr <= (others => '0');
		elsif rising_edge(clk) then
			state_curr <= state_next;
			z_curr <= z_next;
			t_curr <= t_next;
			tz_curr <= tz_next;
		end if;
	end process; 
	
	
	comb: process(state_curr,
			t_curr, tz_curr, z_curr,
			cfg_max_z, cfg_max_t,
			axis_out_ready, axis_in_valid, axis_in_data)
	begin
		finished <= '0';
		
		
		t_next <= t_curr;
		tz_next <= tz_curr;
		z_next <= z_curr;
		
		axis_out_valid 		<= '0';
		axis_in_ready 		<= '0';
		axis_out_last 		<= '0';
		axis_out_data_z 	<= std_logic_vector(z_curr);
		axis_out_data_tz 	<= std_logic_Vector(tz_curr);
		axis_out_data       <= axis_in_data;
		
		state_next <= state_curr;
	
	
		if state_curr = ST_WORKING then
			axis_out_valid <= axis_in_valid;
			axis_in_ready <= axis_out_ready;
			if axis_out_ready = '1' and axis_in_valid = '1' then
				--update coords in BIP mode
				if z_curr = unsigned(cfg_max_z) then
					z_next <= (others => '0');
					if tz_curr = unsigned(cfg_max_z) then
						tz_next <= (others => '0');
					else
						tz_next <= tz_curr + 1;
					end if;
					--use t to track the inner progress, regardless of how frames have been arranged
					if t_curr = unsigned(cfg_max_t) then
						t_next <= (others => '0');
						axis_out_last <= '1';
						state_next <= ST_FINISHED;	
					else
						t_next <= t_curr + 1;
					end if;
				else
					z_next <= z_curr + 1;
				end if;
			end if;
		elsif state_curr = ST_FINISHED then
			finished <= '1';
			--wait till reset
		end if;
	end process;

end Behavioral;