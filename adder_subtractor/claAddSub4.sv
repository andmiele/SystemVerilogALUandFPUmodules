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

// claAddSub4.sv
// 4-bit Carry Look-Ahead Adder-Subtractor

// 4-bit Carry Look-Ahead Adder (total of 4 * 8 + 16 = 48 gates)
// Subtraction logic ((4 + 1) * XORs + OR = 6  gates
// 4-bit Carry Look-Ahead Adder-Subtractor (total of 54 gates)

// x,y -> sum[4]: 4 gate-delays(claLogic4 for ci[3],fan-in higher than 2) + 5 gate-delays(cin -> sum in Reduced Full adder)
// + 2 gate-delays(g,p from Reduced Full Adder) + 2 gate-delays(xor) = 13 gate-delays

// x,y -> g, p: 4 gate-delays(claLogic4 for ci[3],fan-in higher than 2)
// + 2 gate-delays(g,p from Reduced Full Adder) + 2 gate-delays(xor) = 6 gate-delays

// x,y -> cout: 4 gate-delays(claLogic4, fan-in higher than 2) + 2 gate-delays(g,p from Reduced Full Adder) + 2 gate-delays(xor)= 8 gate-delays
// x,y -> v: 4 gate-delays(claLogic4, fan-in higher than 2) + 2 gate-delays(g,p from Reduced Full Adder) + 2 * 2 gate-delays(xor)= 10 gate-delays

// r-bit CLA Logic: r(r + 1) / 2 + r = (r^2 + r + 2r) / 2 = r(r + 3)/ 2 (+ 2 gates if cout is needed)
// In general an M-bit CLA adder with maximum fan-in r requires SUM for i = 1 to log_r{n} {n / r^i} CLA logic blocks
// n Reduced Full Adders for a total of 8n + r(r + 3)/ 2 * (SUM for i = 1 to log_r{n} {n / r^i})

// When used as basic building block for larger CLA Adders a basic CLA block has a 2 + 4 + 5 = 11 gate-delay for p,g generation, ci[] generation 
// and then out[] generation
// ceiling(log_r{n}) levels including basic CLA adder building block level
// Each level adds 4 gate-delays for upward pi[], gi[] generation and 4 gate-delays for "downward" ci[] generation
// So the total delay for an M-bit CLA Adder based on r-bit  (fan-in at most r) CLA blocks is:
// 11 + 8 * (ceiling(log_r{n}) - 1) gate-delays
 
// Reduced Full Adder (8 gates total)
// x,y -> g,p: 2 gate-delays
// x,y -> s:   10 gate-delays
// cin -> sum:  5 gate-delays



module fullAdderPG
(
    input logic cin,
    input logic x,
    input logic y,
    output logic sum,
    output logic g,
    output logic p
);
assign p = x ^ y;
assign g = x & y;
assign sum = p ^ cin;
endmodule

module claAddSub4
(
    input logic sub,
    input logic cin, // arithmetic carry ignored if sub is 1
    input logic [3 : 0] x,
    input logic [3 : 0] y,
    output logic [3 : 0] out,
    output logic cout,
    output logic g,
    output logic p,
    output logic v
);

logic [3 : 0] gi;
logic [3 : 0] pi;
logic [3 : 0] ci;
logic [3 : 0] yn;

assign ci[0] = sub | cin;
assign yn = y ^ {4{sub}};

genvar i;
generate
for(i = 0; i <= 3; i++)
begin: fullAdderGen
    fullAdderPG fa_i(
        .x(x[i]), .y(yn[i]),
        .cin(ci[i]), .sum(out[i]),
        .g(gi[i]), .p(pi[i])
    );
end
endgenerate
// CLA logic
claLogic4 cla4(.cin(ci[0]), .pi(pi), .gi(gi), 
    .ci(ci[3 : 1]), .g(g), .p(p), 
.cout(cout));
assign v = cout ^ ci[3];

endmodule
