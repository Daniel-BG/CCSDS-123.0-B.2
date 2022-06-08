`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.01.2022 16:18:53
// Design Name: 
// Module Name: ccsds_123b2_core_selfcheck_fpga_selftest
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ccsds_123b2_core_standalone_wrapper(
		input logic clk,
		input logic rst,
		//input bus
		input logic [15:0] axi_in_d,
		input logic axi_in_valid,
		output logic axi_in_ready,
		output logic [63:0] axi_out_d,
		output logic axi_out_valid,
		input logic axi_out_ready,
		output logic axi_out_last,
		output logic selfcheck_full_failed,
		output logic selfcheck_full_finished,
		output logic selfcheck_ref_failed,
		output logic selfcheck_ref_finished,
		output logic selfcheck_timeout,
		input logic selfcheck_init
    );    
    
    
     ccsds_123b2_core_selfcheck_wrapper 
    #(
    	.PATTERN_IN("pattern_in.mif"),
		.selfcheck_ref_cnt_limit(4881),
		.selfcheck_ref_checksum(64'h0004360006B58000),
		.PATTERN_OUT("pattern_out.mif"),
		.selfcheck_input_words(61200),
		.selfcheck_timeout_cnt_limit(217500)
    ) 
    selfcheck_core
    (
    	.clk(clk), 
    	.rst(inner_reset),
		.selfcheck_init(selfcheck_init),
		.selfcheck_working(),
		.selfcheck_full_failed(selfcheck_full_failed),
		.selfcheck_full_finished(selfcheck_full_finished),
		.selfcheck_ref_failed(selfcheck_ref_failed),
		.selfcheck_ref_finished(selfcheck_ref_finished),
		.selfcheck_timeout(selfcheck_timeout),
		.cfg_full_prediction(1),
		.cfg_p(3),
		.cfg_smid(32768),
		.cfg_wide_sum(1),
		.cfg_neighbor_sum(1),
		.cfg_samples(128),
		.cfg_tinc(6),
		.cfg_vmax(3),
		.cfg_vmin(-1),
		.cfg_depth(16),
		.cfg_omega(19),
		.cfg_weo(0),
		.cfg_use_abs_err(1),
		.cfg_use_rel_err(1),
		.cfg_abs_err(1024),
		.cfg_rel_err(4096),
		.cfg_smax(65535),
		.cfg_resolution(4),
		.cfg_damping(4),
		.cfg_offset(4),
		.cfg_max_x(127),
		.cfg_max_y(63),
		.cfg_max_z(31),
		.cfg_max_t(8191),
		.cfg_min_preload_value(467),
		.cfg_max_preload_value(471),
		.cfg_initial_counter(2),
		.cfg_final_counter(63),
		.cfg_gamma_star(6),
		.cfg_u_max(18),
		.cfg_iacc(40),
		.cfg_error(),
		.axis_in_s_d(axi_in_d),
		.axis_in_s_valid(axi_in_valid),
		.axis_in_s_ready(axi_in_ready),
		.axis_out_data(axi_out_d),
		.axis_out_valid(axi_out_valid),
		.axis_out_last(axi_out_last),
		.axis_out_ready(axi_out_ready)
    );
    
    
//    ccsds_123b2_dmr
//    core
//    (
//    	.clk(clk), 
//    	.rst(rst),
//		.cfg_full_prediction(1),
//		.cfg_p(3),
//		.cfg_smid(32768),
//		.cfg_wide_sum(1),
//		.cfg_neighbor_sum(1),
//		.cfg_samples(128),
//		.cfg_tinc(6),
//		.cfg_vmax(3),
//		.cfg_vmin(-1),
//		.cfg_depth(16),
//		.cfg_omega(19),
//		.cfg_weo(0),
//		.cfg_use_abs_err(1),
//		.cfg_use_rel_err(1),
//		.cfg_abs_err(1024),
//		.cfg_rel_err(4096),
//		.cfg_smax(65535),
//		.cfg_resolution(4),
//		.cfg_damping(4),
//		.cfg_offset(4),
//		.cfg_max_x(127),
//		.cfg_max_y(63),
//		.cfg_max_z(31),
//		.cfg_max_t(8191),
//		.cfg_min_preload_value(467),
//		.cfg_max_preload_value(471),
//		.cfg_initial_counter(2),
//		.cfg_final_counter(63),
//		.cfg_gamma_star(6),
//		.cfg_u_max(18),
//		.cfg_iacc(40),
//		.cfg_error(),
//		.axis_in_s_d(axi_in_d),
//		.axis_in_s_valid(axi_in_valid),
//		.axis_in_s_ready(axi_in_ready),
//		.axis_out_data(axi_out_d),
//		.axis_out_valid(axi_out_valid),
//		.axis_out_last(axi_out_last),
//		.axis_out_ready(axi_out_ready),
//		//DMR
//		.dmr_error_0(dmr_error_0),
//		.dmr_error_1(dmr_error_1)
//    );
    
endmodule
