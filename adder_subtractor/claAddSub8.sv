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

// claAddSub8.sv
// 8-bit Carry Look-Ahead Adder-Subtractor
// based on Carry Look-Ahead Adder-Subtractor: 52 + 52 (4-bit CLA: first v not needed, second sub OR CIN not needed)
// + 7 (claLogic2) = 111
// x,y -> out[7] = 2 + 4 + 4 + 4 + 5 = 19 gate-delays

module claAddSub8
(
    input logic sub,
    input logic cin, // arithmetic carry ignored if sub is 1
    input logic [7 : 0] x,
    input logic [7 : 0] y,
    output logic [7 : 0] out,
    output logic cout,
    output logic g,
    output logic p,
    output logic v
);

logic [1 : 0] gi;
logic [1 : 0] pi;
logic [1 : 0] ci;
logic [7 : 0] yn;

assign ci[0] = sub | cin;
assign yn = y ^ {8{sub}};

claAddSub4 cla0(.sub(1'b0), .cin(ci[0]), .x(x[3 : 0]), .y(yn[3 : 0]), .out(out[3 : 0]), .cout(), .g(gi[0]), .p(pi[0]), .v());
claAddSub4 cla1(.sub(1'b0), .cin(ci[1]), .x(x[7 : 4]), .y(yn[7 : 4]), .out(out[7 : 4]), .cout(), .g(gi[1]), .p(pi[1]), .v(v));

// CLA logic
claLogic2 cla2(.cin(ci[0]), .pi(pi), .gi(gi), 
.c1(ci[1 : 1]), .g(g), .p(p), .cout(cout));

endmodule
