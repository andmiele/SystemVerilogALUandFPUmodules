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

// compressor_42.sv
// 4-to-2 bits compressor for Wallace tree multiplier
// x1 + x2 + x3 + x4 + cin = sum + 2(carry + cout)

module compressor_42
(
    input logic x1,
    input logic x2,
    input logic x3,
    input logic x4,
    input logic cin,
    output logic sum, // sum
    output logic carry, // vertical carry
    output logic cout // lateral carry
);

logic xor12;
logic xor34;
logic xor1234;

assign xor12 = x1 ^ x2;
assign xor34 = x3 ^ x4;
assign xor1234 = xor12 ^ xor34;

//cout: high if x1 + x2 + x3 generates carry
// cout MUX
assign cout = (xor12) ? x3 : x1;    

// carry: high if sum(x1, x2, x3) + x4 + cin generates carry
// carry MUX
assign carry = (xor1234) ? cin : x4;

//sum
assign sum = xor1234 ^ cin;

endmodule
