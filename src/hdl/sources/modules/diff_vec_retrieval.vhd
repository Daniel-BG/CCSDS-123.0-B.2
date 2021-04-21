----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.03.2021 10:11:28
-- Design Name: 
-- Module Name: neigh_retrieval_north - Behavioral
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
use work.ccsds_constants.all;

entity diff_vec_retrieval is
	port ( 
		clk, rst: in std_logic;
		axis_in_coord_d: in coordinate_bounds_array_t;
		axis_in_coord_valid: in std_logic;
		axis_in_coord_ready: out std_logic;
		axis_in_data_d: in std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
		axis_in_data_valid: in std_logic;
		axis_in_data_ready: out std_logic;
		axis_out_data_d: out std_logic_vector(CONST_CLDVEC_BITS - 1 downto 0);
		axis_out_data_valid: out std_logic;
		axis_out_data_ready: in std_logic
	);
end diff_vec_retrieval;

architecture Behavioral of diff_vec_retrieval is
	signal condition: std_logic;

begin

	update_condition: process(axis_in_coord_d) begin
		condition <= '0' when STDLV2CB(axis_in_coord_d).first_z = '1' else '1';
	end process;

	queue_retrieval: entity work.axis_conditioned_retrieval
		generic map ( 
			DATA_WIDTH => CONST_CLDVEC_BITS 
		)
		port map (
			clk => clk, rst => rst,
			axis_in_cond => condition,
			axis_in_cond_valid => axis_in_coord_valid,
			axis_in_cond_ready => axis_in_coord_ready,
			axis_in_data_d => axis_in_data_d,
			axis_in_data_valid => axis_in_data_valid,
			axis_in_data_ready => axis_in_data_ready,
			axis_out_data_d => axis_out_data_d,
			axis_out_data_valid => axis_out_data_valid,
			axis_out_data_ready => axis_out_data_ready
		);

end Behavioral;
