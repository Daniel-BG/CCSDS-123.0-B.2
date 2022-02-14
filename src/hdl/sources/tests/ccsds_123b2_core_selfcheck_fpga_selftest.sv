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


module ccsds_123b2_core_selfcheck_fpga_selftest(
		input logic clk,
		input logic rst,
		input logic selfcheck_init,
		output logic selfcheck_working,
		output logic selfcheck_full_failed,
		output logic selfcheck_full_finished,
		output logic selfcheck_ref_failed,
		output logic selfcheck_ref_finished,
		output logic selfcheck_timeout,
		output logic check_failed,
		output logic check_finished
    );
    
    wire inner_reset;
    
    wire [15:0] axis_in_s_d;
    wire axis_in_s_valid, axis_in_s_ready;
    wire [63:0] axis_out_data, axis_rom_data;
    wire axis_out_valid, axis_out_last, axis_out_ready, axis_rom_valid, axis_rom_ready;
    
    reg inner_failed, inner_finished;
    
    
	reset_replicator #() reset_rep
		(
			.clk(clk), 
			.rst(rst), 
			.rst_out(inner_reset)
		);
    
    axis_rom_fifo
		#(
			.width(16),
			.depth(61200),
			.intFile("pattern_in.mif")
   		)
   		input_rom
   		(
   			.clk(clk),
   			.rst(inner_reset),
   			.axis_d(axis_in_s_d),
   			.axis_valid(axis_in_s_valid),
   			.axis_ready(axis_in_s_ready)
   		);
    
    ccsds_123b2_core_selfcheck_wrapper 
    #(
    	.PATTERN_IN("pattern_in.mif"),
		.selfcheck_ref_cnt_limit(4881),
		.selfcheck_ref_checksum(64'h0004360006B58000),
		.PATTERN_OUT("pattern_out.mif"),
		.selfcheck_input_words(61200),
		.selfcheck_timeout_cnt_limit(220000)
    ) 
    selfcheck_core
    (
    	.clk(clk), 
    	.rst(inner_reset),
		.selfcheck_init(selfcheck_init),
		.selfcheck_working(selfcheck_working),
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
		.cfg_samples(100),
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
		.cfg_max_x(99),
		.cfg_max_y(35),
		.cfg_max_z(16),
		.cfg_max_t(3599),
		.cfg_min_preload_value(122),
		.cfg_max_preload_value(126),
		.cfg_initial_counter(2),
		.cfg_final_counter(63),
		.cfg_gamma_star(6),
		.cfg_u_max(18),
		.cfg_iacc(40),
		.cfg_error(),
		.axis_in_s_d(axis_in_s_d),
		.axis_in_s_valid(axis_in_s_valid),
		.axis_in_s_ready(axis_in_s_ready),
		.axis_out_data(axis_out_data),
		.axis_out_valid(axis_out_valid),
		.axis_out_last(axis_out_last),
		.axis_out_ready(axis_out_ready)
    );
    
    
	axis_rom_fifo
		#(
			.width(64),
			.depth(4881),
			.intFile("pattern_out.mif")
   		)
   		output_rom
   		(
   			.clk(clk),
   			.rst(inner_reset),
   			.axis_d(axis_rom_data),
   			.axis_valid(axis_rom_valid),
   			.axis_ready(axis_rom_ready)
   		);
   		
   	//logic to check status
   	//always ready to read
   	assign axis_out_ready = 1;
   	assign axis_rom_ready = axis_out_valid;
   	
   	always_ff @(posedge clk)
   	begin
   		if (rst) begin
   			inner_failed <= 0;
   			inner_finished <= 0;
   		end else begin
   			if (axis_out_valid) begin
   				if (axis_rom_data != axis_out_data && inner_finished == 0) begin
   					inner_failed <= 1;
   				end
   				if (axis_out_last) begin
   					inner_finished <= 1;
   				end
   			end
   		end
   	end;
   	
   	
   	assign check_failed = inner_failed;
   	assign check_finished = inner_finished;
    
endmodule
