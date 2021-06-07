/*
 * ccsds_driver.c
 *
 *  Created on: 10 abr. 2019
 *      Author: Daniel
 */


#include "ccsds_driver.h"


inline void XCCSDS_SetSize(UINTPTR BaseAddress, u32 ImageBands, u32 ImageLines, u32 ImageSamples) {
	//Set image boundary sizes
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CFG_SAMPLES_LOCALADDR, ImageSamples);
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CFG_MAX_X_LOCALADDR, ImageSamples - 1);
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CFG_MAX_Y_LOCALADDR, ImageLines - 1);
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CFG_MAX_Z_LOCALADDR, ImageBands - 1);
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CFG_MAX_T_LOCALADDR, ImageSamples*ImageLines - 1);
	//Set preload max and min values based on image size
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CFG_MIN_PRELOAD_VALUE_LOCALADDR, ((ImageBands-1)*(ImageBands-2))/2+2);
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CFG_MAX_PRELOAD_VALUE_LOCALADDR, ((ImageBands-1)*(ImageBands-2))/2+6);
	//Set number of bytes to read based on image size and sample size
	XCCSDS_Out32(BaseAddress + CCSDS_REG_BYTENO_LOCALADDR, ImageSamples * ImageLines * ImageBands * CCSDS_INPUT_BYTE_WIDTH);
}

inline sint32 XCCSDS_GetParam(UINTPTR BaseAddress, u32 LocalAddr) {
	return XCCSDS_In32(BaseAddress + LocalAddr);
}

inline void XCCSDS_SetParam(UINTPTR BaseAddress, u32 LocalAddr, sint32 value) {
	XCCSDS_Out32(BaseAddress + LocalAddr, value);
}

inline void XCCSDS_SetDefaultParameters(UINTPTR BaseAddress) {
	//<Autogen by CCSDS.java>
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_P_LOCALADDR, 				3);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_TINC_LOCALADDR, 				6);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_VMAX_LOCALADDR, 				3);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_VMIN_LOCALADDR, 				-1);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_DEPTH_LOCALADDR, 			16);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_OMEGA_LOCALADDR, 			19);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_WEO_LOCALADDR, 				0);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_USE_ABS_ERR_LOCALADDR, 		0);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_USE_REL_ERR_LOCALADDR,		1);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_ABS_ERR_LOCALADDR, 			0);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_REL_ERR_LOCALADDR, 			2048);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_SMAX_LOCALADDR, 				65535);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_RESOLUTION_LOCALADDR, 		4);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_DAMPING_LOCALADDR, 			4);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_OFFSET_LOCALADDR, 			4);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_INITIAL_COUNTER_LOCALADDR,	2);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_FINAL_COUNTER_LOCALADDR, 	63);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_GAMMA_STAR_LOCALADDR, 		6);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_U_MAX_LOCALADDR, 			18);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_IACC_LOCALADDR, 				40);
	XCCSDS_SetParam(BaseAddress, CCSDS_REG_CFG_SUM_TYPE_LOCALADDR, 			1);
	//</Autogen by CCSDS.java>
}

inline void XCCSDS_SetAddresses(UINTPTR BaseAddress, u32 SourceAddress, u32 TargetAddress) {
	XCCSDS_Out32(BaseAddress + CCSDS_REG_STADDR_LOCALADDR, SourceAddress);
	XCCSDS_Out32(BaseAddress + CCSDS_REG_TGADDR_LOCALADDR, TargetAddress);
}

inline void XCCSDS_Reset(UINTPTR BaseAddress, u32 cycles) {
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CTRLRG_LOCALADDR, CCSDS_CONTROL_CODE_RESET);
	//wait a few cycles
	for(int i = 0; i < cycles; i++);
	//end wait
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CTRLRG_LOCALADDR, CCSDS_CONTROL_CODE_NULL);
}

inline int XCCSDS_GetStatus(UINTPTR BaseAddress) {
	return XCCSDS_In32(BaseAddress + CCSDS_REG_STATUS_LOCALADDR);
}

inline void XCCSDS_Start(UINTPTR BaseAddress) {
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CTRLRG_LOCALADDR, CCSDS_CONTROL_CODE_START_0);
	while (XCCSDS_GetStatus(BaseAddress) != CCSDS_STATUS_WAIT_START_1);
	XCCSDS_Out32(BaseAddress + CCSDS_REG_CTRLRG_LOCALADDR, CCSDS_CONTROL_CODE_START_1);
}

inline int XCCSDS_IsIdle(UINTPTR BaseAddress) {
	return XCCSDS_GetStatus(BaseAddress) == CCSDS_STATUS_IDLE;
}

inline long long XCCSDS_GetMemTime(UINTPTR BaseAddress) {
	unsigned int mtime_low, mtime_high;
	mtime_low	= XCCSDS_In32(BaseAddress + CCSDS_REG_MMCLKL_LOCALADDR);
	mtime_high	= XCCSDS_In32(BaseAddress + CCSDS_REG_MMCLKU_LOCALADDR);
	return ((long long) mtime_high) << 32 | (((long long) mtime_low) & 0xffffffffl);
}

inline long long XCCSDS_GetControlTime(UINTPTR BaseAddress) {
	unsigned int mtime_low, mtime_high;
	mtime_low	= XCCSDS_In32(BaseAddress + CCSDS_REG_CNCLKL_LOCALADDR);
	mtime_high	= XCCSDS_In32(BaseAddress + CCSDS_REG_CNCLKU_LOCALADDR);
	return ((long long) mtime_high) << 32 | (((long long) mtime_low) & 0xffffffffl);
}

inline long long XCCSDS_GetCoreTime(UINTPTR BaseAddress) {
	unsigned int mtime_low, mtime_high;
	mtime_low	= XCCSDS_In32(BaseAddress + CCSDS_REG_COCLKL_LOCALADDR);
	mtime_high	= XCCSDS_In32(BaseAddress + CCSDS_REG_COCLKU_LOCALADDR);
	return ((long long) mtime_high) << 32 | (((long long) mtime_low) & 0xffffffffl);
}














