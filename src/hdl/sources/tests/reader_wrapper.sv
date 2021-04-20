`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.04.2021 17:39:26
// Design Name: 
// Module Name: reader_wrapper
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
`include "test_shared.svh"




module reader_wrapper (
		clk, rst, enable,
		output_valid, output_data, output_ready
);
    
	parameter DATA_WIDTH=10;
	parameter FILE_NUMBER = 0;
	parameter SKIP = 0;
	
	input					clk, rst, enable;
	output 					output_valid;
	output [DATA_WIDTH-1:0]	output_data;
	input					output_ready;
	
	localparam string FILE_NAME = getFileNameFromNum(FILE_NUMBER);
	
	helper_axis_reader #(
		.DATA_WIDTH(DATA_WIDTH),
		.SKIP(SKIP),
		.FILE_NAME(FILE_NAME)
	) reader_instance (
		.clk(clk), .rst(rst), .enable(enable),
		.output_valid(output_valid), .output_data(output_data), .output_ready(output_ready)
	);
    
endmodule
