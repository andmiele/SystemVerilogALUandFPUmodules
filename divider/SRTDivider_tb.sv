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

// SRTDivider_tb.sv
// testbench for generic integer SRT divider

`timescale 1 ns/ 10 ps

module SRTDivider_tb;
localparam N = 16;

localparam step = N <= 10 ? 1 : {(N - 3){1'b1}};
localparam I = {N{1'b1}};
localparam J = {N{1'b1}};
localparam period = 10ns; // clock period for testbench
logic signed [N - 1 : 0] xs;
logic signed [N - 1 : 0] ys;
logic unsigned [N - 1 : 0] x;
logic unsigned [N - 1 : 0] y;
logic unsigned [N : 0] xa;
logic unsigned [N : 0] ya;
logic [N - 1 : 0] q;
logic [N - 1 : 0] r;
logic signed [N - 1 : 0] exp_q;
logic signed [N - 1 : 0] exp_r;

logic signedInput;
logic passed;
logic divByZeroEx;
logic done;
logic start;
logic clk;
logic rst;


SRTDivider #(.N(N)) UUT(.rst(rst), .clk(clk), .start(start), 
.signedInput(signedInput), .x(x), .y(y), .q(q),
.r(r), .done(done), .divByZeroEx(divByZeroEx));

reg [2 * N : 0] i;
reg [2 * N : 0] j;

initial begin
        clk = 1'b0;
        passed = 1'b1;
        signedInput = 1'b0;
        for (integer unsigned i = 0; i <= I; i = i + step) 
        begin
                x = i;
                for (integer unsigned j = 0; j <= J; j = j + step)
                begin
                        y = j;
                        exp_q = x / y;
                        exp_r = x % y;
                        rst = 1'b1;
                        start = 1'b0;
                        #period;
                        rst = 1'b0;
                        start = 1'b1;
                        #period;
                        wait(done)
                          #period;
                        if (y == 0)     
                        begin
                        if(divByZeroEx != 1)
                        begin
                                passed = 1'b0;
                                $display("UDIV TEST FAILED, DIV BY ZERO EXCEPTION NOT RAISED [i :%d, j :%d]\n x: %b y :%b\nq: %b\nr: %b \ndivByZeroEx: %b\n", i, j, x, y, 
                                        q, r, divByZeroEx);
                        end
                        end               
                        else 
                        if ((q !== exp_q) || (r !== exp_r))
                        begin
                                passed = 1'b0;
                                $display("UDIV TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nq: %b \exp_q: %b\nr: %b \exp_r: %b\n", i, j, x, y, 
                                        q, exp_q, r, exp_r);
                                        $stop;
                        end
                end
        end
        signedInput = 1'b1;
        for (integer i = 0; i <= I; i = i + step) 
        begin
                x = i;
                for (integer j = 0; j <= J; j = j + step)
                begin
                        y = j;
			xs = $signed(x);
			ys = $signed(y);
                        xa = xs;
			ya = ys;
			if(xs < 0)
			   xa = -xs;
                        if(ys < 0)
			   ya = -ys;
                        exp_q = xa / ya;
                        exp_r = xa % ya;
                        
			if(xs < 0)
                        begin
				if(ys > 0)
				begin
					exp_q = -exp_q;
				end
			end
                        if(ys < 0)
                        begin
				if(xs > 0)
				begin
					exp_q = -exp_q;
				end
			end
             
                        rst = 1'b1;
                        start = 1'b0;
                        #period;
                        rst = 1'b0;
                        start = 1'b1;
                        #period;
                        wait(done)
                          #period;
                        if (y == 0)     
                        begin
                        if(divByZeroEx != 1)
                        begin
                                passed = 1'b0;
                                $display("SDIV TEST FAILED, DIV BY ZERO EXCEPTION NOT RAISED [i :%d, j :%d]\n x: %b y :%b\nq: %b\nr: %b \ndivByZeroEx: %b\n", i, j, x, y, 
                                        q, r, divByZeroEx);
                        end
                        end               
                        else 
                        if ((q !== exp_q) || (r !== exp_r))
                        begin
                                passed = 1'b0;
                                $display("SDIV TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nq: %b \exp_q: %b\nr: %b \exp_r: %b\n", i, j, x, y, 
                                        q, exp_q, r, exp_r);
                                        $stop;
                        end
                end
        end
        if (passed == 1'b1)
                $display("DIV TEST PASSED!\n");
        else
                $display("DIV TEST FAILED!\n"); 
        $stop;
end

end

always
   #(period / 2) clk = !clk;
endmodule
