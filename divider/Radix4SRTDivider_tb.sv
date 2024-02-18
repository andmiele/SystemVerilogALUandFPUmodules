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

// Radix4SRTdivider_tb.sv
// testbench for generic integer radix-4 SRT divider

`timescale 1 ns/ 10 ps

module Radix4SRTdivider_tb;

localparam N = 32;
localparam step = N <= 10 ? 1 : {(N - 8){1'b1}};
localparam I = {N{1'b1}};
localparam J = {N{1'b1}};
localparam period = 10ns; // clock period for testbench

logic signed [N - 1 : 0] xs;
logic signed [N - 1 : 0] ys;
logic unsigned [N - 1 : 0] x;
logic unsigned [N - 1 : 0] y;
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


Radix4SRTdivider #(.N(N)) UUT(.rst(rst), .clk(clk), .start(start), 
    .signedInput(signedInput), .x(x), .y(y), .q(q),
.r(r), .done(done), .divByZeroEx(divByZeroEx));

reg [2 * N : 0] i;
reg [2 * N : 0] j;


initial 
begin
    clk = 1'b0;
    passed = 1'b1;
    signedInput = 1'b0;
    for (i = 0; i <= I; i = i + step) 
    begin
        x = i;
        for (j = 0; j <= J; j = j + step)
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
                $display("UDIV TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nq: %b \exp_q: %b\nr: %b \exp_r: %b\n", x, y, x, y, 
                q, exp_q, r, exp_r);
                $stop;
            end
        end
    end
    signedInput = 1'b1;
    for (i = 0; i <= I; i = i + step) 
    begin
        xs = i;
        for(j = 0; j <= J; j = j + step)
        begin
            ys = j;
            exp_q = x / y;
            exp_r = x % y;
            if(exp_r[N - 1] && !ys[N - 1])
            begin
                exp_r = exp_r + ys;
                exp_q = exp_q - 1;
            end
            if(exp_r[N - 1] && ys[N - 1])
            begin
                exp_r = exp_r - ys;
                exp_q = exp_q + 1;
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
            begin
                if ((q !== exp_q) || (r !== exp_r))
                begin
                    passed = 1'b0;
                    $display("SDIV TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nq: %b \exp_q: %b\nr: %b \exp_r: %b\n", i, j, xs, ys, 
                    q, exp_q, r, exp_r);
                    $stop;
                end
            end        
        end
    end
    if (passed == 1'b1)
        $display("DIV TEST PASSED!\n");
    else
        $display("DIV TEST FAILED!\n"); 
    $stop;
end      

always
begin
    #(period / 2) clk = !clk;
end        

endmodule
