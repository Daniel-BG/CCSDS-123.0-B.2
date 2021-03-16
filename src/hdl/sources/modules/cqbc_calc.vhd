----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2021 14:01:16
-- Design Name: 
-- Module Name: cqbc_calc - Behavioral
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

entity cqbc_calc is
	generic (
		DATA_WIDTH: integer := 16;
		MEV_WIDTH: integer := 16
	);
	Port ( 
		clk, rst			: in std_logic;
		axis_in_psv_d		: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		axis_in_psv_valid	: in std_logic;
		axis_in_psv_ready	: out std_logic;
		axis_in_qi_d		: in std_logic_vector(DATA_WIDTH downto 0);
		axis_in_qi_valid	: in std_logic;
		axis_in_qi_ready	: out std_logic;
		axis_in_mev_d		: in std_logic_vector(MEV_WIDTH - 1 downto 0);
		axis_in_mev_valid	: in std_logic;
		axis_in_mev_ready	: out std_logic;
		axis_out_cqbc_d		: out std_logic_vector(DATA_WIDTH downto 0);
		axis_out_cqbc_ready	: in std_logic;
		axis_out_cqbc_valid	: out std_logic
	);
end cqbc_calc;

architecture Behavioral of cqbc_calc is
	
	signal axis_in_mev_t2p1: std_logic_vector(axis_in_mev_d'length downto 0);

	signal axis_mult_valid, axis_mult_ready: std_logic;
	signal axis_mult_d: std_logic_vector(axis_in_qi_d'length + axis_in_mev_d'length downto 0);
	
	signal joint_valid, joint_ready: std_logic;
	signal joint_psv: std_logic_vector(axis_in_psv_d'range);
	signal joint_mult: std_logic_vector(axis_in_qi_d'length + axis_in_mev_d'length downto 0);
	

begin

	axis_in_mev_t2p1 <= axis_in_mev_d & "1";

	mult: entity work.AXIS_MULTIPLIER
		Generic map (
			DATA_WIDTH_0 => axis_in_qi_d'length,
			DATA_WIDTH_1 => axis_in_mev_d'length + 1, --length+1
			OUTPUT_WIDTH => axis_in_qi_d'length + axis_in_mev_d'length + 1,  
			SIGN_EXTEND_0=> true,
			SIGN_EXTEND_1=> false,
			SIGNED_OP	 => true

		)
		Port map (
			clk => clk, rst => rst,
			input_0_data	=> axis_in_qi_d,
			input_0_valid	=> axis_in_qi_valid,
			input_0_ready	=> axis_in_qi_ready,
			input_1_data	=> axis_in_mev_t2p1,
			input_1_valid	=> axis_in_mev_valid,
			input_1_ready	=> axis_in_mev_ready,
			output_data		=> axis_mult_d,
			output_valid	=> axis_mult_valid,
			output_ready	=> axis_mult_ready
		);
		
		
	sync: entity work.AXIS_SYNCHRONIZER_2
		generic map (
			DATA_WIDTH_0 => axis_in_psv_d'length,
			DATA_WIDTH_1 => axis_mult_d'length,
			LATCH 		 => false
		)
		port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_in_psv_valid,
			input_0_ready => axis_in_psv_ready,
			input_0_data  => axis_in_psv_d,
			input_1_valid => axis_mult_valid,
			input_1_ready => axis_mult_ready,
			input_1_data  => axis_mult_d,
			--to output axi ports
			output_valid  => joint_valid,
			output_ready  => joint_ready,
			output_data_0 => joint_psv,
			output_data_1 => joint_mult
		);

	joint_ready <= axis_out_cqbc_ready;
	axis_out_cqbc_valid <= joint_valid;
	axis_out_cqbc_d <= 
				(others => '0') when -signed(joint_psv) > signed(joint_mult)
		else 	std_logic_vector(to_unsigned(2**DATA_WIDTH-1,axis_out_cqbc_d'length)) when signed(joint_psv) + signed(joint_mult) > to_signed(2**DATA_WIDTH-1,DATA_WIDTH+1)
		else    std_logic_vector(resize(signed(joint_psv) + signed(joint_mult), axis_out_cqbc_d'length));
	

end Behavioral;
