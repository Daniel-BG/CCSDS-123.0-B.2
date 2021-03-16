----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.03.2021 15:18:52
-- Design Name: 
-- Module Name: hrpsv_calc - Behavioral
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
use work.ccsds_math_functions.all;



entity hrpsv_calc is
	generic (
		DATA_WIDTH: integer := 16;
		WEIGHT_WIDTH: integer := 19;	
		DWIDTH_BITS: integer := 5;
		WWIDTH_BITS: integer := 5;
		PCLD_WIDTH: integer := 22 + 3 + 16;
		LSUM_WIDTH: integer := 16 + 2;
		--ensure HRPSV_WIDTH is big enough to not overflow
		--WEIGHT_WIDTH + 2 + BITS((2**DATA_WIDTH - 1)*(8*P + 19));
		HRPSV_WIDTH: integer := 16 + 24 + 2  
	);
	Port ( 
		clk, rst: in std_logic;
		cfg_in_data_width_log: in std_logic_vector(DWIDTH_BITS - 1 downto 0);
		cfg_in_weight_width_log: in std_logic_vector(WWIDTH_BITS - 1 downto 0); 
		axis_in_pcd_d: in std_logic_vector(PCLD_WIDTH - 1 downto 0);
		axis_in_pcd_valid: in std_logic;
		axis_in_pcd_ready: out std_logic;
		axis_in_lsum_d: in std_logic_vector(LSUM_WIDTH - 1 downto 0);
		axis_in_lsum_valid: in std_logic;
		axis_in_lsum_ready: out std_logic;
		axis_out_hrpsv_d: out std_logic_vector(HRPSV_WIDTH - 1 downto 0);
		axis_out_hrpsv_valid: out std_logic;
		axis_out_hrpsv_ready: in std_logic
	);
end hrpsv_calc;

architecture Behavioral of hrpsv_calc is

	signal axis_joint_valid, axis_joint_ready: std_logic;
	signal axis_joint_lsum: std_logic_vector(LSUM_WIDTH - 1 downto 0);
	signal axis_joint_pcd: std_logic_vector(PCLD_WIDTH - 1 downto 0);
	
	--this ensures no overflow (maybe move somewhere else)
	constant U_TWO: std_logic_vector(2 downto 0) := "010";
	constant U_ONE: std_logic_vector(1 downto 0) := "01";
	signal hrpsv_unclamped, hrpsv_clamped, hrpsv_low, hrpsv_high: std_logic_vector(HRPSV_WIDTH - 1 downto 0);

begin

	assert HRPSV_WIDTH >= PCLD_WIDTH + 2 report "TOO SMALL" severity failure;
	assert HRPSV_WIDTH >= LSUM_WIDTH + WEIGHT_WIDTH + 2 report "TOO SMALL" severity failure;
	assert HRPSV_WIDTH >= DATA_WIDTH + WEIGHT_WIDTH + 3 report "TOO SMALL" severity failure;
	assert to_integer(unsigned(cfg_in_data_width_log)) <= DATA_WIDTH report "VALUE TOO HIGH" severity failure;
	assert to_integer(unsigned(cfg_in_weight_width_log)) <= WEIGHT_WIDTH report "VALUE TOO HIGH" severity failure;


	sync_inputs: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => PCLD_WIDTH,
			DATA_WIDTH_1 => LSUM_WIDTH,
			LATCH 		 => false
		)
		Port map (
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_in_pcd_valid,
			input_0_ready => axis_in_pcd_ready,
			input_0_data  => axis_in_pcd_d,
			input_1_valid => axis_in_lsum_valid,
			input_1_ready => axis_in_lsum_ready,
			input_1_data  => axis_in_lsum_d,
			--to output axi ports
			output_valid  => axis_joint_valid,
			output_ready  => axis_joint_ready,
			output_data_0 => axis_joint_pcd,
			output_data_1 => axis_joint_lsum
		);
		
		
		axis_out_hrpsv_valid <= axis_joint_valid;
		axis_joint_ready <= axis_out_hrpsv_ready;

		hrpsv_unclamped <= std_logic_vector(
			resize(signed(axis_joint_pcd), hrpsv_unclamped'length) 
			+
			shift_left(resize(signed(axis_joint_lsum), hrpsv_unclamped'length) , to_integer(unsigned(cfg_in_weight_width_log))) 
			+
			shift_left(resize(signed(U_TWO), hrpsv_unclamped'length), to_integer(unsigned(cfg_in_weight_width_log)))
		);
		
		hrpsv_low <= (others => '0');
		hrpsv_high <= std_logic_vector(
			shift_left(
				shift_left(resize(signed(U_ONE), hrpsv_unclamped'length), to_integer(unsigned(cfg_in_data_width_log))) - 1,
				to_integer(unsigned(cfg_in_weight_width_log) + 2)
			)
			+
			shift_left(resize(signed(U_TWO), hrpsv_unclamped'length), to_integer(unsigned(cfg_in_weight_width_log)))
		);
		
		axis_out_hrpsv_d <= hrpsv_low when hrpsv_unclamped(hrpsv_unclamped'high) = '1' --is negative
			else hrpsv_high when signed(hrpsv_unclamped) > signed(hrpsv_high) 
			else hrpsv_unclamped;

end Behavioral;
