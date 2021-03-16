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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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
		axis_out_drsr_ready : in std_logic
	);
end drsr_calc;

architecture Behavioral of drsr_calc is
	
	signal fm: std_logic_vector(CONST_MAX_RES_VAL downto 0);
	
	signal mev_times_offset: std_logic_vector(CONST_MEV_BITS + CONST_OFFSET_BITS - 1 downto 0);
	signal hrpsv_times_damping: std_logic_vector(CONST_HRPSV_BITS + CONST_DAMPING_BITS - 1 downto 0);
	signal omega_minus_resolution: std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
	signal cqbc_shifted_by_omega: std_logic_vector(CONST_CQBC_BITS + CONST_MAX_OMEGA_WIDTH - 1 downto 0);
	signal damping_shifted_by_omega_p1: std_logic_vector(CONST_DAMPING_BITS + CONST_MAX_OMEGA_WIDTH downto 0);
	signal omega_plus_res_p1: std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS downto 0);
	
	--first joiner
	signal joint_qi_mev_valid, joint_qi_mev_ready: std_logic;
	signal joint_qi_mev_qi: std_logic_vector(axis_in_qi_d'range);
	signal joint_qi_mev_mev: std_logic_vector(mev_times_offset'range);
	
	signal mev_qi_signed: std_logic_vector(mev_times_offset'range);
	signal mev_qi_shifted: std_logic_vector(mev_times_offset'length + CONST_MAX_OMEGA_WIDTH - 1 downto 0);
	
	--second joiner
	signal joint_sm_valid, joint_sm_ready: std_logic;
	signal joint_sm_mevqi: std_logic_vector(mev_qi_shifted'range);
	signal joint_sm_cqbc: std_logic_vector(cqbc_shifted_by_omega'range);
	
	signal sm_calc: std_logic_vector(joint_sm_cqbc'high + 3 downto 0);
	
	signal fm_times_sm_sb2: std_logic_vector(sm_calc'length+fm'length downto 0);
	
	--third joiner
	signal joint_last_valid, joint_last_ready: std_logic;
	signal joint_last_fmsm: std_logic_vector(fm_times_sm_sb2'range);
	signal joint_last_hrpsv: std_logic_vector(hrpsv_times_damping'range);
	
	signal final_unshifted: std_logic_vector(fm_times_sm_sb2'range);
	
begin

	fm 							<= std_logic_vector(shift_left(resize(unsigned(STDLV_ONE), fm'length),to_integer(unsigned(cfg_resolution))) - unsigned(cfg_damping));
	mev_times_offset 			<= std_logic_vector(unsigned(axis_in_mev_d) * unsigned(cfg_offset));
	hrpsv_times_damping 		<= std_logic_vector(unsigned(axis_in_hrpsv_d) * unsigned(cfg_damping));
	omega_minus_resolution 		<= std_logic_vector(unsigned(cfg_omega) - unsigned(cfg_resolution));
	cqbc_shifted_by_omega 		<= std_logic_vector(shift_left(resize(unsigned(axis_in_cqbc_d), cqbc_shifted_by_omega'length), to_integer(unsigned(cfg_omega))));
	damping_shifted_by_omega_p1 <= std_logic_vector(shift_left(resize(unsigned(axis_in_cqbc_d), damping_shifted_by_omega_p1'length), to_integer(unsigned(cfg_omega))));
	omega_plus_res_p1 			<= std_logic_vector(resize(unsigned(cfg_omega), omega_plus_res_p1'length) + unsigned(cfg_resolution) + 1);
	
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
			input_1_valid => axis_in_mev_valid,
			input_1_ready => axis_in_mev_ready,
			input_1_data  => mev_times_offset,
			--to output axi ports
			output_valid  => joint_qi_mev_valid,
			output_ready  => joint_qi_mev_ready,
			output_data_0 => joint_qi_mev_qi,
			output_data_1 => joint_qi_mev_mev
		);
	
	mev_qi_signed <= joint_qi_mev_mev when joint_qi_mev_qi(joint_qi_mev_qi'high) = '0' else std_logic_vector(-signed(joint_qi_mev_mev));
	mev_qi_shifted <= std_logic_vector(shift_left(resize(signed(mev_qi_signed), mev_qi_shifted'length), to_integer(unsigned(omega_minus_resolution))));
	
	second_stage: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => mev_qi_shifted'length,
			DATA_WIDTH_1 => cqbc_shifted_by_omega'length,
			LATCH 		 => false
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
			--to output axi ports
			output_valid  => joint_sm_valid,
			output_ready  => joint_sm_ready,
			output_data_0 => joint_sm_mevqi,
			output_data_1 => joint_sm_cqbc
		);
		
	sm_calc <= std_logic_vector(signed("0" & joint_sm_cqbc) - signed(joint_sm_mevqi));
	
	fm_times_sm_sb2 <= std_logic_vector(shift_left(signed(sm_calc) * signed("0" & fm), 2));
	
	third_stage: entity work.AXIS_SYNCHRONIZER_2
		Generic map (
			DATA_WIDTH_0 => fm_times_sm_sb2'length,
			DATA_WIDTH_1 => hrpsv_times_damping'length,
			LATCH 		 => false
		)
		Port map (
			clk => clk , rst => rst,
			--to input axi port
			input_0_valid => joint_sm_valid,
			input_0_ready => joint_sm_ready,
			input_0_data  => fm_times_sm_sb2,
			input_1_valid => axis_in_hrpsv_valid,
			input_1_ready => axis_in_hrpsv_ready,
			input_1_data  => hrpsv_times_damping,
			--to output axi ports
			output_valid  => joint_last_valid,
			output_ready  => joint_last_ready,
			output_data_0 => joint_last_fmsm,
			output_data_1 => joint_last_hrpsv
		);
		
	final_unshifted <= std_logic_vector(signed(joint_last_fmsm) + signed("0" & joint_last_hrpsv) - signed("0" & damping_shifted_by_omega_p1));
	
	
	axis_out_drsr_d <= std_logic_vector(resize(shift_right(unsigned(final_unshifted), to_integer(unsigned(omega_plus_res_p1))), axis_out_drsr_d'length));
	axis_out_drsr_valid <= joint_last_valid;
	joint_last_ready <= axis_out_drsr_ready;

end Behavioral;

--	protected long calcDoubleResolutionSampleRepresentative(int b, long clippedQuantizerBinCenter, long quantizerIndex, long maxErrVal, long highResolutionPredSampleValue) { //EQ 47
--		long fm = fm;
--		long sm = (cqbc_shifted_by_omega) - ((Utils.signum(quantizerIndex)*mev_times_offset) << (omega_minus_resolution));
--		long add = hrpsv_times_damping - damping_shifted_by_omega_p1; 
--		long sby = omega_plus_res_p1
--		return (((fm * sm) << 2) + add) >> sby;
--	}
