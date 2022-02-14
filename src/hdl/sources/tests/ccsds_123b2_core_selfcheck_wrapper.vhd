----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.01.2022 15:08:18
-- Design Name: 
-- Module Name: ccsds_123b2_core_selfcheck_wrapper - Behavioral
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

entity ccsds_123b2_core_selfcheck_wrapper is
	Generic (
		PATTERN_IN 							: string := "pattern_in.mif";
		selfcheck_ref_cnt_limit 			: integer := 4881;
		selfcheck_ref_checksum				: std_logic_vector(63 downto 0) := x"0004360006B58000";
		PATTERN_OUT							: string := "pattern_out.mif";
		selfcheck_input_words				: integer := 61200;
		selfcheck_timeout_cnt_limit  		: integer := 220000 --217233 exact? (+-)
	);
	Port ( 
		clk, rst: in std_logic;
		--signal for selfcheck
		selfcheck_init 			: in std_logic;
		selfcheck_working		: out std_logic; --turns 0 when the selfcheck has finished
		selfcheck_full_failed	: out std_logic; --turns 1 if the test failed (detected by full checking with output reference)
		selfcheck_full_finished : out std_logic; --turns 1 when the full test finishes
		selfcheck_ref_failed	: out std_logic; --turns 1 if the test faield (detected by measuring output length + last 64b)
		selfcheck_ref_finished 	: out std_logic; --turns 1 when the ref test finishes
		selfcheck_timeout		: out std_logic; --turns 1 if the test did not complete in the expected time.
		--core config
		cfg_full_prediction		: in std_logic;
		cfg_p					: in std_logic_vector(CONST_MAX_P_WIDTH_BITS - 1 downto 0);
		cfg_wide_sum			: in std_logic;
		cfg_neighbor_sum		: in std_logic;
		cfg_smid 				: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		cfg_samples				: in std_logic_vector(CONST_MAX_SAMPLES_BITS - 1 downto 0);
		cfg_tinc				: in std_logic_vector(CONST_TINC_BITS - 1 downto 0);
		cfg_vmax, cfg_vmin		: in std_logic_vector(CONST_VMINMAX_BITS - 1 downto 0);
		cfg_depth				: in std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
		cfg_omega				: in std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
		cfg_weo					: in std_logic_vector(CONST_WEO_BITS - 1 downto 0);
		cfg_use_abs_err			: in std_logic;
		cfg_use_rel_err			: in std_logic;
		cfg_abs_err 			: in std_logic_vector(CONST_ABS_ERR_BITS - 1 downto 0);
		cfg_rel_err 			: in std_logic_vector(CONST_REL_ERR_BITS - 1 downto 0);
		cfg_smax				: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		cfg_resolution			: in std_logic_vector(CONST_RES_BITS - 1 downto 0);
		cfg_damping				: in std_logic_vector(CONST_DAMPING_BITS - 1 downto 0);
		cfg_offset				: in std_logic_vector(CONST_OFFSET_BITS - 1 downto 0);
		--relocators config
		cfg_max_x				: in std_logic_vector(CONST_MAX_X_VALUE_BITS - 1 downto 0);
		cfg_max_y				: in std_logic_vector(CONST_MAX_Y_VALUE_BITS - 1 downto 0);
		cfg_max_z 				: in std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);	
		cfg_max_t				: in std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
		cfg_min_preload_value 	: in std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);
		cfg_max_preload_value 	: in std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);
		--encoder things
		cfg_initial_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_final_counter		: in std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
		cfg_gamma_star			: in std_logic_vector(CONST_MAX_GAMMA_STAR_BITS - 1 downto 0);
		cfg_u_max				: in std_logic_vector(CONST_U_MAX_BITS - 1 downto 0);
		cfg_iacc				: in std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);
		--cfg error out
		cfg_error				: out std_logic_vector(31 downto 0);

		--input port
		axis_in_s_d				: in std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
		axis_in_s_valid			: in std_logic;
		axis_in_s_ready			: out std_logic;
		--output port
		axis_out_data			: out std_logic_vector(63 downto 0);
		axis_out_valid			: out std_logic;
		axis_out_last			: out std_logic;
		axis_out_ready			: in std_logic
	);
end ccsds_123b2_core_selfcheck_wrapper;

architecture Behavioral of ccsds_123b2_core_selfcheck_wrapper is
	-----------------------------------
	--signals for selfchecking mechanism
	type state_t is (RESET, NORMAL_OPERATION, SELFCHECK, SELFCHECK_END);
	signal state_curr, state_next: state_t;
	signal inner_reset: std_logic;
	
	--signals for selfchecking patterns (in & out)
	signal axis_pattern_in_d: std_logic_vector(15 downto 0);
	signal axis_pattern_in_valid, axis_pattern_in_ready: std_logic;
	signal axis_pattern_out_d: std_logic_vector(63 downto 0);
	signal axis_pattern_out_valid, axis_pattern_out_ready: std_logic;

	signal mux_check_enable				: std_logic;
	
	signal selfcheck_full_finished_inner: std_logic;
	signal selfcheck_ref_finished_inner : std_logic;
	
	signal selfcheck_ref_cnt			: unsigned(31 downto 0);
	signal selfcheck_timeout_cnt		: unsigned(31 downto 0);
	
	signal selfcheck_timeout_inner		: std_logic;
	-----------------------------------

	--signals for muxing the core inputs/outputs
	--piping to default lines OR forced patterns (checking case)
	signal mux_cfg_full_prediction		: std_logic;
	signal mux_cfg_p					: std_logic_vector(CONST_MAX_P_WIDTH_BITS - 1 downto 0);
	signal mux_cfg_wide_sum				: std_logic;
	signal mux_cfg_neighbor_sum			: std_logic;
	signal mux_cfg_smid 				: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal mux_cfg_samples				: std_logic_vector(CONST_MAX_SAMPLES_BITS - 1 downto 0);
	signal mux_cfg_tinc					: std_logic_vector(CONST_TINC_BITS - 1 downto 0);
	signal mux_cfg_vmax, mux_cfg_vmin	: std_logic_vector(CONST_VMINMAX_BITS - 1 downto 0);
	signal mux_cfg_depth				: std_logic_vector(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0);
	signal mux_cfg_omega				: std_logic_vector(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0);
	signal mux_cfg_weo					: std_logic_vector(CONST_WEO_BITS - 1 downto 0);
	signal mux_cfg_use_abs_err			: std_logic;
	signal mux_cfg_use_rel_err			: std_logic;
	signal mux_cfg_abs_err 				: std_logic_vector(CONST_ABS_ERR_BITS - 1 downto 0);
	signal mux_cfg_rel_err 				: std_logic_vector(CONST_REL_ERR_BITS - 1 downto 0);
	signal mux_cfg_smax					: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal mux_cfg_resolution			: std_logic_vector(CONST_RES_BITS - 1 downto 0);
	signal mux_cfg_damping				: std_logic_vector(CONST_DAMPING_BITS - 1 downto 0);
	signal mux_cfg_offset				: std_logic_vector(CONST_OFFSET_BITS - 1 downto 0);

	signal mux_cfg_max_x				: std_logic_vector(CONST_MAX_X_VALUE_BITS - 1 downto 0);
	signal mux_cfg_max_y				: std_logic_vector(CONST_MAX_Y_VALUE_BITS - 1 downto 0);
	signal mux_cfg_max_z 				: std_logic_vector(CONST_MAX_Z_VALUE_BITS - 1 downto 0);	
	signal mux_cfg_max_t				: std_logic_vector(CONST_MAX_T_VALUE_BITS - 1 downto 0);
	signal mux_cfg_min_preload_value 	: std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);
	signal mux_cfg_max_preload_value 	: std_logic_vector(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0);

	signal mux_cfg_initial_counter		: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal mux_cfg_final_counter		: std_logic_vector(CONST_MAX_COUNTER_BITS - 1 downto 0);
	signal mux_cfg_gamma_star			: std_logic_vector(CONST_MAX_GAMMA_STAR_BITS - 1 downto 0);
	signal mux_cfg_u_max				: std_logic_vector(CONST_U_MAX_BITS - 1 downto 0);
	signal mux_cfg_iacc					: std_logic_vector(CONST_MAX_HR_ACC_BITS - 1 downto 0);

	signal mux_axis_in_s_d				: std_logic_vector(CONST_MAX_DATA_WIDTH - 1 downto 0);
	signal mux_axis_in_s_valid			: std_logic;
	signal mux_axis_in_s_ready			: std_logic;

	signal mux_axis_out_data			: std_logic_vector(63 downto 0);
	signal mux_axis_out_valid			: std_logic;
	signal mux_axis_out_last			: std_logic;
	signal mux_axis_out_ready			: std_logic;

begin
	seq: process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				state_curr <= RESET;
			else
				state_curr <= state_next;
			end if;
		end if;
	end process;
	
	comb: process(state_curr, selfcheck_init, selfcheck_timeout_inner, selfcheck_full_finished_inner, selfcheck_ref_finished_inner)
	begin
		inner_reset <= '0';
		mux_check_enable <= '0';
		selfcheck_working <= '0';
		state_next <= state_curr;
		
		if state_curr = RESET then
			inner_reset <= '1';
			if selfcheck_init = '1' then
				state_next <= SELFCHECK;
			else 
				state_next <= NORMAL_OPERATION;
			end if;	
		elsif state_curr = NORMAL_OPERATION then
			mux_check_enable <= '0';
		elsif state_curr = SELFCHECK then
			--this connects the memory directly to the core and it should start reading data right away
			mux_check_enable <= '1';	
			selfcheck_working <= '1';
			if selfcheck_timeout_inner = '1' or selfcheck_full_finished_inner = '1' or selfcheck_ref_finished_inner = '1' then
				state_next <= SELFCHECK_END;
			end if;
		elsif state_curr = SELFCHECK_END then
			mux_check_enable <= '1';	
		end if;
	end process;
	
	selfcheck_full_finished <= selfcheck_full_finished_inner;
	selfcheck_full: process(clk)
	begin
		if rising_edge(clk) then
			if inner_reset = '1' then
				selfcheck_full_failed <= '0';
				selfcheck_full_finished_inner <= '0';
			else
				if selfcheck_init = '1' then
					--assume it is always read, since mux_axis_out_ready is tied to 1
					if mux_axis_out_valid = '1' then
						if axis_pattern_out_d /= mux_axis_out_data and selfcheck_full_finished_inner = '0' then
							selfcheck_full_failed <= '1';
							report "Error detected (expected, actual): (" & integer'image(to_integer(signed(axis_pattern_out_d(63 downto 32))))
													  & integer'image(to_integer(signed(axis_pattern_out_d(31 downto 0))))
													  & " , " 
													  & integer'image(to_integer(signed(mux_axis_out_data(63 downto 32))))
													  & integer'image(to_integer(signed(mux_axis_out_data(31 downto 0))))
													  & ")";
							--$info("Seen: 0x%h Expected: 0x%h (@ %d)", data, ref_data, numloops);
						end if;
						if mux_axis_out_last = '1' then
							selfcheck_full_finished_inner <= '1';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	
	selfcheck_ref_finished <= selfcheck_ref_finished_inner;
	selfcheck_ref: process(clk)
	begin
		if rising_edge(clk) then
			if inner_reset = '1' then
				selfcheck_ref_failed <= '0';
				selfcheck_ref_finished_inner <= '0';
				selfcheck_ref_cnt <= to_unsigned(0, selfcheck_ref_cnt'length);
			else
				if selfcheck_init = '1' then
					--assume it is always read, since mux_axis_out_ready is tied to 1
					if mux_axis_out_valid = '1' and selfcheck_ref_finished_inner = '0' then
						if selfcheck_ref_cnt = (selfcheck_ref_cnt_limit - 1) then
							selfcheck_ref_finished_inner <= '1';
							if mux_axis_out_data = selfcheck_ref_checksum then
								selfcheck_ref_failed <= '0';
							else
								selfcheck_ref_failed <= '1';
							end if;
						end if;
						selfcheck_ref_cnt <= selfcheck_ref_cnt + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	selfcheck_timeout <= selfcheck_timeout_inner;
	selfcheck_timeout_calc: process(clk)
	begin
		if rising_edge(clk) then
			if inner_reset = '1' then
				selfcheck_timeout_inner <= '0';
				selfcheck_timeout_cnt <= to_unsigned(0, selfcheck_timeout_cnt'length);
			else
				if selfcheck_init = '1' then
					if selfcheck_timeout_cnt < selfcheck_timeout_cnt_limit then
						selfcheck_timeout_cnt <= selfcheck_timeout_cnt + 1;
					else
						selfcheck_timeout_inner <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
		
		
	--CORE SIGNAL MULTIPLEXING
	input_mux: process(mux_check_enable, axis_pattern_in_d, axis_pattern_in_valid, mux_axis_in_s_ready, mux_axis_out_valid,
		cfg_full_prediction, cfg_p, cfg_wide_sum, cfg_neighbor_sum, cfg_smid, cfg_samples, cfg_tinc, cfg_vmax, cfg_vmin, cfg_depth,
		cfg_omega, cfg_weo, cfg_use_abs_err, cfg_use_rel_err, cfg_abs_err, cfg_rel_err, cfg_smax, cfg_resolution, cfg_damping, cfg_offset, 
		cfg_max_x, cfg_max_y, cfg_max_z, cfg_max_t, cfg_min_preload_value, cfg_max_preload_value, cfg_initial_counter, cfg_final_counter,
		cfg_gamma_star, cfg_u_max, cfg_iacc, axis_in_s_d, axis_in_s_valid, mux_axis_out_data, mux_axis_out_last, axis_out_ready)
	begin
		if (mux_check_enable = '1') then
			mux_cfg_full_prediction		<= '1';
			mux_cfg_p					<= std_logic_vector(to_unsigned(3, 		CONST_MAX_P_WIDTH_BITS));
			mux_cfg_smid 				<= std_logic_vector(to_unsigned(32768, 	CONST_MAX_DATA_WIDTH));
			mux_cfg_wide_sum			<= '1';
			mux_cfg_neighbor_sum		<= '1';
			mux_cfg_samples				<= std_logic_vector(to_unsigned(100, 	CONST_MAX_SAMPLES_BITS));
			mux_cfg_tinc				<= std_logic_vector(to_unsigned(6, 		CONST_TINC_BITS));
			mux_cfg_vmax				<= std_logic_vector(to_unsigned(3, 		CONST_VMINMAX_BITS));
			mux_cfg_vmin 				<= std_logic_vector(to_signed  (-1,		CONST_VMINMAX_BITS));
			mux_cfg_depth				<= std_logic_vector(to_unsigned(16, 	CONST_MAX_DATA_WIDTH_BITS));
			mux_cfg_omega				<= std_logic_vector(to_unsigned(19, 	CONST_MAX_OMEGA_WIDTH_BITS));
			mux_cfg_weo					<= std_logic_vector(to_unsigned(0, 		CONST_WEO_BITS));
			mux_cfg_use_abs_err			<= '1';
			mux_cfg_use_rel_err			<= '1';
			mux_cfg_abs_err 			<= std_logic_vector(to_unsigned(1024, 	CONST_ABS_ERR_BITS));
			mux_cfg_rel_err 			<= std_logic_vector(to_unsigned(4096, 	CONST_REL_ERR_BITS));
			mux_cfg_smax				<= std_logic_vector(to_unsigned(65535, 	CONST_MAX_DATA_WIDTH));
			mux_cfg_resolution			<= std_logic_vector(to_unsigned(4, 		CONST_RES_BITS));
			mux_cfg_damping				<= std_logic_vector(to_unsigned(4, 		CONST_DAMPING_BITS));
			mux_cfg_offset				<= std_logic_vector(to_unsigned(4,		CONST_OFFSET_BITS));
			
			mux_cfg_max_x				<= std_logic_vector(to_unsigned(99, 	CONST_MAX_X_VALUE_BITS));
			mux_cfg_max_y				<= std_logic_vector(to_unsigned(35, 	CONST_MAX_Y_VALUE_BITS));
			mux_cfg_max_z 				<= std_logic_vector(to_unsigned(16, 	CONST_MAX_Z_VALUE_BITS));
			mux_cfg_max_t				<= std_logic_vector(to_unsigned(3599, 	CONST_MAX_T_VALUE_BITS));
			mux_cfg_min_preload_value 	<= std_logic_vector(to_unsigned(122, 	CONST_MAX_Z_VALUE_BITS*2));
			mux_cfg_max_preload_value 	<= std_logic_vector(to_unsigned(126, 	CONST_MAX_Z_VALUE_BITS*2));
			
			mux_cfg_initial_counter		<= std_logic_vector(to_unsigned(2, 		CONST_MAX_COUNTER_BITS));
			mux_cfg_final_counter		<= std_logic_vector(to_unsigned(63, 	CONST_MAX_COUNTER_BITS));
			mux_cfg_gamma_star			<= std_logic_vector(to_unsigned(6, 		CONST_MAX_GAMMA_STAR_BITS));
			mux_cfg_u_max				<= std_logic_vector(to_unsigned(18, 	CONST_U_MAX_BITS));
			mux_cfg_iacc				<= std_logic_vector(to_unsigned(40, 	CONST_MAX_HR_ACC_BITS));
			--bypass input with pattern
			mux_axis_in_s_d				<= axis_pattern_in_d;
			mux_axis_in_s_valid			<= axis_pattern_in_valid;
			axis_pattern_in_ready 		<= mux_axis_in_s_ready;
			axis_in_s_ready 			<= '0';
			--hide axis output
			axis_out_data 				<= (others => '0');
			axis_out_valid 				<= '0';
			axis_out_last				<= '0';
			--force output to be read, and sync with memory
			mux_axis_out_ready			<= '1';
   			axis_pattern_out_ready 		<= mux_axis_out_valid; --read when data comes out of the core
		else
			mux_cfg_full_prediction		<= cfg_full_prediction;
			mux_cfg_p					<= cfg_p;
			mux_cfg_wide_sum			<= cfg_wide_sum;
			mux_cfg_neighbor_sum		<= cfg_neighbor_sum;
			mux_cfg_smid 				<= cfg_smid;
			mux_cfg_samples				<= cfg_samples;
			mux_cfg_tinc				<= cfg_tinc;
			mux_cfg_vmax				<= cfg_vmax;
			mux_cfg_vmin				<= cfg_vmin;
			mux_cfg_depth				<= cfg_depth;
			mux_cfg_omega				<= cfg_omega;
			mux_cfg_weo					<= cfg_weo;
			mux_cfg_use_abs_err			<= cfg_use_abs_err;
			mux_cfg_use_rel_err			<= cfg_use_rel_err;
			mux_cfg_abs_err 			<= cfg_abs_err;
			mux_cfg_rel_err 			<= cfg_rel_err;
			mux_cfg_smax				<= cfg_smax;
			mux_cfg_resolution			<= cfg_resolution;
			mux_cfg_damping				<= cfg_damping;
			mux_cfg_offset				<= cfg_offset;
			
			mux_cfg_max_x				<= cfg_max_x;
			mux_cfg_max_y				<= cfg_max_y;
			mux_cfg_max_z 				<= cfg_max_z;
			mux_cfg_max_t				<= cfg_max_t;
			mux_cfg_min_preload_value 	<= cfg_min_preload_value;
			mux_cfg_max_preload_value 	<= cfg_max_preload_value;
			
			mux_cfg_initial_counter		<= cfg_initial_counter;
			mux_cfg_final_counter		<= cfg_final_counter;
			mux_cfg_gamma_star			<= cfg_gamma_star;
			mux_cfg_u_max				<= cfg_u_max;
			mux_cfg_iacc				<= cfg_iacc;
			
			mux_axis_in_s_d				<= axis_in_s_d;
			mux_axis_in_s_valid			<= axis_in_s_valid;
			axis_in_s_ready 			<= mux_axis_in_s_ready;
			axis_pattern_in_ready 		<= '0';
			axis_pattern_out_ready 		<= '0';
			
			axis_out_data 				<= mux_axis_out_data;
			axis_out_valid 				<= mux_axis_out_valid;
			axis_out_last				<= mux_axis_out_last;
			mux_axis_out_ready			<= axis_out_ready;
		end if;
	end process;
		
	--CORE INTERFACE
	core: entity work.ccsds_123b2_core
		port map (
			clk => clk,
			rst => inner_reset,
			cfg_full_prediction 	=> mux_cfg_full_prediction,
			cfg_p					=> mux_cfg_p,
			cfg_wide_sum			=> mux_cfg_wide_sum,
			cfg_neighbor_sum		=> mux_cfg_neighbor_sum,
			cfg_smid 				=> mux_cfg_smid,
			cfg_samples				=> mux_cfg_samples,
			cfg_tinc				=> mux_cfg_tinc,
			cfg_vmax				=> mux_cfg_vmax,
			cfg_vmin				=> mux_cfg_vmin,
			cfg_depth				=> mux_cfg_depth,
			cfg_omega				=> mux_cfg_omega,
			cfg_weo					=> mux_cfg_weo,
			cfg_use_abs_err			=> mux_cfg_use_abs_err,
			cfg_use_rel_err			=> mux_cfg_use_rel_err,
			cfg_abs_err 			=> mux_cfg_abs_err,
			cfg_rel_err 			=> mux_cfg_rel_err,
			cfg_smax				=> mux_cfg_smax,
			cfg_resolution			=> mux_cfg_resolution,
			cfg_damping				=> mux_cfg_damping,
			cfg_offset				=> mux_cfg_offset,
			cfg_max_x				=> mux_cfg_max_x,
			cfg_max_y				=> mux_cfg_max_y,
			cfg_max_z 				=> mux_cfg_max_z,	
			cfg_max_t				=> mux_cfg_max_t,
			cfg_min_preload_value 	=> mux_cfg_min_preload_value,
			cfg_max_preload_value 	=> mux_cfg_max_preload_value,
			cfg_initial_counter		=> mux_cfg_initial_counter,
			cfg_final_counter		=> mux_cfg_final_counter,
			cfg_gamma_star			=> mux_cfg_gamma_star,
			cfg_u_max				=> mux_cfg_u_max,
			cfg_iacc				=> mux_cfg_iacc,
			cfg_error				=> cfg_error,
			axis_in_s_d				=> mux_axis_in_s_d,
			axis_in_s_valid			=> mux_axis_in_s_valid,
			axis_in_s_ready			=> mux_axis_in_s_ready,
			axis_out_data			=> mux_axis_out_data,
			axis_out_valid			=> mux_axis_out_valid,
			axis_out_last			=> mux_axis_out_last,
			axis_out_ready			=> mux_axis_out_ready
		);


	--ROMS TO USE FOR I/O

	pattern_rom: entity work.axis_rom_fifo
		generic map (
			width => 16,
			depth => selfcheck_input_words,
			intFile => PATTERN_IN
		)
		port map (
			clk => clk,
			rst => inner_reset,
			axis_d => 		axis_pattern_in_d,
			axis_valid =>	axis_pattern_in_valid,
			axis_ready =>	axis_pattern_in_ready
		);

	fullcheck_rom: entity work.axis_rom_fifo
		generic map (
			width => 64,
			depth => selfcheck_ref_cnt_limit,
			intFile => PATTERN_OUT
		)
		port map (
			clk => clk,
			rst => inner_reset,
			axis_d => 		axis_pattern_out_d,
			axis_valid =>	axis_pattern_out_valid,
			axis_ready =>	axis_pattern_out_ready
		);

end Behavioral;
