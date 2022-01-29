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

// carrySelectAddSub.sv
// Carry-Select Adder-Subtractor

// Each Full Adder for the ripple carry adder blocks requires 9 gates
// A 2-to-1 multiplexer can be implemented with 4 gates: out = (s & x1) | ((~s) & x2) and has a 5-gate delay

// An M-bit Carry-Select Adder with R-bit Ripple Carry Adder blocks requires 2M - R Full Adders,
// ceiling(M / R) - 1 Carry-Select logic blocks that each amount to 2 gates and M - R 2-to-1 multiplexers each requiring 4 gates 
// for a total of 22M - 13R + 2*ceiling(M / R) - 2

// The delay is given by x[],y[] -> cout for the first block + ceiling(M / R) - 2 2 gate-delays for the Carry-Select logic blocks +
// the delay for the last multiplexer = 9 + 4(R - 1) + 4*(ceiling(M / R) - 2) + 5 = 4R + 4*ceiling(M / R) + 2

// Taking the derivative of the delay function with respect to R and setting it equal to zero we can derive
// the value of R that result in the optimal delay: r = sqrt(M)
// Plugging that into the delay function gives the optimal delay: 8*sqrt(M) + 2
// For example, if M = 16, we get R = 4 and a delay equal to 34 gate-delays
// Similar to Carry-Skip Adders the delay can be further reduce by using Ripple Carry blocks of variable size: smaller at the beginning and at the end
// and larger in the middle
// For example, if M = 16 with the following sizes: (2, 2, 3, 4, 5) requires 322 gates instead of 306 and has a delay of 30 gate-delays instead of 34

// This adder is useful in situations in which the carry-in arrives later than the operands, e.g., when the exponents of two floating-point numbers
// are added and then the carry-in is ready after normalization
// Compared to Carry-Skip and Carry-Look-Ahead adders it is the most expensive in terms of gates (Carry-Skip adders are the cheapest)

module carrySelectAddSub
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
logic [M / R - 1 : 0] coi;
logic [M / R - 1 : 0] coi_cin;
logic [M / R - 1 : 0] coi_nocin;
logic [M - 1 : 0] outi_cin;
logic [M - 1 : 0] outi_nocin;
logic [M / R - 1 : 0] vi; // only last one is used
logic [M / R - 1 : 0] vi_cin; // only last one is used
logic [M / R - 1 : 0] vi_nocin; // only last one is used

assign yn = y ^ {(M){sub}};

// first block
rippleCarryAddSubP #(.M(R)) rca_0(.sub(1'b0), .cin(sub | cin), .x(x[R - 1 : 0]), .y(yn[R - 1 : 0]),
.out(out[R - 1 : 0]), .p(), .cout(coi[0]), .v());

genvar i;
generate
for(i = R; i < M; i = i + R)
begin: rcaGen
    rippleCarryAddSubP   #(.M(R)) rca_i_nocin(.sub(1'b0), .cin(1'b0), .x(x[i + R - 1 : i]), .y(yn[i + R - 1 : i]),
    .out(outi_nocin[i + R - 1 : i]), .p(), .cout(coi_nocin[i / R]), .v(vi_nocin[i / R]));
    rippleCarryAddSubP   #(.M(R)) rca_i_cin(.sub(1'b0), .cin(1'b1), .x(x[i + R - 1 : i]), .y(yn[i + R - 1 : i]),
    .out(outi_cin[i + R - 1 : i]), .p(), .cout(coi_cin[i / R]), .v(vi_cin[i / R]));
    // Carry-Select logic
    assign out[i + R - 1 : i] = coi[i / R - 1] ? outi_cin[i + R - 1 : i] : outi_nocin[i + R - 1 : i];
    assign coi[i / R] = coi[i / R - 1] ? coi_cin[i / R] : coi_nocin[i / R];
    assign vi[i / R] = coi[i / R - 1] ? vi_cin[i / R] : vi_nocin[i / R];
end
endgenerate

assign cout = coi[M / R - 1];
assign v = vi[M / R - 1];

endmodule
