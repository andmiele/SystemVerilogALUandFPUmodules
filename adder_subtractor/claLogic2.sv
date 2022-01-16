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

// claLogic2.sv
// 2-bit Carry Look-Ahead logic
// r-bit CLA Logic: r(r + 1) / 2 + r = (r^2 + r + 2r) / 2 = r(r + 3)/ 2 (+ 2 gates if cout is needed)

module claLogic2
(
    input logic cin,
    input logic [1 : 0] gi,
    input logic [1 : 0] pi,
    output logic c1,
    output logic g,
    output logic p,
    output logic cout
);

assign c1 = (cin & pi[0]) | gi[0]; // 2 gates

assign p = pi[0] & pi[1]; // 1 gate
assign g = (gi[0] & pi[1]) | // 2 gates
gi[1];
assign cout = (cin & p) | g; // 2 gates
endmodule
