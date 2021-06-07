--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : ccsds_controller_tb.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Thu Jun  3 09:48:20 2021
-- Last update : Thu Jun  3 09:50:52 2021
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
use work.am_constants.all;

-----------------------------------------------------------

entity ccsds_controller_tb is

end entity ccsds_controller_tb;

-----------------------------------------------------------

architecture testbench of ccsds_controller_tb is

	-- Testbench DUT generics
	constant CONTROLLER_ADDR_WIDTH     : integer := 32;
	constant CONTROLLER_DATA_BYTES_LOG : integer := 2;
	constant DDR3_AXI_ADDR_WIDTH       : integer := 32;
	constant DDR3_AXI_DATA_BYTES_LOG   : integer := 2;

	-- Testbench DUT ports
	signal ccsds_clk                    : std_logic;
	signal c_s_axi_clk , c_s_axi_resetn : std_logic;
	signal c_s_axi_araddr               : std_logic_vector(CONTROLLER_ADDR_WIDTH - 1 downto 0);
	signal c_s_axi_arready              : std_logic;
	signal c_s_axi_arvalid              : std_logic;
	signal c_s_axi_rdata                : std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0);
	signal c_s_axi_rready               : std_logic;
	signal c_s_axi_rresp                : std_logic_vector(AXI_BRESP_WIDTH - 1 downto 0);
	signal c_s_axi_rvalid               : std_logic;
	signal c_s_axi_awaddr               : std_logic_vector(CONTROLLER_ADDR_WIDTH - 1 downto 0);
	signal c_s_axi_awready              : std_logic;
	signal c_s_axi_awvalid              : std_logic;
	signal c_s_axi_wdata                : std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG)*8 - 1 downto 0);
	signal c_s_axi_wready               : std_logic;
	signal c_s_axi_wstrb                : std_logic_vector((2**CONTROLLER_DATA_BYTES_LOG) - 1 downto 0);
	signal c_s_axi_wvalid               : std_logic;
	signal c_s_axi_bready               : std_logic;
	signal c_s_axi_bresp                : std_logic_vector(AXI_BRESP_WIDTH - 1 downto 0);
	signal c_s_axi_bvalid               : std_logic;
	signal d_m_axi_clk , d_m_axi_resetn : std_logic;
	signal d_m_axi_awaddr               : std_logic_vector(DDR3_AXI_ADDR_WIDTH - 1 downto 0);
	signal d_m_axi_awlen                : std_logic_vector(AXI_LEN_WIDTH - 1 downto 0);
	signal d_m_axi_awsize               : std_logic_vector(AXI_SIZE_WIDTH - 1 downto 0);
	signal d_m_axi_awburst              : std_logic_vector(AXI_BURST_WIDTH - 1 downto 0);
	signal d_m_axi_awlock               : std_logic;
	signal d_m_axi_awcache              : std_logic_vector(AXI_CACHE_WIDTH - 1 downto 0);
	signal d_m_axi_awprot               : std_logic_vector(AXI_PROT_WIDTH - 1 downto 0);
	signal d_m_axi_awqos                : std_logic_vector(AXI_QOS_WIDTH - 1 downto 0);
	signal d_m_axi_awvalid              : std_logic;
	signal d_m_axi_awready              : std_logic;
	signal d_m_axi_wdata                : std_logic_vector((2**DDR3_AXI_DATA_BYTES_LOG)*8 - 1 downto 0);
	signal d_m_axi_wstrb                : std_logic_vector((2**DDR3_AXI_DATA_BYTES_LOG) - 1 downto 0);
	signal d_m_axi_wlast                : std_logic;
	signal d_m_axi_wvalid               : std_logic;
	signal d_m_axi_wready               : std_logic;
	signal d_m_axi_bresp                : std_logic_vector(AXI_BRESP_WIDTH - 1 downto 0);
	signal d_m_axi_bvalid               : std_logic;
	signal d_m_axi_bready               : std_logic;
	signal d_m_axi_araddr               : std_logic_vector(DDR3_AXI_ADDR_WIDTH - 1 downto 0);
	signal d_m_axi_arlen                : std_logic_vector(AXI_LEN_WIDTH - 1 downto 0);
	signal d_m_axi_arsize               : std_logic_vector(AXI_SIZE_WIDTH - 1 downto 0);
	signal d_m_axi_arburst              : std_logic_vector(AXI_BURST_WIDTH - 1 downto 0);
	signal d_m_axi_arlock               : std_logic;
	signal d_m_axi_arcache              : std_logic_vector(AXI_CACHE_WIDTH - 1 downto 0);
	signal d_m_axi_arprot               : std_logic_vector(AXI_PROT_WIDTH - 1 downto 0);
	signal d_m_axi_arqos                : std_logic_vector(AXI_QOS_WIDTH - 1 downto 0);
	signal d_m_axi_arvalid              : std_logic;
	signal d_m_axi_arready              : std_logic;
	signal d_m_axi_rdata                : std_logic_vector((2**DDR3_AXI_DATA_BYTES_LOG)*8 - 1 downto 0);
	signal d_m_axi_rresp                : std_logic_vector(AXI_BRESP_WIDTH - 1 downto 0);
	signal d_m_axi_rlast                : std_logic;
	signal d_m_axi_rvalid               : std_logic;
	signal d_m_axi_rready               : std_logic;

	-- Other constants
	constant C_CLK_PERIOD_CNT : real := 10.0e-9; -- NS
	constant C_CLK_PERIOD_MEM : real := 5.0e-9; -- NS
	constant C_CLK_PERIOD_CORE : real := 3.333e-9; -- NS

begin
	-----------------------------------------------------------
	-- Clocks and Reset
	-----------------------------------------------------------
	CLK_GEN_CNT : process
	begin
		c_s_axi_clk <= '1';
		wait for C_CLK_PERIOD_CNT / 2.0 * (1 SEC);
		c_s_axi_clk <= '0';
		wait for C_CLK_PERIOD_CNT / 2.0 * (1 SEC);
	end process CLK_GEN_CNT;

	CLK_GEN_MEM : process
	begin
		d_m_axi_clk <= '1';
		wait for C_CLK_PERIOD_MEM / 2.0 * (1 SEC);
		d_m_axi_clk <= '0';
		wait for C_CLK_PERIOD_MEM / 2.0 * (1 SEC);
	end process CLK_GEN_MEM;

	CLK_GEN_CORE : process
	begin
		ccsds_clk <= '1';
		wait for C_CLK_PERIOD_CORE / 2.0 * (1 SEC);
		ccsds_clk <= '0';
		wait for C_CLK_PERIOD_CORE / 2.0 * (1 SEC);
	end process CLK_GEN_CORE;

	RESET_GEN_C : process
	begin
		c_s_axi_resetn <= '0',
		         '1' after 20.0*C_CLK_PERIOD_CNT * (1 SEC);
		wait;
	end process RESET_GEN_C;

	RESET_GEN_D : process
	begin
		d_m_axi_resetn <= '0',
		         '1' after 20.0*C_CLK_PERIOD_MEM * (1 SEC);
		wait;
	end process RESET_GEN_D;
	-----------------------------------------------------------
	-- Testbench Stimulus
	-----------------------------------------------------------

	-----------------------------------------------------------
	-- Entity Under Test
	-----------------------------------------------------------
	DUT : entity work.ccsds_controller
		generic map (
			CONTROLLER_ADDR_WIDTH     => CONTROLLER_ADDR_WIDTH,
			CONTROLLER_DATA_BYTES_LOG => CONTROLLER_DATA_BYTES_LOG,
			DDR3_AXI_ADDR_WIDTH       => DDR3_AXI_ADDR_WIDTH,
			DDR3_AXI_DATA_BYTES_LOG   => DDR3_AXI_DATA_BYTES_LOG
		)
		port map (
			ccsds_clk       => ccsds_clk,
			c_s_axi_clk     => c_s_axi_clk,
			c_s_axi_resetn  => c_s_axi_resetn,
			c_s_axi_araddr  => c_s_axi_araddr,
			c_s_axi_arready => c_s_axi_arready,
			c_s_axi_arvalid => c_s_axi_arvalid,
			c_s_axi_rdata   => c_s_axi_rdata,
			c_s_axi_rready  => c_s_axi_rready,
			c_s_axi_rresp   => c_s_axi_rresp,
			c_s_axi_rvalid  => c_s_axi_rvalid,
			c_s_axi_awaddr  => c_s_axi_awaddr,
			c_s_axi_awready => c_s_axi_awready,
			c_s_axi_awvalid => c_s_axi_awvalid,
			c_s_axi_wdata   => c_s_axi_wdata,
			c_s_axi_wready  => c_s_axi_wready,
			c_s_axi_wstrb   => c_s_axi_wstrb,
			c_s_axi_wvalid  => c_s_axi_wvalid,
			c_s_axi_bready  => c_s_axi_bready,
			c_s_axi_bresp   => c_s_axi_bresp,
			c_s_axi_bvalid  => c_s_axi_bvalid,
			d_m_axi_clk     => d_m_axi_clk,
			d_m_axi_resetn  => d_m_axi_resetn,
			d_m_axi_awaddr  => d_m_axi_awaddr,
			d_m_axi_awlen   => d_m_axi_awlen,
			d_m_axi_awsize  => d_m_axi_awsize,
			d_m_axi_awburst => d_m_axi_awburst,
			d_m_axi_awlock  => d_m_axi_awlock,
			d_m_axi_awcache => d_m_axi_awcache,
			d_m_axi_awprot  => d_m_axi_awprot,
			d_m_axi_awqos   => d_m_axi_awqos,
			d_m_axi_awvalid => d_m_axi_awvalid,
			d_m_axi_awready => d_m_axi_awready,
			d_m_axi_wdata   => d_m_axi_wdata,
			d_m_axi_wstrb   => d_m_axi_wstrb,
			d_m_axi_wlast   => d_m_axi_wlast,
			d_m_axi_wvalid  => d_m_axi_wvalid,
			d_m_axi_wready  => d_m_axi_wready,
			d_m_axi_bresp   => d_m_axi_bresp,
			d_m_axi_bvalid  => d_m_axi_bvalid,
			d_m_axi_bready  => d_m_axi_bready,
			d_m_axi_araddr  => d_m_axi_araddr,
			d_m_axi_arlen   => d_m_axi_arlen,
			d_m_axi_arsize  => d_m_axi_arsize,
			d_m_axi_arburst => d_m_axi_arburst,
			d_m_axi_arlock  => d_m_axi_arlock,
			d_m_axi_arcache => d_m_axi_arcache,
			d_m_axi_arprot  => d_m_axi_arprot,
			d_m_axi_arqos   => d_m_axi_arqos,
			d_m_axi_arvalid => d_m_axi_arvalid,
			d_m_axi_arready => d_m_axi_arready,
			d_m_axi_rdata   => d_m_axi_rdata,
			d_m_axi_rresp   => d_m_axi_rresp,
			d_m_axi_rlast   => d_m_axi_rlast,
			d_m_axi_rvalid  => d_m_axi_rvalid,
			d_m_axi_rready  => d_m_axi_rready
		);

end architecture testbench;