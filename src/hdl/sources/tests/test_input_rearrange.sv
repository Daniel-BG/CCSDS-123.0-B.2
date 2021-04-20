`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.03.2021 09:28:53
// Design Name: 
// Module Name: test_input_rearrange
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


module test_input_rearrange;
	parameter MAX_X_WIDTH = 9;
	parameter MAX_Y_WIDTH = 10;
	parameter MAX_Z_WIDTH = 8;
	parameter MAX_T_WIDTH = 19;
	parameter DATA_WIDTH = 16;

	parameter PERIOD = 10;

	reg clk, rst;
	wire finished;
	wire [MAX_X_WIDTH-1:0] cfg_max_x = 7;
	wire [MAX_Y_WIDTH-1:0] cfg_max_y = 7;
	wire [MAX_Z_WIDTH-1:0] cfg_max_z = 7;	
	wire [MAX_T_WIDTH-1:0] cfg_max_t = 63;
	wire [MAX_Z_WIDTH*2-1:0] cfg_min_preload_value = ((cfg_max_z)*(cfg_max_z-1))/2 + 2;
	wire [MAX_Z_WIDTH*2-1:0] cfg_max_preload_value = ((cfg_max_z)*(cfg_max_z-1))/2 + 6;
	
	reg [DATA_WIDTH-1:0] axis_input_d;
	wire axis_input_ready;
	reg axis_input_valid;
	
	wire [DATA_WIDTH-1:0]axis_output_d;
	wire [5:0]axis_output_flags;
	wire axis_output_last;
	wire axis_output_valid;
	reg axis_output_ready;

	always #(PERIOD/2) clk = ~clk;
	
	initial begin
		clk = 0;
		rst = 1;
		axis_input_d = 0;
		axis_input_valid = 0;
		axis_output_ready = 0;
		#(PERIOD*2) //hold reset
		rst = 0;
		axis_output_ready = 1;
		#(PERIOD) //start now
		
		
		fork
			
			begin : thread_fill
				@(posedge clk);
				for (int y = 0; y <= cfg_max_y; y++) begin
					for (int x = 0; x <= cfg_max_x; x++) begin
						for (int z = 0; z <= cfg_max_z; z++) begin
							#(PERIOD/2);
							axis_input_d = z*(cfg_max_x+1)*(cfg_max_y+1) + y*(cfg_max_x+1) + x;
							axis_input_valid = 1;
							wait (axis_input_ready == 1);
							@(posedge clk);
						end
					end
				end
				axis_input_valid = 0;
			end : thread_fill
		
			begin : thread_empty
				automatic int z = 0;
				automatic int t = 0;
				automatic int x = 0; 
				automatic int y = 0;
				automatic int expected = 0;
				
				for (int i = 0; i < (cfg_max_x+1)*(cfg_max_y+1)*(cfg_max_z+1); i++) begin
					//create current value
					x = t % (cfg_max_x+1);
					y = t / (cfg_max_x+1);
					//wait for output
					#(PERIOD/2);
					axis_output_ready = 1;
					wait (axis_output_valid == 1);
					@(posedge clk);
					
					//check current output
					expected = z*(cfg_max_x+1)*(cfg_max_y+1)+ y*(cfg_max_x+1) + x;
					if (axis_output_d != expected || (^axis_output_d === 1'bX)) begin
						$info("Displaying info");
						$display("Received value 0x%h and was expecting 0x%h", axis_output_d, expected);
					end
					
					//update value
					if (z == 0) begin
						if (t < cfg_max_z) begin
							z = t + 1;
							t = 0;
						end else begin
							z = cfg_max_z;
							t = t - cfg_max_z + 1;
						end
					end else if (t == cfg_max_t) begin
						if (z == cfg_max_z) begin
							axis_output_ready = 0;
							break; //we are finished
						end else begin
							t = t + z - cfg_max_z + 1;
							z = cfg_max_z;
						end 
					end else begin
						z = z - 1;
						t = t + 1;
					end
				end
			end : thread_empty
		join
		
		$stop;
	end
	
	sample_rearrange rearrange_instance (
		.clk(clk), .rst(rst),
		.finished(finished),
		.cfg_max_x(cfg_max_x),
		.cfg_max_y(cfg_max_y),
		.cfg_max_z(cfg_max_z),	
		.cfg_max_t(cfg_max_t),
		.cfg_min_preload_value(cfg_min_preload_value),
		.cfg_max_preload_value(cfg_max_preload_value),
		.axis_input_d(axis_input_d),
		.axis_input_ready(axis_input_ready),
		.axis_input_valid(axis_input_valid),
		.axis_output_d(axis_output_d),
		.axis_output_coord(axis_output_flags),
		.axis_output_last(axis_output_last),
		.axis_output_valid(axis_output_valid),
		.axis_output_ready(axis_output_ready)
	);
	
	
endmodule
