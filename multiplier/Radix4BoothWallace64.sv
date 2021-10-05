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

// Radix4BoothWallace64.sv
// 64-bit unsigned/signed Radix-4 Booth Wallace tree multiplier top level

module Radix4BoothWallace64
(
    input logic signedFlag, // 1 signed, 0 unsigned 
    input logic [63 : 0] multiplicand,
    input logic [63 : 0] multiplier,
    output logic [127 : 0] out
);

localparam M = 64;
localparam NPP = M / 2 + 1;
logic [M + 2 - 1 : 0] pprods [0 : NPP - 1]; //    - 2m <= pp <= 2m
logic [M + 4 - 1 : 0] pprodsExt [0 : NPP - 1];
logic [0 : NPP - 1] signsLow;
logic [2 * M - 1 : 0] sum_0 [0 : NPP / 4];
logic [2 * M - 1  : 0] carry_0 [0 : NPP / 4];
logic [2 * M - 1 : 0] hor_cout_0 [0 : NPP / 4];
logic [2 * M - 1 : 0] sum_1 [0 : NPP / 8];
logic [2 * M - 1  : 0] carry_1 [0 : NPP / 8];
logic [2 * M - 1 : 0] hor_cout_1 [0 : NPP / 8];
logic [2 * M - 1 : 0] sum_2 [0 : NPP / 16];
logic [2 * M - 1  : 0] carry_2 [0 : NPP / 16];
logic [2 * M - 1 : 0] hor_cout_2 [0 : NPP / 16];
logic [2 * M - 1 : 0] sum_3 [0 : NPP / 32];
logic [2 * M - 1 : 0] carry_3 [0 : NPP / 32];
logic [2 * M - 1 : 0] hor_cout_3 [0 : NPP / 32];
logic [2 * M - 1 : 0] sum_4;
logic [2 * M - 1 : 0] carry_4;
logic [2 * M - 1 : 0] hor_cout_4;

pProdsGen #(.M(M), .N(M), .NPP(NPP)) pProdsGen(.signedFlag(signedFlag), .multiplicand(multiplicand), 
.multiplier(multiplier), .pprods(pprods), .signsLow(signsLow));

assign pprodsExt[0] = {~pprods[0][M + 1], pprods[0][M + 1], pprods[0][M + 1 : 0]};

// generate partial products and extend with sign compression values
genvar i;
generate
for(i = 1; i < NPP; i = i + 1)
begin: pProdsGenLoop
    assign pprodsExt[i] = {1'b1, ~pprods[i][M + 1], pprods[i][M : 0]}; 
end

////// tree


///**** level 0, rows 0 - NPP / 4 - 1 ****///

///PREAMBLE///

genvar row_0;
for (row_0 = 0; row_0 < NPP / 4; row_0 = row_0 + 1)
begin: row_0_for
    // y is low sign of pprod
    halfAdder ha_row0_0(.x(pprodsExt[row_0 * 4][0]), .y(signsLow[row_0 * 4]), 
        .sum(sum_0[row_0][row_0 * 8]), 
    .cout(carry_0[row_0][row_0 * 8]));

    assign sum_0[row_0][row_0 * 8 + 1] = pprodsExt[row_0 * 4][1];

    // x3 is low sign
    fullAdder fa0_2(.x(pprodsExt[row_0 * 4][2]), 
        .y(pprodsExt[row_0 * 4 + 1][0]), .cin(signsLow[row_0 * 4 + 1]), 
        .sum(sum_0[row_0][row_0 * 8 + 2]), 
    .cout(carry_0[row_0][row_0 * 8 + 2]));

    halfAdder ha_row0_3(.x(pprodsExt[row_0 * 4][3]), 
        .y(pprodsExt[row_0 * 4 + 1][1]), 
        .sum(sum_0[row_0][row_0 * 8 + 3]),
    .cout(carry_0[row_0][row_0 * 8 + 3]));

    // x4 is low sign
    compressor_42 comp_0_4(.x1(pprodsExt[row_0 * 4][4]), 
        .x2(pprodsExt[row_0 * 4 + 1][2]), 
        .x3(pprodsExt[row_0 * 4 + 2][0]), 
        .x4(signsLow[row_0 * 4 + 2]), .cin(1'b0), 
        .sum(sum_0[row_0][row_0 * 8 + 4]), 
        .carry(carry_0[row_0][row_0 * 8 + 4]), 
    .cout(hor_cout_0[row_0][row_0 * 8 + 4]));

    compressor_42 comp_0_5(.x1(pprodsExt[row_0 * 4][5]), 
        .x2(pprodsExt[row_0 * 4 + 1][3]),
        .x3(pprodsExt[row_0 * 4 + 2][1]), .x4(1'b0), 
        .cin(hor_cout_0[row_0][row_0 * 8 + 4]), 
        .sum(sum_0[row_0][row_0 * 8 + 5]),
        .carry(carry_0[row_0][row_0 * 8 + 5]), 
    .cout(hor_cout_0[row_0][row_0 * 8 + 5]));

    // MIDDLE

    genvar col;
    for (col = 6; col <= M + 3 - row_0 * 8; col = col + 1)
    begin: middle_0
        compressor_42 comp_mid_col(.x1(pprodsExt[row_0 * 4][col]), 
            .x2(pprodsExt[row_0 * 4 + 1][col - 2]),
            .x3(pprodsExt[row_0 * 4 + 2][col - 4]), 
            .x4(pprodsExt[row_0 * 4 + 3][col - 6]), 
            .cin(hor_cout_0[row_0][row_0 * 8 + col - 1]), 
            .sum(sum_0[row_0][row_0 * 8 + col]),
            .carry(carry_0[row_0][row_0 * 8 + col]), 
        .cout(hor_cout_0[row_0][row_0 * 8 + col]));
    end

    //TAIL

    compressor_42 comp_0_0_M_4(
        .x1(pprodsExt[row_0 * 4 + 1][M + 2 - row_0 * 8]), 
        .x2(pprodsExt[row_0 * 4 + 2][M + 2 - row_0 * 8 - 2]), 
        .x3(pprodsExt[row_0 * 4 + 3][M + 2 - row_0 * 8 - 4]), 
        .x4(pprodsExt[row_0 * 4 + 4][M + 2 - row_0 * 8 - 6]), 
        .cin(hor_cout_0[row_0][M + 3]), 
        .sum(sum_0[row_0][M + 4]), 
        .carry(carry_0[row_0][M + 4]),
    .cout(hor_cout_0[row_0][M + 4]));

    genvar j;

    for (j = row_0 * 4 + 2; j <= NPP - 4; j = j + 1)
    begin: comp_tail_0

        // x is 1's complement of sign 
        compressor_42 comp_0_2j(.x1(pprodsExt[j][M + 1 - row_0 * 8]), 
            .x2(pprodsExt[j + 1][M + 1 - row_0 * 8 - 2]),
            .x3(pprodsExt[j + 2][M + 1 - row_0 * 8 - 4]), 
            .x4(pprodsExt[j + 3][M + 1 - row_0 * 8 - 6]),
            .cin(hor_cout_0[row_0][M + 5 + ((j - (row_0 * 4 + 2)) * 2) - 1]), 
            .sum(sum_0[row_0][M + 5 + ((j - (row_0 * 4 + 2)) * 2)]), 
            .carry(carry_0[row_0][M + 5 + ((j - (row_0 * 4 + 2)) * 2)]), 
        .cout(hor_cout_0[row_0][M + 5 + ((j - (row_0 * 4 + 2)) * 2)]));

        compressor_42 comp_0_2j_1(.x1(pprodsExt[j][M + 1 - row_0 * 8 + 1]), 
            .x2(pprodsExt[j + 1][M + 1 - row_0 * 8 + 1 - 2]), 
            .x3(pprodsExt[j + 2][M + 1 - row_0 * 8 + 1 - 4]), 
            .x4(pprodsExt[j + 3][M + 1 - row_0 * 8 + 1 - 6]), 
            .cin(hor_cout_0[row_0][M + 5 + ((j - (row_0 * 4 + 2)) * 2)]), 
            .sum(sum_0[row_0][M + 5 + ((j - (row_0 * 4 + 2)) * 2) + 1]), 
            .carry(carry_0[row_0][M + 5 + ((j - (row_0 * 4 + 2)) * 2) + 1]), 
        .cout(hor_cout_0[row_0][M + 5 + ((j - (row_0 * 4 + 2)) * 2) + 1]));

    end

    // FINAL TAIL ADDERS
    compressor_42 comp_0_final_0(.x1(pprodsExt[NPP - 3][M + 1 - 8 * row_0]), 
        .x2(pprodsExt[NPP - 2][M + 1 - 8 * row_0 - 2]), 
        .x3(pprodsExt[NPP - 1][M + 1 - 8 * row_0 - 4]), 
        .x4(1'b0), .cin(hor_cout_0[row_0][2 * M - 4 - 8 * row_0]), 
        .sum(sum_0[row_0][2 * M - 3 - 8 * row_0]), 
        .carry(carry_0[row_0][2 * M - 3 - 8 * row_0]), 
    .cout(hor_cout_0[row_0][2 * M - 3 - 8 * row_0]));

    compressor_42 comp_0_final_1(.x1(pprodsExt[NPP - 3][M + 2 - 8 * row_0]), 
        .x2(pprodsExt[NPP - 2][M + 2 - 8 * row_0 - 2]), 
        .x3(pprodsExt[NPP - 1][M + 2 - 8 * row_0 - 4]), 
        .x4(1'b0), .cin(hor_cout_0[row_0][2 * M - 3 - 8 * row_0]), 
        .sum(sum_0[row_0][2 * M - 2 - 8 * row_0]), 
        .carry(carry_0[row_0][2 * M - 2 - 8 * row_0]), 
    .cout(hor_cout_0[row_0][2 * M - 2 - 8 * row_0]));

    fullAdder fa_0_final_0(.x(pprodsExt[NPP - 2][M + 1 - 8 * row_0]), 
        .y(pprodsExt[NPP - 1][M + 1 - 8 * row_0 - 2]), 
        .cin(hor_cout_0[row_0][2 * M - 2 - 8 * row_0]), 
        .sum(sum_0[row_0][2 * M - 1 - 8 * row_0]), 
    .cout(carry_0[row_0][2 * M - 1 - 8 * row_0])); 

    for(j = 0; j < (row_0); j = j + NPP / 4) // skip row 0
    begin: row_0_g1_tail
        halfAdder ha_0_final_0(.x(pprodsExt[NPP - 2][M + 2 - 8 * row_0]), 
            .y(pprodsExt[NPP - 1][M - 8 * (row_0)]),  
            .sum(sum_0[row_0][2 * M - 8 * (row_0)]), 
        .cout(carry_0[row_0][2 * M - 8 * row_0]));
        assign sum_0[row_0][2 * M + 1 - 8 * row_0] 
        = pprodsExt[NPP - 1][M - 7 - 8 * (row_0 - 1)] ;
        assign sum_0[row_0][2 * M + 2 - 8 * row_0] 
        = pprodsExt[NPP - 1][M - 6 - 8 * (row_0 - 1)];
        // signsLow
        assign sum_0[row_0][6 + 8 * (row_0 - 1)] = signsLow[4 * row_0 - 1];
    end 
end // end row_0 for

assign carry_0[0][1] = 1'b0; // needed for final addition
// pprod NPP pass-through 

assign sum_0[NPP / 4][M - 2] = signsLow[NPP - 2];

genvar j;
for(j = 0; j < 4; j = j + 1) 
begin: level_0_sumPassThroughs
    assign sum_0[NPP / 4][M + j] = pprodsExt[NPP - 1][j];
end

///END **** level 0 - row 0 - 3 ****///


///**** level 1: row 0 - NPP / 8 - 1 ****///

// PASS-THROUGHS
// sum and carry values for final addition
for(i = 0; i <= 5; i++)
begin: level_1_sumPassThroughs
    assign sum_1[0][i] = sum_0[0][i];
end
for(i = 0; i <= 4; i++)
begin: level_1_carryPassThroughs
    assign carry_1[0][i] = carry_0[0][i];
end
assign carry_1[0][5] = 1'b0;

genvar row_1;

// row >= 1 only PREAMBLE halfAdder / assign
for(row_1 = 1; row_1 < NPP / 8 ; row_1 = row_1 + 1)
begin: row_1_g1_pre

    halfAdder ha_pre_row_1_1(.x(sum_0[2 * row_1][16 * row_1 + 1]), 
        .y(carry_0[2 * row_1][16 * row_1]), 
    .sum(sum_1[row_1][16 * row_1 + 1]), .cout(carry_1[row_1][16 * row_1 + 1]));

    for(j = 3; j <= 5; j = j + 1)
    begin: row_1_g1_pre_3_5
        halfAdder ha_pre_row_1_3(.x(sum_0[row_1 * 2][j + 16 * row_1]), 
            .y(carry_0[row_1 * 2][j - 1 + 16 * row_1]), 
        .sum(sum_1[row_1][j + 16 * row_1]), .cout(carry_1[row_1][j + 16 * row_1]));
    end
    assign sum_1[row_1][14 + 16 * (row_1 - 1)] = sum_0[2 * row_1][14 + 16 * (row_1 - 1)]; //signsLow
    assign sum_1[row_1][16 + 16 * (row_1 - 1)] = sum_0[2 * row_1][16 + 16 * (row_1 - 1)];
    assign sum_1[row_1][18 + 16 * (row_1 - 1)] = sum_0[2 * row_1][18 + 16 * (row_1 - 1)];
    assign sum_1[row_1][2 * M - 14 - 16 * (row_1 - 1)] = sum_0[2 * row_1][2 * M - 14 - 16 * (row_1 - 1)];
end

// rows
for(row_1 = 0; row_1 < NPP / 8; row_1 = row_1 + 1)
begin: pre_1

    // PREAMBLE

    fullAdder fa_pre_row_1_6(.x(sum_0[row_1 * 2][6 + 16 * row_1]),
        .y(carry_0[row_1 * 2][6 - 1 + 16 * row_1]), 
        .cin(sum_0[row_1 * 2 + 1][6 + 16 * row_1]), 
        .sum(sum_1[row_1][6 + 16 * row_1]), 
    .cout(carry_1[row_1][6 + 16 * row_1]));
    halfAdder ha_pre_row_1_7(.x(sum_0[row_1 * 2][7 + 16 * row_1]),
        .y(carry_0[row_1 * 2][7 - 1 + 16 * row_1]), 
        .sum(sum_1[row_1][7 + 16 * row_1]), 
    .cout(carry_1[row_1][7 + 16 * row_1]));
    fullAdder fa_pre_row_1_8(.x(sum_0[row_1 * 2][8 + 16 * row_1]),
        .y(carry_0[row_1 * 2][8 - 1 + 16 * row_1]), 
        .cin(sum_0[row_1 * 2 + 1][8 + 16 * row_1]), 
        .sum(sum_1[row_1][8 + 16 * row_1]), 
    .cout(carry_1[row_1][8 + 16 * row_1]));
    compressor_42 ca_pre_row_1_9(.x1(sum_0[row_1 * 2][9 + 16 * row_1]), 
        .x2(carry_0[row_1 * 2][9 - 1 + 16 * row_1]), 
        .x3(sum_0[row_1 * 2 + 1][9 + 16 * row_1]),
        .x4(carry_0[row_1 * 2 + 1][9 - 1 + 16 * row_1]),
        .cin(1'b0),
        .sum(sum_1[row_1][9 + 16 * row_1]), 
        .carry(carry_1[row_1][9 + 16 * row_1]),
    .cout(hor_cout_1[row_1][9 + 16 * row_1]));
    compressor_42 ca_pre_row_1_10(.x1(sum_0[row_1 * 2][10 + 16 * row_1]), 
        .x2(carry_0[row_1 * 2][10 - 1 + 16 * row_1]), 
        .x3(sum_0[row_1 * 2 + 1][10 + 16 * row_1]),
        .x4(1'b0),
        .cin(hor_cout_1[row_1][10 - 1 + 16 * row_1]),
        .sum(sum_1[row_1][10 + 16 * row_1]), 
        .carry(carry_1[row_1][10 + 16 * row_1]),
    .cout(hor_cout_1[row_1][10 + 16 * row_1]));

    // MIDDLE

    for(j = 11 + 16 * row_1; j <= 2 * M - 7 - 16 * row_1; j = j + 1)
    begin: row_1_comp_middle
        compressor_42 comp_1_middle(.x1(sum_0[row_1 * 2][j]),
            .x2(carry_0[row_1 * 2][j - 1]), 
            .x3(sum_0[row_1 * 2 + 1][j]), 
            .x4(carry_0[row_1 * 2 + 1][j - 1]), .cin(hor_cout_1[row_1][j - 1]), 
            .sum(sum_1[row_1][j]), 
        .carry(carry_1[row_1][j]), .cout(hor_cout_1[row_1][j]));
    end

    compressor_42 comp_1_middle_2_M_6(
        .x1(sum_0[row_1 * 2][2 * M - 6 - 16 * row_1]), 
        .x2(carry_0[row_1 * 2][2 * M - 6 - 16 * row_1 - 1]), 
        .x3(sum_0[row_1 * 2 + 1][2 * M - 6 - 16 * row_1]), 
        .x4(1'b0), .cin(hor_cout_1[row_1][2 * M - 6 - 16 * row_1 - 1]), 
        .sum(sum_1[row_1][2 * M - 6 - 16 * row_1]), 
        .carry(carry_1[row_1][2 * M - 6 - 16 * row_1]), 
    .cout(hor_cout_1[row_1][2 * M - 6 - 16 * row_1]));

    //TAIL
    fullAdder fa_1_tail_2_M_5(.x(sum_0[row_1 * 2][2 * M - 5 - 16 * row_1]), 
        .y(carry_0[row_1 * 2][2 * M - 5 - 16 * row_1 - 1]), 
        .cin(hor_cout_1[row_1][2 * M - 5 - 16 * row_1 - 1]), 
        .sum(sum_1[row_1][2 * M - 5 - 16 * row_1]), 
    .cout(carry_1[row_1][2 * M - 5 - 16 * row_1]));

    for(j = 2 * M - 4 - 16 * row_1; j <= 2 * M - 1 - 16 * row_1 + 2 * (row_1 > 0); j = j + 1)
    begin: tail_1
        halfAdder ha_1_tail(.x(sum_0[row_1 * 2][j]), .y(carry_0[row_1 * 2][j - 1]), 
            .sum(sum_1[row_1][j]), 
        .cout(carry_1[row_1][j]));
    end

end // end row_1 for 

assign sum_1[NPP / 8][M - 2] = sum_0[NPP / 4][M - 2];
for(j = 0; j < 4; j = j + 1) 
begin: level_0_endSumPassThroughs
    assign sum_1[NPP / 8][M + j] = sum_0[NPP / 4][M + j];
end

///**** END level 1 ****///


///**** level 2 ****///

// PASS-THROUGHS
// sum and carry values for final addition
for(i = 0; i <= 13; i++)
begin: level_2_sumPassThroughs
    assign sum_2[0][i] = sum_1[0][i];
end
for(i = 0; i <= 12; i++)
begin: level_2_carryPassThroughs
    assign carry_2[0][i] = carry_1[0][i];
end
assign carry_2[0][13] = 1'b0;

genvar row_2;
for(row_2 = 1; row_2 < NPP / 16 ; row_2 = row_2 + 1)
begin: pre_2_g1
    // row >= 1 only PREAMBLE halfAdder / assign
    halfAdder ha_pre_row_2_1(.x(sum_1[2 * row_2][32 * row_2 + 2]), 
        .y(carry_1[2 * row_2][32 * row_2 + 1]), 
    .sum(sum_2[row_2][32 * row_2 + 2]), .cout(carry_2[row_2][32 * row_2 + 2]));

    for(j = 32 * row_2 + 4 ; j <= 32 * row_2 + 4 + 9; j = j + 1) // only row 1
    begin: ha_pre_row_2_10
        halfAdder ha_pre_row_2_3(.x(sum_1[row_2 * 2][j]), 
            .y(carry_1[row_2 * 2][j - 1]), 
        .sum(sum_2[row_2][j]), .cout(carry_2[row_2][j]));
    end
    assign sum_2[row_2][32 * row_2 - 2] = sum_1[2 * row_2][32 * row_2 - 2]; //signsLow
    assign sum_2[row_2][32 * row_2] = sum_1[2 * row_2][32 * row_2];
    assign sum_2[row_2][32 * row_2 + 1] = sum_1[2 * row_2][32 * row_2 + 1];
    assign sum_2[row_2][32 * row_2 + 3] = sum_1[2 * row_2][32 * row_2 + 3];
end

for(row_2 = 0; row_2 < NPP / 16; row_2 = row_2 + 1)
begin: row_2_for

    // PREAMBLE

    fullAdder fa_pre_row_2_14(.x(sum_1[row_2 * 2][14 + 32 * row_2]),
        .y(carry_1[row_2 * 2][13 + 32 * row_2]), 
        .cin(sum_1[row_2 * 2 + 1][14 + 32 * row_2]), 
        .sum(sum_2[row_2][14 + 32 * row_2]), 
    .cout(carry_2[row_2][14 + 32 * row_2]));
    halfAdder ha_pre_row_2_15(.x(sum_1[row_2 * 2][15 + 32 * row_2]),
        .y(carry_1[row_2 * 2][14 + 32 * row_2]), 
        .sum(sum_2[row_2][15 + 32 * row_2]), 
    .cout(carry_2[row_2][15 + 32 * row_2]));
    fullAdder fa_pre_row_2_16(.x(sum_1[row_2 * 2][16 + 32 * row_2]),
        .y(carry_1[row_2 * 2][15 + 32 * row_2]), 
        .cin(sum_1[row_2 * 2 + 1][16 + 32 * row_2]), 
        .sum(sum_2[row_2][16 + 32 * row_2]), 
    .cout(carry_2[row_2][16 + 32 * row_2]));
    fullAdder fa_pre_row_2_17(.x(sum_1[row_2 * 2][17 + 32 * row_2]),
        .y(carry_1[row_2 * 2][16 + 32 * row_2]), 
        .cin(sum_1[row_2 * 2 + 1][17 + 32 * row_2]), 
        .sum(sum_2[row_2][17 + 32 * row_2]), 
    .cout(carry_2[row_2][17 + 32 * row_2]));
    compressor_42 ca_pre_row_2_18(.x1(sum_1[row_2 * 2][18 + 32 * row_2]), 
        .x2(carry_1[row_2 * 2][17 + 32 * row_2]), 
        .x3(sum_1[row_2 * 2 + 1][18 + 32 * row_2]),
        .x4(carry_1[row_2 * 2 + 1][17 + 32 * row_2]),
        .cin(1'b0),
        .sum(sum_2[row_2][18 + 32 * row_2]), 
        .carry(carry_2[row_2][18 + 32 * row_2]),
    .cout(hor_cout_2[row_2][18 + 32 * row_2]));
    compressor_42 ca_pre_row_2_19(.x1(sum_1[row_2 * 2][19 + 32 * row_2]), 
        .x2(carry_1[row_2 * 2][18 + 32 * row_2]), 
        .x3(sum_1[row_2 * 2 + 1][19 + 32 * row_2]),
        .x4(1'b0),
        .cin(hor_cout_2[row_2][18 + 32 * row_2]),
        .sum(sum_2[row_2][19 + 32 * row_2]), 
        .carry(carry_2[row_2][19 + 32 * row_2]),
    .cout(hor_cout_2[row_2][19 + 32 * row_2]));

    for(i = 20 + 32 * row_2; i <= 2 * M - 14 - 32 * row_2; i = i + 1)
    begin: row_2_middle
        compressor_42 comp_2(.x1(sum_1[2 * row_2][i]),
            .x2(carry_1[2 * row_2][i - 1]),
            .x3(sum_1[2 * row_2 + 1][i]), 
            .x4(carry_1[2 * row_2 + 1][i - 1]), 
            .cin(hor_cout_2[row_2][i - 1]),
            .sum(sum_2[row_2][i]), 
            .carry(carry_2[row_2][i]), 
        .cout(hor_cout_2[row_2][i]));
    end

    fullAdder fa_2_tail_2M_13(.x(sum_1[2 * row_2][2 * M - 13 - 32 * row_2]), 
        .y(carry_1[2 * row_2][2 * M - 14 - 32 * row_2]),
        .cin(hor_cout_2[row_2][2 * M - 14 - 32 * row_2]), 
        .sum(sum_2[row_2][2 * M - 13 - 32 * row_2]), 
    .cout(carry_2[row_2][2 * M - 13 - 32 * row_2]));

    for(i = 2 * M - 12 - 32 * row_2; i <= 2 * M - 1 - 32 * row_2 + 3 * (row_2 > 0); i = i + 1)
    begin: ha_2_final
        halfAdder ha_2_final(.x(sum_1[2 * row_2][i]), .y(carry_1[2 * row_2][i - 1]),
        .sum(sum_2[row_2][i]), .cout(carry_2[row_2][i]));
    end
end // end row_2 for

assign sum_2[NPP / 16][M - 2] = sum_1[NPP / 8][M - 2]; // signsLow

for(j = 0; j < 4; j = j + 1) 
begin: level_1_endsumPassThroughs
    assign sum_2[NPP / 16][M + j] = sum_1[NPP / 8][M + j];
end

///END **** level 2 ****///


///*** level 3 ***///
// PASS-THROUGHS
// sum and carry values for final addition
for(i = 0; i <= 29; i++)
begin: level_3_sumPassThroughs
    assign sum_3[0][i] = sum_2[0][i];
end
for(i = 0; i <= 28; i++)
begin: level_3_carryPassThroughs
    assign carry_3[0][i] = carry_2[0][i];
end
assign carry_3[0][29] = 1'b0;


genvar row_3;

for(row_3 = 0; row_3 < NPP / 32; row_3 = row_3 + 1)
begin: row_3_for
    fullAdder fa_3_30(.x(sum_2[row_3][30]), .y(carry_2[row_3][29]), 
        .cin(sum_2[row_3 + 1][30]),
    .sum(sum_3[row_3][30]), .cout(carry_3[row_3][30]));

    halfAdder ha_3_31(.x(sum_2[row_3][31]), .y(carry_2[row_3][30]),
    .sum(sum_3[row_3][31]), .cout(carry_3[row_3][31]));

    for(i = 32; i <= 34; i = i + 1)
    begin: pre_3
        fullAdder fa_3_pre(.x(sum_2[row_3][i]), .y(carry_2[row_3][i - 1]), 
            .cin(sum_2[row_3 + 1][i]),
        .sum(sum_3[row_3][i]), .cout(carry_3[row_3][i]));
    end
    compressor_42 comp_3_pre_35(.x1(sum_2[row_3][35]), 
        .x2(carry_2[row_3][34]),
        .x3(sum_2[row_3 + 1][35]), .x4(carry_2[row_3 + 1][34]), .cin(1'b0),
        .sum(sum_3[row_3][35]), .carry(carry_3[row_3][35]), 
    .cout(hor_cout_3[row_3][35]));
    compressor_42 comp_3_pre_36(.x1(sum_2[row_3][36]), 
        .x2(carry_2[row_3][35]),
        .x3(sum_2[row_3 + 1][36]), .x4(1'b0), .cin(hor_cout_2[row_3][35]),
        .sum(sum_3[row_3][36]), .carry(carry_3[row_3][36]), 
    .cout(hor_cout_3[row_3][36]));
    for(i = 37; i <= 2 * M - 30; i = i + 1)
    begin: comp_3_middle
        compressor_42 comp_3_pre(.x1(sum_2[row_3][i]), .x2(carry_2[row_3][i - 1]),
            .x3(sum_2[row_3 + 1][i]), .x4(carry_2[row_3 + 1][i - 1]), 
            .cin(hor_cout_3[row_3][i - 1]),
        .sum(sum_3[row_3][i]), .carry(carry_3[row_3][i]), .cout(hor_cout_3[row_3][i]));
    end

    compressor_42 comp_3_pre_last(.x1(sum_2[row_3][2 * M - 29]), 
        .x2(carry_2[row_3][2 * M - 30]),
        .x3(carry_2[row_3 + 1][2 * M - 30]),  .x4(1'b0), 
        .cin(hor_cout_3[row_3][2 * M - 30]),
        .sum(sum_3[row_3][2 * M - 29]), .carry(carry_3[row_3][2 * M - 29]), 
    .cout(hor_cout_3[row_3][2 * M - 29]));

    fullAdder fa_3_tail_M_28(.x(sum_2[row_3][2 * M - 28]),
        .y(carry_2[row_3][2 * M - 29]), 
        .cin(hor_cout_3[row_3][2 * M - 29]),
    .sum(sum_3[row_3][2 * M - 28]), .cout(carry_3[row_3][2 * M - 28]));

    for(i = 2 * M - 27; i <= 2 * M - 1; i = i + 1)
    begin: ha_3_tail
        halfAdder ha_3_tail(.x(sum_2[row_3][i]), .y(carry_2[row_3][i - 1]),
        .sum(sum_3[row_3][i]), .cout(carry_3[row_3][i]));
    end

end // end row_3 for

assign sum_3[NPP / 32][M - 2] = sum_2[NPP / 16][M - 2]; // signsLow

for(j = 0; j < 4; j = j + 1) 
begin: level_3_endSumPassThroughs
    assign sum_3[NPP / 32][M + j] = sum_2[NPP / 16][M + j];
end
///END **** level 3 ****///

/// **** level 4 ****///

// PASS-THROUGHS
// sum and carry values for final addition
for(i = 0; i <= 61; i++)
begin: level_4_sumPassThroughs
    assign sum_4[i] = sum_3[0][i];
end
for(i = 0; i <= 60; i++)
begin: level_4_carryPassThroughs
    assign carry_4[i] = carry_3[0][i];
end
assign carry_4[61] = 1'b0;

fullAdder fa_4_M_2(.x(sum_3[0][M - 2]), .y(carry_3[0][M - 3]), 
    .cin(sum_3[1][M - 2]),
.sum(sum_4[M - 2]), .cout(carry_4[M - 2]));

halfAdder ha_4_M_1(.x(sum_3[0][M - 1]), .y(carry_3[0][M - 2]),
.sum(sum_4[M - 1]), .cout(carry_4[M - 1]));

for(i = M; i <= M + 3; i = i + 1)
begin: level_4_fa_M
    fullAdder fa_4_pre(.x(sum_3[0][i]), .y(carry_3[0][i - 1]), 
        .cin(sum_3[1][i]),
    .sum(sum_4[i]), .cout(carry_4[i]));
end

for(i = M + 4; i <= 2 * M - 1; i = i + 1)
begin: level_4_fa_2M
    halfAdder ha_4_pre(.x(sum_3[0][i]), .y(carry_3[0][i - 1]),
    .sum(sum_4[i]), .cout(carry_4[i]));
end
endgenerate
//**** Final addition ****//
claAddSubGen #(.M(128)) finalCLAadder128(.sub(1'b0), .cin(1'b0),
    .x({sum_4[127 : 0]}), 
    .y({carry_4[126 : 0], 1'b0}), 
    .out(out[127 : 0]), .cout(), .v(),
.g(), .p());
endmodule
