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

// rippleCarryAddSubP.sv
// Ripple-Carry Adder-Subtractor with carry propagate output signals


// Full Adder (9 gates total)
// sum = x ^ y ^ cin; 
// cout = (x & y) | (x & cin) | (y & cin)
// Can be implemented with two HAs and one OR gate:
// x,y -> sum: 10 gate-delays
// x,y -> cout: 9 gate-delays
// cin -> sum:  5 gate-delays
// cin -> cout: 4 gate-delays

module fullAdder
(
    input logic x,
    input logic y,
    input logic cin,
    output logic sum,
    output logic cout,
    output logic p
);
assign sum = x ^ y ^ cin;
assign cout = (x & y) | (x & cin) | (y & cin);
assign p = x & y;
endmodule

module rippleCarryAddSubP
#(parameter M)
(
    input logic sub,
    input logic cin,
    input logic [M - 1 : 0] x,
    input logic [M - 1 : 0] y,
    output logic [M - 1 : 0] out,
    output logic [M - 1 : 0] p,
    output logic cout,
    output logic v
);

logic [M - 1 : 0] yn;
logic [M : 0] ci;

assign yn = y ^ {M{sub}};
assign ci[0] = sub | cin;

genvar i;
generate
for(i = 0; i < M; i = i + 1)
begin: faRippleGen
    fullAdder fa_i(.x(x[i]), .y(yn[i]), .cin(ci[i]), .sum(out[i]), .cout(ci[i + 1]), .p(p[i]));
end
endgenerate

assign cout = ci[M];
assign v = ci[M] ^ ci[M - 1]; // signed overflow

endmodule
