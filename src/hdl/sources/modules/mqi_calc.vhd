----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.03.2021 14:02:37
-- Design Name: 
-- Module Name: mqi_calc - Behavioral
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

entity mqi_calc is
	Port ( 
		clk, rst			: in std_logic;
		axis_in_drpsv_d		: in std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);
		axis_in_drpsv_valid	: in std_logic;
		axis_in_drpsv_ready	: out std_logic;
		axis_in_theta_d		: in std_logic_vector(CONST_THETA_BITS - 1 downto 0);
		axis_in_theta_valid	: in std_logic;
		axis_in_theta_ready	: out std_logic;
		axis_in_qi_d		: in std_logic_vector(CONST_QI_BITS - 1 downto 0);
		axis_in_qi_valid	: in std_logic;
		axis_in_qi_ready	: out std_logic;
		axis_out_mqi_d		: out std_logic_vector(CONST_MQI_BITS - 1 downto 0);
		axis_out_mqi_ready	: in std_logic;
		axis_out_mqi_valid	: out std_logic
	);
end mqi_calc;

architecture Behavioral of mqi_calc is

	signal joint_qt_valid, joint_qt_ready: std_logic;
	signal joint_qt_theta: std_logic_vector(CONST_THETA_BITS - 1 downto 0);
	signal joint_qt_qi: std_logic_vector(CONST_QI_BITS - 1 downto 0);
	signal joint_qt_qit: std_logic_vector(CONST_QI_BITS + CONST_THETA_BITS - 1 downto 0);
	
	signal final_ready, final_valid: std_logic;
	signal final_qit: std_logic_vector(CONST_QI_BITS + CONST_THETA_BITS - 1 downto 0);
	signal final_theta: std_logic_vector(CONST_THETA_BITS - 1 downto 0);
	signal final_qi: std_logic_vector(CONST_QI_BITS - 1 downto 0);
	signal final_drpsv: std_logic_vector(CONST_DRPSV_BITS - 1 downto 0);

begin

	sync_qi_theta: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_QI_BITS,
			DATA_WIDTH_1 => CONST_THETA_BITS,
			LATCH => false
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_in_qi_valid,
			input_0_ready => axis_in_qi_ready,
			input_0_data  => axis_in_qi_d,
			input_1_valid => axis_in_theta_valid,
			input_1_ready => axis_in_theta_ready,
			input_1_data  => axis_in_theta_d,
			--to output axi ports
			output_valid	=> joint_qt_valid,
			output_ready	=> joint_qt_ready,
			output_data_0	=> joint_qt_qi,
			output_data_1	=> joint_qt_theta
		);
	joint_qt_qit <= joint_qt_qi & joint_qt_theta;
	sync_all: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => CONST_QI_BITS+CONST_THETA_BITS,
			DATA_WIDTH_1 => CONST_DRPSV_BITS,
			LATCH => false
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => joint_qt_valid,
			input_0_ready => joint_qt_ready,
			input_0_data  => joint_qt_qit,
			input_1_valid => axis_in_drpsv_valid,
			input_1_ready => axis_in_drpsv_ready,
			input_1_data  => axis_in_drpsv_d,
			--to output axi ports
			output_valid	=> final_valid,
			output_ready	=> final_ready,
			output_data_0	=> final_qit,
			output_data_1	=> final_drpsv
		);
	final_theta <= final_qit(CONST_THETA_BITS - 1 downto 0);
	final_qi <= final_qit(final_qit'high downto CONST_THETA_BITS);
	
	
	final_ready <= axis_out_mqi_ready;
	axis_out_mqi_valid <= final_valid;
	
	gen_out: process(final_theta, final_qi, final_drpsv)
		variable abs_qi: std_logic_vector(CONST_QI_BITS - 1 downto 0);
		variable qi_times_drpsv_pos: boolean;
	begin
		axis_out_mqi_d <= (others => '0');
		
		if (signed(final_qi) < 0) then
			abs_qi := std_logic_vector(-signed(final_qi));
		else
			abs_qi := final_qi;
		end if;
		if (final_drpsv(0) = '0' and signed(final_qi) < 0) or (final_drpsv(0) = '1' and signed(final_qi) > 0) then
			qi_times_drpsv_pos := false;
		else
			qi_times_drpsv_pos := true;
		end if;
		
		if unsigned(abs_qi) > unsigned(final_theta) then
			axis_out_mqi_d <= std_logic_vector(resize(unsigned(abs_qi) + unsigned(final_theta), CONST_MQI_BITS));
		elsif qi_times_drpsv_pos and unsigned(final_qi) < unsigned(final_theta) then
			axis_out_mqi_d <= std_logic_vector(resize(unsigned(abs_qi) & "0", CONST_MQI_BITS));
		else
			axis_out_mqi_d <= std_logic_vector(resize(unsigned(abs_qi & "0") - 1, CONST_MQI_BITS));
		end if;
	end process;

end Behavioral;
