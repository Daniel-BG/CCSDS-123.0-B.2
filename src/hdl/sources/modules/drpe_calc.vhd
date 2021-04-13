----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 15.03.2021 14:00:05
-- Design Name: 
-- Module Name: drpe_calc - Behavioral
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
use work.ccsds_constants.all;
use ieee.numeric_std.all;

entity drpe_calc is
	port ( 
		clk, rst			: in std_logic;
		axis_in_cqbc_d		: in std_logic_vector(CONST_CQBC_BITS - 1 downto 0);
		axis_in_cqbc_valid  : in std_logic;
		axis_in_cqbc_ready	: out std_logic;
		axis_in_drpsv_d 	: in std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
		axis_in_drpsv_ready : out std_logic;
		axis_in_drpsv_valid : in std_logic;
		axis_out_drpe_valid : out std_logic;
		axis_out_drpe_ready : in std_logic;
		axis_out_drpe_d		: out std_logic_vector(CONST_DRPE_BITS - 1 downto 0)
	);
end drpe_calc;

architecture Behavioral of drpe_calc is

	signal joint_valid, joint_ready: std_logic;
	signal joint_cqbc: std_logic_vector(CONST_CQBC_BITS - 1 downto 0);
	signal joint_drpsv: std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
		
begin


	sync: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_CQBC_BITS,
			DATA_WIDTH_1 => CONST_DRPSV_BITS,
			LATCH => true
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_in_cqbc_valid,
			input_0_ready => axis_in_cqbc_ready,
			input_0_data  => axis_in_cqbc_d,
			input_1_valid => axis_in_drpsv_valid,
			input_1_ready => axis_in_drpsv_ready,
			input_1_data  => axis_in_drpsv_d,
			--to output axi ports
			output_valid  => joint_valid,
			output_ready  => joint_ready,
			output_data_0 => joint_cqbc,
			output_data_1 => joint_drpsv
		);
		
	axis_out_drpe_valid <= joint_valid;
	joint_ready <= axis_out_drpe_ready;
	axis_out_drpe_d <= std_logic_vector(signed("0" & unsigned(joint_cqbc) & "0") - signed("0" & unsigned(joint_drpsv)));

end Behavioral;
