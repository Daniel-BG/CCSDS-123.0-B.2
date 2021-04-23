--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : test_ccsds_123b2_core.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Fri Apr 16 11:13:14 2021
-- Last update : Fri Apr 16 11:16:08 2021
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2021 User Company Name
-------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.ccsds_constants.all;
use work.ccsds_test_constants.all;

-----------------------------------------------------------

entity test_ccsds_123b2_core is

end entity test_ccsds_123b2_core;

-----------------------------------------------------------

architecture testbench of test_ccsds_123b2_core is
	--control signals for testbench
	signal input_enable: std_logic;

	-- Testbench DUT generics
	constant USE_HYBRID_CODER : boolean := true;

	-- Testbench DUT ports
	signal clk, rst              : std_logic;
	signal cfg_p                 : std_logic_vector(CONST_MAX_P_WIDTH_BITS - 1 downto 0);
	signal cfg_sum_type          : local_sum_t;
	signal cfg_samples           : std_logic_vector(CONST_MAX_SAMPLES_BITS - 1 downto 0);
	signal cfg_tinc              : std_logic_vector(CONST_TINC_BITS - 1 downto 0);
	signal cfg_vmax, cfg_vmin    : std_logic_vector(CONST_VMINMAX_BITS - 1 downto 0);
	signal cfg_depth             : std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
	signal cfg_omega             : std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
	signal cfg_weo               : std_logic_vector(CONST_WEO_BITS - 1 downto 0);
	signal cfg_use_abs_err       : std_logic;
	signal cfg_use_rel_err       : std_logic;
	signal cfg_abs_err           : std_logic_vector(CONST_ABS_ERR_BITS - 1 downto 0);
	signal cfg_rel_err           : std_logic_vector(CONST_REL_ERR_BITS - 1 downto 0);
	signal cfg_smax              : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal cfg_resolution        : std_logic_vector(CONST_RES_BITS - 1 downto 0);
	signal cfg_damping           : std_logic_vector(CONST_DAMPING_BITS - 1 downto 0);
	signal cfg_offset            : std_logic_vector(CONST_OFFSET_BITS - 1 downto 0);
	signal cfg_max_x             : std_logic_vector(CONST_MAX_X_VALUE_BITS - 1 downto 0);
	signal cfg_max_y             : std_logic_vector(CONST_MAX_Y_VALUE_BITS - 1 downto 0);
	signal cfg_max_z             : std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);
	signal cfg_max_t             : std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
	signal cfg_min_preload_value : std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);
	signal cfg_max_preload_value : std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);
	signal cfg_weight_vec		 : std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
	signal cfg_initial_counter   : std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal cfg_final_counter     : std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal cfg_u_max             : std_logic_vector(CONST_U_MAX_BITS - 1 downto 0);
	signal cfg_iacc				 : std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
	--input control
	signal inputter_d           : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal inputter_valid       : std_logic;
	signal inputter_ready       : std_logic;
	signal axis_in_s_d           : std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal axis_in_s_valid       : std_logic;
	signal axis_in_s_ready       : std_logic;
	signal axis_out_data         : std_logic_vector(63 downto 0);
	signal axis_out_valid        : std_logic;
	signal axis_out_last         : std_logic;
	signal axis_out_ready        : std_logic;

	-- Other constants
	constant C_CLK_PERIOD : real := 10.0e-9; -- NS
	
begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	CLK_GEN : process
	begin
		clk <= '1';
		wait for C_CLK_PERIOD / 2.0 * (1 SEC);
		clk <= '0';
		wait for C_CLK_PERIOD / 2.0 * (1 SEC);
	end process CLK_GEN;

	RESET_GEN : process
	begin
		rst <= '1';
		input_enable <= '0';
		wait for 20.0*C_CLK_PERIOD * (1 SEC);
		wait for 0.5*C_CLK_PERIOD * (1 SEC);
		rst <= '0';
		wait for 2.0*C_CLK_PERIOD * (1 SEC);
		input_enable <= '1';
		wait;
	end process RESET_GEN;

	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------
	CONFIG_UNIT : process
	begin
		--algorithm constants
		cfg_p 				<= std_logic_vector(to_unsigned(CONST_MAX_P, CONST_MAX_P_WIDTH_BITS));
		cfg_sum_type 		<= WIDE_NEIGHBOR_ORIENTED; 
		cfg_samples 		<= std_logic_vector(to_unsigned(8, CONST_MAX_SAMPLES_BITS));
		cfg_tinc 			<= std_logic_vector(to_unsigned(6, CONST_TINC_BITS));
		cfg_vmax			<= std_logic_vector(to_unsigned(3, CONST_VMINMAX_BITS));
		cfg_vmin			<= std_logic_vector(to_signed(-1, CONST_VMINMAX_BITS));
		cfg_depth 			<= std_logic_vector(to_unsigned(16, CONST_MAX_DATA_WIDTH_BITS));
		cfg_omega 			<= std_logic_vector(to_unsigned(19, CONST_MAX_OMEGA_WIDTH_BITS));
		cfg_weo 			<= std_logic_vector(to_unsigned(0, CONST_WEO_BITS));
		cfg_use_abs_err 	<= '0';
		cfg_use_rel_err 	<= '1';
		cfg_abs_err			<= std_logic_vector(to_unsigned(0, CONST_ABS_ERR_BITS));
		cfg_rel_err			<= std_logic_vector(to_unsigned(2048, CONST_REL_ERR_BITS));
		cfg_smax			<= std_logic_vector(to_unsigned(2**16-1, CONST_MAX_DATA_WIDTH));
		cfg_resolution 		<= std_logic_vector(to_unsigned(4, CONST_RES_BITS));
		cfg_damping 		<= std_logic_vector(to_unsigned(4, CONST_DAMPING_BITS));
		cfg_offset 			<= std_logic_vector(to_unsigned(4, CONST_OFFSET_BITS));
		cfg_max_x			<= std_logic_vector(to_unsigned(7, CONST_MAX_X_VALUE_BITS));
		cfg_max_y 			<= std_logic_vector(to_unsigned(7, CONST_MAX_Y_VALUE_BITS));
		cfg_max_z 			<= std_logic_vector(to_unsigned(7, CONST_MAX_Z_VALUE_BITS));
		cfg_max_t 			<= std_logic_vector(to_unsigned(63, CONST_MAX_T_VALUE_BITS));
		cfg_initial_counter <= std_logic_vector(to_unsigned(2, CONST_MAX_COUNTER_BITS)); 
		cfg_final_counter 	<= std_logic_vector(to_unsigned(2**6-1, CONST_MAX_COUNTER_BITS));
		cfg_u_max 			<= std_logic_vector(to_unsigned(18, CONST_U_MAX_BITS));
		for i in CONST_MAX_C - 1 downto CONST_MAX_P loop
			cfg_weight_vec(CONST_MAX_WEIGHT_BITS*(i+1) - 1 downto CONST_MAX_WEIGHT_BITS*i) <= (others => '0'); 
		end loop;
		for i in CONST_MAX_P - 1 downto 0 loop
			cfg_weight_vec(CONST_MAX_WEIGHT_BITS*(i+1) - 1 downto CONST_MAX_WEIGHT_BITS*i) <= std_logic_vector(to_unsigned(7*(2**19) / (2**(3*(CONST_MAX_P - i))) , CONST_MAX_WEIGHT_BITS));
		end loop;
		cfg_iacc 			<= std_logic_vector(to_unsigned(4*(2**1)*5,  CONST_MAX_HR_ACC_BITS)); --4*(1 << this.gammaZero)*meanMQIestimate (5)
		--architecture constants
		cfg_min_preload_value <= std_logic_vector(to_unsigned(7*6/2+2, CONST_MAX_Z_VALUE_BITS*2)); --((cfg_max_z)*(cfg_max_z-1))/2 + 2
		cfg_max_preload_value <= std_logic_vector(to_unsigned(7*6/2+6, CONST_MAX_Z_VALUE_BITS*2)); --((cfg_max_z)*(cfg_max_z-1))/2 + 6
		
		wait;
	end process CONFIG_UNIT;
	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	
	INPUTTER: entity work.reader_wrapper
		generic map (
			DATA_WIDTH => CONST_MAX_DATA_WIDTH,
			SKIP => 0,
			FILE_NUMBER => CONST_GOLDEN_NUM_S
		)
		port map (
			clk => clk, rst => rst, 
			enable => input_enable,
			output_valid => inputter_valid,
			output_ready => inputter_ready,
			output_data  => inputter_d
		);
	
	axis_in_s_d <= inputter_d;
	inputter_ready <= axis_in_s_ready;
	axis_in_s_valid <= inputter_valid;
	
	DUT : entity work.ccsds_123b2_core
		generic map (
			USE_HYBRID_CODER => USE_HYBRID_CODER
		)
		port map (
			clk                   => clk,
			rst                   => rst,
			cfg_p                 => cfg_p,
			cfg_sum_type          => cfg_sum_type,
			cfg_samples           => cfg_samples,
			cfg_tinc              => cfg_tinc,
			cfg_vmax              => cfg_vmax,
			cfg_vmin              => cfg_vmin,
			cfg_depth             => cfg_depth,
			cfg_omega             => cfg_omega,
			cfg_weo               => cfg_weo,
			cfg_use_abs_err       => cfg_use_abs_err,
			cfg_use_rel_err       => cfg_use_rel_err,
			cfg_abs_err           => cfg_abs_err,
			cfg_rel_err           => cfg_rel_err,
			cfg_smax              => cfg_smax,
			cfg_resolution        => cfg_resolution,
			cfg_damping           => cfg_damping,
			cfg_offset            => cfg_offset,
			cfg_max_x             => cfg_max_x,
			cfg_max_y             => cfg_max_y,
			cfg_max_z             => cfg_max_z,
			cfg_max_t             => cfg_max_t,
			cfg_min_preload_value => cfg_min_preload_value,
			cfg_max_preload_value => cfg_max_preload_value,
			cfg_weight_vec    	  => cfg_weight_vec,
			cfg_initial_counter   => cfg_initial_counter,
			cfg_final_counter     => cfg_final_counter,
			cfg_u_max             => cfg_u_max,
			cfg_iacc              => cfg_iacc,
			axis_in_s_d           => axis_in_s_d,
			axis_in_s_valid       => axis_in_s_valid,
			axis_in_s_ready       => axis_in_s_ready,
			axis_out_data         => axis_out_data,
			axis_out_valid        => axis_out_valid,
			axis_out_last         => axis_out_last,
			axis_out_ready        => axis_out_ready
		);
		
	OUTPUT_CTRL : process
	begin
		axis_out_ready <= '1';
		wait;
	end process OUTPUT_CTRL;

end architecture testbench;