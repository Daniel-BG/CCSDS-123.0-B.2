----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.03.2021 13:26:11
-- Design Name: 
-- Module Name: sample_relocator - Behavioral
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


entity sample_relocator is
	generic (
		MAX_SIDE_LOG: integer := 9; --final mem size is 2**(MAX_SIZE_WIDTH*2)
		DATA_WIDTH: integer := 16
	);
	port (
		--control signals 
		clk, rst: in std_logic;
		finished: out std_logic;
		--control inputs
		cfg_min_preload_value: in std_logic_vector(MAX_SIDE_LOG*2 - 1 downto 0);
		cfg_max_preload_value: in std_logic_vector(MAX_SIDE_LOG*2 - 1 downto 0);
		--axis bus for input coordinates (write to here)
		axis_input_coord_d: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_input_coord_x: in std_logic_vector(MAX_SIDE_LOG - 1 downto 0);
		axis_input_coord_z: in std_logic_vector(MAX_SIDE_LOG - 1 downto 0);
		axis_input_coord_ready: out std_logic;
		axis_input_coord_valid: in std_logic;
		axis_input_coord_last: in std_logic;
		--axis bus for output coordinates (read from here)
		axis_output_coord_x: in std_logic_vector(MAX_SIDE_LOG - 1 downto 0);
		axis_output_coord_z: in std_logic_vector(MAX_SIDE_LOG - 1 downto 0);
		axis_output_coord_ready: out std_logic;
		axis_output_coord_valid: in std_logic;
		axis_output_coord_last: in std_logic;
		--axis bus to output the data (read from output_coord)
		axis_output_data_d: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_output_data_ready: in std_logic;
		axis_output_data_valid: out std_logic;
		axis_output_data_last: out std_logic
	);
end sample_relocator;

architecture Behavioral of sample_relocator is
	type state_main_t is (ST_M_WORKING, ST_M_FINISHED);
	signal state_main_curr, state_main_next: state_main_t;
	type state_write_t is (ST_W_LOADING, ST_W_FINISHED);
	signal state_write_curr, state_write_next: state_write_t;
	type state_read_t is (ST_R_LOADING, ST_R_LOADED, ST_R_LOADED_LAST, ST_R_FINISHED);
	signal state_read_curr, state_read_next: state_read_t;

	signal loaded_samples, loaded_samples_next: unsigned(MAX_SIDE_LOG*2-1 downto 0);
	
	--ram signals
	signal ram_addra: std_logic_vector(MAX_SIDE_LOG*2 - 1 downto 0);
	signal ram_dina: std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal ram_wena: std_logic;
	signal ram_addrb: std_logic_vector(MAX_SIDE_LOG*2 - 1 downto 0);
	signal ram_doutb: std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal ram_rdenb: std_logic;
	
begin
	--OUTPUTS
	axis_output_data_d <= ram_doutb;

	--RAM CONTROLS
	ram_addra <= axis_input_coord_x & axis_input_coord_z;
	ram_addrb <= axis_output_coord_x & axis_output_coord_z;
	ram_dina  <= axis_input_coord_d;
	
	ram: entity work.simple_dual_port_ram
		generic map (
			DATA_WIDTH => DATA_WIDTH,
			ADDR_WIDTH => MAX_SIDE_LOG*2,
			DEPTH => 2**(MAX_SIDE_LOG*2)
		)
		port map (
			clk => clk, addra => ram_addra, dina => ram_dina, wena => ram_wena, addrb => ram_addrb, doutb => ram_doutb, rdenb => ram_rdenb
		); 
	
	--STATE AND OTHER UPDATES
	seq: process(clk, rst, state_main_next) 
	begin
		if rising_edge(clk) then
			if rst = '1' then
				--main process
				state_main_curr	   	<= ST_M_WORKING;
				loaded_samples     	<= (others => '0');
				--write/read process
				state_write_curr  	<= ST_W_LOADING;
				state_read_curr 	<= ST_R_LOADING;
			else
				--main process
				state_main_curr 	<= state_main_next;
				loaded_samples     	<= loaded_samples_next;
				--write/read process
				state_write_curr  	<= state_write_next;
				state_read_curr		<= state_read_next;
			end if;
		end if;
	end process;
	
	comb_main: process(state_main_curr, 
			loaded_samples,
			cfg_min_preload_value, cfg_max_preload_value, 
			ram_wena, ram_rdenb, 
			state_read_curr, state_write_curr)
	begin
		loaded_samples_next 	<= loaded_samples;
		state_main_next 		<= state_main_curr;
		finished 				<= '0';
				
		if state_main_curr = ST_M_WORKING then
			if ram_wena = '0' and ram_rdenb = '1' then
				loaded_samples_next <= loaded_samples - 1;
			elsif ram_wena = '1' and ram_rdenb = '0' then
				loaded_samples_next <= loaded_samples + 1;
			end if;
			
			if state_write_curr = ST_W_FINISHED and state_read_curr = ST_R_FINISHED then
				state_main_next <= ST_M_FINISHED;
			end if;
			
		elsif state_main_curr = ST_M_FINISHED then
			finished <= '1';
		end if;
	end process;
	
	
	comb_write: process(state_write_curr, state_main_curr, 
			loaded_samples, cfg_max_preload_value,
			axis_input_coord_valid, axis_input_coord_last) 
	begin
		state_write_next <= state_write_curr;
		ram_wena <= '0';
		axis_input_coord_ready <= '0';
		
		
		if state_write_curr = ST_W_LOADING then
			if loaded_samples < unsigned(cfg_max_preload_value) then
				axis_input_coord_ready <= '1';
				if axis_input_coord_valid = '1' then
					ram_wena <= '1';
					if axis_input_coord_last = '1' then
						state_write_next <= ST_W_FINISHED;
					end if;
				end if;
			end if;
		elsif state_write_curr = ST_W_FINISHED then
			--idle here till reset, signal has been sent with the state itself
		end if;
	end process;
	
	comb_read: process(state_read_curr, state_main_curr, state_write_curr,
			loaded_samples, cfg_min_preload_value,
			axis_output_coord_valid, axis_output_coord_last, axis_output_data_ready)
	begin
		state_read_next <= state_read_curr;
		ram_rdenb <= '0';
		axis_output_data_valid <= '0';
		axis_output_data_last <= '0';
		axis_output_coord_ready <= '0';
		
		
		if state_read_curr = ST_R_LOADING then
			if state_write_curr = ST_W_FINISHED or loaded_samples > unsigned(cfg_min_preload_value) then
				axis_output_coord_ready <= '1';
				if axis_output_coord_valid = '1' then
					ram_rdenb <= '1';
					if axis_output_coord_last = '1' then
						state_read_next <= ST_R_LOADED_LAST;
					else
						state_read_next <= ST_R_LOADED;
					end if;
				end if;
			end if;
		elsif state_read_curr = ST_R_LOADED then
			axis_output_data_valid <= '1';
			if axis_output_data_ready = '1' then
				--data has been read, load if possible
				if state_write_curr = ST_W_FINISHED or loaded_samples > unsigned(cfg_min_preload_value) then
					axis_output_coord_ready <= '1';
					if axis_output_coord_valid = '1' then
						ram_rdenb <= '1';
						if axis_output_coord_last = '1' then
							state_read_next <= ST_R_LOADED_LAST;
						else
							state_read_next <= ST_R_LOADED;
						end if;
					end if;
				else
					state_read_next <= ST_R_LOADING; --go back, we don't have the coords
				end if;
			end if;
		elsif state_read_curr = ST_R_LOADED_LAST then
			axis_output_data_valid <= '1';
			axis_output_data_last <= '1';
			if axis_output_data_ready = '1' then
				--last data has been sent, go to sleep
				state_read_next <= ST_R_FINISHED;
			end if;
		elsif state_read_curr = ST_R_FINISHED then
			--idle here, signal has been sent as the state itself
		end if;
	end process;
end Behavioral;

--axis_output_data_last
