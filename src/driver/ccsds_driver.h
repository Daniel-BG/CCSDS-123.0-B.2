/*
 * ccsds_driver.h
 *
 *  Created on: 25 may. 2021
 *      Author: Daniel
 */

#ifndef CCSDS_DRIVER_H
#define CCSDS_DRIVER_H

#include "xil_types.h"
#include "xil_io.h"



#define CCSDS_REG_CTRLRG_LOCALADDR 					0
#define CCSDS_REG_STADDR_LOCALADDR 					4
#define CCSDS_REG_TGADDR_LOCALADDR 					8
#define CCSDS_REG_BYTENO_LOCALADDR 					12

#define CCSDS_REG_CFG_P_LOCALADDR 					36
#define CCSDS_REG_CFG_SUM_TYPE_LOCALADDR 			40
#define CCSDS_REG_CFG_SAMPLES_LOCALADDR 			44
#define CCSDS_REG_CFG_TINC_LOCALADDR 				48
#define CCSDS_REG_CFG_VMAX_LOCALADDR 				52
#define CCSDS_REG_CFG_VMIN_LOCALADDR 				56
#define CCSDS_REG_CFG_DEPTH_LOCALADDR 				60
#define CCSDS_REG_CFG_OMEGA_LOCALADDR 				64
#define CCSDS_REG_CFG_WEO_LOCALADDR 				68
#define CCSDS_REG_CFG_USE_ABS_ERR_LOCALADDR 		72
#define CCSDS_REG_CFG_USE_REL_ERR_LOCALADDR 		76
#define CCSDS_REG_CFG_ABS_ERR_LOCALADDR 			80
#define CCSDS_REG_CFG_REL_ERR_LOCALADDR 			84
#define CCSDS_REG_CFG_SMAX_LOCALADDR 				88
#define CCSDS_REG_CFG_RESOLUTION_LOCALADDR 			92
#define CCSDS_REG_CFG_DAMPING_LOCALADDR 			96
#define CCSDS_REG_CFG_OFFSET_LOCALADDR 				100
#define CCSDS_REG_CFG_MAX_X_LOCALADDR 				104
#define CCSDS_REG_CFG_MAX_Y_LOCALADDR 				108
#define CCSDS_REG_CFG_MAX_Z_LOCALADDR 				112
#define CCSDS_REG_CFG_MAX_T_LOCALADDR 				116
#define CCSDS_REG_CFG_MIN_PRELOAD_VALUE_LOCALADDR 	120
#define CCSDS_REG_CFG_MAX_PRELOAD_VALUE_LOCALADDR 	124
#define CCSDS_REG_CFG_INITIAL_COUNTER_LOCALADDR 	128
#define CCSDS_REG_CFG_FINAL_COUNTER_LOCALADDR 		132
#define CCSDS_REG_CFG_GAMMA_STAR_LOCALADDR 			136
#define CCSDS_REG_CFG_U_MAX_LOCALADDR 				140
#define CCSDS_REG_CFG_IACC_LOCALADDR 				144

#define CCSDS_REG_STATUS_LOCALADDR 					256
#define CCSDS_REG_INBYTE_LOCALADDR 					260
#define CCSDS_REG_OUTBYT_LOCALADDR 					264
#define CCSDS_REG_DDRRST_LOCALADDR 					268
#define CCSDS_REG_DDRWST_LOCALADDR 					272
#define CCSDS_REG_CNCLKL_LOCALADDR					276	//lower part of clock count for control bus
#define CCSDS_REG_CNCLKU_LOCALADDR					280	//upper part of clock count for control bus
#define CCSDS_REG_MMCLKL_LOCALADDR					284	//lower part of clock count for memory bus
#define CCSDS_REG_MMCLKU_LOCALADDR					288	//upper part of clock count for memory bus
#define CCSDS_REG_COCLKL_LOCALADDR					292	//lower part of clock count for core
#define CCSDS_REG_COCLKU_LOCALADDR					296	//upper part of clock count for core


					
#define CCSDS_REG_CONFIG_LOCALADDR 					384 
#define CCSDS_REG_SIGN_LOCALADDR					500
#define CCSDS_REG_DBGREG_LOCALADDR 					508


//CONTROL CODES AND OTHERS
#define CCSDS_CONTROL_CODE_NULL						0
#define CCSDS_CONTROL_CODE_RESET					127
#define CCSDS_CONTROL_CODE_START_0					62
#define CCSDS_CONTROL_CODE_START_1					63

#define CCSDS_STATUS_IDLE			0x1
#define CCSDS_STATUS_WAIT_START_1 	0x100

#define CCSDS_INPUT_BYTE_WIDTH						2
/*
 * Define the appropriate I/O access method to memory mapped I/O or DCR.
 */


#define XCCSDS_In32(A)		(*(volatile u32 *) (A))
#define XCCSDS_Out32(A, B)	((*(volatile u32 *) (A)) = (B))


/****************************************************************************/
/**
*
* Write a value to a CCSDS register. A 32 bit write is performed.
*
* @param	BaseAddress is the base address of the CCSDS device.
* @param	RegOffset is the register offset from the base to write to.
* @param	Data is the data written to the register.
*
* @return	None.
*
* @note		C-style signature:
*		void XCCSDS_WriteReg(u32 BaseAddress, u32 RegOffset,
*					u32 Data)
*
****************************************************************************/
#define XCCSDS_WriteReg(BaseAddress, RegOffset, Data) \
	XCCSDS_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/****************************************************************************/
/**
*
* Read a value from a CCSDS register. A 32 bit read is performed.
*
* @param	BaseAddress is the base address of the CCSDS device.
* @param	RegOffset is the register offset from the base to read from.
*
* @return	Data read from the register.
*
* @note		C-style signature:
*		u32 XCCSDS_ReadReg(u32 BaseAddress, u32 RegOffset)
*
****************************************************************************/
#define XCCSDS_ReadReg(BaseAddress, RegOffset) \
	XCCSDS_In32((BaseAddress) + (RegOffset))


/************************** Function Prototypes *****************************/

void XCCSDS_SetSize(UINTPTR BaseAddress, u32 ImageBands, u32 ImageLines, u32 ImageSamples);
sint32 XCCSDS_GetParam(UINTPTR BaseAddress, u32 LocalAddr);
void XCCSDS_SetParam(UINTPTR BaseAddress, u32 LocalAddr, sint32 value);
void XCCSDS_SetDefaultParameters(UINTPTR BaseAddress);
void XCCSDS_SetAddresses(UINTPTR BaseAddress, u32 SourceAddress, u32 TargetAddress);
void XCCSDS_Reset(UINTPTR BaseAddress, u32 cycles);
int XCCSDS_GetStatus(UINTPTR BaseAddress);
void XCCSDS_Start(UINTPTR BaseAddress);
int XCCSDS_IsIdle(UINTPTR BaseAddress);
long long XCCSDS_GetMemTime(UINTPTR BaseAddress);
long long XCCSDS_GetControlTime(UINTPTR BaseAddress);
long long XCCSDS_GetCoreTime(UINTPTR BaseAddress);

#endif /* CCSDS_DRIVER_H */
