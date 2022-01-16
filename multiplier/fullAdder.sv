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

// fullAdder.sv

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
    output logic cout
);

assign sum = x ^ y ^ cin;
assign cout = (x & y) | (x & cin) | (y & cin);

endmodule
