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

// claAddSub106.sv
// 106-bit Adder-Subtractor based on 4-bit Carry Look-Ahead Adder-Subtractor

module claAddSub106
#(parameter M = 106)
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

logic [1 : 0] ci;
logic [1 : 0] gi;
logic [1 : 0] pi;
logic [1 : 0] vi;

logic [M - 1 : 0] yn;

logic icout;

assign ci[0] = sub | cin;
assign yn = y ^ {M{sub}};

localparam M2 = M / 2;
genvar i;
generate
for(i = 0; i <= 1; i = i + 1)
begin: cla53Adders
    claAddSub53 a53(
        .sub(1'b0), .cin(ci[i]),
        .x(x[M2 * i + M2 - 1 : M2 * i]),
        .y(yn[M2 * i + M2 - 1 : M2 * i]), 
        .out(out[M2 * i + M2 - 1 : M2 * i]),
        .cout(),
        .v(vi[i]),
        .g(gi[i]),
        .p(pi[i])
    );  
end
endgenerate
claLogic2 cla(.cin(ci[0]), .gi(gi), 
    .pi(pi), .c1(ci[1]), .g(g),
.p(p), .cout(icout));

assign cout = icout ^ sub;
assign v = vi[1];

endmodule
