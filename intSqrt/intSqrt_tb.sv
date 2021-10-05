//-----------------------------------------------------------------------------
// Copyright 2021 Andrea Miele
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------------------

// intSqrt_tb.sv
// testbench for generic integer square root module

`timescale 1 ns/ 10 ps

module intSqrt_tb;
localparam N = 5;

// input and output signals for DUT
logic clk, rst, start, done;
logic [N - 1 : 0] in, out, out_tv;

localparam period = 10; // clock period for testbench
localparam n_tv = 31; // number of test vectors

intSqrt #(.N(N)) UUT(.clk(clk), .rst(rst), .start(start), .done(done), .in(in), .out(out));

// test vectors 
logic[2 * N - 1 : 0] tv[0 : n_tv - 1];
integer i;

initial
begin
	clk = 0;
	// read test vectors from file
	$readmemb("intSqrt_tv.txt", tv);

	for (i = 0; i < n_tv; i++)
	begin
		rst = 1'b1;
		start = 1'b0;
		{in, out_tv} = tv[i];
		#period;
		rst = 1'b0;
		start = 1'b1;
		wait(done);
		if(out_tv != out)
		begin  
		$display("test failed for input test vector: %d\n", i);
		break;
end
#period;
    end
    if(i == n_tv)  
	    $display("Integer Square Root TEST PASSED!\n");
    $stop;
end
always
	#(period / 2) clk = !clk;
endmodule
