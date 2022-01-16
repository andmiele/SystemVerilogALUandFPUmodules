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

// claAddSub53.sv
// 53-bit Adder-Subtractor based on 4-bit Carry Look-Ahead Adder-Subtractor

module claAddSub53
#(parameter M = 53)
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
logic [3 : 0] gi;
logic [3 : 0] pi;
logic gl;
logic pl;
logic gfa;
logic pfa;

logic [M - 1 : 0] yn;

logic icout;

assign ci[0] = sub | cin;
assign yn = y ^ {M{sub}};

localparam M1 = 16;
genvar i;
generate
for(i = 0; i <= 2; i = i + 1)
begin: claGen
    claAddSubGen #(.M(16)) aM1(
        .sub(1'b0), .cin(ci[i]),
        .x(x[M1 * i + M1 - 1 : M1 * i]),
        .y(yn[M1 * i + M1 - 1 : M1 * i]), 
        .out(out[M1 * i + M1 - 1 : M1 * i]),
        .cout(),
        .v(),
        .g(gi[i]),
        .p(pi[i])
    );  
end
endgenerate
claAddSub4 a4(
    .sub(1'b0), .cin(ci[3]),
    .x(x[M1 * 3 + 4 - 1 : M1 * 3]),
    .y(yn[M1 * 3 + 4 - 1 : M1 * 3]), 
    .out(out[M1 * 3 + 4 - 1 : M1 * 3]),
    .cout(),
    .v(),
    .g(gi[3]),
    .p(pi[3])
); 

claLogic4 cla(.cin(ci[0]), .gi(gi), 
    .pi(pi), .ci(ci[3 : 1]), .g(gl),
.p(pl), .cout(ci[4]));

fullAdderPG final_fa(.x(x[52]), .y(yn[52]), .cin(ci[4]), 
.sum(out[52]), .cout(icout), .g(gfa), .p(pfa));

assign g = (gl & pfa) | gfa;
assign p = pl * pfa;

assign cout = icout ^ sub;
assign v = ci[4] ^ icout;

endmodule
