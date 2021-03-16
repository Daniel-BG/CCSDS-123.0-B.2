----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 10:50:17
-- Design Name: 
-- Module Name: first_pixel_queue_filler - Behavioral
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
use work.ccsds_data_structures.all;

entity first_pixel_queue_filler is
	generic (
		DATA_WIDTH: integer := 16
	);
	Port (
		clk, rst: in std_logic; 
		axis_in_coord_d		: in coordinate_bounds_array_t;
		axis_in_coord_valid	: in std_logic;
		axis_in_coord_ready	: out std_logic;
		axis_in_sample_d	: in std_logic_vector(DATA_WIDTH - 1 downto 0);	
		axis_in_sample_valid: in std_logic;
		axis_in_sample_ready: out std_logic;
		axis_out_fpq_d 		: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_out_fpq_ready	: in std_logic;
		axis_out_fpq_valid	: out std_logic
	);
end first_pixel_queue_filler;

architecture Behavioral of first_pixel_queue_filler is

	signal axis_joint_ready, axis_joint_valid: std_logic;
	signal axis_joint_sample: std_logic_vector(DATA_WIDTH - 1 downto 0);
	signal axis_joint_Coord: std_logic_vector(axis_in_coord_d'range);
	
	signal is_fpq: std_logic;

begin

sync_inputs: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => DATA_WIDTH,
			DATA_WIDTH_1 => coordinate_bounds_array_t'length,
			LATCH 		 => false
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_in_sample_valid,
			input_0_ready => axis_in_sample_ready,
			input_0_data  => axis_in_sample_d,
			input_1_valid => axis_in_coord_valid,
			input_1_ready => axis_in_coord_ready,
			input_1_data  => axis_in_coord_d,
			--to output axi ports
			output_valid  => axis_joint_valid,
			output_ready  => axis_joint_ready,
			output_data_0 => axis_joint_sample,
			output_data_1 => axis_joint_coord
		);
		
		axis_out_fpq_d <= axis_joint_sample;
		is_fpq <= '1' when STDLV2CB(axis_joint_coord).first_x = '1' and STDLV2CB(axis_joint_coord).first_y = '1' else '0';
		
		axis_out_fpq_valid <= axis_joint_valid when is_fpq = '1' else '0';
		axis_joint_ready <= axis_out_fpq_ready when is_fpq = '1' else '1';
		

end Behavioral;
