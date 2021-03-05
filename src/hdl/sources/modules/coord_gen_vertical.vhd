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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity coord_gen_vertical is
	generic (
		MAX_COORD_X_WIDTH: integer := 9;
		MAX_COORD_Y_WIDTH: integer := 9;
		MAX_COORD_Z_WIDTH: integer := 9
	);
	port (
		--control signals 
		clk, rst, start : in std_logic;
		finished: out std_logic;
		--control inputs
		cfg_bands: in unsigned(MAX_COORD_Z_WIDTH - 1 downto 0);
		cfg_lines: in unsigned(MAX_COORD_Y_WIDTH - 1 downto 0);
		cfg_samples: in unsigned(MAX_COORD_X_WIDTH - 1 downto 0);
		--output bus
		axis_out_valid: out std_logic;
		axis_out_ready: in std_logic;
		axis_out_last: out std_logic;
		axis_out_data_z: out unsigned(MAX_COORD_Z_WIDTH - 1 downto 0);
		axis_out_data_y: out unsigned(MAX_COORD_Y_WIDTH - 1 downto 0);
		axis_out_data_x: out unsigned(MAX_COORD_X_WIDTH - 1 downto 0)
	);
end coord_gen_vertical;

architecture Behavioral of coord_gen_vertical is
	type state_t is (ST_IDLE, ST_WORKING, ST_FINISHED);
	signal state_curr, state_next : state_t;

	signal saved_max_x, next_saved_max_x: unsigned(MAX_COORD_X_WIDTH - 1 downto 0); 
	signal saved_max_y, next_saved_max_y: unsigned(MAX_COORD_Y_WIDTH - 1 downto 0);
	signal saved_max_z, next_saved_max_z: unsigned(MAX_COORD_Z_WIDTH - 1 downto 0);
	
	signal z_curr, z_next: unsigned(MAX_COORD_Z_WIDTH - 1 downto 0);
	signal y_curr, y_next: unsigned(MAX_COORD_Y_WIDTH - 1 downto 0);
	signal x_curr, x_next: unsigned(MAX_COORD_X_WIDTH - 1 downto 0);
	
	
begin

	seq: process(clk, rst)
	begin
		if rst = '1' then
			state_curr <= ST_IDLE;
			saved_max_z <= (others => '0');
			saved_max_x <= (others => '0');
			saved_max_y <= (others => '0');
			z_curr <= (others => '0');
			x_curr <= (others => '0');
			y_curr <= (others => '0');
		elsif rising_edge(clk) then
			state_curr <= state_next;
			saved_max_z <= next_saved_max_z;
			saved_max_x <= next_saved_max_x;
			saved_max_y <= next_saved_max_y;
			z_curr <= z_next;
			x_curr <= x_next;
			y_curr <= y_next;
		end if;
	end process; 
	
	
	comb: process(state_curr,
			saved_max_x, saved_max_y, saved_max_z,
			x_curr, y_curr, z_curr ,
			start,
			cfg_samples, cfg_lines, cfg_bands,
			axis_out_ready)
	begin
		finished <= '0';
		
		next_saved_max_x <= saved_max_x;
		next_saved_max_y <= saved_max_y;
		next_saved_max_z <= saved_max_z;
		
		x_next <= x_curr;
		y_next <= y_curr;
		z_next <= z_curr;
		
		axis_out_valid 	<= '0';
		axis_out_last 	<= '0';
		axis_out_data_z <= z_curr;
		axis_out_data_y <= y_curr;
		axis_out_data_x <= x_curr;
		
		state_next <= state_curr;
	
	
		if state_curr = ST_IDLE then
			if start = '1' then
				next_saved_max_x <= cfg_samples - 1;
				next_saved_max_y <= cfg_lines - 1;
				next_saved_max_z <= cfg_bands - 1;
				x_next <= (others => '0');
				y_next <= (others => '0');
				z_next <= (others => '0');
				state_next <= ST_WORKING;
			end if;
		elsif state_curr = ST_WORKING then
			axis_out_valid <= '1';
			if axis_out_ready = '1' then
				--update coords in BIP mode
				if z_curr = saved_max_z then
					z_next <= (others => '0');
					if x_curr = saved_max_x then
						x_next <= (others => '0');
						if y_curr = saved_max_y then
							y_next <= (others => '0');
							axis_out_last <= '1';
							state_next <= ST_FINISHED;
						else
							y_next <= y_curr + 1;
						end if;
					else
						x_next <= x_curr + 1;
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
