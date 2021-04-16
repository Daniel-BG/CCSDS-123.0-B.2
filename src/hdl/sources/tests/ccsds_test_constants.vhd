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

package ccsds_test_constants is
	constant CONST_CHECK_RESULTS: boolean := true;
	constant CONST_BASE_GOLDEN_DIRECTORY: string := "C:\\Users\\Daniel\\Basurero\\out\\";
	
	--PREDICTOR
	constant CONST_GOLDEN_S 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_s.smp";
	constant CONST_GOLDEN_DRPSV : string := CONST_BASE_GOLDEN_DIRECTORY & "c_drpsv.smp";
	constant CONST_GOLDEN_PSV 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_psv.smp";
	constant CONST_GOLDEN_PR 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_pr.smp";
	constant CONST_GOLDEN_W		: string := CONST_BASE_GOLDEN_DIRECTORY & "c_w.smp";
	constant CONST_GOLDEN_WUSE 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_wuse.smp";
	constant CONST_GOLDEN_DRPE 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_drpe.smp";
	constant CONST_GOLDEN_DRSR 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_drsr.smp";
	constant CONST_GOLDEN_CQBC 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_cqbc.smp";
	constant CONST_GOLDEN_MEV 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_mev.smp";
	constant CONST_GOLDEN_HRPSV : string := CONST_BASE_GOLDEN_DIRECTORY & "c_hrpsv.smp";
	constant CONST_GOLDEN_PCD 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_pcd.smp";
	constant CONST_GOLDEN_CLD 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_cld.smp";
	constant CONST_GOLDEN_NWD 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_nwd.smp";
	constant CONST_GOLDEN_WD 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_wd.smp";
	constant CONST_GOLDEN_ND 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_nd.smp";
	constant CONST_GOLDEN_LS 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_ls.smp";
	constant CONST_GOLDEN_QI 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_qi.smp";
	constant CONST_GOLDEN_SR 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_sr.smp";
	constant CONST_GOLDEN_TS 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_ts.smp";
	constant CONST_GOLDEN_MQI 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_mqi.smp";
	--ENCODER
	constant CONST_GOLDEN_ACC 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_acc.smp";
	constant CONST_GOLDEN_CNT 	: string := CONST_BASE_GOLDEN_DIRECTORY & "c_cnt.smp";
	
	
end ccsds_test_constants;

package body ccsds_test_constants is
	
end ccsds_test_constants;
