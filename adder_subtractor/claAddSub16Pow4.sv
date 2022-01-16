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

// claAddSub16Pow4.sv
// 16-bit, 64-bit or higher power of 4 Carry Look-Ahead Adder-Subtractor based on 4-bit Carry Look-Ahead Adder-Subtractor

// Ripple-Carry adder using FAs:
// x[0], y[0] -> out[M - 1]: (x[0],y[0] -> cout_0) + ((M - 2) * (cin -> cout)) + (cin -> sum) =
// 9 gate-delays + (M - 2) * (4 gate-delays) + (5 gate-delays) = 4M + 6 gate-delays

// x[0], y[0] -> cout: (x[0],y[0] -> cout_0) + ((M - 2) * (cin -> cout)) + (cin -> cout) =
// 9 gate-delays + (M - 2) * (4 gate-delays) + (4 gate-delays) = 4M + 5 gate-delays

// Ripple-Carry adder become 2-complement adder/subtractor with addition of a subtract signal s, XOR gates (assume 2-gate delays) to complement
// each bit of y (y[i] ^ s) and feeding s into cin of first FA 

// 16-bit CLA adder from 4 4-bit CLA adders: 46 * 4 + 14 = 198 gates
// x[0]y[0] -> out[7], out[11], out[15] : 2 gate-delays (p,g) + 4 gate-delays (claLogic4) + 4 gate-delays (claLogic4) + 5 gate-delays (cin -> sum in Full adder) =
// 19 gate-delays

// r-bit CLA Logic: r(r + 1) / 2 + r = (r^2 + r + 2r) / 2 = r(r + 3)/ 2 (+ 2 gates if cout is needed)
// In general an M-bit CLA adder with maximum fan-in r requires SUM for i = 1 to log_r{n} {n / r^i} CLA logic blocks
// n Reduced Full Adders for a total of 8n + r(r + 3)/ 2 * (SUM for i = 1 to log_r{n} {n / r^i})

// When used as basic building block for larger CLA Adders a basic CLA block has a 2 + 4 + 5 = 11 gate-delay for p,g generation, ci[] generation 
// and then out[] generation
// ceiling(log_r{n}) levels including basic CLA adder building block level
// Each level adds 4 gate-delays for upward pi[], gi[] generation and 4 gate-delays for "downward" ci[] generation
// So the total delay for an M-bit CLA Adder based on r-bit  (fan-in at most r) CLA blocks is:
// 11 + 8 * (ceiling(log_r{n}) - 1) gate-delays

module claAddSub16Pow4
#(parameter M) // can be 
(
 input logic sub,
 input logic cin, // arithmetic carry ignored if sub is 1
 input logic [M -1 : 0] x,
 input logic [M - 1 : 0] y,
 output logic [M - 1 : 0] out,
 output logic cout,
 output logic v,
 output logic g,
 output logic p
 );

logic [4 : 0] ci;
logic [4 : 0] gi;
logic [4 : 0] pi;
logic [4 : 0] vi;

logic [M - 1 : 0] yn;

assign ci[0] = sub | cin;
assign yn = y ^ {M{sub}};

localparam M4 = M / 4;
genvar i;
generate
for(i = 0; i < 4; i = i + 1)
begin: claFor
    if(M == 16)
    begin: M_eq_16
        claAddSub4 a4(
                        .sub(1'b0), .cin(ci[i]),
                        .x(x[M4 * i + M4 - 1 : M4 * i]),
                        .y(yn[M4 * i + M4 - 1 : M4 * i]), 
                        .out(out[M4 * i + M4 - 1 : M4 * i]),
                        .cout(),
                        .v(vi[i]),
                        .g(gi[i]),
                        .p(pi[i])
                     );
    end
    else
    begin: claAdders
        claAddSubGen #(.M(M4)) aM(
                        .sub(1'b0), .cin(ci[i]),
                        .x(x[M4 * i + M4 - 1 : M4 * i]),
                        .y(yn[M4 * i + M4 - 1 : M4 * i]), 
                        .out(out[M4 * i + M4 - 1 : M4 * i]),
                        .cout(),
                        .v(vi[i]),
                        .g(gi[i]),
                        .p(pi[i])
                        );  
    end
end
endgenerate

claLogic4 cla(.cin(ci[0]), .gi(gi), 
.pi(pi), .ci(ci[3:1]), .g(g),
.p(p), .cout(cout));

assign v = vi[3];

endmodule
