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

// qSelPLA.sv
// PLA for Radix-4 SRT quotient selection 
// -2/3y <= r <= 2/3 y
// follows table in H&P 5th edition, appendix J, page 57

module qSelPLA
(
    input logic [5 : 0] r6,
    input logic [3 : 0] y4,
    output logic [2 : 0] q2s // sign and magnitude quotient digit [-2, 2]
);

always_comb
begin

    case ({y4, r6})
        // 8 -12: -2
        {4'h8, 6'h34}: q2s = 3'b110;
        // 8 -11: -2
        {4'h8, 6'h35}: q2s = 3'b110;
        // 8 -10: -2
        {4'h8, 6'h36}: q2s = 3'b110;
        // 8 -9: -2
        {4'h8, 6'h37}: q2s = 3'b110;
        // 8 -8: -2
        {4'h8, 6'h38}: q2s = 3'b110;
        // 8 -7: -2
        {4'h8, 6'h39}: q2s = 3'b110;
        // 8 -6: -1
        {4'h8, 6'h3a}: q2s = 3'b101;
        // 8 -5: -1
        {4'h8, 6'h3b}: q2s = 3'b101;
        // 8 -4: -1
        {4'h8, 6'h3c}: q2s = 3'b101;
        // 8 -3: -1
        {4'h8, 6'h3d}: q2s = 3'b101;
        // 8 -2: 0
        {4'h8, 6'h3e}: q2s = 3'b000;
        // 8 -1: 0
        {4'h8, 6'h3f}: q2s = 3'b000;
        // 8 0: 0
        {4'h8, 6'h0}: q2s = 3'b000;
        // 8 1: 0
        {4'h8, 6'h1}: q2s = 3'b000;
        // 8 2: 1
        {4'h8, 6'h2}: q2s = 3'b001;
        // 8 3: 1
        {4'h8, 6'h3}: q2s = 3'b001;
        // 8 4: 1
        {4'h8, 6'h4}: q2s = 3'b001;
        // 8 5: 1
        {4'h8, 6'h5}: q2s = 3'b001;
        // 8 6: 2
        {4'h8, 6'h6}: q2s = 3'b010;
        // 8 7: 2
        {4'h8, 6'h7}: q2s = 3'b010;
        // 8 8: 2
        {4'h8, 6'h8}: q2s = 3'b010;
        // 8 9: 2
        {4'h8, 6'h9}: q2s = 3'b010;
        // 8 10: 2
        {4'h8, 6'ha}: q2s = 3'b010;
        // 8 11: 2
        {4'h8, 6'hb}: q2s = 3'b010;
        // 9 -14: -2
        {4'h9, 6'h32}: q2s = 3'b110;
        // 9 -13: -2
        {4'h9, 6'h33}: q2s = 3'b110;
        // 9 -12: -2
        {4'h9, 6'h34}: q2s = 3'b110;
        // 9 -11: -2
        {4'h9, 6'h35}: q2s = 3'b110;
        // 9 -10: -2
        {4'h9, 6'h36}: q2s = 3'b110;
        // 9 -9: -2
        {4'h9, 6'h37}: q2s = 3'b110;
        // 9 -8: -2
        {4'h9, 6'h38}: q2s = 3'b110;
        // 9 -7: -1
        {4'h9, 6'h39}: q2s = 3'b101;
        // 9 -6: -1
        {4'h9, 6'h3a}: q2s = 3'b101;
        // 9 -5: -1
        {4'h9, 6'h3b}: q2s = 3'b101;
        // 9 -4: -1
        {4'h9, 6'h3c}: q2s = 3'b101;
        // 9 -3: -1
        {4'h9, 6'h3d}: q2s = 3'b101;
        // 9 -2: 0
        {4'h9, 6'h3e}: q2s = 3'b000;
        // 9 -1: 0
        {4'h9, 6'h3f}: q2s = 3'b000;
        // 9 0: 0
        {4'h9, 6'h0}: q2s = 3'b000;
        // 9 1: 0
        {4'h9, 6'h1}: q2s = 3'b000;
        // 9 2: 0
        {4'h9, 6'h2}: q2s = 3'b000;
        // 9 3: 1
        {4'h9, 6'h3}: q2s = 3'b001;
        // 9 4: 1
        {4'h9, 6'h4}: q2s = 3'b001;
        // 9 5: 1
        {4'h9, 6'h5}: q2s = 3'b001;
        // 9 6: 1
        {4'h9, 6'h6}: q2s = 3'b001;
        // 9 7: 2
        {4'h9, 6'h7}: q2s = 3'b010;
        // 9 8: 2
        {4'h9, 6'h8}: q2s = 3'b010;
        // 9 9: 2
        {4'h9, 6'h9}: q2s = 3'b010;
        // 9 10: 2
        {4'h9, 6'ha}: q2s = 3'b010;
        // 9 11: 2
        {4'h9, 6'hb}: q2s = 3'b010;
        // 9 12: 2
        {4'h9, 6'hc}: q2s = 3'b010;
        // 9 13: 2
        {4'h9, 6'hd}: q2s = 3'b010;
        // 10 -15: -2
        {4'ha, 6'h31}: q2s = 3'b110;
        // 10 -14: -2
        {4'ha, 6'h32}: q2s = 3'b110;
        // 10 -13: -2
        {4'ha, 6'h33}: q2s = 3'b110;
        // 10 -12: -2
        {4'ha, 6'h34}: q2s = 3'b110;
        // 10 -11: -2
        {4'ha, 6'h35}: q2s = 3'b110;
        // 10 -10: -2
        {4'ha, 6'h36}: q2s = 3'b110;
        // 10 -9: -2
        {4'ha, 6'h37}: q2s = 3'b110;
        // 10 -8: -1
        {4'ha, 6'h38}: q2s = 3'b101;
        // 10 -7: -1
        {4'ha, 6'h39}: q2s = 3'b101;
        // 10 -6: -1
        {4'ha, 6'h3a}: q2s = 3'b101;
        // 10 -5: -1
        {4'ha, 6'h3b}: q2s = 3'b101;
        // 10 -4: -1
        {4'ha, 6'h3c}: q2s = 3'b101;
        // 10 -3: -1
        {4'ha, 6'h3d}: q2s = 3'b101;
        // 10 -2: 0
        {4'ha, 6'h3e}: q2s = 3'b000;
        // 10 -1: 0
        {4'ha, 6'h3f}: q2s = 3'b000;
        // 10 0: 0
        {4'ha, 6'h0}: q2s = 3'b000;
        // 10 1: 0
        {4'ha, 6'h1}: q2s = 3'b000;
        // 10 2: 0
        {4'ha, 6'h2}: q2s = 3'b000;
        // 10 3: 1
        {4'ha, 6'h3}: q2s = 3'b001;
        // 10 4: 1
        {4'ha, 6'h4}: q2s = 3'b001;
        // 10 5: 1
        {4'ha, 6'h5}: q2s = 3'b001;
        // 10 6: 1
        {4'ha, 6'h6}: q2s = 3'b001;
        // 10 7: 1
        {4'ha, 6'h7}: q2s = 3'b001;
        // 10 8: 2
        {4'ha, 6'h8}: q2s = 3'b010;
        // 10 9: 2
        {4'ha, 6'h9}: q2s = 3'b010;
        // 10 10: 2
        {4'ha, 6'ha}: q2s = 3'b010;
        // 10 11: 2
        {4'ha, 6'hb}: q2s = 3'b010;
        // 10 12: 2
        {4'ha, 6'hc}: q2s = 3'b010;
        // 10 13: 2
        {4'ha, 6'hd}: q2s = 3'b010;
        // 10 14: 2
        {4'ha, 6'he}: q2s = 3'b010;
        // 11 -16: -2
        {4'hb, 6'h30}: q2s = 3'b110;
        // 11 -15: -2
        {4'hb, 6'h31}: q2s = 3'b110;
        // 11 -14: -2
        {4'hb, 6'h32}: q2s = 3'b110;
        // 11 -13: -2
        {4'hb, 6'h33}: q2s = 3'b110;
        // 11 -12: -2
        {4'hb, 6'h34}: q2s = 3'b110;
        // 11 -11: -2
        {4'hb, 6'h35}: q2s = 3'b110;
        // 11 -10: -2
        {4'hb, 6'h36}: q2s = 3'b110;
        // 11 -9: -2
        {4'hb, 6'h37}: q2s = 3'b110;
        // 11 -8: -1
        {4'hb, 6'h38}: q2s = 3'b101;
        // 11 -7: -1
        {4'hb, 6'h39}: q2s = 3'b101;
        // 11 -6: -1
        {4'hb, 6'h3a}: q2s = 3'b101;
        // 11 -5: -1
        {4'hb, 6'h3b}: q2s = 3'b101;
        // 11 -4: -1
        {4'hb, 6'h3c}: q2s = 3'b101;
        // 11 -3: -1
        {4'hb, 6'h3d}: q2s = 3'b101;
        // 11 -2: 0
        {4'hb, 6'h3e}: q2s = 3'b000;
        // 11 -1: 0
        {4'hb, 6'h3f}: q2s = 3'b000;
        // 11 0: 0
        {4'hb, 6'h0}: q2s = 3'b000;
        // 11 1: 0
        {4'hb, 6'h1}: q2s = 3'b000;
        // 11 2: 0
        {4'hb, 6'h2}: q2s = 3'b000;
        // 11 3: 1
        {4'hb, 6'h3}: q2s = 3'b001;
        // 11 4: 1
        {4'hb, 6'h4}: q2s = 3'b001;
        // 11 5: 1
        {4'hb, 6'h5}: q2s = 3'b001;
        // 11 6: 1
        {4'hb, 6'h6}: q2s = 3'b001;
        // 11 7: 1
        {4'hb, 6'h7}: q2s = 3'b001;
        // 11 8: 1
        {4'hb, 6'h8}: q2s = 3'b001;
        // 11 9: 2
        {4'hb, 6'h9}: q2s = 3'b010;
        // 11 10: 2
        {4'hb, 6'ha}: q2s = 3'b010;
        // 11 11: 2
        {4'hb, 6'hb}: q2s = 3'b010;
        // 11 12: 2
        {4'hb, 6'hc}: q2s = 3'b010;
        // 11 13: 2
        {4'hb, 6'hd}: q2s = 3'b010;
        // 11 14: 2
        {4'hb, 6'he}: q2s = 3'b010;
        // 11 15: 2
        {4'hb, 6'hf}: q2s = 3'b010;
        // 12 -18: -2
        {4'hc, 6'h2e}: q2s = 3'b110;
        // 12 -17: -2
        {4'hc, 6'h2f}: q2s = 3'b110;
        // 12 -16: -2
        {4'hc, 6'h30}: q2s = 3'b110;
        // 12 -15: -2
        {4'hc, 6'h31}: q2s = 3'b110;
        // 12 -14: -2
        {4'hc, 6'h32}: q2s = 3'b110;
        // 12 -13: -2
        {4'hc, 6'h33}: q2s = 3'b110;
        // 12 -12: -2
        {4'hc, 6'h34}: q2s = 3'b110;
        // 12 -11: -2
        {4'hc, 6'h35}: q2s = 3'b110;
        // 12 -10: -2
        {4'hc, 6'h36}: q2s = 3'b110;
        // 12 -9: -1
        {4'hc, 6'h37}: q2s = 3'b101;
        // 12 -8: -1
        {4'hc, 6'h38}: q2s = 3'b101;
        // 12 -7: -1
        {4'hc, 6'h39}: q2s = 3'b101;
        // 12 -6: -1
        {4'hc, 6'h3a}: q2s = 3'b101;
        // 12 -5: -1
        {4'hc, 6'h3b}: q2s = 3'b101;
        // 12 -4: -1
        {4'hc, 6'h3c}: q2s = 3'b101;
        // 12 -3: 0
        {4'hc, 6'h3d}: q2s = 3'b000;
        // 12 -2: 0
        {4'hc, 6'h3e}: q2s = 3'b000;
        // 12 -1: 0
        {4'hc, 6'h3f}: q2s = 3'b000;
        // 12 0: 0
        {4'hc, 6'h0}: q2s = 3'b000;
        // 12 1: 0
        {4'hc, 6'h1}: q2s = 3'b000;
        // 12 2: 0
        {4'hc, 6'h2}: q2s = 3'b000;
        // 12 3: 0
        {4'hc, 6'h3}: q2s = 3'b000;
        // 12 4: 1
        {4'hc, 6'h4}: q2s = 3'b001;
        // 12 5: 1
        {4'hc, 6'h5}: q2s = 3'b001;
        // 12 6: 1
        {4'hc, 6'h6}: q2s = 3'b001;
        // 12 7: 1
        {4'hc, 6'h7}: q2s = 3'b001;
        // 12 8: 1
        {4'hc, 6'h8}: q2s = 3'b001;
        // 12 9: 1
        {4'hc, 6'h9}: q2s = 3'b001;
        // 12 10: 2
        {4'hc, 6'ha}: q2s = 3'b010;
        // 12 11: 2
        {4'hc, 6'hb}: q2s = 3'b010;
        // 12 12: 2
        {4'hc, 6'hc}: q2s = 3'b010;
        // 12 13: 2
        {4'hc, 6'hd}: q2s = 3'b010;
        // 12 14: 2
        {4'hc, 6'he}: q2s = 3'b010;
        // 12 15: 2
        {4'hc, 6'hf}: q2s = 3'b010;
        // 12 16: 2
        {4'hc, 6'h10}: q2s = 3'b010;
        // 12 17: 2
        {4'hc, 6'h11}: q2s = 3'b010;
        // 13 -19: -2
        {4'hd, 6'h2d}: q2s = 3'b110;
        // 13 -18: -2
        {4'hd, 6'h2e}: q2s = 3'b110;
        // 13 -17: -2
        {4'hd, 6'h2f}: q2s = 3'b110;
        // 13 -16: -2
        {4'hd, 6'h30}: q2s = 3'b110;
        // 13 -15: -2
        {4'hd, 6'h31}: q2s = 3'b110;
        // 13 -14: -2
        {4'hd, 6'h32}: q2s = 3'b110;
        // 13 -13: -2
        {4'hd, 6'h33}: q2s = 3'b110;
        // 13 -12: -2
        {4'hd, 6'h34}: q2s = 3'b110;
        // 13 -11: -2
        {4'hd, 6'h35}: q2s = 3'b110;
        // 13 -10: -1
        {4'hd, 6'h36}: q2s = 3'b101;
        // 13 -9: -1
        {4'hd, 6'h37}: q2s = 3'b101;
        // 13 -8: -1
        {4'hd, 6'h38}: q2s = 3'b101;
        // 13 -7: -1
        {4'hd, 6'h39}: q2s = 3'b101;
        // 13 -6: -1
        {4'hd, 6'h3a}: q2s = 3'b101;
        // 13 -5: -1
        {4'hd, 6'h3b}: q2s = 3'b101;
        // 13 -4: -1
        {4'hd, 6'h3c}: q2s = 3'b101;
        // 13 -3: 0
        {4'hd, 6'h3d}: q2s = 3'b000;
        // 13 -2: 0
        {4'hd, 6'h3e}: q2s = 3'b000;
        // 13 -1: 0
        {4'hd, 6'h3f}: q2s = 3'b000;
        // 13 0: 0
        {4'hd, 6'h0}: q2s = 3'b000;
        // 13 1: 0
        {4'hd, 6'h1}: q2s = 3'b000;
        // 13 2: 0
        {4'hd, 6'h2}: q2s = 3'b000;
        // 13 3: 0
        {4'hd, 6'h3}: q2s = 3'b000;
        // 13 4: 1
        {4'hd, 6'h4}: q2s = 3'b001;
        // 13 5: 1
        {4'hd, 6'h5}: q2s = 3'b001;
        // 13 6: 1
        {4'hd, 6'h6}: q2s = 3'b001;
        // 13 7: 1
        {4'hd, 6'h7}: q2s = 3'b001;
        // 13 8: 1
        {4'hd, 6'h8}: q2s = 3'b001;
        // 13 9: 1
        {4'hd, 6'h9}: q2s = 3'b001;
        // 13 10: 2
        {4'hd, 6'ha}: q2s = 3'b010;
        // 13 11: 2
        {4'hd, 6'hb}: q2s = 3'b010;
        // 13 12: 2
        {4'hd, 6'hc}: q2s = 3'b010;
        // 13 13: 2
        {4'hd, 6'hd}: q2s = 3'b010;
        // 13 14: 2
        {4'hd, 6'he}: q2s = 3'b010;
        // 13 15: 2
        {4'hd, 6'hf}: q2s = 3'b010;
        // 13 16: 2
        {4'hd, 6'h10}: q2s = 3'b010;
        // 13 17: 2
        {4'hd, 6'h11}: q2s = 3'b010;
        // 13 18: 2
        {4'hd, 6'h12}: q2s = 3'b010;
        // 14 -20: -2
        {4'he, 6'h2c}: q2s = 3'b110;
        // 14 -19: -2
        {4'he, 6'h2d}: q2s = 3'b110;
        // 14 -18: -2
        {4'he, 6'h2e}: q2s = 3'b110;
        // 14 -17: -2
        {4'he, 6'h2f}: q2s = 3'b110;
        // 14 -16: -2
        {4'he, 6'h30}: q2s = 3'b110;
        // 14 -15: -2
        {4'he, 6'h31}: q2s = 3'b110;
        // 14 -14: -2
        {4'he, 6'h32}: q2s = 3'b110;
        // 14 -13: -2
        {4'he, 6'h33}: q2s = 3'b110;
        // 14 -12: -2
        {4'he, 6'h34}: q2s = 3'b110;
        // 14 -11: -2
        {4'he, 6'h35}: q2s = 3'b110;
        // 14 -10: -1
        {4'he, 6'h36}: q2s = 3'b101;
        // 14 -9: -1
        {4'he, 6'h37}: q2s = 3'b101;
        // 14 -8: -1
        {4'he, 6'h38}: q2s = 3'b101;
        // 14 -7: -1
        {4'he, 6'h39}: q2s = 3'b101;
        // 14 -6: -1
        {4'he, 6'h3a}: q2s = 3'b101;
        // 14 -5: -1
        {4'he, 6'h3b}: q2s = 3'b101;
        // 14 -4: -1
        {4'he, 6'h3c}: q2s = 3'b101;
        // 14 -3: 0
        {4'he, 6'h3d}: q2s = 3'b000;
        // 14 -2: 0
        {4'he, 6'h3e}: q2s = 3'b000;
        // 14 -1: 0
        {4'he, 6'h3f}: q2s = 3'b000;
        // 14 0: 0
        {4'he, 6'h0}: q2s = 3'b000;
        // 14 1: 0
        {4'he, 6'h1}: q2s = 3'b000;
        // 14 2: 0
        {4'he, 6'h2}: q2s = 3'b000;
        // 14 3: 0
        {4'he, 6'h3}: q2s = 3'b000;
        // 14 4: 1
        {4'he, 6'h4}: q2s = 3'b001;
        // 14 5: 1
        {4'he, 6'h5}: q2s = 3'b001;
        // 14 6: 1
        {4'he, 6'h6}: q2s = 3'b001;
        // 14 7: 1
        {4'he, 6'h7}: q2s = 3'b001;
        // 14 8: 1
        {4'he, 6'h8}: q2s = 3'b001;
        // 14 9: 1
        {4'he, 6'h9}: q2s = 3'b001;
        // 14 10: 1
        {4'he, 6'ha}: q2s = 3'b001;
        // 14 11: 2
        {4'he, 6'hb}: q2s = 3'b010;
        // 14 12: 2
        {4'he, 6'hc}: q2s = 3'b010;
        // 14 13: 2
        {4'he, 6'hd}: q2s = 3'b010;
        // 14 14: 2
        {4'he, 6'he}: q2s = 3'b010;
        // 14 15: 2
        {4'he, 6'hf}: q2s = 3'b010;
        // 14 16: 2
        {4'he, 6'h10}: q2s = 3'b010;
        // 14 17: 2
        {4'he, 6'h11}: q2s = 3'b010;
        // 14 18: 2
        {4'he, 6'h12}: q2s = 3'b010;
        // 14 19: 2
        {4'he, 6'h13}: q2s = 3'b010;
        // 15 -22: -2
        {4'hf, 6'h2a}: q2s = 3'b110;
        // 15 -21: -2
        {4'hf, 6'h2b}: q2s = 3'b110;
        // 15 -20: -2
        {4'hf, 6'h2c}: q2s = 3'b110;
        // 15 -19: -2
        {4'hf, 6'h2d}: q2s = 3'b110;
        // 15 -18: -2
        {4'hf, 6'h2e}: q2s = 3'b110;
        // 15 -17: -2
        {4'hf, 6'h2f}: q2s = 3'b110;
        // 15 -16: -2
        {4'hf, 6'h30}: q2s = 3'b110;
        // 15 -15: -2
        {4'hf, 6'h31}: q2s = 3'b110;
        // 15 -14: -2
        {4'hf, 6'h32}: q2s = 3'b110;
        // 15 -13: -2
        {4'hf, 6'h33}: q2s = 3'b110;
        // 15 -12: -2
        {4'hf, 6'h34}: q2s = 3'b110;
        // 15 -11: -1
        {4'hf, 6'h35}: q2s = 3'b101;
        // 15 -10: -1
        {4'hf, 6'h36}: q2s = 3'b101;
        // 15 -9: -1
        {4'hf, 6'h37}: q2s = 3'b101;
        // 15 -8: -1
        {4'hf, 6'h38}: q2s = 3'b101;
        // 15 -7: -1
        {4'hf, 6'h39}: q2s = 3'b101;
        // 15 -6: -1
        {4'hf, 6'h3a}: q2s = 3'b101;
        // 15 -5: -1
        {4'hf, 6'h3b}: q2s = 3'b101;
        // 15 -4: -1
        {4'hf, 6'h3c}: q2s = 3'b101;
        // 15 -3: 0
        {4'hf, 6'h3d}: q2s = 3'b000;
        // 15 -2: 0
        {4'hf, 6'h3e}: q2s = 3'b000;
        // 15 -1: 0
        {4'hf, 6'h3f}: q2s = 3'b000;
        // 15 0: 0
        {4'hf, 6'h0}: q2s = 3'b000;
        // 15 1: 0
        {4'hf, 6'h1}: q2s = 3'b000;
        // 15 2: 0
        {4'hf, 6'h2}: q2s = 3'b000;
        // 15 3: 0
        {4'hf, 6'h3}: q2s = 3'b000;
        // 15 4: 0
        {4'hf, 6'h4}: q2s = 3'b000;
        // 15 5: 1
        {4'hf, 6'h5}: q2s = 3'b001;
        // 15 6: 1
        {4'hf, 6'h6}: q2s = 3'b001;
        // 15 7: 1
        {4'hf, 6'h7}: q2s = 3'b001;
        // 15 8: 1
        {4'hf, 6'h8}: q2s = 3'b001;
        // 15 9: 1
        {4'hf, 6'h9}: q2s = 3'b001;
        // 15 10: 1
        {4'hf, 6'ha}: q2s = 3'b001;
        // 15 11: 1
        {4'hf, 6'hb}: q2s = 3'b001;
        // 15 12: 2
        {4'hf, 6'hc}: q2s = 3'b010;
        // 15 13: 2
        {4'hf, 6'hd}: q2s = 3'b010;
        // 15 14: 2
        {4'hf, 6'he}: q2s = 3'b010;
        // 15 15: 2
        {4'hf, 6'hf}: q2s = 3'b010;
        // 15 16: 2
        {4'hf, 6'h10}: q2s = 3'b010;
        // 15 17: 2
        {4'hf, 6'h11}: q2s = 3'b010;
        // 15 18: 2
        {4'hf, 6'h12}: q2s = 3'b010;
        // 15 19: 2
        {4'hf, 6'h13}: q2s = 3'b010;
        // 15 20: 2
        {4'hf, 6'h14}: q2s = 3'b010;
        // 15 21: 2
        {4'hf, 6'h15}: q2s = 3'b010;
		  
		  default:       q2s = 3'b000;
    endcase
end
endmodule
