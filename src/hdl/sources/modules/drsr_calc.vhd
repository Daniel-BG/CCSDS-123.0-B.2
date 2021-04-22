----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.03.2021 10:28:53
-- Design Name: 
-- Module Name: drsr_calc - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
use work.ccsds_data_structures.all;
use work.am_data_types.all;

entity drsr_calc is
	port ( 
		clk, rst			: in std_logic;
		cfg_resolution		: in std_logic_vector(CONST_RES_BITS - 1 downto 0);
		cfg_damping			: in std_logic_vector(CONST_DAMPING_BITS - 1 downto 0);
		cfg_offset			: in std_logic_vector(CONST_OFFSET_BITS - 1 downto 0);
		cfg_omega 			: in std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
		axis_in_cqbc_d		: in std_logic_vector(CONST_CQBC_BITS - 1 downto 0);
		axis_in_cqbc_valid  : in std_logic;
		axis_in_cqbc_ready	: out std_logic;
		axis_in_cqbc_coord	: in coordinate_bounds_array_t;
		axis_in_qi_d		: in std_logic_vector(CONST_QI_BITS - 1 downto 0);
		axis_in_qi_valid 	: in std_logic;
		axis_in_qi_ready	: out std_logic;
		axis_in_mev_d		: in std_logic_vector(CONST_MEV_BITS - 1 downto 0);
		axis_in_mev_valid	: in std_logic;
		axis_in_mev_ready	: out std_logic;
		axis_in_hrpsv_d		: in std_logic_vector(CONST_HRPSV_BITS - 1 downto 0);
		axis_in_hrpsv_valid	: in std_logic;
		axis_in_hrpsv_ready	: out std_logic;
		axis_out_drsr_d		: out std_logic_vector(CONST_DRSR_BITS - 1 downto 0);
		axis_out_drsr_valid	: out std_logic;
		axis_out_drsr_ready : in std_logic;
		axis_out_drsr_coord : out coordinate_bounds_array_t
	);
end drsr_calc;

architecture Behavioral of drsr_calc is
	
	signal fm: std_logic_vector(CONST_MAX_RES_VAL downto 0);
	
	signal omega_minus_resolution: std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
	signal cqbc_shifted_by_omega: std_logic_vector(CONST_CQBC_BITS + CONST_MAX_OMEGA - 1 downto 0);
	signal damping_shifted_by_omega_p1: std_logic_vector(CONST_DAMPING_BITS + CONST_MAX_OMEGA downto 0);
	signal omega_plus_res_p1: std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS downto 0);
	
	--mev times offset mult
	signal mev_times_offset: std_logic_vector(CONST_MEV_BITS + CONST_OFFSET_BITS - 1 downto 0);
	signal mev_times_offset_valid, mev_times_offset_ready: std_logic;
	
	--hrpsv mult
	signal hrpsv_times_damping: std_logic_vector(CONST_HRPSV_BITS + CONST_DAMPING_BITS - 1 downto 0);
	signal hrpsv_times_damping_valid, hrpsv_times_damping_ready: std_logic;
	
	--first joiner
	signal joint_qi_mev_valid, joint_qi_mev_ready: std_logic;
	signal joint_qi_mev_qi: std_logic_vector(axis_in_qi_d'range);
	signal joint_qi_mev_mev: std_logic_vector(mev_times_offset'range);
	
	signal mev_qi_signed: std_logic_vector(mev_times_offset'range);
	signal mev_qi_shifted: std_logic_vector(mev_times_offset'length + CONST_MAX_OMEGA - 1 downto 0);
	
	--second joiner
	signal joint_sm_valid, joint_sm_ready: std_logic;
	signal joint_sm_mevqi: std_logic_vector(mev_qi_shifted'range);
	signal joint_sm_cqbc: std_logic_vector(cqbc_shifted_by_omega'range);
	signal joint_sm_coord: coordinate_bounds_array_t;
	
	signal sm_calc: std_logic_vector(joint_sm_cqbc'high + 3 downto 0);
	
	signal fm_times_sm: std_logic_vector(sm_calc'length+fm'length - 1 downto 0);
	signal fm_times_sm_valid, fm_times_sm_ready: std_logic;
	signal fm_times_sm_coord: coordinate_bounds_array_t;
	signal fm_times_sm_sb2: std_logic_vector(sm_calc'length+fm'length +1 downto 0);
	
	--third joiner
	signal joint_last_valid, joint_last_ready: std_logic;
	signal joint_last_fmsm: std_logic_vector(fm_times_sm_sb2'range);
	signal joint_last_hrpsv: std_logic_vector(hrpsv_times_damping'range);
	signal joint_last_coord: coordinate_bounds_array_t;
	signal final_unshifted: std_logic_vector(fm_times_sm_sb2'range);
	
	--latch final result for critical path reasons
	signal latched_final_unshifted: std_logic_vector(fm_times_sm_sb2'range);
	signal latched_final_ready, latched_final_valid: std_logic;
	signal latched_final_coord: coordinate_bounds_array_t;
	
begin

	fm 							<= std_logic_vector(shift_left(resize(unsigned(STDLV_ONE), fm'length),to_integer(unsigned(cfg_resolution))) - unsigned(cfg_damping));
	omega_minus_resolution 		<= std_logic_vector(unsigned(cfg_omega) - unsigned(cfg_resolution));
	cqbc_shifted_by_omega 		<= std_logic_vector(shift_left(resize(unsigned(axis_in_cqbc_d), cqbc_shifted_by_omega'length), to_integer(unsigned(cfg_omega))));
	damping_shifted_by_omega_p1 <= std_logic_vector(shift_left(resize(unsigned(cfg_damping), damping_shifted_by_omega_p1'length), to_integer(unsigned(cfg_omega) + 1)));
	omega_plus_res_p1 			<= std_logic_vector(resize(unsigned(cfg_omega), omega_plus_res_p1'length) + unsigned(cfg_resolution) + 1);
	
	mev_times_offset_calc: entity work.AXIS_MULTIPLIER
		Generic map (
			DATA_WIDTH_0		=> axis_in_mev_d'length,
			DATA_WIDTH_1		=> cfg_offset'length,
			SIGNED_0			=> false,
			SIGNED_1			=> false,
			STAGES_AFTER_SYNC	=> 3
		)
		Port map(
			clk => clk, rst => rst,
			input_0_data	=> axis_in_mev_d,
			input_0_valid	=> axis_in_mev_valid,
			input_0_ready	=> axis_in_mev_ready,
			input_1_data	=> cfg_offset,
			input_1_valid	=> '1',
			input_1_ready	=> open,
			output_data		=> mev_times_offset,
			output_valid	=> mev_times_offset_valid,
			output_ready	=> mev_times_offset_ready
		);
		
	hrpsv_times_damping_calc: entity work.AXIS_MULTIPLIER
		Generic map (
			DATA_WIDTH_0		=> axis_in_hrpsv_d'length,
			DATA_WIDTH_1		=> cfg_damping'length,
			SIGNED_0			=> false,
			SIGNED_1			=> false,
			STAGES_AFTER_SYNC	=> 3
		)
		Port map(
			clk => clk, rst => rst,
			input_0_data	=> axis_in_hrpsv_d,
			input_0_valid	=> axis_in_hrpsv_valid,
			input_0_ready	=> axis_in_hrpsv_ready,
			input_1_data	=> cfg_damping,
			input_1_valid	=> '1',
			input_1_ready	=> open,
			output_data		=> hrpsv_times_damping,
			output_valid	=> hrpsv_times_damping_valid,
			output_ready	=> hrpsv_times_damping_ready
		);
	
	first_stage: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => axis_in_qi_d'length,
			DATA_WIDTH_1 => mev_times_offset'length,
			LATCH 		 => false
		)
		Port map (
			clk => clk , rst => rst,
			--to input axi port
			input_0_valid => axis_in_qi_valid,
			input_0_ready => axis_in_qi_ready,
			input_0_data  => axis_in_qi_d,
			input_1_valid => mev_times_offset_valid,
			input_1_ready => mev_times_offset_ready,
			input_1_data  => mev_times_offset,
			--to output axi ports
			output_valid  => joint_qi_mev_valid,
			output_ready  => joint_qi_mev_ready,
			output_data_0 => joint_qi_mev_qi,
			output_data_1 => joint_qi_mev_mev
		);
	
	--mev_qi_signed <= joint_qi_mev_mev when joint_qi_mev_qi(joint_qi_mev_qi'high) = '0' else std_logic_vector(-signed(joint_qi_mev_mev));
	mev_qi_signed <= (others => '0') when joint_qi_mev_qi = (joint_qi_mev_qi'range => '0') else
					joint_qi_mev_mev when joint_qi_mev_qi(joint_qi_mev_qi'high) = '0' else 
					std_logic_vector(-signed(joint_qi_mev_mev));
	mev_qi_shifted <= std_logic_vector(shift_left(resize(signed(mev_qi_signed), mev_qi_shifted'length), to_integer(unsigned(omega_minus_resolution))));
	
	second_stage: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => mev_qi_shifted'length,
			DATA_WIDTH_1 => cqbc_shifted_by_omega'length,
			LATCH 		 => false,
			USER_WIDTH   => coordinate_bounds_array_t'length,
			USER_POLICY  => PASS_ONE
		)
		Port map (
			clk => clk , rst => rst,
			--to input axi port
			input_0_valid => joint_qi_mev_valid,
			input_0_ready => joint_qi_mev_ready,
			input_0_data  => mev_qi_shifted,
			input_1_valid => axis_in_cqbc_valid,
			input_1_ready => axis_in_cqbc_ready,
			input_1_data  => cqbc_shifted_by_omega,
			input_1_user  => axis_in_cqbc_coord,
			--to output axi ports
			output_valid  => joint_sm_valid,
			output_ready  => joint_sm_ready,
			output_data_0 => joint_sm_mevqi,
			output_data_1 => joint_sm_cqbc,
			output_user   => joint_sm_coord
		);
		
	sm_calc <= std_logic_vector(signed("0" & unsigned(joint_sm_cqbc)) - signed(joint_sm_mevqi));
	
	fm_times_sm_multiplier: entity work.AXIS_MULTIPLIER
		Generic map (
			DATA_WIDTH_0 => sm_calc'length,
			DATA_WIDTH_1 => fm'length,
			SIGNED_0	 => true,
			SIGNED_1	 => false,
			STAGES_AFTER_SYNC => 3,
			USER_WIDTH => coordinate_bounds_array_t'length,
			USER_POLICY => PASS_ZERO
		)
		Port map (
			clk => clk, rst => rst,
			input_0_data	=> sm_calc,
			input_0_valid	=> joint_sm_valid,
			input_0_ready	=> joint_sm_ready,
			input_0_user    => joint_sm_coord,
			input_1_data	=> fm,
			input_1_valid	=> '1',
			input_1_ready	=> open,
			input_1_user    => open,
			output_data		=> fm_times_sm,
			output_valid	=> fm_times_sm_valid,
			output_ready	=> fm_times_sm_ready,
			output_user		=> fm_times_sm_coord
		);
	fm_times_sm_sb2 <= std_logic_vector(shift_left(resize(signed(fm_times_sm), fm_times_sm_sb2'length), 2));
	
	third_stage: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => fm_times_sm_sb2'length,
			DATA_WIDTH_1 => hrpsv_times_damping'length,
			LATCH 		 => false,
			USER_WIDTH   => coordinate_bounds_array_t'length,
			USER_POLICY  => PASS_ZERO
		)
		Port map (
			clk => clk , rst => rst,
			--to input axi port
			input_0_valid => fm_times_sm_valid,
			input_0_ready => fm_times_sm_ready,
			input_0_data  => fm_times_sm_sb2,
			input_0_user  => fm_times_sm_coord,
			input_1_valid => hrpsv_times_damping_valid,
			input_1_ready => hrpsv_times_damping_ready,
			input_1_data  => hrpsv_times_damping,
			--to output axi ports
			output_valid  => joint_last_valid,
			output_ready  => joint_last_ready,
			output_data_0 => joint_last_fmsm,
			output_data_1 => joint_last_hrpsv,
			output_user   => joint_last_coord
		);
		
	final_unshifted <= std_logic_vector(signed(joint_last_fmsm) + signed("0" & unsigned(joint_last_hrpsv)) - signed("0" & unsigned(damping_shifted_by_omega_p1)));
	
	latch_final_unshifted: entity work.AXIS_DATA_LATCH
		Generic map (
			DATA_WIDTH => final_unshifted'length,
			USER_WIDTH => coordinate_bounds_array_t'length
		)
		Port map ( 
			clk => clk, rst => rst,
			input_data	=> final_unshifted,
			input_ready => joint_last_ready,
			input_valid => joint_last_valid,
			input_user 	=> joint_last_coord,
			output_data	=> latched_final_unshifted,
			output_ready=> latched_final_ready,
			output_valid=> latched_final_valid,
			output_user => latched_final_coord
		);
	
	axis_out_drsr_d <= std_logic_vector(resize(shift_right(unsigned(latched_final_unshifted), to_integer(unsigned(omega_plus_res_p1))), axis_out_drsr_d'length));
	axis_out_drsr_valid <= latched_final_valid;
	latched_final_ready <= axis_out_drsr_ready;
	axis_out_drsr_coord <= latched_final_coord;

end Behavioral;

--	protected long calcDoubleResolutionSampleRepresentative(int b, long clippedQuantizerBinCenter, long quantizerIndex, long maxErrVal, long highResolutionPredSampleValue) { //EQ 47
--		long fm = fm;
--		long sm = (cqbc_shifted_by_omega) - ((Utils.signum(quantizerIndex)*mev_times_offset) << (omega_minus_resolution));
--		long add = hrpsv_times_damping - damping_shifted_by_omega_p1; 
--		long sby = omega_plus_res_p1
--		return (((fm * sm) << 2) + add) >> sby;
--	}
