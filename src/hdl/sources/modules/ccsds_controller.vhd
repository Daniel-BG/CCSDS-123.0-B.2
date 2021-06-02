----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2021 14:42:21
-- Design Name: 
-- Module Name: ccsds_controller - Behavioral
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
use ieee.numeric_std.all;
use work.am_constants.all; --get axi constants from here
use work.ccsds_constants.all;

entity ccsds_controller is
	Generic (
		--controller axi generics
		CONTROLLER_ADDR_WIDTH		: integer := 32; 
		CONTROLLER_DATA_BYTES_LOG	: integer := 2;	
		--ddr3 axi generics
		DDR3_AXI_ADDR_WIDTH			: integer := 32;
		DDR3_AXI_DATA_BYTES_LOG		: integer := 2 
	);
	Port (
		-------------------------------------------------
		--CCSDS SIGNALS
		-------------------------------------------------
		ccsds_clk: in std_logic;
		-------------------------------------------------
		--CONTROLLER AXI SLAVE INTERFACE
		--c_s_axi_<name> (control slave axi <signal_name>
		-------------------------------------------------
		c_s_axi_clk	, c_s_axi_resetn	: in  std_logic;
		--address read channel
		c_s_axi_araddr		: in  std_logic_vector(CONTROLLER_ADDR_WIDTH - 1 downto 0);
		c_s_axi_arready		: out std_logic;
		c_s_axi_arvalid		: in  std_logic;
		--read data channel
		c_s_axi_rdata		: out std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0);
		c_s_axi_rready		: in  std_logic;
		c_s_axi_rresp		: out std_logic_vector(AXI_BRESP_WIDTH - 1 downto 0);
		c_s_axi_rvalid		: out std_logic;
		--address write channel
		c_s_axi_awaddr		: in  std_logic_vector(CONTROLLER_ADDR_WIDTH - 1 downto 0);
		c_s_axi_awready		: out std_logic;
		c_s_axi_awvalid		: in  std_logic;
		--write data channel
		c_s_axi_wdata		: in  std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0);
		c_s_axi_wready		: out std_logic;
		c_s_axi_wstrb		: in  std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG) - 1 downto 0); --ignored
		c_s_axi_wvalid		: in  std_logic;
		--write response channel
		c_s_axi_bready		: in  std_logic;
		c_s_axi_bresp		: out std_logic_vector(AXI_BRESP_WIDTH - 1 downto 0);
		c_s_axi_bvalid		: out std_logic;
		-------------------------------------------------
		--DDR AXI MASTER INTERFACE
		--d_m_axi_<name> (ccsds master axi <signal_name>)
		-------------------------------------------------
		d_m_axi_clk	, d_m_axi_resetn	: in  std_logic;
		--address write channel
		d_m_axi_awaddr		: out std_logic_vector(DDR3_AXI_ADDR_WIDTH - 1 downto 0);
		d_m_axi_awlen		: out std_logic_vector(AXI_LEN_WIDTH - 1 downto 0);
		d_m_axi_awsize		: out std_logic_vector(AXI_SIZE_WIDTH - 1 downto 0);
		d_m_axi_awburst		: out std_logic_vector(AXI_BURST_WIDTH - 1 downto 0);
		d_m_axi_awlock		: out std_logic;
		d_m_axi_awcache		: out std_logic_vector(AXI_CACHE_WIDTH - 1 downto 0);
		d_m_axi_awprot		: out std_logic_vector(AXI_PROT_WIDTH - 1 downto 0);
		d_m_axi_awqos		: out std_logic_vector(AXI_QOS_WIDTH - 1 downto 0);
		d_m_axi_awvalid		: out std_logic;
		d_m_axi_awready		: in  std_logic;
		--data write channel
		d_m_axi_wdata		: out std_logic_vector((2**DDR3_AXI_DATA_BYTES_LOG)*8 - 1 downto 0);
		d_m_axi_wstrb		: out std_logic_vector((2**DDR3_AXI_DATA_BYTES_LOG) - 1 downto 0);
		d_m_axi_wlast		: out std_logic;
		d_m_axi_wvalid		: out std_logic;
		d_m_axi_wready		: in  std_logic;
		--write response channel
		d_m_axi_bresp		: in  std_logic_vector(AXI_BRESP_WIDTH - 1 downto 0);
		d_m_axi_bvalid		: in  std_logic;
		d_m_axi_bready		: out std_logic;
		--address read channel
		d_m_axi_araddr		: out std_logic_vector(DDR3_AXI_ADDR_WIDTH - 1 downto 0);
		d_m_axi_arlen		: out std_logic_vector(AXI_LEN_WIDTH - 1 downto 0);
		d_m_axi_arsize		: out std_logic_vector(AXI_SIZE_WIDTH - 1 downto 0);
		d_m_axi_arburst		: out std_logic_vector(AXI_BURST_WIDTH - 1 downto 0);
		d_m_axi_arlock		: out std_logic;
		d_m_axi_arcache		: out std_logic_vector(AXI_CACHE_WIDTH - 1 downto 0);
		d_m_axi_arprot		: out std_logic_vector(AXI_PROT_WIDTH - 1 downto 0);
		d_m_axi_arqos		: out std_logic_vector(AXI_QOS_WIDTH - 1 downto 0);
		d_m_axi_arvalid		: out std_logic;
		d_m_axi_arready		: in  std_logic;
		--read data channel
		d_m_axi_rdata		: in  std_logic_vector((2**DDR3_AXI_DATA_BYTES_LOG)*8 - 1 downto 0);
		d_m_axi_rresp		: in  std_logic_vector(AXI_BRESP_WIDTH - 1 downto 0);
		d_m_axi_rlast		: in  std_logic;
		d_m_axi_rvalid		: in  std_logic;
		d_m_axi_rready		: out std_logic
	);

end ccsds_controller;

architecture Behavioral of ccsds_controller is
	-------------------------------------------------
	--CONSTANTS
	-------------------------------------------------
	constant CCSDS_DATA_BYTES_IN_LOG	: integer := 1;

	-------------------------------------------------
	--CONTROLLER AXI SLAVE INTERFACE
	-------------------------------------------------
	--read/write registers (local addresses)
	constant C_S_AXI_REG_CTRLRG_LOCALADDR: integer := 0;	--
	constant C_S_AXI_REG_STADDR_LOCALADDR: integer := 4;	--addr start of raw data
	constant C_S_AXI_REG_TGADDR_LOCALADDR: integer := 8;   --addr start of output data
	constant C_S_AXI_REG_BYTENO_LOCALADDR: integer := 12;	--total bytes to be read (BYTES, not samples)
	--read/write registers for CCSDS configuration
	constant C_S_AXI_REG_CFG_P_LOCALADDR 				: integer := 36;
	constant C_S_AXI_REG_CFG_SUM_TYPE_LOCALADDR 		: integer := 40;
	constant C_S_AXI_REG_CFG_SAMPLES_LOCALADDR 			: integer := 44;
	constant C_S_AXI_REG_CFG_TINC_LOCALADDR 			: integer := 48;
	constant C_S_AXI_REG_CFG_VMAX_LOCALADDR 			: integer := 52;
	constant C_S_AXI_REG_CFG_VMIN_LOCALADDR 			: integer := 56;
	constant C_S_AXI_REG_CFG_DEPTH_LOCALADDR 			: integer := 60;
	constant C_S_AXI_REG_CFG_OMEGA_LOCALADDR 			: integer := 64;
	constant C_S_AXI_REG_CFG_WEO_LOCALADDR 				: integer := 68;
	constant C_S_AXI_REG_CFG_USE_ABS_ERR_LOCALADDR 		: integer := 72;
	constant C_S_AXI_REG_CFG_USE_REL_ERR_LOCALADDR 		: integer := 76;
	constant C_S_AXI_REG_CFG_ABS_ERR_LOCALADDR 			: integer := 80;
	constant C_S_AXI_REG_CFG_REL_ERR_LOCALADDR 			: integer := 84;
	constant C_S_AXI_REG_CFG_SMAX_LOCALADDR 			: integer := 88;
	constant C_S_AXI_REG_CFG_RESOLUTION_LOCALADDR 		: integer := 92;
	constant C_S_AXI_REG_CFG_DAMPING_LOCALADDR 			: integer := 96;
	constant C_S_AXI_REG_CFG_OFFSET_LOCALADDR 			: integer := 100;
	constant C_S_AXI_REG_CFG_MAX_X_LOCALADDR 			: integer := 104;
	constant C_S_AXI_REG_CFG_MAX_Y_LOCALADDR 			: integer := 108;
	constant C_S_AXI_REG_CFG_MAX_Z_LOCALADDR 			: integer := 112;
	constant C_S_AXI_REG_CFG_MAX_T_LOCALADDR 			: integer := 116;
	constant C_S_AXI_REG_CFG_MIN_PRELOAD_VALUE_LOCALADDR: integer := 120;
	constant C_S_AXI_REG_CFG_MAX_PRELOAD_VALUE_LOCALADDR: integer := 124;
	constant C_S_AXI_REG_CFG_INITIAL_COUNTER_LOCALADDR 	: integer := 128;
	constant C_S_AXI_REG_CFG_FINAL_COUNTER_LOCALADDR 	: integer := 132;
	constant C_S_AXI_REG_CFG_GAMMA_STAR_LOCALADDR 		: integer := 136;
	constant C_S_AXI_REG_CFG_U_MAX_LOCALADDR 			: integer := 140;
	constant C_S_AXI_REG_CFG_IACC_LOCALADDR 			: integer := 144;	
	
	--read only status registers (local addresses)
	constant C_S_AXI_REG_STATUS_LOCALADDR: integer := 256;  
	constant C_S_AXI_REG_INBYTE_LOCALADDR: integer := 260;	--number of bytes read from mem so far
	constant C_S_AXI_REG_OUTBYT_LOCALADDR: integer := 264;  --number of bytes output so far
	constant C_S_AXI_REG_DDRRST_LOCALADDR: integer := 268;  --ddr read status register
	constant C_S_AXI_REG_DDRWST_LOCALADDR: integer := 272;  --ddr write status register
	constant C_S_AXI_REG_CNCLKL_LOCALADDR: integer := 276;  --lower part of clock count for control bus
	constant C_S_AXI_REG_CNCLKU_LOCALADDR: integer := 280;	--upper part of clock count for control bus
	constant C_S_AXI_REG_MMCLKL_LOCALADDR: integer := 284;	--lower part of clock count for memory bus
	constant C_S_AXI_REG_MMCLKU_LOCALADDR: integer := 288;	--upper part of clock count for memory bus
	constant C_S_AXI_REG_COCLKL_LOCALADDR: integer := 292;	--lower part of clock count for core
	constant C_S_AXI_REG_COCLKU_LOCALADDR: integer := 296;	--upper part of clock count for core
	--ccsds generics to know how it was configured
	constant C_S_AXI_REG_CONFIG_LOCALADDR: integer := 384;  
	--debug register
	constant C_S_AXI_REG_SIGN_LOCALADDR: integer := 500;
	constant C_S_AXI_REG_DBGREG_LOCALADDR: integer := 508;

	--codes for running the core by writing to status registe
	constant CONTROL_CODE_RESET		: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0) := std_logic_vector(to_unsigned(127, (2**CONTROLLER_DATA_BYTES_LOG)*8));
	constant CONTROL_CODE_START_0	: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0) := std_logic_vector(to_unsigned(62, (2**CONTROLLER_DATA_BYTES_LOG)*8));
	constant CONTROL_CODE_START_1	: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0) := std_logic_vector(to_unsigned(63, (2**CONTROLLER_DATA_BYTES_LOG)*8));

	--metaconfig registers
	signal 
		s_axi_reg_ctrlrg, s_axi_reg_staddr, s_axi_reg_tgaddr, s_axi_reg_status, s_axi_reg_signature, s_axi_reg_dbgreg,
		s_axi_reg_byteno,
		s_axi_reg_ddrrst, s_axi_reg_ddrwst,
		s_axi_reg_inbyte, s_axi_reg_inbyte_next,
		s_axi_reg_outbyt, s_axi_reg_outbyt_next,
		s_axi_reg_cfg_p,
		s_axi_reg_cfg_sum_type,
		s_axi_reg_cfg_samples,
		s_axi_reg_cfg_tinc,
		s_axi_reg_cfg_vmax,
		s_axi_reg_cfg_vmin,
		s_axi_reg_cfg_depth,
		s_axi_reg_cfg_omega,
		s_axi_reg_cfg_weo,
		s_axi_reg_cfg_use_abs_err,
		s_axi_reg_cfg_use_rel_err,
		s_axi_reg_cfg_abs_err,
		s_axi_reg_cfg_rel_err,
		s_axi_reg_cfg_smax,
		s_axi_reg_cfg_resolution,
		s_axi_reg_cfg_damping,
		s_axi_reg_cfg_offset,
		s_axi_reg_cfg_max_x,
		s_axi_reg_cfg_max_y,
		s_axi_reg_cfg_max_z,
		s_axi_reg_cfg_max_t,
		s_axi_reg_cfg_min_preload_value,
		s_axi_reg_cfg_max_preload_value,
		s_axi_reg_cfg_initial_counter,
		s_axi_reg_cfg_final_counter,
		s_axi_reg_cfg_gamma_star,
		s_axi_reg_cfg_u_max,
		s_axi_reg_cfg_iacc
	: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0);
	signal s_axi_reg_cfg_sum_type_converted: local_sum_t;

	--clock registers
	--control axis bus, master axis bus, core axis bus
	signal s_axi_reg_cnclk, s_axi_reg_mmclk, s_axi_reg_mmclk_pre, s_axi_reg_coclk, s_axi_reg_coclk_pre: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*2*8 - 1 downto 0);
	alias s_axi_reg_cnclku: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0) is s_axi_reg_cnclk((2**CONTROLLER_DATA_BYTES_LOG)*2*8 - 1 downto (2**CONTROLLER_DATA_BYTES_LOG)*8);
	alias s_axi_reg_cnclkl: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0) is s_axi_reg_cnclk((2**CONTROLLER_DATA_BYTES_LOG)  *8 - 1 downto 0);
	alias s_axi_reg_mmclku: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0) is s_axi_reg_mmclk((2**CONTROLLER_DATA_BYTES_LOG)*2*8 - 1 downto (2**CONTROLLER_DATA_BYTES_LOG)*8);
	alias s_axi_reg_mmclkl: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0) is s_axi_reg_mmclk((2**CONTROLLER_DATA_BYTES_LOG)  *8 - 1 downto 0);
	alias s_axi_reg_coclku: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0) is s_axi_reg_coclk((2**CONTROLLER_DATA_BYTES_LOG)*2*8 - 1 downto (2**CONTROLLER_DATA_BYTES_LOG)*8);
	alias s_axi_reg_coclkl: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0) is s_axi_reg_coclk((2**CONTROLLER_DATA_BYTES_LOG)  *8 - 1 downto 0);
	--ccsds config registers
	signal s_axi_reg_maxx: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0);
	signal s_axi_reg_wren, s_axi_reg_readen: std_logic; 

	--control registers write state and signals
	type control_slave_write_state_t is (CSW_IDLE, CSW_AWAIT_ADDR_OR_DATA, CSW_AWAIT_ADDR, CSW_AWAIT_DATA, CSW_PERFORM_OP, CSW_SEND_RESPONSE);
	signal c_s_w_state_curr, c_s_w_state_next: control_slave_write_state_t;

	signal c_s_axi_writeaddr_curr, c_s_axi_writeaddr_next: std_logic_vector(CONTROLLER_ADDR_WIDTH - 1 downto 0);
	signal c_s_axi_writedata_curr, c_s_axi_writedata_next: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0);

	signal local_c_s_axi_writeaddr: integer range 0 to 511;

	--control registers read state and signals
	type control_slave_read_state_t is (CSR_IDLE, CSR_AWAIT_ADDR, CSR_SEND_DATA);
	signal c_s_r_state_curr, c_s_r_state_next: control_slave_read_state_t;

	signal c_s_axi_readdata: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0);

	signal local_c_s_axi_readaddr: integer range 0 to 511;

	--control state machine and control signals for other processes
	type control_main_state_t is (CONTROL_IDLE, CONTROL_RESET, CONTROL_WAIT_START_1, CONTROL_START, CONTROL_ABRUPT_END, CONTROL_END);
	signal control_main_state_curr, control_main_state_next: control_main_state_t;

	signal control_input_transfer_enable, control_output_transfer_enable: std_logic;
	signal control_input_transfer_done, control_output_transfer_done: std_logic;
	signal control_input_reset, control_output_reset: std_logic;
	signal control_input_idle, control_output_idle: std_logic;

	--ddr read states
	type ddr_read_state_t is (DDR_READ_IDLE, DDR_READ_READY, DDR_READ_REQUEST, DDR_READ_TRANSFER, DDR_READ_FINISH);
	signal ddr_read_state_curr, ddr_read_state_next: ddr_read_state_t;

	signal ddr_read_bytes_remaining_next, ddr_read_bytes_remaining_curr: std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0);
	signal ddr_read_addr_next, ddr_read_addr_curr: std_logic_vector(DDR3_AXI_ADDR_WIDTH - 1 downto 0);
	signal ddr_read_align_next, ddr_read_align_curr: std_logic_vector(DDR3_AXI_DATA_BYTES_LOG - CCSDS_DATA_BYTES_IN_LOG - 1 downto 0);

	signal ififo_almost_empty_pre, ififo_almost_empty: std_logic;
	signal ififo_input_valid, ififo_input_ready, ififo_output_ready, ififo_output_valid: std_logic;
	signal ififo_input_data, ififo_output_data: std_logic_vector((2**CCSDS_DATA_BYTES_IN_LOG)*8 - 1 downto 0);

	--ddr write states
	type ddr_write_state_t is (DDR_WRITE_IDLE, DDR_WRITE_READY, DDR_WRITE_REQUEST, DDR_WRITE_TRANSFER, DDR_WRITE_TRANSFER_NOSTRB, DDR_WRITE_RESPONSE, DDR_WRITE_LAST_RESPONSE, DDR_WRITE_FINISH);
	signal ddr_write_state_curr, ddr_write_state_next: ddr_write_state_t;
	
	signal ddr_write_addr_curr, ddr_write_addr_next: std_logic_vector(DDR3_AXI_ADDR_WIDTH - 1 downto 0);
	signal ddr_write_transactions_left_curr, ddr_write_transactions_left_next: std_logic_vector(AXI_LEN_WIDTH - 1 downto 0);

	signal ofifo_seen_last, ofifo_seen_last_pre: std_logic;

	signal ofifo_almost_full_pre, ofifo_almost_full: std_logic;
	signal ofifo_output_ready, ofifo_output_valid: std_logic;
	signal ofifo_output_last: std_logic;
	signal ofifo_output_data: std_logic_vector(2**(DDR3_AXI_DATA_BYTES_LOG)*8 - 1 downto 0);

	---------------------------------------------------
	--CCSDS SIGNALS
	---------------------------------------------------
	signal ccsds_rst: std_logic;
	signal ccsds_rstn: std_logic;
	
	signal core_raw_output_data: std_logic_vector(63 downto 0);
	signal core_raw_output_valid, core_raw_output_last, core_raw_output_ready: std_logic;

	signal core_output_data: std_logic_vector((2**DDR3_AXI_DATA_BYTES_LOG)*8 - 1 downto 0);
	signal core_output_ready, core_output_valid: std_logic;
	signal core_output_last: std_logic;
	
	-----------
	--MODULES
	-----------
	COMPONENT axis_data_fifo_16b_512s
		PORT (
			s_axis_aresetn : IN STD_LOGIC;
			s_axis_aclk : IN STD_LOGIC;
			s_axis_tvalid : IN STD_LOGIC;
			s_axis_tready : OUT STD_LOGIC;
			s_axis_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			m_axis_aclk : IN STD_LOGIC;
			m_axis_tvalid : OUT STD_LOGIC;
			m_axis_tready : IN STD_LOGIC;
			m_axis_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			prog_empty : OUT STD_LOGIC
		);
	END COMPONENT;
	COMPONENT axis_data_fifo_32b_512s
		PORT (
			s_axis_aresetn : IN STD_LOGIC;
			s_axis_aclk : IN STD_LOGIC;
			s_axis_tvalid : IN STD_LOGIC;
			s_axis_tready : OUT STD_LOGIC;
			s_axis_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			s_axis_tlast : IN STD_LOGIC;
			m_axis_aclk : IN STD_LOGIC;
			m_axis_tvalid : OUT STD_LOGIC;
			m_axis_tready : IN STD_LOGIC;
			m_axis_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			m_axis_tlast : OUT STD_LOGIC;
			prog_full : OUT STD_LOGIC
		);
	END COMPONENT;
	
	------------
	--CCD logic
	------------
	signal d_m_axi_reset: std_logic;
	signal c_s_axi_reset: std_logic;
begin
	-- DEBUG BEGIN
	s_axi_reg_signature <= x"cc5d5004";
	s_axi_reg_dbgreg <= 
		x"caf"
		& ofifo_almost_full & ofifo_output_last 	& ofifo_output_valid	& ofifo_output_ready
		& 				"0" & core_raw_output_last  & core_raw_output_valid & core_raw_output_ready 
		& 				"0" & core_output_last  	& core_output_valid  	& core_output_ready 
		& 				"0" & "0" 					& ififo_output_valid 	& ififo_output_ready
		& ififo_almost_empty& "0" 					& ififo_input_valid  	& ififo_input_ready; 
	-- DEBUG END

	------------------------------
	--CONTROLLER WRITE PROCESSES--
	------------------------------
	control_write_seq: process(c_s_axi_clk)
	begin
		if rising_edge(c_s_axi_clk) then
			if c_s_axi_resetn = '0' then
				c_s_w_state_curr <= CSW_IDLE;
			else
				c_s_w_state_curr <= c_s_w_state_next;
				c_s_axi_writeaddr_curr <= c_s_axi_writeaddr_next;
				c_s_axi_writedata_curr <= c_s_axi_writedata_next;

				if s_axi_reg_wren = '1' then
					if local_c_s_axi_writeaddr = C_S_AXI_REG_CTRLRG_LOCALADDR then
						s_axi_reg_ctrlrg <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_BYTENO_LOCALADDR then
						s_axi_reg_byteno <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_STADDR_LOCALADDR then
						s_axi_reg_staddr <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_TGADDR_LOCALADDR then
						s_axi_reg_tgaddr <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_P_LOCALADDR then
						s_axi_reg_cfg_p <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_SUM_TYPE_LOCALADDR then
						s_axi_reg_cfg_sum_type <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_SAMPLES_LOCALADDR then
						s_axi_reg_cfg_samples <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_TINC_LOCALADDR then
						s_axi_reg_cfg_tinc <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_VMAX_LOCALADDR then
						s_axi_reg_cfg_vmax <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_VMIN_LOCALADDR then
						s_axi_reg_cfg_vmin <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_DEPTH_LOCALADDR then
						s_axi_reg_cfg_depth <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_OMEGA_LOCALADDR then
						s_axi_reg_cfg_omega <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_WEO_LOCALADDR then
						s_axi_reg_cfg_weo <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_USE_ABS_ERR_LOCALADDR then
						s_axi_reg_cfg_use_abs_err <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_USE_REL_ERR_LOCALADDR then
						s_axi_reg_cfg_use_rel_err <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_ABS_ERR_LOCALADDR then
						s_axi_reg_cfg_abs_err <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_REL_ERR_LOCALADDR then
						s_axi_reg_cfg_rel_err <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_SMAX_LOCALADDR then
						s_axi_reg_cfg_smax <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_RESOLUTION_LOCALADDR then
						s_axi_reg_cfg_resolution <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_DAMPING_LOCALADDR then
						s_axi_reg_cfg_damping <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_OFFSET_LOCALADDR then
						s_axi_reg_cfg_offset <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_MAX_X_LOCALADDR then
						s_axi_reg_cfg_max_x <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_MAX_Y_LOCALADDR then
						s_axi_reg_cfg_max_y <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_MAX_Z_LOCALADDR then
						s_axi_reg_cfg_max_z <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_MAX_T_LOCALADDR then
						s_axi_reg_cfg_max_t <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_MIN_PRELOAD_VALUE_LOCALADDR then
						s_axi_reg_cfg_min_preload_value <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_MAX_PRELOAD_VALUE_LOCALADDR then
						s_axi_reg_cfg_max_preload_value <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_INITIAL_COUNTER_LOCALADDR then
						s_axi_reg_cfg_initial_counter <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_FINAL_COUNTER_LOCALADDR then
						s_axi_reg_cfg_final_counter <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_GAMMA_STAR_LOCALADDR then
						s_axi_reg_cfg_gamma_star <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_U_MAX_LOCALADDR then
						s_axi_reg_cfg_u_max <= c_s_axi_writedata_curr;
					elsif local_c_s_axi_writeaddr = C_S_AXI_REG_CFG_IACC_LOCALADDR then
						s_axi_reg_cfg_iacc <= c_s_axi_writedata_curr;
					end if;
				end if;
			end if;
		end if;
	end process;

	local_c_s_axi_writeaddr <= to_integer(unsigned(c_s_axi_writeaddr_curr(7 downto 0)));

	control_write_comb: process(c_s_w_state_curr,
		c_s_axi_writeaddr_curr, c_s_axi_writedata_curr, c_s_axi_awvalid, c_s_axi_wvalid,
		c_s_axi_awaddr, c_s_axi_wdata, c_s_axi_bready)
	begin
		--keep old values unless changed
		c_s_w_state_next <= c_s_w_state_curr;
		c_s_axi_awready <= '0';
		c_s_axi_wready  <= '0';
		c_s_axi_writeaddr_next <= c_s_axi_writeaddr_curr;
		c_s_axi_writedata_next <= c_s_axi_writedata_curr;
		s_axi_reg_wren <= '0';
		c_s_axi_bresp <= AXI_RESP_OKAY;
		c_s_axi_bvalid <= '0';

		if c_s_w_state_curr = CSW_IDLE then
			--use this state as reset to keep AXI signals low
			--during resets so as to not introduce phantom transactions
			c_s_w_state_next <= CSW_AWAIT_ADDR_OR_DATA;
		elsif c_s_w_state_curr = CSW_AWAIT_ADDR_OR_DATA then
			--await either address or data.
			c_s_axi_awready <= '1';
			c_s_axi_wready  <= '1';
			if c_s_axi_awvalid = '1' and c_s_axi_wvalid = '1' then
				c_s_axi_writeaddr_next <= c_s_axi_awaddr;
				c_s_axi_writedata_next <= c_s_axi_wdata;
				c_s_w_state_next <= CSW_PERFORM_OP;
			elsif c_s_axi_awvalid = '1' then
				c_s_axi_writeaddr_next <= c_s_axi_awaddr;
				c_s_w_state_next <= CSW_AWAIT_DATA;
			elsif c_s_axi_wvalid = '1' then
				c_s_axi_writedata_next <= c_s_axi_wdata;
				c_s_w_state_next <= CSW_AWAIT_ADDR;
			end if;
		elsif c_s_w_state_curr = CSW_AWAIT_ADDR then
			--await for address on bus
			c_s_axi_awready <= '1';
			if c_s_axi_awvalid = '1' then
				c_s_axi_writeaddr_next <= c_s_axi_awaddr;
				c_s_w_state_next <= CSW_PERFORM_OP;
			end if;
		elsif c_s_w_state_curr = CSW_AWAIT_DATA then
			--await for data on bus
			c_s_axi_wready <= '1';
			if c_s_axi_wvalid = '1' then
				c_s_axi_writedata_next <= c_s_axi_wdata;
				c_s_w_state_next <= CSW_PERFORM_OP;
			end if;
		elsif c_s_w_state_curr = CSW_PERFORM_OP then
			--enable reg write (which will be done in one cycle)
			s_axi_reg_wren <= '1';
			c_s_w_state_next <= CSW_SEND_RESPONSE;
		elsif c_s_w_state_curr = CSW_SEND_RESPONSE then
			--assert bresp signals and wait for master ack
			c_s_axi_bresp <= AXI_RESP_OKAY;
			c_s_axi_bvalid <= '1';
			if c_s_axi_bready = '1' then
				c_s_w_state_next <= CSW_AWAIT_ADDR_OR_DATA;
			end if;
		end if;
	end process;

	-----------------------------
	--CONTROLLER READ PROCESSES--
	-----------------------------
	control_read_seq: process(c_s_axi_clk)
	begin
		if rising_edge(c_s_axi_clk) then
			if c_s_axi_resetn = '0' then
				c_s_r_state_curr <= CSR_IDLE;
			else
				c_s_r_state_curr <= c_s_r_state_next;
				if s_axi_reg_readen = '1' then
					if local_c_s_axi_readaddr = C_S_AXI_REG_CTRLRG_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_ctrlrg;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_STATUS_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_status;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_INBYTE_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_inbyte;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_DDRRST_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_ddrrst;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_BYTENO_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_byteno;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_STADDR_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_staddr;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_TGADDR_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_tgaddr;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_P_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_p;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_SUM_TYPE_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_sum_type;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_SAMPLES_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_samples;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_TINC_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_tinc;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_VMAX_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_vmax;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_VMIN_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_vmin;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_DEPTH_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_depth;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_OMEGA_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_omega;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_WEO_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_weo;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_USE_ABS_ERR_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_use_abs_err;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_USE_REL_ERR_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_use_rel_err;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_ABS_ERR_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_abs_err;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_REL_ERR_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_rel_err;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_SMAX_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_smax;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_RESOLUTION_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_resolution;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_DAMPING_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_damping;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_OFFSET_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_offset;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_MAX_X_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_max_x;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_MAX_Y_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_max_y;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_MAX_Z_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_max_z;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_MAX_T_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_max_t;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_MIN_PRELOAD_VALUE_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_min_preload_value;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_MAX_PRELOAD_VALUE_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_max_preload_value;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_INITIAL_COUNTER_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_initial_counter;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_FINAL_COUNTER_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_final_counter;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_GAMMA_STAR_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_gamma_star;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_U_MAX_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_u_max;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CFG_IACC_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cfg_iacc;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_OUTBYT_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_outbyt;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_DDRWST_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_ddrwst;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CNCLKL_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cnclkl;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_CNCLKU_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_cnclku;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_MMCLKL_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_mmclkl;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_MMCLKU_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_mmclku;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_COCLKL_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_coclkl;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_COCLKU_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_coclku;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_SIGN_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_signature;
					elsif local_c_s_axi_readaddr = C_S_AXI_REG_DBGREG_LOCALADDR then
						c_s_axi_readdata <= s_axi_reg_dbgreg;
					else --fallback to all zeroes
						c_s_axi_readdata <= x"fa11fa11";
					end if;
				end if;
			end if;
		end if;
	end process;

	local_c_s_axi_readaddr <= to_integer(unsigned(c_s_axi_araddr(8 downto 0)));

	control_read_comb: process(c_s_r_state_curr,
		c_s_axi_arvalid, c_s_axi_rready)
	begin
		c_s_r_state_next <= c_s_r_state_curr;
		c_s_axi_arready <= '0';
		s_axi_reg_readen <= '0';
		c_s_axi_rvalid <= '0';
		c_s_axi_rresp <= AXI_RESP_OKAY;

		if c_s_r_state_curr = CSR_IDLE then
			c_s_r_state_next <= CSR_AWAIT_ADDR;
		elsif c_s_r_state_curr = CSR_AWAIT_ADDR then
			c_s_axi_arready <= '1';
			if c_s_axi_arvalid = '1' then
				s_axi_reg_readen <= '1';
				c_s_r_state_next <= CSR_SEND_DATA;
			end if;
		elsif c_s_r_state_curr = CSR_SEND_DATA then
			c_s_axi_rvalid <= '1';
			c_s_axi_rresp <= AXI_RESP_OKAY;
			if c_s_axi_rready = '1' then
				--done, wait for next transaction
				c_s_r_state_next <= CSR_AWAIT_ADDR;
			end if;
		end if;
	end process;
	--could be directly routed but then we'd have a mux in front of the bus, so this way is better
	c_s_axi_rdata <= c_s_axi_readdata; 


	---------------------------
	--CONTROLLER MAIN PROCESS--
	---------------------------
	controller_main_seq: process(c_s_axi_clk)
	begin
		if rising_edge(c_s_axi_clk) then
			if c_s_axi_resetn = '0' then
				control_main_state_curr <= CONTROL_IDLE;
			else
				control_main_state_curr <= control_main_state_next;
			end if;
		end if;
	end process;


	controller_main_comb: process(control_main_state_curr, s_axi_reg_ctrlrg, 
		control_input_transfer_done, control_output_transfer_done, control_input_idle, control_output_idle)
	begin
		control_main_state_next <= control_main_state_curr;
		ccsds_rst <= '0';
		control_input_transfer_enable	<= '0';
		control_output_transfer_enable	<= '0';
		control_input_reset    <= '0';
		control_output_reset   <= '0';
		s_axi_reg_status <= (others => '0');

		if control_main_state_curr = CONTROL_IDLE then
			s_axi_reg_status <= x"00000001";
			if s_axi_reg_ctrlrg = CONTROL_CODE_RESET then
				control_main_state_next <= CONTROL_RESET;
			elsif s_axi_reg_ctrlrg = CONTROL_CODE_START_0 then
				control_main_state_next <= CONTROL_WAIT_START_1;
			end if;
		elsif control_main_state_curr = CONTROL_RESET then
			s_axi_reg_status <= x"00000010";
			ccsds_rst <= '1';
			--get out of reset state
			if s_axi_reg_ctrlrg /= CONTROL_CODE_RESET then
				control_main_state_next <= CONTROL_IDLE;
			end if;
		elsif control_main_state_curr = CONTROL_WAIT_START_1 then
			s_axi_reg_status <= x"00000100";
			if s_axi_reg_ctrlrg = CONTROL_CODE_START_0 then
				--stay here
			elsif s_axi_reg_ctrlrg = CONTROL_CODE_START_1 then
				control_main_state_next <= CONTROL_START;
			else
				--go back to idle, start sequence was wrong
				control_main_state_next <= CONTROL_IDLE;
			end if;
		elsif control_main_state_curr = CONTROL_START then
			s_axi_reg_status <= x"00001000";
			control_input_transfer_enable	<= '1';
			control_output_transfer_enable	<= '1';
			if control_input_transfer_done = '1' and control_output_transfer_done = '1' then
				control_main_state_next <= CONTROL_END;
			elsif s_axi_reg_ctrlrg = CONTROL_CODE_RESET then
				control_main_state_next <= CONTROL_ABRUPT_END;
			end if;
			--if we overwrite the control status while on this state, also end the transactions
		elsif control_main_state_curr = CONTROL_ABRUPT_END then
			s_axi_reg_status <= x"00010000";
			if control_input_transfer_done = '1' and control_output_transfer_done = '1' then
				control_main_state_next <= CONTROL_END;
			end if;
		elsif control_main_state_curr = CONTROL_END then
			s_axi_reg_status <= x"00100000";
			control_input_reset    <= '1';
			control_output_reset   <= '1';
			if control_input_idle = '1' and control_output_idle = '1' then
				control_main_state_next <= CONTROL_IDLE;
			end if;
		end if;
	end process;



	-------------------------------
	--DDR TO CORE INPUT PROCESSES--
	-------------------------------
	ddr_read_seq: process(d_m_axi_clk)
	begin
		if rising_edge(d_m_axi_clk) then
			if d_m_axi_resetn = '0' then
				ddr_read_state_curr <= DDR_READ_IDLE;
				s_axi_reg_inbyte	<= (others => '0');
			else
				ddr_read_state_curr <= ddr_read_state_next;
				ddr_read_bytes_remaining_curr <= ddr_read_bytes_remaining_next;
				ddr_read_addr_curr <= ddr_read_addr_next;
				ddr_read_align_curr <= ddr_read_align_next;
				s_axi_reg_inbyte <= s_axi_reg_inbyte_next;
			end if;
		end if;
	end process;


	--fixed AXI signals
	d_m_axi_arsize	<= std_logic_vector(to_unsigned(CCSDS_DATA_BYTES_IN_LOG, d_m_axi_arsize'length));
	d_m_axi_arburst	<= AXI_BURST_INCR;
	d_m_axi_arlock  <= AXI_LOCK_UNLOCKED;
	d_m_axi_arcache <= AXI_CACHE_NORMAL_NONCACHE_NONBUFF;
	d_m_axi_arprot  <= AXI_PROT_UNPRIVILEDGED_NONSECURE_DATA;
	d_m_axi_arqos   <= AXI_QOS_EIGHT;
	d_m_axi_araddr	<= ddr_read_addr_curr;
	--end fixed AXI signals
	ddr_read_comb: process(ddr_read_state_curr, 
		ddr_read_bytes_remaining_curr, ddr_read_addr_curr, ddr_read_align_curr,
		control_input_transfer_enable, control_input_reset,
		s_axi_reg_inbyte,s_axi_reg_byteno, s_axi_reg_staddr, s_axi_reg_tgaddr,
		d_m_axi_arready, d_m_axi_rvalid, d_m_axi_rlast, ififo_input_ready, ififo_almost_empty)
	begin
		s_axi_reg_ddrrst <= x"00000000";
		--control signals defaults
		ddr_read_state_next <= ddr_read_state_curr;
		control_input_transfer_done <= '0';
		control_input_idle <= '0';
		ddr_read_bytes_remaining_next <= ddr_read_bytes_remaining_curr;
		ddr_read_addr_next <= ddr_read_addr_curr;
		ddr_read_align_next <= ddr_read_align_curr;
		--axi defaults
		d_m_axi_arvalid	<= '0';
		d_m_axi_arlen	<= (others => '0');
		d_m_axi_rready 	<= '0';
		--
		ififo_input_valid <= '0';
		--
		s_axi_reg_inbyte_next <= s_axi_reg_inbyte;

		if ddr_read_state_curr = DDR_READ_IDLE then
			s_axi_reg_ddrrst <= x"00000001";
			control_input_idle <= '1';
			--wait for central control to enable us
			if control_input_transfer_enable = '1' then
				ddr_read_state_next <= DDR_READ_REQUEST;
				ddr_read_bytes_remaining_next <= s_axi_reg_byteno;
				ddr_read_addr_next <= s_axi_reg_staddr;
			end if;
		elsif ddr_read_state_curr = DDR_READ_READY then
			s_axi_reg_ddrrst <= x"00000010";
			if control_input_transfer_enable = '1' then
				--check if we still have bytes left
				if ddr_read_bytes_remaining_curr = (ddr_read_bytes_remaining_curr'high downto 0 => '0') then
					ddr_read_state_next <= DDR_READ_FINISH;
				else
					--still have bytes left, only initiate transaction if fifo is almost empty
					if ififo_almost_empty = '1' then
						ddr_read_state_next <= DDR_READ_REQUEST;
					end if;
				end if;
			else
				--early (in-flight) termination
				ddr_read_state_next <= DDR_READ_FINISH;
			end if;
		elsif ddr_read_state_curr = DDR_READ_REQUEST then
			s_axi_reg_ddrrst <= x"00000100";
			--align for read mux
			ddr_read_align_next			  <= ddr_read_addr_curr(DDR3_AXI_DATA_BYTES_LOG - 1 downto CCSDS_DATA_BYTES_IN_LOG);
			--if we still have more than the max transaction of bytes left, perform a transaction
			if ddr_read_bytes_remaining_curr(ddr_read_bytes_remaining_curr'high downto AXI_LEN_WIDTH + CCSDS_DATA_BYTES_IN_LOG)
					/= (ddr_read_bytes_remaining_curr'high downto AXI_LEN_WIDTH + CCSDS_DATA_BYTES_IN_LOG => '0') then
				d_m_axi_arvalid 		<= '1';
				d_m_axi_arlen 			<= (others => '1');
				if d_m_axi_arready = '1' then
					ddr_read_bytes_remaining_next <= std_logic_vector(unsigned(ddr_read_bytes_remaining_curr) - to_unsigned(2**(AXI_LEN_WIDTH+CCSDS_DATA_BYTES_IN_LOG), ddr_read_bytes_remaining_curr'length));
					ddr_read_addr_next			  <= std_logic_vector(unsigned(ddr_read_addr_curr) 			  + to_unsigned(2**(AXI_LEN_WIDTH+CCSDS_DATA_BYTES_IN_LOG), 			ddr_read_addr_curr'length));
					ddr_read_state_next 		  <= DDR_READ_TRANSFER;
				end if;
			--we have less than max, but still have some
			else --if ddr_read_bytes_remaining_curr(AXI_LEN_WIDTH + CCSDS_DATA_BYTES_IN_LOG - 1 downto CCSDS_DATA_BYTES_IN_LOG) /= (AXI_LEN_WIDTH - 1 downto 0 => '0') then
				d_m_axi_arvalid 		<= '1';
				d_m_axi_arlen 			<= std_logic_vector(unsigned(ddr_read_bytes_remaining_curr(AXI_LEN_WIDTH + CCSDS_DATA_BYTES_IN_LOG - 1 downto CCSDS_DATA_BYTES_IN_LOG)) - to_unsigned(1, AXI_LEN_WIDTH));
				if d_m_axi_arready = '1' then
					ddr_read_bytes_remaining_next <= (others => '0');
					ddr_read_state_next 		  <= DDR_READ_TRANSFER;
				end if;
				--ddr_read_addr_next; --don't care for this value since it won't be used again
			end if;
		elsif ddr_read_state_curr = DDR_READ_TRANSFER then
			s_axi_reg_ddrrst <= x"00001000";
			ififo_input_valid <= d_m_axi_rvalid;
			d_m_axi_rready <= ififo_input_ready;
			if d_m_axi_rvalid = '1' and ififo_input_ready = '1' then
				s_axi_reg_inbyte_next 		  <= std_logic_vector(unsigned(s_axi_reg_inbyte) + to_unsigned(2**CCSDS_DATA_BYTES_IN_LOG, s_axi_reg_inbyte'length));
				ddr_read_align_next	<= std_logic_vector(unsigned(ddr_read_align_curr) + to_unsigned(1, ddr_read_align_curr'length));
				if d_m_axi_rlast = '1' then
					--burst is finished, go back to requesting transactions
					ddr_read_state_next <= DDR_READ_READY;
				end if;
			end if;
		elsif ddr_read_state_curr = DDR_READ_FINISH then
			s_axi_reg_ddrrst <= x"00010000";
			--no more bytes left, goto idle state when we can (wait to sync with master fsm)
			control_input_transfer_done <= '1';
			if control_input_reset = '1' then
				ddr_read_state_next <= DDR_READ_IDLE;
			end if;
		end if;
	end process;

	assert DDR3_AXI_DATA_BYTES_LOG >= CCSDS_DATA_BYTES_IN_LOG
	report "MASTER AXI DATA WIDTH HAS TO BE WIDER THAN MASTER AXIS DATA WIDTH"
	severity failure;

	gen_ififo_input: if DDR3_AXI_DATA_BYTES_LOG > CCSDS_DATA_BYTES_IN_LOG generate
		assign_ififo_input_data: process(d_m_axi_rdata, ddr_read_align_curr)
		begin
			ififo_input_data <= d_m_axi_rdata((2**CCSDS_DATA_BYTES_IN_LOG)*8 - 1 downto 0);
			for i in 0 to 2**(DDR3_AXI_DATA_BYTES_LOG - CCSDS_DATA_BYTES_IN_LOG) - 1 loop	
				if unsigned(ddr_read_align_curr) = to_unsigned(i, ddr_read_align_curr'length) then
					ififo_input_data <= d_m_axi_rdata((2**CCSDS_DATA_BYTES_IN_LOG)*8*(i+1) - 1 downto (2**CCSDS_DATA_BYTES_IN_LOG)*8*i);
					exit;
				end if;
			end loop;
		end process;
	end generate;
	gen_ififo_input_equal_length: if DDR3_AXI_DATA_BYTES_LOG = CCSDS_DATA_BYTES_IN_LOG generate
		ififo_input_data <= d_m_axi_rdata;
	end generate;

	------------------------
	------------------------
	--CCSDS PIPELINE BELOW--
	------------------------
	------------------------
	--ccsds_rst is controlled by main process
	ccsds_rstn <= not ccsds_rst;
	------------------------
	
	
--	input_sample_fifo: entity work.AXIS_ASYNC_FIFO_SWRAP
--		Generic map (
--			DATA_WIDTH => 16,
--			FIFO_DEPTH_LOG => 9, --greater than 2!! (otherwise use other AXIS LINKS)
--			ALMOST_FULL_THRESHOLD => 256,
--			ALMOST_EMPTY_THRESHOLD => 256
--		)
--		Port map ( 
--			rst	=> ccsds_rst,
--			--input ctrl signals
--			axis_in_clk				=> d_m_axi_clk,
--			--input axi port
--			axis_in_valid			=> ififo_input_valid,
--			axis_in_ready			=> ififo_input_ready,
--			axis_in_data			=> ififo_input_data,
--			axis_in_last			=> '0',
--			axis_in_user			=> (others => '0'), 
--			axis_in_almost_full		=> open,
--			axis_in_full			=> open,
--			--output ctrl signals
--			axis_out_clk		 	=> ccsds_clk,
--			--output axi port
--			axis_out_ready			=> ififo_output_ready,
--			axis_out_data			=> ififo_output_data,
--			axis_out_last			=> open,
--			axis_out_user			=> open,
--			axis_out_valid			=> ififo_output_valid,
--			axis_out_almost_empty	=> ififo_almost_empty_pre,
--			axis_out_empty			=> open
--		);
	
	input_sample_fifo: axis_data_fifo_16b_512s
		Port map (
			s_axis_aresetn => ccsds_rstn,
			s_axis_aclk => d_m_axi_clk,
			s_axis_tvalid =>  ififo_input_valid,
			s_axis_tready => ififo_input_ready,
			s_axis_tdata => ififo_input_data,
			m_axis_aclk =>  ccsds_clk,
			m_axis_tvalid => ififo_output_valid,
			m_axis_tready => ififo_output_ready,
			m_axis_tdata => ififo_output_data,
			prog_empty => ififo_almost_empty_pre
		);
		
	d_m_axi_reset <= not d_m_axi_resetn;
	ififo_almost_empty_ccd: entity work.flag_cross_clock_domain
		port map (
			clk_a => ccsds_clk,
			rst_a => ccsds_rst,
			flag_a => ififo_almost_empty_pre,
			clk_b => d_m_axi_clk,
			rst_b => d_m_axi_reset,
			flag_b => ififo_almost_empty
		);

	s_axi_reg_cfg_sum_type_converted <= WIDE_NEIGHBOR_ORIENTED when s_axi_reg_cfg_sum_type(0) = '1' else WIDE_COLUMN_ORIENTED;
	ccsds_core: entity work.ccsds_123b2_core
		generic map (
			USE_HYBRID_CODER		=> true
		)
		port map ( 
			clk => ccsds_clk, rst => ccsds_rst,
			--core config
			cfg_p					=> s_axi_reg_cfg_p(CONST_MAX_P_WIDTH_BITS - 1 downto 0),
			cfg_sum_type 			=> s_axi_reg_cfg_sum_type_converted,
			cfg_samples				=> s_axi_reg_cfg_samples(CONST_MAX_SAMPLES_BITS - 1 downto 0),
			cfg_tinc				=> s_axi_reg_cfg_tinc(CONST_TINC_BITS - 1 downto 0),
			cfg_vmax 				=> s_axi_reg_cfg_vmax(CONST_VMINMAX_BITS - 1 downto 0),
			cfg_vmin				=> s_axi_reg_cfg_vmin(CONST_VMINMAX_BITS - 1 downto 0),
			cfg_depth				=> s_axi_reg_cfg_depth(CONST_MAX_DATA_WIDTH_BITS - 1 downto 0),
			cfg_omega				=> s_axi_reg_cfg_omega(CONST_MAX_OMEGA_WIDTH_BITS - 1 downto 0),
			cfg_weo					=> s_axi_reg_cfg_weo(CONST_WEO_BITS - 1 downto 0),
			cfg_use_abs_err			=> s_axi_reg_cfg_use_abs_err(0),
			cfg_use_rel_err			=> s_axi_reg_cfg_use_rel_err(0),
			cfg_abs_err 			=> s_axi_reg_cfg_abs_err(CONST_ABS_ERR_BITS - 1 downto 0),
			cfg_rel_err 			=> s_axi_reg_cfg_rel_err(CONST_REL_ERR_BITS - 1 downto 0),
			cfg_smax				=> s_axi_reg_cfg_smax(CONST_MAX_DATA_WIDTH - 1 downto 0),
			cfg_resolution			=> s_axi_reg_cfg_resolution(CONST_RES_BITS - 1 downto 0),
			cfg_damping				=> s_axi_reg_cfg_damping(CONST_DAMPING_BITS - 1 downto 0),
			cfg_offset				=> s_axi_reg_cfg_offset(CONST_OFFSET_BITS - 1 downto 0),
			--relocators config
			cfg_max_x				=> s_axi_reg_cfg_max_x(CONST_MAX_X_VALUE_BITS - 1 downto 0),
			cfg_max_y				=> s_axi_reg_cfg_max_y(CONST_MAX_Y_VALUE_BITS - 1 downto 0),
			cfg_max_z 				=> s_axi_reg_cfg_max_z(CONST_MAX_Z_VALUE_BITS - 1 downto 0),
			cfg_max_t				=> s_axi_reg_cfg_max_t(CONST_MAX_T_VALUE_BITS - 1 downto 0),
			cfg_min_preload_value 	=> s_axi_reg_cfg_min_preload_value(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0),
			cfg_max_preload_value 	=> s_axi_reg_cfg_max_preload_value(CONST_MAX_Z_VALUE_BITS*2 - 1 downto 0),
			--axis for starting weights (cfg)
			--cfg_weight_vec			: in std_logic_vector(CONST_WEIGHTVEC_BITS - 1 downto 0);
			--encoder things
			cfg_initial_counter		=> s_axi_reg_cfg_initial_counter(CONST_MAX_COUNTER_BITS - 1 downto 0),
			cfg_final_counter		=> s_axi_reg_cfg_final_counter(CONST_MAX_COUNTER_BITS - 1 downto 0),
			cfg_gamma_star			=> s_axi_reg_cfg_gamma_star(CONST_MAX_GAMMA_STAR_BITS - 1 downto 0),
			cfg_u_max				=> s_axi_reg_cfg_u_max(CONST_U_MAX_BITS - 1 downto 0),
			cfg_iacc				=> s_axi_reg_cfg_iacc(CONST_MAX_HR_ACC_BITS - 1 downto 0),
			--input port
			axis_in_s_d				=> ififo_output_data,
			axis_in_s_valid			=> ififo_output_valid,
			axis_in_s_ready			=> ififo_output_ready,
			--output port
			axis_out_data			=> core_raw_output_data,
			axis_out_valid			=> core_raw_output_valid,
			axis_out_last			=> core_raw_output_last,
			axis_out_ready			=> core_raw_output_ready
		);

	core_output_width_converter: entity work.axis_width_converter
		generic map (
			INPUT_DATA_WIDTH		=> 64,
			OUTPUT_DATA_WIDTH		=> 32
		)
		port map (
			clk => ccsds_clk, rst => ccsds_rst,
			input_ready	=> core_raw_output_ready,
			input_valid	=> core_raw_output_valid,
			input_data	=> core_raw_output_data,
			input_last	=> core_raw_output_last,
			output_ready=> core_output_ready,
			output_valid=> core_output_valid,
			output_data	=> core_output_data,
			output_last => core_output_last
		);

--	core_bypass: entity work.axis_width_converter
--		generic map (
--			INPUT_DATA_WIDTH		=> 16,
--			OUTPUT_DATA_WIDTH		=> 32
--		)
--		port map (
--			clk => ccsds_clk, rst => ccsds_rst,
--			input_ready	=> ififo_output_ready,
--			input_valid	=> ififo_output_valid,
--			input_data	=> ififo_output_data,
--			output_ready=> core_output_ready,
--			output_valid=> core_output_valid,
--			output_data	=> core_output_data
--		);
--	core_output_last <= '0';

	last_watcher: process(ccsds_clk)
	begin
		if rising_edge(ccsds_clk) then
			if ccsds_rst = '1' then
				ofifo_seen_last_pre <= '0';
			else
				if core_output_valid = '1' and core_output_ready = '1' then
					if core_output_last = '1' then
						ofifo_seen_last_pre <= '1';
					end if;
				elsif control_output_reset = '1' then
					ofifo_seen_last_pre <= '0';
				end if;	
			end if;
		end if;
	end process;
	
	ofifo_seen_last_ccd: entity work.flag_cross_clock_domain
		port map (
			clk_a => ccsds_clk,
			rst_a => ccsds_rst,
			flag_a => ofifo_seen_last_pre,
			clk_b => d_m_axi_clk,
			rst_b => d_m_axi_reset,
			flag_b => ofifo_seen_last
		);
		
--	output_sample_fifo: entity work.AXIS_ASYNC_FIFO_SWRAP
--		Generic map (
--			DATA_WIDTH => 32,
--			FIFO_DEPTH_LOG => 9, --greater than 2!! (otherwise use other AXIS LINKS)
--			ALMOST_FULL_THRESHOLD => 256,
--			ALMOST_EMPTY_THRESHOLD => 256
--		)
--		Port map ( 
--			rst	=> ccsds_rst,
--			--input ctrl signals
--			axis_in_clk	=> ccsds_clk,
--			--input axi port
--			axis_in_valid			=> core_output_valid,
--			axis_in_ready			=> core_output_ready,
--			axis_in_data			=> core_output_data,
--			axis_in_last			=> core_output_last,
--			axis_in_user			=> (others => '0'), 
--			axis_in_almost_full		=> ofifo_almost_full_pre,
--			axis_in_full			=> open,
--			--output ctrl signals
--			axis_out_clk		 	=> d_m_axi_clk,
--			--output axi port
--			axis_out_ready			=> ofifo_output_ready,
--			axis_out_data			=> ofifo_output_data,
--			axis_out_last			=> ofifo_output_last,
--			axis_out_user			=> open,
--			axis_out_valid			=> ofifo_output_valid,
--			axis_out_almost_empty	=> open,
--			axis_out_empty			=> open
--		);
	
	output_sample_fifo: axis_data_fifo_32b_512s
		Port map (
			s_axis_aresetn => ccsds_rstn,
			s_axis_aclk => ccsds_clk,
			s_axis_tvalid => core_output_valid,
			s_axis_tready => core_output_ready,
			s_axis_tdata => core_output_data,
			s_axis_tlast => core_output_last,
			m_axis_aclk => d_m_axi_clk,
			m_axis_tvalid => ofifo_output_valid,
			m_axis_tready => ofifo_output_ready,
			m_axis_tdata => ofifo_output_data,
			m_axis_tlast => ofifo_output_last,
			prog_full => ofifo_almost_full_pre
		);
		
	ofifo_almost_full_ccd: entity work.flag_cross_clock_domain
		port map (
			clk_a => ccsds_clk,
			rst_a => ccsds_rst,
			flag_a => ofifo_almost_full_pre,
			clk_b => d_m_axi_clk,
			rst_b => d_m_axi_reset,
			flag_b => ofifo_almost_full
		);
		
	------------------------
	------------------------
	--CCSDS PIPELINE ABOVE--
	------------------------
	------------------------

	--------------------------------
	--CORE TO DDR OUTPUT PROCESSES--
	--------------------------------
	ddr_write_seq: process(d_m_axi_clk)
	begin
		if rising_edge(d_m_axi_clk) then
			if d_m_axi_resetn = '0' then
				ddr_write_state_curr <= DDR_WRITE_IDLE;
				s_axi_reg_outbyt <= (others => '0');
			else
				ddr_write_state_curr <= ddr_write_state_next;
				ddr_write_addr_curr  <= ddr_write_addr_next;
				ddr_write_transactions_left_curr <= ddr_write_transactions_left_next;
				s_axi_reg_outbyt     <= s_axi_reg_outbyt_next;
			end if;
		end if;
	end process;

	--fixed signals
	d_m_axi_awlen	<= (others => '1'); --set all by default (we don't know how many we'll have) (when we run out set wstrb to zero)
	d_m_axi_awsize	<= std_logic_vector(to_unsigned(DDR3_AXI_DATA_BYTES_LOG, d_m_axi_arsize'length));
	d_m_axi_awburst	<= AXI_BURST_INCR;
	d_m_axi_awlock  <= AXI_LOCK_UNLOCKED;
	d_m_axi_awcache <= AXI_CACHE_NORMAL_NONCACHE_NONBUFF;
	d_m_axi_awprot  <= AXI_PROT_UNPRIVILEDGED_NONSECURE_DATA;
	d_m_axi_awqos   <= AXI_QOS_EIGHT;
	d_m_axi_awaddr	<= ddr_write_addr_curr;
	--
	d_m_axi_wdata  <= ofifo_output_data;
	ddr_write_comb: process(ddr_write_state_curr, ddr_write_addr_curr, ddr_write_transactions_left_curr, s_axi_reg_tgaddr,
			control_output_transfer_enable, control_output_reset, s_axi_reg_outbyt,
			d_m_axi_awready, d_m_axi_wready, d_m_axi_bvalid, ofifo_output_valid, ofifo_output_last,
			ofifo_almost_full, ofifo_seen_last)
	begin
		s_axi_reg_ddrwst <= x"00000000";
		
		ddr_write_state_next <= ddr_write_state_curr;
		control_output_idle <= '0';
		ddr_write_addr_next <= ddr_write_addr_curr;
		d_m_axi_awvalid 	<= '0';
		ddr_write_transactions_left_next <= ddr_write_transactions_left_curr;
		ofifo_output_ready	<= '0';
		d_m_axi_wvalid 		<= '0';
		d_m_axi_wlast 		<= '0';
		d_m_axi_wstrb		<= (others => '0');
		d_m_axi_bready 		<= '0';

		control_output_transfer_done <= '0';
		
		s_axi_reg_outbyt_next <= s_axi_reg_outbyt;

		if ddr_write_state_curr = DDR_WRITE_IDLE then
			s_axi_reg_ddrwst <= x"00000001";
			control_output_idle <= '1';
			if control_output_transfer_enable = '1' then
				ddr_write_state_next <= DDR_WRITE_READY;
				ddr_write_addr_next  <= s_axi_reg_tgaddr;
			end if;
		elsif ddr_write_state_curr = DDR_WRITE_READY then
			s_axi_reg_ddrwst <= x"00000010";
			if control_output_transfer_enable = '1' then
				--IF output fifo is almost full (has enough bytes to feed a full write) 
				--OR output fifo has read a 'last' flag (has to send stuff out cause its never gonna fill)
				--THEN initiate transaction (which potentially ends in a string of zero-strobed writes)
				if ofifo_almost_full = '1' or ofifo_seen_last = '1' then
					ddr_write_state_next <= DDR_WRITE_REQUEST;
				end if;
			--if central control has deasserted our enable, we know we have to finish early (in-flight reset)
			else 
				ddr_write_state_next <= DDR_WRITE_FINISH;
			end if;
		elsif ddr_write_state_curr = DDR_WRITE_REQUEST then
			s_axi_reg_ddrwst <= x"00000100";
			d_m_axi_awvalid <= '1';
			if d_m_axi_awready = '1' then
				ddr_write_state_next <= DDR_WRITE_TRANSFER;
				ddr_write_transactions_left_next <= (others => '1');
				ddr_write_addr_next			  	 <= std_logic_vector(unsigned(ddr_write_addr_curr) + to_unsigned(2**(AXI_LEN_WIDTH+DDR3_AXI_DATA_BYTES_LOG), ddr_write_addr_curr'length));
			end if;
		elsif ddr_write_state_curr = DDR_WRITE_TRANSFER then
			s_axi_reg_ddrwst <= x"00001000";
			ofifo_output_ready	<= d_m_axi_wready;
			d_m_axi_wvalid 		<= ofifo_output_valid;
			d_m_axi_wstrb		<= (others => '1');
			if ofifo_output_valid = '1' and d_m_axi_wready = '1' then
				s_axi_reg_outbyt_next <= std_logic_vector(unsigned(s_axi_reg_outbyt) + to_unsigned(2**DDR3_AXI_DATA_BYTES_LOG, s_axi_reg_outbyt'length));
				if ddr_write_transactions_left_curr = (ddr_write_transactions_left_curr'range => '0') then
					d_m_axi_wlast <= '1';
					if ofifo_output_last = '0' then
						ddr_write_state_next <= DDR_WRITE_RESPONSE;
					else
						ddr_write_state_next <= DDR_WRITE_LAST_RESPONSE;
					end if;
				else
					ddr_write_transactions_left_next <= std_logic_vector(unsigned(ddr_write_transactions_left_curr) - to_unsigned(1, ddr_write_transactions_left_curr'length));
					if ofifo_output_last = '1' then
						--last word but we still are on the write transaction. Change state to go to disable strobing
						ddr_write_state_next <= DDR_WRITE_TRANSFER_NOSTRB;
					end if;
				end if;
			end if;
		--finishing transaction with empty bytes to avoid overwriting of stuff
		elsif ddr_write_state_curr = DDR_WRITE_TRANSFER_NOSTRB then
			s_axi_reg_ddrwst <= x"00010000";
			d_m_axi_wvalid <= '1';
			d_m_axi_wstrb <= (others => '0');
			if d_m_axi_wready = '1' then
				--don't count these as bytes sent
				--s_axi_reg_outbyt_next <= std_logic_vector(unsigned(s_axi_reg_outbyt) + to_unsigned(1, s_axi_reg_outbyt'length));
				if ddr_write_transactions_left_curr = (ddr_write_transactions_left_curr'range => '0') then
					d_m_axi_wlast <= '1';
					ddr_write_state_next <= DDR_WRITE_LAST_RESPONSE;
				else
					ddr_write_transactions_left_next <= std_logic_vector(unsigned(ddr_write_transactions_left_curr) - to_unsigned(1, ddr_write_transactions_left_curr'length));
				end if;
			end if;
		elsif ddr_write_state_curr = DDR_WRITE_RESPONSE then
			s_axi_reg_ddrwst <= x"00100000";
			d_m_axi_bready <= '1';
			if d_m_axi_bvalid = '1' then
				ddr_write_state_next <= DDR_WRITE_READY;
			end if;
		elsif ddr_write_state_curr = DDR_WRITE_LAST_RESPONSE then
			s_axi_reg_ddrwst <= x"01000000";
			d_m_axi_bready <= '1';
			if d_m_axi_bvalid = '1' then
				ddr_write_state_next <= DDR_WRITE_FINISH;
			end if;
		elsif ddr_write_state_curr = DDR_WRITE_FINISH then
			s_axi_reg_ddrwst <= x"10000000";
			control_output_transfer_done <= '1';
			if control_output_reset = '1' then
				ddr_write_state_next <= DDR_WRITE_IDLE;
			end if;
		end if;
	end process;

	--------------------------
	--CLOCK STATUS REGISTERS--
	--------------------------
	clk_control_update: process(c_s_axi_clk)
	begin
		if rising_edge(c_s_axi_clk) then
			if c_s_axi_resetn = '0' then
				s_axi_reg_cnclk <= (others => '0');
			else
				s_axi_reg_cnclk <= std_logic_vector(unsigned(s_axi_reg_cnclk) + to_unsigned(1, s_axi_reg_cnclk'length));
			end if;
		end if;
	end process;
	clk_data_update: process(d_m_axi_clk)
	begin
		if rising_edge(d_m_axi_clk) then
			if d_m_axi_resetn = '0' then
				s_axi_reg_mmclk_pre <= (others => '0');
			else
				s_axi_reg_mmclk_pre <= std_logic_vector(unsigned(s_axi_reg_mmclk_pre) + to_unsigned(1, s_axi_reg_mmclk_pre'length));
			end if;
		end if;
	end process;
	mmclk_cross: entity work.stdlv_cross_clock_domain
		generic map (
			SIGNAL_WIDTH => (2**CONTROLLER_DATA_BYTES_LOG)*2*8
		)
		port map (
			clk_a => d_m_axi_clk,
			rst_a => '0',
			signal_a => s_axi_reg_mmclk_pre,
			clk_b => c_s_axi_clk,
			rst_b => '0',
			signal_b => s_axi_reg_mmclk
		);
	clk_ccsds_update: process(ccsds_clk)
	begin
		if rising_edge(ccsds_clk) then
			if ccsds_rst = '1' then
				s_axi_reg_coclk_pre <= (others => '0');
			else
				s_axi_reg_coclk_pre <= std_logic_vector(unsigned(s_axi_reg_coclk_pre) + to_unsigned(1, s_axi_reg_coclk_pre'length));
			end if;
		end if;
	end process;
	c_s_axi_reset <= not c_s_axi_resetn;
	coclk_cross: entity work.stdlv_cross_clock_domain
		generic map (
			SIGNAL_WIDTH => (2**CONTROLLER_DATA_BYTES_LOG)*2*8
		)
		port map (
			clk_a => ccsds_clk,
			rst_a => '0',
			signal_a => s_axi_reg_coclk_pre,
			clk_b => c_s_axi_clk,
			rst_b => '0',
			signal_b => s_axi_reg_coclk
		);


end Behavioral;