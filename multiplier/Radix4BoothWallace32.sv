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

// Radix4BoothWallace32.sv
// 32-bit unsigned/signed Radix-4 Booth Wallace tree multiplier top level

module Radix4BoothWallace32
(
    input logic signedFlag, // 1 signed, 0 unsigned 
    input logic [32 - 1 : 0] multiplicand,
    input logic [32 - 1 : 0] multiplier,
    output logic [64 - 1 : 0] out
);

localparam M = 32;
localparam NPP = M / 2 + 1;
logic [M + 2 - 1 : 0] pprods [0 : NPP - 1]; //    - 2m <= pp <= 2m
logic [M + 4 - 1 : 0] pprodsExt [0 : NPP - 1];
logic [0 : NPP - 1] signsLow;
logic [2 * M - 1 : 0] sum_0 [0 : NPP /4];
logic [2 * M - 1  : 0] carry_0 [0 : NPP / 4];
logic [2 * M - 2 : 0] hor_cout_0 [0 : NPP / 4];
logic [2 * M - 1 : 0] sum_1 [0 : NPP / 8];
logic [2 * M - 1  : 0] carry_1 [0 : NPP / 8];
logic [2 * M - 2 : 0] hor_cout_1 [0 : NPP / 8];
logic [2 * M - 1 : 0] sum_2 [0 : NPP / 16];
logic [2 * M - 1  : 0] carry_2 [0 : NPP / 16];
logic [2 * M - 2 : 6] hor_cout_2 [0 : NPP / 16];
logic [2 * M - 1 : 0] sum_3 [0 : NPP / M];
logic [2 * M - 1  : 0] carry_3 [0 : NPP / M];
logic [M - 3 : 14] hor_cout_3 [0 : NPP / M];

pProdsGen #(.M(M), .N(M), .NPP(NPP)) pProdsGen(.signedFlag(signedFlag), .multiplicand(multiplicand), 
.multiplier(multiplier), .pprods(pprods), .signsLow(signsLow));

assign pprodsExt[0] = {~pprods[0][M + 1], pprods[0][M + 1], pprods[0][M + 1 : 0]};

// generate partial products and extend with sign compression values
genvar i;
generate
for(i = 1; i < NPP; i = i + 1)
begin: pProdsLoop
    assign pprodsExt[i] = {1'b1, ~pprods[i][M + 1], pprods[i][M : 0]}; 
end

////// tree


///**** level 0, rows 0 - 3 ****///

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
    begin: middle
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
    begin: comp_tail_level_0_0

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
    begin: fm
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
begin: level_0_pprodPassThroughs
    assign sum_0[NPP / 4][M + j] = pprodsExt[NPP - 1][j];
end

///END **** level 0 - row 0 - 3 ****///


///**** level 1: row 0 - NPP / 8 - 1 ****///

// PASS-THROUGHS
// sum and carry values for final addition
for(i = 0; i <= 5; i++)
begin: level_1_sum_PassThroughs
    assign sum_1[0][i] = sum_0[0][i];
end
for(i = 0; i <= 4; i++)
begin: level_1_carry_PassThroughs
    assign carry_1[0][i] = carry_0[0][i];
end
assign carry_1[0][5] = 1'b0;

genvar row_1;

// row >= 1 only PREAMBLE halfAdder / assign
for(row_1 = 1; row_1 < NPP / 8 ; row_1 = row_1 + 1)
begin: level_0_preamble

    halfAdder ha_pre_row_1_1(.x(sum_0[2 * row_1][16 * row_1 + 1]), 
        .y(carry_0[2 * row_1][16 * row_1]), 
    .sum(sum_1[row_1][16 * row_1 + 1]), .cout(carry_1[row_1][16 * row_1 + 1]));

    for(j = 3; j <= 5; j = j + 1)
    begin: level_0_preamble_3_5
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
begin: level_0_rows

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

    //assign hor_cout_1[row_1][9 + 16 * row_1] = 1'b0;

    for(j = 11 + 16 * row_1; j <= 2 * M - 7 - 16 * row_1; j = j + 1)
    begin: level_0_1_middle
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
    begin: level_0_1_tail
        halfAdder ha_1_tail(.x(sum_0[row_1 * 2][j]), .y(carry_0[row_1 * 2][j - 1]), 
            .sum(sum_1[row_1][j]), 
        .cout(carry_1[row_1][j]));
    end

end // end row_1 for 

assign sum_1[NPP / 8][M - 2] = sum_0[NPP / 4][M - 2];
for(j = 0; j < 4; j = j + 1) 
begin: level_1_endSumPassThroughs
    assign sum_1[NPP / 8][M + j] = sum_0[NPP / 4][M + j];
end

///**** END level 1 ****///


///**** level 2 ****///

// PASS-THROUGHS
// sum and carry values for final addition
for(i = 0; i <= 13; i++)
begin: level_2_sum_PassThroughs
    assign sum_2[0][i] = sum_1[0][i];
end

for(i = 0; i <= 12; i++)
begin: level_2_carry_PassThroughs
    assign carry_2[0][i] = carry_1[0][i];
end
assign carry_2[0][13] = 1'b0;

fullAdder fa_2_pre_14(.x(sum_1[0][14]), .y(carry_1[0][13]),
.cin(sum_1[1][14]), .sum(sum_2[0][14]), .cout(carry_2[0][14]));

halfAdder ha_2_pre_15(.x(sum_1[0][15]), .y(carry_1[0][14]),
.sum(sum_2[0][15]), .cout(carry_2[0][15]));

fullAdder fa_2_pre_16(.x(sum_1[0][16]), .y(carry_1[0][15]),
.cin(sum_1[1][16]), .sum(sum_2[0][16]), .cout(carry_2[0][16]));

fullAdder fa_2_pre_17(.x(sum_1[0][17]), .y(carry_1[0][16]),
.cin(sum_1[1][17]), .sum(sum_2[0][17]), .cout(carry_2[0][17]));

compressor_42 comp_2_pre_18(.x1(sum_1[0][18]), 
    .x2(carry_1[0][17]),
    .x3(sum_1[1][18]), 
    .x4(carry_1[1][17]), 
    .cin(1'b0),
    .sum(sum_2[0][18]), 
    .carry(carry_2[0][18]), 
.cout(hor_cout_2[0][18]));

compressor_42 comp_2_pre_19(.x1(sum_1[0][19]), 
    .x2(carry_1[0][18]),
    .x3(sum_1[1][19]), 
    .x4(1'b0), 
    .cin(hor_cout_2[0][18]),
    .sum(sum_2[0][19]), 
    .carry(carry_2[0][19]), 
.cout(hor_cout_2[0][19]));

for(i = 20; i <= 50; i = i + 1)
begin: comp_2_20_50
    compressor_42 comp_2(.x1(sum_1[0][i]), .x2(carry_1[0][i - 1]),
        .x3(sum_1[1][i]), 
        .x4(carry_1[1][i - 1]), 
        .cin(hor_cout_2[0][i - 1]),
    .sum(sum_2[0][i]), .carry(carry_2[0][i]), .cout(hor_cout_2[0][i]));
end

fullAdder fa_2_pre_51(.x(sum_1[0][51]), .y(carry_1[0][50]),
.cin(hor_cout_2[0][50]), .sum(sum_2[0][51]), .cout(carry_2[0][51]));

for(i = 52; i <= 63; i = i + 1)
begin: level_2_52_63
    halfAdder ha_2_pre_51(.x(sum_1[0][i]), .y(carry_1[0][i - 1]),
    .sum(sum_2[0][i]), .cout(carry_2[0][i]));
end

assign sum_2[NPP / 16][M - 2] = sum_1[NPP / 8][M - 2]; // signsLow

for(j = 0; j < 4; j = j + 1) 
begin: level_2_endSumPassThroughs
    assign sum_2[NPP / 16][M + j] = sum_1[NPP / 8][M + j];
end
///END **** level 2 ****///


///*** level 3 ***///

// PASS-THROUGHS
// sum and carry values for final addition
for(i = 0; i <= M - 3; i++)
begin: level_3_sum_PassThroughs
    assign sum_3[0][i] = sum_2[0][i];
end

for(i = 0; i <= M - 4; i++)
begin: level_3_carry_PassThroughs
    assign carry_3[0][i] = carry_2[0][i];
end
assign carry_3[0][M - 3] = 1'b0;

fullAdder fa_3_M_2(.x(sum_2[0][M - 2]), .y(carry_2[0][M - 3]), 
    .cin(sum_2[1][M - 2]),
.sum(sum_3[0][M - 2]), .cout(carry_3[0][M - 2]));

halfAdder ha_3_M_1(.x(sum_2[0][M - 1]), .y(carry_2[0][M - 2]),
.sum(sum_3[0][M - 1]), .cout(carry_3[0][M - 1]));

for(i = M; i <= M + 3; i = i + 1)
begin: level_2_fa
    fullAdder fa_3_pre(.x(sum_2[0][i]), .y(carry_2[0][i - 1]), 
        .cin(sum_2[1][i]),
    .sum(sum_3[0][i]), .cout(carry_3[0][i]));
end
for(i = M + 4; i <= 63; i = i + 1)
begin: level_2_fa_63
    halfAdder fa_3_pre(.x(sum_2[0][i]), .y(carry_2[0][i - 1]),
    .sum(sum_3[0][i]), .cout(carry_3[0][i]));
end
///END **** level 3 ****///
endgenerate

//**** Final addition ****//
claAddSubGen #(.M(2 * M)) finalCLAadder64(.sub(1'b0), .cin(1'b0),
    .x({sum_3[0][63 : 0]}), 
    .y({carry_3[0][62 : 0], 1'b0}), 
    .out(out[63: 0]), .cout(), .v(),
.g(), .p());
endmodule
