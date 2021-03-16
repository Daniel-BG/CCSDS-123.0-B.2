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
	
	--OTHER CONSTANTS
	constant STDLV_ONE: std_logic_vector(0 downto 0) := "1";
	constant STDLV_ZERO: std_logic_vector(0 downto 0) := "0";

	--FIXED CONSTANTS
	constant CONST_MAX_DATA_WIDTH		: integer := 32;				--maximum allowed bits for inputs (Can be set lower through cfg ports)
	constant CONST_MAX_OMEGA_WIDTH		: integer := 19;				--maximum allowed bits for weights (Can be set lower through cfg ports)
	constant CONST_MAX_P				: integer := 6;					--maximum allowed bits for previous bands used in prediction
	constant CONST_MAX_X				: integer := 512;				--maximum allowed size in the x direction (Can be set lower through cfg ports)
	constant CONST_MAX_Y				: integer := 512;				--maximum allowed size in the y direction (Can be set lower through cfg ports)
	constant CONST_MAX_Z				: integer := 512;  				--maximum allowed size in the z direction (Can be set lower through cfg ports)
	
	constant CONST_MAX_RES_VAL 			: integer := 4;
	
	constant CONST_ABS_ERR_BITS 		: integer := 16; --has to be min(D-1, 16). 16 ensures it always fits
	constant CONST_REL_ERR_BITS 		: integer := 16; --has to be min(D-1, 16). 16 ensures it always fits
	
	--DERIVED CONSTANTS
	constant CONST_MAX_T				: integer := CONST_MAX_Y * CONST_MAX_X;
	constant CONST_MAX_OMEGA_WIDTH_BITS	: integer := BITS(CONST_MAX_OMEGA_WIDTH);		
	constant CONST_MAX_DATA_WIDTH_BITS: integer := BITS(CONST_MAX_DATA_WIDTH);	
	
	constant CONST_MAX_X_BITS			: integer := BITS(CONST_MAX_X);
	constant CONST_MAX_Y_BITS			: integer := BITS(CONST_MAX_Y);
	constant CONST_MAX_Z_BITS			: integer := BITS(CONST_MAX_Z);
	constant CONST_MAX_T_BITS			: integer := BITS(CONST_MAX_T);
	
	constant CONST_CQBC_BITS			: integer := CONST_MAX_DATA_WIDTH;
	constant CONST_QI_BITS				: integer := CONST_MAX_DATA_WIDTH + 1;
	constant CONST_LSUM_BITS			: integer := CONST_MAX_DATA_WIDTH + 2;
	constant CONST_LDIF_BITS			: integer := CONST_MAX_DATA_WIDTH + 3;
	constant CONST_DRSR_BITS 			: integer := CONST_MAX_DATA_WIDTH + 1;
	constant CONST_DRPSV_BITS 			: integer := CONST_MAX_DATA_WIDTH + 1;
	constant CONST_DRPE_BITS 			: integer := CONST_MAX_DATA_WIDTH + 2;
	
	constant CONST_MEV_BITS 			: integer := MAX(CONST_ABS_ERR_BITS, CONST_REL_ERR_BITS);
	constant CONST_PCLD_BITS 			: integer := CONST_MAX_OMEGA_WIDTH + 3 + BITS((2**CONST_MAX_DATA_WIDTH - 1)*(8*CONST_MAX_P + 19));
	constant CONST_HRPSV_BITS			: integer := CONST_MAX_OMEGA_WIDTH + 2 + CONST_MAX_DATA_WIDTH; 
	
	constant CONST_RES_BITS				: integer := BITS(CONST_MAX_RES_VAL);
	constant CONST_DAMPING_BITS			: integer := CONST_MAX_RES_VAL;
	constant CONST_OFFSET_BITS			: integer := CONST_MAX_RES_VAL;
	
	constant CONST_WUSE_BITS 			: integer := 7;
	constant CONST_TINC_BITS 			: integer := 4;
	constant CONST_VMINMAX_BITS 		: integer := 5;
	--ALGORITM CONSTANTS
	
	
	
	

end ccsds_constants;

package body ccsds_constants is
	
end ccsds_constants;
