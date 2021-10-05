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

// claAddSub24.sv
// 24-bit adder-subtractor based 4-bit carry-look-ahead adder

module claAddSub24
#(parameter M = 24)
(
 input logic sub,
 input logic cin,
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

logic [M - 1 : 0] yn;

logic icout;

assign ci[0] = cin ^ sub;
assign yn = y ^ {M{sub}};

localparam M1 = 16;
genvar i;
generate
for(i = 0; i <= 0; i = i + 1)
begin: claFor
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
claAddSubGen #(.M(8)) a8(
                .sub(1'b0), .cin(ci[1]),
                .x(x[M1 * 1 + 8 - 1 : M1 * 1]),
                .y(yn[M1 * 1 + 8 - 1 : M1 * 1]), 
                .out(out[M1 * 1 + 8 - 1 : M1 * 1]),
                .cout(),
                .v(v),
                .g(gi[1]),
                .p(pi[1])
                ); 


claLogic2 cla(.cin(ci[0]), .gi(gi), 
                .pi(pi), .c1(ci[1]), .g(g),
                .p(p), .cout(icout));

assign cout = icout ^ sub;

endmodule
