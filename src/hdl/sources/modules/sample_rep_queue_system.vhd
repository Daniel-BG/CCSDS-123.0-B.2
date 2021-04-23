----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2021 08:44:59
-- Design Name: 
-- Module Name: sample_rep_queue_system - Behavioral
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

entity sample_rep_queue_system is
	Port (
		clk, rst				: in std_logic;
		--input coordinate for reading
		axis_in_coord_valid		: in std_logic;
		axis_in_coord_d 		: in coordinate_bounds_array_t;
		axis_in_coord_ready		: out std_logic;
		--input sample from current representative
		axis_in_cr_d			: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_cr_coord		: in coordinate_bounds_array_t;
		axis_in_cr_valid		: in std_logic; 
		axis_in_cr_ready		: out std_logic;
		--output synchronized neighborhood
		axis_out_w				: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_n				: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_ne				: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_nw				: out std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_out_ready			: in std_logic;
		axis_out_valid			: out std_logic;
		axis_out_coord			: out coordinate_bounds_array_t
	);
end sample_rep_queue_system;

architecture Behavioral of sample_rep_queue_system is
	--neighbor retrievals
	--neighbor retrieval coord splitter
	signal axis_nrcs_nrn_valid, axis_nrcs_nrn_ready: std_logic;
	signal axis_nrcs_nrn_coord: coordinate_bounds_array_t;
	signal axis_nrcs_nrw_valid, axis_nrcs_nrw_ready: std_logic;
	signal axis_nrcs_nrw_coord: coordinate_bounds_array_t;
	signal axis_nrcs_nrnw_valid, axis_nrcs_nrnw_ready: std_logic;
	signal axis_nrcs_nrnw_coord: coordinate_bounds_array_t;
	signal axis_nrcs_nrne_valid, axis_nrcs_nrne_ready: std_logic;
	signal axis_nrcs_nrne_coord: coordinate_bounds_array_t;
	--from queues before
	signal axis_nq_nrn_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nq_nrn_valid, axis_nq_nrn_ready: std_logic;
	signal axis_wq_nrw_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_wq_nrw_valid, axis_wq_nrw_ready: std_logic;
	signal axis_nwq_nrnw_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nwq_nrnw_valid, axis_nwq_nrnw_ready: std_logic;
	signal axis_neq_nrne_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_neq_nrne_valid, axis_neq_nrne_ready: std_logic;
	--to spliters and latches after
	signal axis_nrn_nrns_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrn_nrns_coord : coordinate_bounds_array_t;
	signal axis_nrn_nrns_valid, axis_nrn_nrns_ready: std_logic;
	signal axis_nrw_nrws_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrw_nrws_coord : coordinate_bounds_array_t;
	signal axis_nrw_nrws_valid, axis_nrw_nrws_ready: std_logic;
	signal axis_nrnw_nrnwl_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrnw_nrnwl_valid, axis_nrnw_nrnwl_ready: std_logic;
	signal axis_nrne_nrnes_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrne_nrnes_coord : coordinate_bounds_array_t;
	signal axis_nrne_nrnes_valid, axis_nrne_nrnes_ready: std_logic;
	--north neigh retrieval splitter
	signal axis_nrns_nrsy_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrns_nrsy_coord : coordinate_bounds_array_t;
	signal axis_nrns_nrsy_valid, axis_nrns_nrsy_ready: std_logic;
	signal axis_nrns_nwqp_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrns_nwqp_coord : coordinate_bounds_array_t;
	signal axis_nrns_nwqp_valid, axis_nrns_nwqp_ready: std_logic;
	--north east retrieval splitter
	signal axis_nrnes_nrsy_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrnes_nrsy_coord : coordinate_bounds_array_t;
	signal axis_nrnes_nrsy_valid, axis_nrnes_nrsy_ready: std_logic;
	signal axis_nrnes_nqp_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrnes_nqp_coord : coordinate_bounds_array_t;
	signal axis_nrnes_nqp_valid, axis_nrnes_nqp_ready: std_logic;
	--west retrieval splitter
	signal axis_nrws_nrsy_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrws_nrsy_coord : coordinate_bounds_array_t;
	signal axis_nrws_nrsy_valid, axis_nrws_nrsy_ready: std_logic;
	signal axis_nrws_neqp_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrws_neqp_coord : coordinate_bounds_array_t;
	signal axis_nrws_neqp_valid, axis_nrws_neqp_ready: std_logic;
	--north west latch
	signal axis_nrnwl_nrsy_d : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nrnwl_nrsy_valid, axis_nrnwl_nrsy_ready: std_logic;
	
	--loopback for putters
	signal axis_nwqp_nwq_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nwqp_nwq_valid, axis_nwqp_nwq_ready: std_logic;
	signal axis_neqp_neq_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_neqp_neq_valid, axis_neqp_neq_ready: std_logic;
	signal axis_nqp_nq_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_nqp_nq_valid, axis_nqp_nq_ready: std_logic;
	signal axis_wqp_wq_d: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_wqp_wq_valid, axis_wqp_wq_ready: std_logic;

	--input coord fifo
	signal axis_coordq_valid	: std_logic;
	signal axis_coordq_d 		: coordinate_bounds_array_t;
	signal axis_coordq_ready	: std_logic;
begin

	input_coord_queue: entity work.axis_fifo
		Generic map (
			DATA_WIDTH => coordinate_bounds_array_t'length,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_valid	=> axis_in_coord_valid,
			input_ready => axis_in_coord_ready,
			input_data	=> axis_in_coord_d,
			output_ready=> axis_coordq_ready,
			output_data	=> axis_coordq_d,
			output_valid=> axis_coordq_valid
		);

	neigh_ret_coord_splitter: entity work.AXIS_SPLITTER_4
		Generic map (
			DATA_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst	=> rst,
			--to input axi port
			input_valid		=> axis_coordq_valid,
			input_data		=> axis_coordq_d,
			input_ready		=> axis_coordq_ready,
			--to output axi ports
			output_0_valid	=> axis_nrcs_nrn_valid,
			output_0_data	=> axis_nrcs_nrn_coord,
			output_0_ready	=> axis_nrcs_nrn_ready,
			output_1_valid	=> axis_nrcs_nrw_valid,
			output_1_data	=> axis_nrcs_nrw_coord,
			output_1_ready	=> axis_nrcs_nrw_ready,
			output_2_valid	=> axis_nrcs_nrne_valid,
			output_2_data	=> axis_nrcs_nrne_coord,
			output_2_ready	=> axis_nrcs_nrne_ready,
			output_3_valid	=> axis_nrcs_nrnw_valid,
			output_3_data	=> axis_nrcs_nrnw_coord,
			output_3_ready	=> axis_nrcs_nrnw_ready
		);
		
	neigh_ret_north: entity work.neigh_retrieval_north
		port map ( 
			clk => clk, rst => rst,
			axis_in_coord_d		=> axis_nrcs_nrn_coord,
			axis_in_coord_valid => axis_nrcs_nrn_valid,
			axis_in_coord_ready => axis_nrcs_nrn_ready,
			axis_in_data_d		=> axis_nq_nrn_d,
			axis_in_data_valid  => axis_nq_nrn_valid,
			axis_in_data_ready  => axis_nq_nrn_ready,
			axis_out_data_d		=> axis_nrn_nrns_d,
			axis_out_data_coord => axis_nrn_nrns_coord,
			axis_out_data_valid => axis_nrn_nrns_valid,
			axis_out_data_ready => axis_nrn_nrns_ready
		);
		
	neigh_ret_north_split: entity work.AXIS_SPLITTER_2
		Generic map(
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst => rst,
			input_valid		=> axis_nrn_nrns_valid,
			input_data		=> axis_nrn_nrns_d,
			input_ready		=> axis_nrn_nrns_ready,
			input_user		=> axis_nrn_nrns_coord,
			--to output axi ports
			output_0_valid	=> axis_nrns_nrsy_valid,
			output_0_data	=> axis_nrns_nrsy_d,
			output_0_ready	=> axis_nrns_nrsy_ready,
			output_0_user	=> axis_nrns_nrsy_coord,
			output_1_valid	=> axis_nrns_nwqp_valid,
			output_1_data	=> axis_nrns_nwqp_d,
			output_1_ready	=> axis_nrns_nwqp_ready,
			output_1_user	=> axis_nrns_nwqp_coord
		);
		
	neigh_ret_west: entity work.neigh_retrieval_west
		port map ( 
			clk => clk, rst => rst,
			axis_in_coord_d		=> axis_nrcs_nrw_coord,
			axis_in_coord_valid => axis_nrcs_nrw_valid,
			axis_in_coord_ready => axis_nrcs_nrw_ready,
			axis_in_data_d		=> axis_wq_nrw_d,
			axis_in_data_valid  => axis_wq_nrw_valid,
			axis_in_data_ready  => axis_wq_nrw_ready,
			axis_out_data_d		=> axis_nrw_nrws_d,
			axis_out_data_coord => axis_nrw_nrws_coord,
			axis_out_data_valid => axis_nrw_nrws_valid,
			axis_out_data_ready => axis_nrw_nrws_ready
		);
		
	neigh_ret_west_split: entity work.AXIS_SPLITTER_2
		Generic map(
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst => rst,
			input_valid		=> axis_nrw_nrws_valid,
			input_data		=> axis_nrw_nrws_d,
			input_ready		=> axis_nrw_nrws_ready,
			input_user		=> axis_nrw_nrws_coord,
			--to output axi ports
			output_0_valid	=> axis_nrws_nrsy_valid,
			output_0_data	=> axis_nrws_nrsy_d,
			output_0_ready	=> axis_nrws_nrsy_ready,
			output_0_user	=> axis_nrws_nrsy_coord,
			output_1_valid	=> axis_nrws_neqp_valid,
			output_1_data	=> axis_nrws_neqp_d,
			output_1_ready	=> axis_nrws_neqp_ready,
			output_1_user	=> axis_nrws_neqp_coord
		);
		
	neigh_ret_northwest: entity work.neigh_retrieval_northwest
		port map ( 
			clk => clk, rst => rst,
			axis_in_coord_d		=> axis_nrcs_nrnw_coord,
			axis_in_coord_valid => axis_nrcs_nrnw_valid,
			axis_in_coord_ready => axis_nrcs_nrnw_ready,
			axis_in_data_d		=> axis_nwq_nrnw_d,
			axis_in_data_valid  => axis_nwq_nrnw_valid,
			axis_in_data_ready  => axis_nwq_nrnw_ready,
			axis_out_data_d		=> axis_nrnw_nrnwl_d,
			axis_out_data_coord => open,
			axis_out_data_valid => axis_nrnw_nrnwl_valid,
			axis_out_data_ready => axis_nrnw_nrnwl_ready
		);
		
	neigh_ret_northwest_latch: entity work.AXIS_LATCHED_CONNECTION
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH
		)
		Port map (
			clk => clk, rst => rst,
			input_ready => axis_nrnw_nrnwl_ready,
			input_valid => axis_nrnw_nrnwl_valid,
			input_data  => axis_nrnw_nrnwl_d,
			output_ready=> axis_nrnwl_nrsy_ready,
			output_valid=> axis_nrnwl_nrsy_valid,
			output_data => axis_nrnwl_nrsy_d
		);
		
	neigh_ret_northeast: entity work.neigh_retrieval_northeast
		port map ( 
			clk => clk, rst => rst,
			axis_in_coord_d		=> axis_nrcs_nrne_coord,
			axis_in_coord_valid => axis_nrcs_nrne_valid,
			axis_in_coord_ready => axis_nrcs_nrne_ready,
			axis_in_data_d		=> axis_neq_nrne_d,
			axis_in_data_valid  => axis_neq_nrne_valid,
			axis_in_data_ready  => axis_neq_nrne_ready,
			axis_out_data_d		=> axis_nrne_nrnes_d,
			axis_out_data_coord => axis_nrne_nrnes_coord,
			axis_out_data_valid => axis_nrne_nrnes_valid,
			axis_out_data_ready => axis_nrne_nrnes_ready
		);
	
	neigh_ret_northeast_split: entity work.AXIS_SPLITTER_2
		Generic map(
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map (
			clk => clk, rst => rst,
			input_valid		=> axis_nrne_nrnes_valid,
			input_data		=> axis_nrne_nrnes_d,
			input_ready		=> axis_nrne_nrnes_ready,
			input_user		=> axis_nrne_nrnes_coord,
			--to output axi ports
			output_0_valid	=> axis_nrnes_nrsy_valid,
			output_0_data	=> axis_nrnes_nrsy_d,
			output_0_ready	=> axis_nrnes_nrsy_ready,
			output_0_user	=> axis_nrnes_nrsy_coord,
			output_1_valid	=> axis_nrnes_nqp_valid,
			output_1_data	=> axis_nrnes_nqp_d,
			output_1_ready	=> axis_nrnes_nqp_ready,
			output_1_user	=> axis_nrnes_nqp_coord
		);
		
	north_west_putter: entity work.neigh_putter_northwest
		Port map ( 
			clk => clk, rst	=> rst,
			axis_in_d		=> axis_nrns_nwqp_d,
			axis_in_coord	=> axis_nrns_nwqp_coord,
			axis_in_valid	=> axis_nrns_nwqp_valid,
			axis_in_ready	=> axis_nrns_nwqp_ready,
			axis_out_d		=> axis_nwqp_nwq_d,
			axis_out_valid	=> axis_nwqp_nwq_valid,
			axis_out_ready	=> axis_nwqp_nwq_ready
		);
		
	north_putter: entity work.neigh_putter_north 
		Port map ( 
			clk => clk, rst	=> rst,
			axis_in_d		=> axis_nrnes_nqp_d,
			axis_in_coord	=> axis_nrnes_nqp_coord,
			axis_in_valid	=> axis_nrnes_nqp_valid,
			axis_in_ready	=> axis_nrnes_nqp_ready,
			axis_out_d		=> axis_nqp_nq_d,
			axis_out_valid	=> axis_nqp_nq_valid,
			axis_out_ready	=> axis_nqp_nq_ready
		);
		
	north_east_putter: entity work.neigh_putter_northeast
		Port map ( 
			clk => clk, rst	=> rst,
			axis_in_d		=> axis_nrws_neqp_d,
			axis_in_coord	=> axis_nrws_neqp_coord,
			axis_in_valid	=> axis_nrws_neqp_valid,
			axis_in_ready	=> axis_nrws_neqp_ready,
			axis_out_d		=> axis_neqp_neq_d,
			axis_out_valid	=> axis_neqp_neq_valid,
			axis_out_ready	=> axis_neqp_neq_ready
		);
		
	west_putter: entity work.neigh_putter_west
		Port map ( 
			clk => clk, rst	=> rst,
			axis_in_d		=> axis_in_cr_d,
			axis_in_coord	=> axis_in_cr_coord,
			axis_in_valid	=> axis_in_cr_valid,
			axis_in_ready	=> axis_in_cr_ready,
			axis_out_d		=> axis_wqp_wq_d,
			axis_out_valid	=> axis_wqp_wq_valid,
			axis_out_ready	=> axis_wqp_wq_ready
		);
		
	north_queue: entity work.axis_fifo_latched 
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_valid	=> axis_nqp_nq_valid,
			input_ready => axis_nqp_nq_ready,
			input_data	=> axis_nqp_nq_d,
			output_ready=> axis_nq_nrn_ready,
			output_data	=> axis_nq_nrn_d,
			output_valid=> axis_nq_nrn_valid
		);
		
	west_queue: entity work.axis_fifo_latched 
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_valid	=> axis_wqp_wq_valid,
			input_ready => axis_wqp_wq_ready,
			input_data	=> axis_wqp_wq_d,
			output_ready=> axis_wq_nrw_ready,
			output_data	=> axis_wq_nrw_d,
			output_valid=> axis_wq_nrw_valid
		);
		
	northwest_queue: entity work.axis_fifo_latched 
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			FIFO_DEPTH => CONST_MAX_BANDS
		)
		Port map ( 
			clk => clk, rst => rst,
			input_valid	=> axis_nwqp_nwq_valid,
			input_ready => axis_nwqp_nwq_ready,
			input_data	=> axis_nwqp_nwq_d,
			output_ready=> axis_nwq_nrnw_ready,
			output_data	=> axis_nwq_nrnw_d,
			output_valid=> axis_nwq_nrnw_valid
		);
		
	northeast_queue: entity work.axis_fifo_latched 
		Generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			FIFO_DEPTH => CONST_MAX_BANDS*CONST_MAX_SAMPLES
		)
		Port map ( 
			clk => clk, rst => rst,
			input_valid	=> axis_neqp_neq_valid,
			input_ready => axis_neqp_neq_ready,
			input_data	=> axis_neqp_neq_d,
			output_ready=> axis_neq_nrne_ready,
			output_data	=> axis_neq_nrne_d,
			output_valid=> axis_neq_nrne_valid
		);
		
	neigh_retrieval_syncrhonizer: entity work.axis_symmetric_synchronizer_latched_4
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			USER_WIDTH => coordinate_bounds_array_t'length,
			USER_POLICY=> OR_ALL
		)
		port map (
			clk => clk, rst => rst,
			axis_in_0_d		=> axis_nrns_nrsy_d,
			axis_in_0_ready	=> axis_nrns_nrsy_ready,
			axis_in_0_valid => axis_nrns_nrsy_valid,
			axis_in_0_user	=> axis_nrns_nrsy_coord,
			axis_in_1_d		=> axis_nrnes_nrsy_d,
			axis_in_1_ready	=> axis_nrnes_nrsy_ready,
			axis_in_1_valid => axis_nrnes_nrsy_valid,
			axis_in_2_d		=> axis_nrnwl_nrsy_d,
			axis_in_2_ready	=> axis_nrnwl_nrsy_ready,
			axis_in_2_valid => axis_nrnwl_nrsy_valid,
			axis_in_3_d		=> axis_nrws_nrsy_d,
			axis_in_3_ready	=> axis_nrws_nrsy_ready,
			axis_in_3_valid => axis_nrws_nrsy_valid,
			axis_out_d_0 	=> axis_out_n,
			axis_out_d_1 	=> axis_out_ne,
			axis_out_d_2 	=> axis_out_nw,
			axis_out_d_3 	=> axis_out_w,
			axis_out_ready 	=> axis_out_ready,
			axis_out_valid 	=> axis_out_valid,
			axis_out_user 	=> axis_out_coord	
		);

end Behavioral;
