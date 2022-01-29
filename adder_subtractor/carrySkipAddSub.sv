//-----------------------------------------------------------------------------
// Copyright 2022 Andrea Miele
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

// carrySkipAddSub.sv
// Carry-Skip Adder-Subtractor

// Each Full Adder for the ripple carry adder blocks requires 9 gates
// There are ceiling(M/R) - 2 Carry-Skip logic blocks each requiring 2 gates
// In total there are (ceiling(M / R) - 2) * 2 + 9  * M gates

// The critical path is the longest "propagate" path, namely the path going from the input signal cin
// of the Carry-Skip Adder to the output signal cout that goes through:
// first RCA -> M / R - 2 carry-skip logic blocks -> last RCA: 9 + 4(R - 1) gate-delays (first x,y -> cout and then R - 1 cin -> cout) +
// + (ceiling(M / R) - 2) * 2 gate-delays (Carry Skip Logic) + 4(R - 1) + 5 (R - 1 cin -> cout, then cin -> out[R - 1]) =
// = 8R + 6 + (ceiling(M / R) - 2) * 2
// Taking the derivative, setting it equal to 0 and solving for R:
// - 2M/R^2 + 8 = 0 -> R = sqrt(M / 4) (optimal value)
// we get the optimal value of R that gives the following optimal delay: 4 * sqrt(4M) + 6
// For example, if M = 32 we have R ~= 3

// A Carry-Skip Adder can be made faster by using Ripple Carry Adder blocks of different sizes, normally smaller blocks at the beginning and
// at the end and larger blocks in the middle (for instance, for M=16 using Ripple Carry Adder blocks of sizes 1, 2, 3, 4, 3, 2, 1 requires 154 gates instead of 148 and 
// result in a worst-case delay of 34 gate-delays instead of 38 gate-delays when the block sizes are all equal to 4).
// Faster adder blocks can also be used (e.g., CLA) as well as multiple levels of Carry-Skip logic.
 
module carrySkipLogic
#(parameter R = 4)
(
    input logic cin,
    input logic [R - 1 : 0] p,
    input logic cCurrBlock,
    output logic cout
);
logic ci;
always_comb
begin: csl_and
    ci = cin;
    for(int i = 0; i < R; i++)
        ci = ci & p[i];
end
assign cout = ci | cCurrBlock;
endmodule

module carrySkipAddSub
#(parameter M = 32, parameter R = 4) // M must be divisible by R and larger than R
(
    input logic sub,
    input logic cin, // arithmetic carry ignored if sub is 1
    input logic [M - 1 : 0] x,
    input logic [M - 1 : 0] y,
    output logic [M - 1 : 0] out,
    output logic cout,
    output logic v
);

logic [M - 1 : 0] yn;
logic [M - 1 : 0] p;
logic [M / R - 1 : 0] coi;
logic [M / R - 1 : 0] ciskip;
logic [M / R - 1 : 0] vi; // only last one is used

assign ciskip[0] = sub | cin;
assign ciskip[1] = coi[0];

assign yn = y ^ {(M){sub}};

genvar i;
generate
for(i = 0; i < M; i = i + R)
begin: rcaGen
    rippleCarryAddSubP   #(.M(R)) rca_i(.sub(1'b0), .cin(ciskip[i / R]), .x(x[i + R - 1 : i]), .y(yn[i + R - 1 : i]),
    .out(out[i + R - 1 : i]), .p(p[i + R - 1 : i]), .cout(coi[i / R]), .v(vi[i / R]));
    if(i > 0 && i < M - R)
        carrySkipLogic   #(.R(R)) csl_i(.cin(ciskip[i / R]), .p(p[i + R - 1 : i]), .cCurrBlock(coi[i / R]), .cout(ciskip[i / R + 1]));  										

end
endgenerate

assign cout = coi[M / R - 1];
assign v = vi[M / R - 1];

endmodule
