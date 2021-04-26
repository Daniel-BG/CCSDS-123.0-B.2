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




module checker_wrapper (
		clk, rst,
		valid, data, ready
);
    
	parameter DATA_WIDTH=10;
	parameter FILE_NUMBER = 0;
	parameter SKIP = 0;
	parameter SHOW_ALL = 0;
	parameter BINARY = 0;
	
	input					clk, rst;
	input 					valid;
	input [DATA_WIDTH-1:0]	data;
	input					ready;
	
	localparam string FILE_NAME = getFileNameFromNum(FILE_NUMBER);
	
	`ifndef DO_NOT_CHECK
		inline_axis_checker #(
			.DATA_WIDTH(DATA_WIDTH),
			.SKIP(SKIP),
			.FILE_NAME(FILE_NAME),
			.SHOW_ALL(SHOW_ALL),
			.BINARY(BINARY)
		) checker_instance (
			.clk(clk), .rst(rst),
			.valid(valid), .data(data), .ready(ready)
		);
	`endif
    
endmodule
