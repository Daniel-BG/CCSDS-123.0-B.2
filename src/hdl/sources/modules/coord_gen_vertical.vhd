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
use work.ccsds_constants.all;

entity coord_gen_vertical is
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
end coord_gen_vertical;

architecture Behavioral of coord_gen_vertical is
	type state_t is (ST_RESET, ST_WORKING, ST_FINISHED);
	signal state_curr, state_next: state_t;
		
	signal z_curr, z_next: unsigned(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal tz_curr, tz_next: unsigned(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal t_curr, t_next: unsigned(CONST_MAX_T_VALUE_BITS - 1 downto 0);

	--inner signals
	signal inner_reset			: std_logic;
begin

	reset_replicator: entity work.reset_replicator
		port map (
			clk => clk, rst => rst,
			rst_out => inner_reset
		);

	seq: process(clk, inner_reset)
	begin
		if rising_edge(clk) then
			if inner_reset = '1' then
				state_curr <= ST_RESET;
				z_curr <= (others => '0');
				tz_curr <= (others => '0');
				t_curr <= (others => '0');
			else
				state_curr <= state_next;
				z_curr <= z_next;
				tz_curr <= tz_next;
				t_curr <= t_next;
			end if;
		end if;
	end process; 
	
	
	comb: process(state_curr,
			cfg_max_z, cfg_max_t,
			z_curr, t_curr, tz_curr ,
			axis_out_ready)
	begin
		finished <= '0';
		state_next <= state_curr;
		t_next <= t_curr;
		tz_next <= tz_curr;
		z_next <= z_curr;
		
		axis_out_valid 	<= '0';
		axis_out_last 	<= '0';
		axis_out_data_z <= std_logic_vector(z_curr);
		axis_out_data_t <= std_logic_vector(t_curr);
		axis_out_data_tz <= std_logic_vector(tz_curr);

		if state_curr = ST_RESET then
			state_next <= ST_WORKING;
		elsif state_curr = ST_WORKING then
			axis_out_valid <= '1';
			if axis_out_ready = '1' then
				--update coords in BIP mode
				if z_curr = unsigned(cfg_max_z)then
					z_next <= (others => '0');
					if t_curr = unsigned(cfg_max_t) then
						t_next <= (others => '0');
						axis_out_last <= '1';
						state_next <= ST_FINISHED;
					else
						t_next <= t_curr + 1;
					end if;
					--update local t
					if tz_curr = unsigned(cfg_max_z) then
						tz_next <= (others => '0');
					else
						tz_next <= tz_curr + 1;
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
