----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 09:57:15
-- Design Name: 
-- Module Name: drpsv_calc - Behavioral
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
use ieee.numeric_std.all;
use work.ccsds_data_structures.all;
use work.ccsds_constants.all;


entity drpsv_calc is
	Port (
		clk, rst: in std_logic; 
		cfg_pred_bands 			: in std_logic_vector(CONST_MAX_P_WIDTH_BITS - 1 downto 0);
		cfg_in_data_width_log	: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		cfg_in_weight_width_log	: in std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
		axis_in_hrpsv_d			: in std_logic_vector(CONST_HRPSV_BITS - 1 downto 0);	
		axis_in_hrpsv_valid 	: in std_logic;
		axis_in_hrpsv_ready 	: out std_logic;
		axis_in_hrpsv_coord 	: in coordinate_bounds_array_t;
		axis_in_fpq_d 			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_fpq_valid 		: in std_logic;
		axis_in_fpq_ready 		: out std_logic;
		axis_out_drpsv_d 		: out std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
		axis_out_drpsv_ready	: in std_logic;
		axis_out_drpsv_valid	: out std_logic;
		axis_out_drpsv_coord	: out coordinate_bounds_array_t
	);
end drpsv_calc;

architecture Behavioral of drpsv_calc is

	type state_t is (RESET, IDLE, VALUE_READ);
	signal state_curr, state_next: state_t;
	
	signal buffered_coord_bounds, buffered_coord_bounds_next: coordinate_bounds_array_t;
	signal buffered_hrpsv, buffered_hrpsv_next: std_logic_vector(CONST_HRPSV_BITS - 1 downto 0);
	
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
				state_curr <= RESET;
				buffered_coord_bounds <= (others => '0');
				buffered_hrpsv <= (others => '0');
			else
				state_curr <= state_next;
				buffered_coord_bounds <= buffered_coord_bounds_next;
				buffered_hrpsv <= buffered_hrpsv_next;
			end if;
		end if;
		
	end process;
	
	
	comb: process(state_curr, buffered_coord_bounds, buffered_hrpsv,
			axis_in_hrpsv_valid, axis_in_hrpsv_coord, axis_in_hrpsv_d,
			cfg_in_weight_width_log, cfg_pred_bands, cfg_in_data_width_log,
			axis_out_drpsv_ready,
			axis_in_fpq_valid, axis_in_fpq_d)
	begin
		state_next <= state_curr;
		buffered_coord_bounds_next <= buffered_coord_bounds;
		buffered_hrpsv_next <= buffered_hrpsv;
		axis_in_hrpsv_ready <= '0';
		axis_out_drpsv_valid <= '0';
		axis_in_fpq_ready <= '0';
		axis_out_drpsv_d <= (others => '0');
		axis_out_drpsv_coord <= buffered_coord_bounds;
		
		if state_curr = RESET then
			state_next <= IDLE;
		elsif state_curr = IDLE then
			axis_in_hrpsv_ready <= '1';
			if axis_in_hrpsv_valid = '1' then
				state_next <= VALUE_READ;
				buffered_coord_bounds_next <= axis_in_hrpsv_coord;
				buffered_hrpsv_next <= axis_in_hrpsv_d;
			end if;
		elsif state_curr = VALUE_READ then
			if F_STDLV2CB(buffered_coord_bounds).first_x = '0' or F_STDLV2CB(buffered_coord_bounds).first_y = '0' then
				--pipe buffered value
				axis_out_drpsv_valid <= '1';
				axis_out_drpsv_d <= std_logic_vector(resize(
						shift_right(unsigned(buffered_hrpsv), to_integer(unsigned(cfg_in_weight_width_log) + 1))
						, 
						CONST_DRPSV_BITS
					));
				if axis_out_drpsv_ready = '1' then
					axis_in_hrpsv_ready <= '1';
					if axis_in_hrpsv_valid = '1' then
						state_next <= VALUE_READ;
						buffered_coord_bounds_next <= axis_in_hrpsv_coord;
						buffered_hrpsv_next <= axis_in_hrpsv_d;
					else
						state_next <= IDLE;
					end if;
				end if;
			elsif F_STDLV2CB(buffered_coord_bounds).first_z = '1' or cfg_pred_bands = (cfg_pred_bands'range => '0') then
				--buffered value is trash, pipe mid sample
				axis_out_drpsv_valid <= '1';
				axis_out_drpsv_d <= std_logic_vector(shift_left(to_unsigned(1, axis_out_drpsv_d'length), to_integer(unsigned(cfg_in_data_width_log))));
				if axis_out_drpsv_ready = '1' then
					axis_in_hrpsv_ready <= '1';
					if axis_in_hrpsv_valid = '1' then
						state_next <= VALUE_READ;
						buffered_coord_bounds_next <= axis_in_hrpsv_coord;
						buffered_hrpsv_next <= axis_in_hrpsv_d;
					else
						state_next <= IDLE;
					end if;
				end if;
			else
				--pipe FPQ
				axis_out_drpsv_valid <= axis_in_fpq_valid;
				axis_in_fpq_ready <= axis_out_drpsv_ready;
				axis_out_drpsv_d <= std_logic_vector(resize(unsigned(axis_in_fpq_d) & "0", axis_out_drpsv_d'length));
				if axis_in_fpq_valid = '1' and axis_out_drpsv_ready = '1' then
					axis_in_hrpsv_ready <= '1';
					if axis_in_hrpsv_valid = '1' then
						state_next <= VALUE_READ;
						buffered_coord_bounds_next <= axis_in_hrpsv_coord;
						buffered_hrpsv_next <= axis_in_hrpsv_d;
					else
						state_next <= IDLE;
					end if;
				end if;
			end if; 
		end if;
	end process;

end Behavioral;
