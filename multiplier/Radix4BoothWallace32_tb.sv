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

// Radix4BoothWallace32_tb.sv
// Testbench: Radix4BoothWallace32

`timescale 1 ns / 10 ps

module Radix4BoothWallace32_tb;
localparam M = 32;
localparam step = M <= 10 ? 1 : {(M - 6){1'b1}};
localparam I = {M{1'b1}};
localparam J = {M{1'b1}};
localparam period = 5; // clock period for testbench
logic [M - 1 : 0] x;
logic [M - 1 : 0] y;
logic signed [M - 1 : 0] xs;
logic signed [M - 1 : 0] ys;
logic [2 * M - 1 : 0] out;
logic [2 * M - 1 : 0] exp;
logic signed [2 * M - 1 : 0] exp_s;

logic signedFlag = 1'b0; 

Radix4BoothWallace32 UUT(.signedFlag(signedFlag), 
.multiplicand(x), .multiplier(y), .out(out));

logic passed;
logic[2 * M - 1 : 0] i, j;

assign exp = x * y;
assign exp_s = xs * ys;

initial begin
    passed = 1'b1;
    for(i = 0; i <= I; i = i + step) 
    begin
        x = i;
        for(j = 0; j <= J; j = j + step)
        begin
            y = j;
            #period;
            if (out !== exp)
            begin
                passed = 1'b0;
                $display("TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nout: %b\nexp: %b\n", i, j, x, y, out, exp);
            end
        end
    end
    signedFlag = 1'b1;
    for(i = 0; i <= I; i = i + step) 
    begin
        x = i;
        xs = i;
        for(j = 0; j <= J; j = j + step)
        begin
            y = j;
            ys = j;
            #period;
            if (out !== exp_s)
            begin
                passed = 1'b0;
                $display("SIGNED TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nout: %b\nexp_s: %b\n", i, j, xs, ys, out, exp_s);
                $stop;
            end
        end
    end
    signedFlag = 1'b0;
    x = 32'hFFFFFFFF;
    y = 32'hFFFFFFFF;
    #period;
    if (out !== exp)
    begin
        passed = 1'b0;
        $display("TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nout: %b\nexp: %b\n", i, j, x, y, out, exp);
    end
    if (passed == 1'b1)
        $display("TEST PASSED!\n");
    else
        $display("TEST FAILED!\n");
    end
    endmodule
