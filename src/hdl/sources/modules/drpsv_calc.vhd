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


entity drpsv_calc is
	generic (
		HRPSV_WIDTH: integer := 30;
		DATA_WIDTH: integer := 16;
		DRPSV_WIDTH: integer := 16 + 1;
		PRED_BANDS_WIDTH: integer := 3;
		WWIDTH_BITS: integer := 5;
		DWIDTH_BITS: integer := 5
	);
	Port (
		clk, rst: in std_logic; 
		cfg_pred_bands 			: in std_logic_vector(PRED_BANDS_WIDTH - 1 downto 0);
		cfg_in_data_width_log	: in std_logic_vector(DWIDTH_BITS - 1 downto 0);
		cfg_in_weight_width_log	: in std_logic_vector(WWIDTH_BITS - 1 downto 0);
		axis_in_coord_d		: in coordinate_bounds_array_t;
		axis_in_coord_valid	: in std_logic;
		axis_in_coord_ready	: out std_logic;
		axis_in_hrpsv_d		: in std_logic_vector(HRPSV_WIDTH - 1 downto 0);	
		axis_in_hrpsv_valid : in std_logic;
		axis_in_hrpsv_ready : out std_logic;
		axis_in_fpq_d 		: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_in_fpq_valid 	: in std_logic;
		axis_in_fpq_ready 	: out std_logic;
		axis_out_drpsv_d 	: out std_logic_vector(DRPSV_WIDTH - 1 downto 0);
		axis_out_drpsv_ready: in std_logic;
		axis_out_drpsv_valid: out std_logic
	);
end drpsv_calc;

architecture Behavioral of drpsv_calc is

	type state_t is (IDLE, VALUE_READ);
	signal state_curr, state_next: state_t;

	signal axis_joint_valid, axis_joint_ready: std_logic;
	signal axis_joint_coord_bounds: coordinate_bounds_array_t;
	signal axis_joint_hrpsv: std_logic_vector(HRPSV_WIDTH - 1 downto 0);
	
	signal buffered_coord_bounds, buffered_coord_bounds_next: coordinate_bounds_array_t;
	signal buffered_hrpsv, buffered_hrpsv_next: std_logic_vector(HRPSV_WIDTH - 1 downto 0);
	
begin

	sync_inputs: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => axis_in_coord_d'length,
			DATA_WIDTH_1 => HRPSV_WIDTH,
			LATCH 		 => false
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_in_coord_valid,
			input_0_ready => axis_in_coord_ready,
			input_0_data  => axis_in_coord_d,
			input_1_valid => axis_in_hrpsv_valid,
			input_1_ready => axis_in_hrpsv_ready,
			input_1_data  => axis_in_hrpsv_d,
			--to output axi ports
			output_valid  => axis_joint_valid,
			output_ready  => axis_joint_ready,
			output_data_0 => axis_joint_coord_bounds,
			output_data_1 => axis_joint_hrpsv
		);

	seq: process(clk, rst)
	begin
		if rst = '1' then
			state_curr <= IDLE;
			buffered_coord_bounds <= (others => '0');
			buffered_hrpsv <= (others => '0');
		elsif rising_edge(clk) then
			state_curr <= state_next;
			buffered_coord_bounds <= buffered_coord_bounds_next;
			buffered_hrpsv <= buffered_hrpsv_next;
		end if;
		
	end process;
	
	
	comb: process(state_curr, buffered_coord_bounds, buffered_hrpsv,
			axis_joint_valid, axis_joint_coord_bounds, axis_joint_hrpsv,
			cfg_in_weight_width_log, cfg_pred_bands, cfg_in_data_width_log,
			axis_out_drpsv_ready,
			axis_in_fpq_valid, axis_in_fpq_d)
	begin
		state_next <= state_curr;
		buffered_coord_bounds_next <= buffered_coord_bounds;
		buffered_hrpsv_next <= buffered_hrpsv;
		axis_joint_ready <= '0';
		axis_out_drpsv_valid <= '0';
		axis_in_fpq_ready <= '0';
		axis_out_drpsv_d <= (others => '0');
		
		if state_curr = IDLE then
			axis_joint_ready <= '1';
			if axis_joint_valid = '1' then
				state_next <= VALUE_READ;
				buffered_coord_bounds_next <= axis_joint_coord_bounds;
				buffered_hrpsv_next <= axis_joint_hrpsv;
			end if;
		elsif state_curr = VALUE_READ then
			if STDLV2CB(buffered_coord_bounds).first_x = '0' or STDLV2CB(buffered_coord_bounds).first_y = '0' then
				--pipe buffered value
				axis_out_drpsv_valid <= '1';
				axis_out_drpsv_d <= std_logic_vector(resize(
						shift_right(unsigned(buffered_hrpsv), to_integer(unsigned(cfg_in_weight_width_log) + 1))
						, 
						DRPSV_WIDTH
					));
				if axis_out_drpsv_ready = '1' then
					axis_joint_ready <= '1';
					if axis_joint_valid = '1' then
						state_next <= VALUE_READ;
						buffered_coord_bounds_next <= axis_joint_coord_bounds;
						buffered_hrpsv_next <= axis_joint_hrpsv;
					else
						state_next <= IDLE;
					end if;
				end if;
			elsif STDLV2CB(buffered_coord_bounds).first_z = '1' or cfg_pred_bands = (cfg_pred_bands'range => '0') then
				--buffered value is trash, pipe mid sample
				axis_out_drpsv_valid <= '1';
				axis_out_drpsv_d <= std_logic_vector(shift_left(to_unsigned(1, axis_out_drpsv_d'length), to_integer(unsigned(cfg_in_data_width_log))));
				if axis_out_drpsv_ready = '1' then
					axis_joint_ready <= '1';
					if axis_joint_valid = '1' then
						state_next <= VALUE_READ;
						buffered_coord_bounds_next <= axis_joint_coord_bounds;
						buffered_hrpsv_next <= axis_joint_hrpsv;
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
					axis_joint_ready <= '1';
					if axis_joint_valid = '1' then
						state_next <= VALUE_READ;
						buffered_coord_bounds_next <= axis_joint_coord_bounds;
						buffered_hrpsv_next <= axis_joint_hrpsv;
					else
						state_next <= IDLE;
					end if;
				end if;
			end if; 
		end if;
	end process;

end Behavioral;
