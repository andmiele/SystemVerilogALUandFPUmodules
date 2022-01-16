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

// claLogic4.sv
// 4-bit Carry Look-Ahead Logic (total of 16 gates, several with fan-in higher than 2)
// cin -> cout: 4 gate-delays (but with "higher than 2" fan-in requirements)
// r-bit CLA Logic: r(r + 1) / 2 + r = (r^2 + r + 2r) / 2 = r(r + 3)/ 2 (+ 2 gates if cout is needed)

module claLogic4
(
    input logic cin,
    input logic [3 : 0] gi,
    input logic [3 : 0] pi,
    output logic [3 : 1] ci,
    output logic g,
    output logic p,
    output logic cout
);

assign ci[1] = (cin & pi[0]) | gi[0]; // 2 gates
assign ci[2] = (cin & pi[0] & pi[1]) |  // 3 gates
(gi[0] & pi[1]) | gi[1];
assign ci[3] = (cin & pi[0] & pi[1] & pi[2]) | // 4 gates
(gi[0] & pi[1] & pi[2]) |
(gi[1] & pi[2]) | gi[2];

assign p = pi[0] & pi[1] & pi[2] & pi[3]; // 1 gate
assign g = (gi[0] & pi[1] & pi[2] & pi[3]) | // 4 gates
(gi[1] & pi[2] & pi[3]) |
(gi[2] & pi[3]) | 
gi[3];
assign cout = (cin & p) | g; // 2 gates
endmodule
