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
// 4-bit carry-look-ahead adder-subtractor

module fullAdderPG
(
 input logic cin,
 input logic x,
 input logic y,
 output logic sum,
 output logic cout,
 output logic g,
 output logic p
 );
assign p = x ^ y;
assign g = x & y;
assign sum = p ^ cin;
assign cout = cin & p | g;
endmodule

module claAddSub4
(
 input logic sub,
 input logic cin,
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

logic icout;

assign ci[0] = cin ^ sub;
assign yn = y ^ {4{sub}};

genvar i;
generate
for(i = 0; i <= 3; i++)
        begin: fullAdderGen
        fullAdderPG fa_i(
                        .x(x[i]), .y(yn[i]),
                        .cin(ci[i]), .sum(out[i]),
                        .g(gi[i]), .p(pi[i]), .cout()
                        );
        end
        endgenerate
        // CLA logic
        claLogic4 cla4(.cin(ci[0]), .pi(pi), .gi(gi), 
                        .ci(ci[3 : 1]), .g(g), .p(p), 
                        .cout(icout));
assign cout = icout ^ sub;
assign v = icout ^ ci[3];

endmodule
