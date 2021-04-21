----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2021 13:01:58
-- Design Name: 
-- Module Name: diff_putter - Behavioral
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
use work.ccsds_data_structures.all;
use work.am_data_types.all;

entity diff_putter is
	Port ( 
		clk, rst			: in std_logic;
		axis_diffs_d		: in std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
		axis_diffs_valid	: in std_logic;
		axis_diffs_ready	: out std_logic;
		axis_cdif_d			: in std_logic_vector(CONST_LDIF_BITS - 1 downto 0);
		axis_cdif_coord		: in coordinate_bounds_array_t;
		axis_cdif_valid		: in std_logic;
		axis_cdif_ready		: out std_logic;
		axis_out_diffs_d	: out std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
		axis_out_diffs_valid: out std_logic;
		axis_out_diffs_ready: in std_logic
	);
end diff_putter;

architecture Behavioral of diff_putter is
	signal joint_coord: coordinate_bounds_array_t;
	signal joint_diffvec: std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
	signal joint_cdif:  std_logic_vector(CONST_LDIF_BITS - 1 downto 0);
	signal joint_valid, joint_ready: std_logic;
	
	signal deleting: boolean;
begin

	sync: entity work.AXIS_SYNCHRONIZER_2
		generic map (
			DATA_WIDTH_0 => CONST_CLDVEC_BITS,
			DATA_WIDTH_1 => CONST_LDIF_BITS,
			LATCH => false,
			USER_WIDTH => coordinate_bounds_array_t'length,
			USER_POLICY => PASS_ONE
		)
		port map(
			clk => clk, rst => rst,
			--to input axi port
			input_0_valid => axis_diffs_valid,
			input_0_ready => axis_diffs_ready,
			input_0_data  => axis_diffs_d,
			input_1_valid => axis_cdif_valid,
			input_1_ready => axis_cdif_ready,
			input_1_data  => axis_cdif_d,
			input_1_user  => axis_cdif_coord,
			--to output axi ports
			output_valid  => joint_valid,
			output_ready  => joint_ready,
			output_data_0 => joint_diffvec,
			output_data_1 => joint_cdif,
			output_user	  => joint_coord
		);

	update_deleting: process(joint_coord) begin
		deleting <= STDLV2CB(joint_coord).last_z = '1';
	end process;
	
	gen_output: for i in 0 to CONST_MAX_P - 2 generate
		axis_out_diffs_d(CONST_LDIF_BITS*(i+1)-1 downto CONST_LDIF_BITS*i) <= joint_diffvec(CONST_LDIF_BITS*(i+2)-1 downto CONST_LDIF_BITS*(i+1));
	end generate;
	axis_out_diffs_d(CONST_LDIF_BITS*CONST_MAX_P - 1 downto CONST_LDIF_BITS*(CONST_MAX_P-1)) <= joint_cdif;
	
	joint_ready <= '1' when deleting else axis_out_diffs_ready;
	axis_out_diffs_valid <= '0' when deleting else joint_valid;
end Behavioral;
