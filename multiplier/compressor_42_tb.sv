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

// compressor_42_tb.sv
// Testbench: 4-to-2 bits compressor for Wallace tree multiplier

`timescale 1 ns/ 10 ps

module compressor_42_tb;

// input and output signals for DUT
logic x1, x2, x3, x4, cin, sum, carry, cout;
// input and output signals for Test Vectors
logic x1_tv, x2_tv, x3_tv, x4_tv, cin_tv, sum_tv, carry_tv, cout_tv;

localparam period = 10; // clock period for testbench
localparam n_tv = 32; // number of test vectors
localparam width_tv = 8; // width of test vectors
compressor_42 UUT(.x1(x1), .x2(x2), .x3(x3), .x4(x4), .cin(cin), .sum(sum), .carry(carry), .cout(cout));
// test vectors 
logic[width_tv - 1 : 0] tv[0 : n_tv - 1];
integer i;

initial
begin
    // read test vectors from file
    $readmemb("compressor_42_tv.txt", tv);

    for (i = 0; i < n_tv; i++)
    begin
        {x1, x2, x3, x4, cin, sum_tv, carry_tv, cout_tv} = tv[i];
        if(sum != sum_tv || cout != cout_tv || carry != carry_tv)
        begin  
            $display("test failed for input test vector: %d\n", i);
            break;
        end
        #period;
    end
    if(i == n_tv)  
        $display("4_2 compressor TEST PASSED!\n");
end

endmodule
