`ifndef CCSDS_TEST_SHARED_SVH
	`define CCSDS_TEST_SHARED_SVH
	
	`define GOLDEN_ROOT_DIR "C:/Users/Daniel/Basurero/out/"
	`define GOLDEN_EXT ".smp"
	`define GOLDEN_EXT_DIAG ".smp.diag"
	//PREDICTOR
	`define CONST_GOLDEN_S 	    {`GOLDEN_ROOT_DIR, "c_s",					`GOLDEN_EXT}
	`define CONST_GOLDEN_DRPSV  {`GOLDEN_ROOT_DIR, "c_drpsv",				`GOLDEN_EXT}
	`define CONST_GOLDEN_PSV 	{`GOLDEN_ROOT_DIR, "c_psv",					`GOLDEN_EXT}
	`define CONST_GOLDEN_PR 	{`GOLDEN_ROOT_DIR, "c_pr",					`GOLDEN_EXT}
	`define CONST_GOLDEN_W		{`GOLDEN_ROOT_DIR, "c_w",					`GOLDEN_EXT}
	`define CONST_GOLDEN_WUSE   {`GOLDEN_ROOT_DIR, "c_wuse",				`GOLDEN_EXT}
	`define CONST_GOLDEN_DRPE   {`GOLDEN_ROOT_DIR, "c_drpe",				`GOLDEN_EXT}
	`define CONST_GOLDEN_DRSR   {`GOLDEN_ROOT_DIR, "c_drsr",				`GOLDEN_EXT}
	`define CONST_GOLDEN_CQBC   {`GOLDEN_ROOT_DIR, "c_cqbc",				`GOLDEN_EXT}
	`define CONST_GOLDEN_MEV 	{`GOLDEN_ROOT_DIR, "c_mev",					`GOLDEN_EXT}
	`define CONST_GOLDEN_HRPS   {`GOLDEN_ROOT_DIR, "c_hrpsv",				`GOLDEN_EXT}
	`define CONST_GOLDEN_PCD 	{`GOLDEN_ROOT_DIR, "c_pcd",					`GOLDEN_EXT}
	`define CONST_GOLDEN_CLD 	{`GOLDEN_ROOT_DIR, "c_cld",					`GOLDEN_EXT}
	`define CONST_GOLDEN_NWD 	{`GOLDEN_ROOT_DIR, "c_nwd",					`GOLDEN_EXT}
	`define CONST_GOLDEN_WD 	{`GOLDEN_ROOT_DIR, "c_wd",					`GOLDEN_EXT}
	`define CONST_GOLDEN_ND 	{`GOLDEN_ROOT_DIR, "c_nd",					`GOLDEN_EXT}
	`define CONST_GOLDEN_LS 	{`GOLDEN_ROOT_DIR, "c_ls",					`GOLDEN_EXT}
	`define CONST_GOLDEN_QI 	{`GOLDEN_ROOT_DIR, "c_qi",					`GOLDEN_EXT}
	`define CONST_GOLDEN_SR 	{`GOLDEN_ROOT_DIR, "c_sr",					`GOLDEN_EXT}
	`define CONST_GOLDEN_TS 	{`GOLDEN_ROOT_DIR, "c_ts",					`GOLDEN_EXT}
	`define CONST_GOLDEN_MQI 	{`GOLDEN_ROOT_DIR, "c_mqi",					`GOLDEN_EXT}
	//PREDICTOR DIAGONAL
	`define CONST_GOLDEN_DIAG_S		{`GOLDEN_ROOT_DIR, "c_s",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_DRPSV {`GOLDEN_ROOT_DIR, "c_drpsv",				`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_PSV 	{`GOLDEN_ROOT_DIR, "c_psv",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_PR 	{`GOLDEN_ROOT_DIR, "c_pr",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_W		{`GOLDEN_ROOT_DIR, "c_w",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_WUSE  {`GOLDEN_ROOT_DIR, "c_wuse",				`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_DRPE  {`GOLDEN_ROOT_DIR, "c_drpe",				`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_DRSR  {`GOLDEN_ROOT_DIR, "c_drsr",				`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_CQBC  {`GOLDEN_ROOT_DIR, "c_cqbc",				`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_MEV 	{`GOLDEN_ROOT_DIR, "c_mev",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_HRPS  {`GOLDEN_ROOT_DIR, "c_hrpsv",				`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_PCD 	{`GOLDEN_ROOT_DIR, "c_pcd",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_CLD 	{`GOLDEN_ROOT_DIR, "c_cld",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_NWD 	{`GOLDEN_ROOT_DIR, "c_nwd",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_WD 	{`GOLDEN_ROOT_DIR, "c_wd",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_ND 	{`GOLDEN_ROOT_DIR, "c_nd",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_LS 	{`GOLDEN_ROOT_DIR, "c_ls",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_QI 	{`GOLDEN_ROOT_DIR, "c_qi",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_SR 	{`GOLDEN_ROOT_DIR, "c_sr",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_TS 	{`GOLDEN_ROOT_DIR, "c_ts",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_MQI 	{`GOLDEN_ROOT_DIR, "c_mqi",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_WR 	{`GOLDEN_ROOT_DIR, "c_wr",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_NWR 	{`GOLDEN_ROOT_DIR, "c_nwr",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_NER 	{`GOLDEN_ROOT_DIR, "c_ner",					`GOLDEN_EXT_DIAG}
	`define CONST_GOLDEN_DIAG_NR 	{`GOLDEN_ROOT_DIR, "c_nr",					`GOLDEN_EXT_DIAG}
	//ENCODER
	`define CONST_GOLDEN_ACC 	{`GOLDEN_ROOT_DIR, "c_acc",					`GOLDEN_EXT}
	`define CONST_GOLDEN_CNT 	{`GOLDEN_ROOT_DIR, "c_cnt",					`GOLDEN_EXT}
	
	
	
	`define CONST_GOLDEN_NUM_S 	    0
	`define CONST_GOLDEN_NUM_DRPSV  1
	`define CONST_GOLDEN_NUM_PSV 	2
	`define CONST_GOLDEN_NUM_PR 	3
	`define CONST_GOLDEN_NUM_W		4
	`define CONST_GOLDEN_NUM_WUSE   5
	`define CONST_GOLDEN_NUM_DRPE   6
	`define CONST_GOLDEN_NUM_DRSR   7
	`define CONST_GOLDEN_NUM_CQBC   8
	`define CONST_GOLDEN_NUM_MEV 	9
	`define CONST_GOLDEN_NUM_HRPS   10
	`define CONST_GOLDEN_NUM_PCD 	11
	`define CONST_GOLDEN_NUM_CLD 	12
	`define CONST_GOLDEN_NUM_NWD 	13
	`define CONST_GOLDEN_NUM_WD 	14
	`define CONST_GOLDEN_NUM_ND 	15
	`define CONST_GOLDEN_NUM_LS 	16
	`define CONST_GOLDEN_NUM_QI 	17
	`define CONST_GOLDEN_NUM_SR 	18
	`define CONST_GOLDEN_NUM_TS 	19
	`define CONST_GOLDEN_NUM_MQI 	20
	`define CONST_GOLDEN_NUM_DIAG_S 	    21
	`define CONST_GOLDEN_NUM_DIAG_DRPSV  	22
	`define CONST_GOLDEN_NUM_DIAG_PSV 		23
	`define CONST_GOLDEN_NUM_DIAG_PR 		24
	`define CONST_GOLDEN_NUM_DIAG_W			25
	`define CONST_GOLDEN_NUM_DIAG_WUSE   	26
	`define CONST_GOLDEN_NUM_DIAG_DRPE   	27
	`define CONST_GOLDEN_NUM_DIAG_DRSR   	28
	`define CONST_GOLDEN_NUM_DIAG_CQBC   	29
	`define CONST_GOLDEN_NUM_DIAG_MEV 		30
	`define CONST_GOLDEN_NUM_DIAG_HRPS   	31
	`define CONST_GOLDEN_NUM_DIAG_PCD 		32
	`define CONST_GOLDEN_NUM_DIAG_CLD 		33
	`define CONST_GOLDEN_NUM_DIAG_NWD 		34
	`define CONST_GOLDEN_NUM_DIAG_WD 		35
	`define CONST_GOLDEN_NUM_DIAG_ND 		36
	`define CONST_GOLDEN_NUM_DIAG_LS 		37
	`define CONST_GOLDEN_NUM_DIAG_QI 		38
	`define CONST_GOLDEN_NUM_DIAG_SR 		39
	`define CONST_GOLDEN_NUM_DIAG_TS 		40
	`define CONST_GOLDEN_NUM_DIAG_MQI 		41
	`define CONST_GOLDEN_NUM_DIAG_WR 		42
	`define CONST_GOLDEN_NUM_DIAG_NWR 		43
	`define CONST_GOLDEN_NUM_DIAG_NER 		44
	`define CONST_GOLDEN_NUM_DIAG_NR 		45
	//ENCODER
	`define CONST_GOLDEN_NUM_ACC 	100
	`define CONST_GOLDEN_NUM_CNT 	101
	
	
	function string getFileNameFromNum (input int x);
		case (x)
			`CONST_GOLDEN_NUM_S 	    	: return `CONST_GOLDEN_S; 	    
			`CONST_GOLDEN_NUM_DRPSV  		: return `CONST_GOLDEN_DRPSV;  
			`CONST_GOLDEN_NUM_PSV 			: return `CONST_GOLDEN_PSV; 	
			`CONST_GOLDEN_NUM_PR 			: return `CONST_GOLDEN_PR; 	
			`CONST_GOLDEN_NUM_W				: return `CONST_GOLDEN_W;		
			`CONST_GOLDEN_NUM_WUSE   		: return `CONST_GOLDEN_WUSE;   
			`CONST_GOLDEN_NUM_DRPE   		: return `CONST_GOLDEN_DRPE;   
			`CONST_GOLDEN_NUM_DRSR   		: return `CONST_GOLDEN_DRSR;   
			`CONST_GOLDEN_NUM_CQBC   		: return `CONST_GOLDEN_CQBC;   
			`CONST_GOLDEN_NUM_MEV 			: return `CONST_GOLDEN_MEV; 	
			`CONST_GOLDEN_NUM_HRPS   		: return `CONST_GOLDEN_HRPS;   
			`CONST_GOLDEN_NUM_PCD 			: return `CONST_GOLDEN_PCD; 	
			`CONST_GOLDEN_NUM_CLD 			: return `CONST_GOLDEN_CLD; 	
			`CONST_GOLDEN_NUM_NWD 			: return `CONST_GOLDEN_NWD; 	
			`CONST_GOLDEN_NUM_WD 			: return `CONST_GOLDEN_WD; 	
			`CONST_GOLDEN_NUM_ND 			: return `CONST_GOLDEN_ND; 	
			`CONST_GOLDEN_NUM_LS 			: return `CONST_GOLDEN_LS; 	
			`CONST_GOLDEN_NUM_QI 			: return `CONST_GOLDEN_QI; 	
			`CONST_GOLDEN_NUM_SR 			: return `CONST_GOLDEN_SR; 	
			`CONST_GOLDEN_NUM_TS 			: return `CONST_GOLDEN_TS; 	
			`CONST_GOLDEN_NUM_MQI 			: return `CONST_GOLDEN_MQI; 	
			`CONST_GOLDEN_NUM_DIAG_S 	    : return `CONST_GOLDEN_DIAG_S; 	    
			`CONST_GOLDEN_NUM_DIAG_DRPSV  	: return `CONST_GOLDEN_DIAG_DRPSV;  
			`CONST_GOLDEN_NUM_DIAG_PSV 		: return `CONST_GOLDEN_DIAG_PSV; 	
			`CONST_GOLDEN_NUM_DIAG_PR 		: return `CONST_GOLDEN_DIAG_PR; 	
			`CONST_GOLDEN_NUM_DIAG_W		: return `CONST_GOLDEN_DIAG_W;		
			`CONST_GOLDEN_NUM_DIAG_WUSE   	: return `CONST_GOLDEN_DIAG_WUSE;   
			`CONST_GOLDEN_NUM_DIAG_DRPE   	: return `CONST_GOLDEN_DIAG_DRPE;   
			`CONST_GOLDEN_NUM_DIAG_DRSR   	: return `CONST_GOLDEN_DIAG_DRSR;   
			`CONST_GOLDEN_NUM_DIAG_CQBC   	: return `CONST_GOLDEN_DIAG_CQBC;   
			`CONST_GOLDEN_NUM_DIAG_MEV 		: return `CONST_GOLDEN_DIAG_MEV; 	
			`CONST_GOLDEN_NUM_DIAG_HRPS   	: return `CONST_GOLDEN_DIAG_HRPS;   
			`CONST_GOLDEN_NUM_DIAG_PCD 		: return `CONST_GOLDEN_DIAG_PCD; 	
			`CONST_GOLDEN_NUM_DIAG_CLD 		: return `CONST_GOLDEN_DIAG_CLD; 	
			`CONST_GOLDEN_NUM_DIAG_NWD 		: return `CONST_GOLDEN_DIAG_NWD; 	
			`CONST_GOLDEN_NUM_DIAG_WD 		: return `CONST_GOLDEN_DIAG_WD; 	
			`CONST_GOLDEN_NUM_DIAG_ND 		: return `CONST_GOLDEN_DIAG_ND; 	
			`CONST_GOLDEN_NUM_DIAG_LS 		: return `CONST_GOLDEN_DIAG_LS; 	
			`CONST_GOLDEN_NUM_DIAG_QI 		: return `CONST_GOLDEN_DIAG_QI; 	
			`CONST_GOLDEN_NUM_DIAG_SR 		: return `CONST_GOLDEN_DIAG_SR; 	
			`CONST_GOLDEN_NUM_DIAG_TS 		: return `CONST_GOLDEN_DIAG_TS; 	
			`CONST_GOLDEN_NUM_DIAG_MQI 		: return `CONST_GOLDEN_DIAG_MQI; 
			`CONST_GOLDEN_NUM_ACC 			: return `CONST_GOLDEN_ACC; 	
			`CONST_GOLDEN_NUM_CNT 			: return `CONST_GOLDEN_CNT; 	
			`CONST_GOLDEN_NUM_DIAG_WR 		: return `CONST_GOLDEN_DIAG_WR;
			`CONST_GOLDEN_NUM_DIAG_NWR 		: return `CONST_GOLDEN_DIAG_NWR;
			`CONST_GOLDEN_NUM_DIAG_NER 		: return `CONST_GOLDEN_DIAG_NER;
			`CONST_GOLDEN_NUM_DIAG_NR 		: return `CONST_GOLDEN_DIAG_NR;
			default							: return "FUNCTION INCOMPLETE @test_shared.svh";
		endcase // x
	endfunction

`endif