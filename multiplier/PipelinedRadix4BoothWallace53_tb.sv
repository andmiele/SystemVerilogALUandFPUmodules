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

// PipelinedRadix4BoothWallace53_tb.sv
// Testbench: PipelinedRadix4BoothWallace53

`timescale 1 ns / 10 ps

module PipelinedRadix4BoothWallace16_tb;
localparam M = 53;
localparam step = M <= 10 ? 1 : {(M - 8){1'b1}};
localparam I = {M{1'b1}};
localparam J = {M{1'b1}};
localparam period = 10; // clock period for testbench
logic [M - 1 : 0] x;
logic [M - 1 : 0] y;
logic signed [M - 1 : 0] xs;
logic signed [M - 1 : 0] ys;
logic [2 * M - 1 : 0] out;
logic [2 * M - 1 : 0] exp [0 : 3];
logic [2 * M - 1 : 0] e;
logic signed [2 * M - 1 : 0] exp_s[0 : 3];
logic signed [2 * M - 1 : 0] es;
logic clk;
logic run;
logic signedFlag = 1'b0; 
int unsigned stages = 4;
logic [M : 0] counter;

PipelinedRadix4BoothWallace53 UUT(.clk(clk), .run(run),.signedFlag(signedFlag), 
.multiplicand(x), .multiplier(y), .out(out));

logic passed;
logic[2 * M - 1 : 0] i, j;

assign es = xs * ys; //
assign e = x * y;

initial begin
    clk = 1'b0;
    passed = 1'b1;
    run = 1'b0;
    #period;
    for(i = 0; i <= I; i = i + step) 
    begin
        x = i;
        for(j = 0; j <= J; j = j + step)
        begin

            y = j;
            run = 1'b1;
            #(period);
            if(counter >= 4)
            begin
                if (out !== exp[counter % stages])
                begin
                    passed = 1'b0;
                    $display("UNSIGNED TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nout: %b\nexp: %b\n", i, j, x, y, out, exp[counter % stages]);
                end
            end
        end
    end
    signedFlag = 1'b1;
    run = 1'b0;
    #period;
    for(i = 0; i <= I; i = i + step) 
    begin
        x = i;
        xs = i;
        for(j = 0; j <= J; j = j + step)
        begin
            y = j;
            ys = j;
            run = 1'b1;
            #(period);
            if(counter >= 4)
            begin
                if (out !== exp_s[counter % stages])
                begin
                    passed = 1'b0;
                    $display("SIGNED TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nout: %b\nexp_s: %b\n", i, j, xs, ys, out, exp_s[counter % stages]);
                    $stop;
                end
            end
        end
    end
    signedFlag = 1'b0;
    x = 53'h1FFFFFFFFFFFFF;
    y = 53'h1FFFFFFFFFFFFF;
    run = 1'b0;
    #period;
    run = 1'b1;     
    #(4 * period);
    if (out !== exp[0])
    begin
        passed = 1'b0;
        $display("FINAL TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nout: %b\nexp: %b\n", i, j, x, y, out, exp[0]);
    end
    if (passed == 1'b1)
        $display("TEST PASSED!\n");
    else
        $display("TEST FAILED!\n");
    end

    always
        #(period / 2) clk = !clk;
    always_ff @(posedge clk)

    begin: fifo
        if(!run)
            counter <= 0;
        else
        begin
            counter <= counter + 1;
            exp[counter % stages] <= e;
            exp_s[counter % stages] <= es;
        end
    end
    endmodule
