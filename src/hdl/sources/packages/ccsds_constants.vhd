----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.03.2021 10:35:20
-- Design Name: 
-- Module Name: constants - Behavioral
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
use work.ccsds_math_functions.all;

package ccsds_constants is
	--IMAGE CONSTANTS
	type local_sum_t is (WIDE_NEIGHBOR_ORIENTED, WIDE_COLUMN_ORIENTED);
	type relocation_mode_t is (VERTICAL_TO_DIAGONAL, DIAGONAL_TO_VERTICAL); 
	
	--OTHER CONSTANTS
	constant STDLV_ONE: std_logic_vector(0 downto 0) := "1";
	constant STDLV_ZERO: std_logic_vector(0 downto 0) := "0";
	
	--FIXED CONSTANTS
	constant CONST_TINC_MIN				: integer := 4;
	constant CONST_TINC_MAX				: integer := 11;
	constant CONST_TINC_BITS 			: integer := 4;
	constant CONST_VMIN					: integer := -6;
	constant CONST_VMAX					: integer := 9;
	constant CONST_VMINMAX_BITS 		: integer := 5;
	constant CONST_WEO_MIN				: integer := -6;
	constant CONST_WEO_MAX				: integer := 5;
	constant CONST_WEO_BITS 			: integer := 4;
	constant CONST_MAX_RES_VAL 			: integer := 4;
	constant CONST_DATA_WIDTH_MAX		: integer := 32;
	constant CONST_DATA_WIDTH_MIN		: integer := 2;
	constant CONST_OMEGA_WIDTH_MAX		: integer := 19;
	constant CONST_OMEGA_WIDTH_MIN		: integer := 4;
	constant CONST_WUSE_BITS 			: integer := 7;

	--CONSTANTS THAT CAN ALTER RESOURCE USE
	constant CONST_MAX_DATA_WIDTH		: integer := 16;				--maximum allowed bits for inputs (Can be set lower through cfg ports)
	constant CONST_MAX_OMEGA			: integer := 19;				--maximum allowed bits for weights (Can be set lower through cfg ports)
	constant CONST_MIN_OMEGA			: integer := 4;
	constant CONST_MAX_P				: integer := 3;					--maximum allowed bits for previous bands used in prediction
	constant CONST_MAX_BANDS			: integer := 256;				--maximum allowed size in the x direction (Can be set lower through cfg ports)
	constant CONST_MAX_LINES			: integer := 1024;				--maximum allowed size in the y direction (Can be set lower through cfg ports)
	constant CONST_MAX_SAMPLES			: integer := 512;  				--maximum allowed size in the z direction (Can be set lower through cfg ports)
	
	--DERIVED CONSTANTS
	constant CONST_MAX_SAMPLES_PER_BAND	: integer := CONST_MAX_SAMPLES * CONST_MAX_LINES;
	
	constant CONST_MAX_X_VALUE			: integer := CONST_MAX_SAMPLES - 1;	--maximum allowed size in the x direction (Can be set lower through cfg ports)
	constant CONST_MAX_Y_VALUE			: integer := CONST_MAX_LINES - 1;	--maximum allowed size in the y direction (Can be set lower through cfg ports)
	constant CONST_MAX_Z_VALUE			: integer := CONST_MAX_BANDS - 1;  	--maximum allowed size in the z direction (Can be set lower through cfg ports)
	constant CONST_MAX_T_VALUE			: integer := CONST_MAX_SAMPLES_PER_BAND - 1;
	
	constant CONST_ABS_ERR_BITS 		: integer := MIN(CONST_MAX_DATA_WIDTH - 1, 16); 
	constant CONST_REL_ERR_BITS 		: integer := MIN(CONST_MAX_DATA_WIDTH - 1, 16); 
	
	constant CONST_MAX_WEIGHT_BITS		: integer := CONST_MAX_OMEGA + 3;
	constant CONST_MAX_C				: integer := CONST_MAX_P + 3; --number of previous bands plus 3 (full pred mode)
	constant CONST_MAX_OMEGA_WIDTH_BITS	: integer := BITS(CONST_MAX_OMEGA);		
	constant CONST_MAX_DATA_WIDTH_BITS	: integer := BITS(CONST_MAX_DATA_WIDTH);	
	constant CONST_MAX_P_WIDTH_BITS  	: integer := BITS(CONST_MAX_P);
	constant CONST_MAX_C_BITS			: integer := BITS(CONST_MAX_C);
	
	constant CONST_MAX_X_VALUE_BITS		: integer := BITS(CONST_MAX_X_VALUE);
	constant CONST_MAX_Y_VALUE_BITS		: integer := BITS(CONST_MAX_Y_VALUE);
	constant CONST_MAX_Z_VALUE_BITS		: integer := BITS(CONST_MAX_Z_VALUE);
	constant CONST_MAX_T_VALUE_BITS		: integer := BITS(CONST_MAX_T_VALUE);
	
	constant CONST_MAX_BANDS_BITS		: integer := BITS(CONST_MAX_BANDS);
	constant CONST_MAX_LINES_BITS		: integer := BITS(CONST_MAX_LINES);
	constant CONST_MAX_SAMPLES_BITS		: integer := BITS(CONST_MAX_SAMPLES);
	
	constant CONST_CQBC_BITS			: integer := CONST_MAX_DATA_WIDTH;
	constant CONST_QI_BITS				: integer := CONST_MAX_DATA_WIDTH + 1;
	constant CONST_LSUM_BITS			: integer := CONST_MAX_DATA_WIDTH + 2;
	constant CONST_LDIF_BITS			: integer := CONST_MAX_DATA_WIDTH + 3;
	constant CONST_DRSR_BITS 			: integer := CONST_MAX_DATA_WIDTH + 1;
	constant CONST_DRPSV_BITS 			: integer := CONST_MAX_DATA_WIDTH + 1;
	constant CONST_DRPE_BITS 			: integer := CONST_MAX_DATA_WIDTH + 2;
	constant CONST_PR_BITS 				: integer := CONST_MAX_DATA_WIDTH + 1;
	
	constant CONST_MEV_BITS 			: integer := MAX(CONST_ABS_ERR_BITS, CONST_REL_ERR_BITS);
	constant CONST_PCLD_BITS 			: integer := CONST_MAX_WEIGHT_BITS + BITS((2**CONST_MAX_DATA_WIDTH - 1)*(8*CONST_MAX_P + 19));
	constant CONST_HRPSV_BITS			: integer := CONST_MAX_OMEGA + 2 + CONST_MAX_DATA_WIDTH; 
	
	constant CONST_RES_BITS				: integer := BITS(CONST_MAX_RES_VAL);
	constant CONST_DAMPING_BITS			: integer := CONST_MAX_RES_VAL;
	constant CONST_OFFSET_BITS			: integer := CONST_MAX_RES_VAL;
	
	constant CONST_DIFFVEC_BITS 		: integer := CONST_MAX_C * CONST_LDIF_BITS;
	constant CONST_CLDVEC_BITS 			: integer := CONST_MAX_P * CONST_LDIF_BITS;
	constant CONST_DIRDIFFVEC_BITS		: integer := 3 * CONST_LDIF_BITS;
	constant CONST_WEIGHTVEC_BITS		: integer := CONST_MAX_C * CONST_MAX_WEIGHT_BITS;
	
	constant CONST_W_UPDATE_BITS		: integer := CONST_LDIF_BITS - CONST_VMIN - CONST_WEO_MIN - CONST_DATA_WIDTH_MIN + CONST_OMEGA_WIDTH_MAX; --should be 64
	
	constant CONST_THETA_BITS			: integer := CONST_MAX_DATA_WIDTH;
	constant CONST_MQI_BITS				: integer := CONST_MAX_DATA_WIDTH;
	
	--ENCODER CONSTANTS
	constant CONST_MIN_GAMMA_ZERO		: integer := 1;
	constant CONST_MAX_GAMMA_ZERO		: integer := 8;
	constant CONST_MAX_GAMMA_STAR		: integer := 11;
	constant CONST_MAX_COUNTER_BITS 	: integer := CONST_MAX_GAMMA_STAR;
	constant CONST_MAX_ACC_BITS			: integer := CONST_MAX_GAMMA_STAR + CONST_MAX_DATA_WIDTH;
	constant CONST_MAX_K				: integer := CONST_MAX_DATA_WIDTH - 2;
	constant CONST_MAX_K_BITS			: integer := BITS(CONST_MAX_K);
	constant CONST_U_MAX_MIN			: integer := 8;
	constant CONST_U_MAX_MAX			: integer := 32;
	constant CONST_U_MAX_BITS			: integer := BITS(CONST_U_MAX_MAX);
	
	constant CONST_MAX_CODE_LENGTH		: integer := CONST_U_MAX_MAX + CONST_MAX_DATA_WIDTH;
	constant CONST_MAX_CODE_LENGTH_BITS : integer := BITS(CONST_MAX_CODE_LENGTH);
	
	
	
	

end ccsds_constants;

package body ccsds_constants is
	
end ccsds_constants;
