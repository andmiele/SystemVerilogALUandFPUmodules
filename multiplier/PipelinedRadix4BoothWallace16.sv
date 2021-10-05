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

// PipelinedRadix4BoothWallace16.sv
// Pipelined 16-bit unsigned/signed Radix-4 Booth Wallace tree multiplier top level

module PipelinedRadix4BoothWallace16
(
    input logic clk,
    input logic run,
    input logic signedFlag, // 1 signed, 0 unsigned 
    input logic [15 : 0] multiplicand,
    input logic [15 : 0] multiplier,
    output logic [31 : 0] out
);

localparam NPP = 16 / 2 + 1;
logic [16 + 2 - 1 : 0] pprods [0 : NPP - 1]; //    - 2m <= pp <= 2m
logic [16 + 4 - 1 : 0] pprodsExt [0 : NPP - 1];
logic [0 : NPP - 1] signsLow;
logic [32 - 1 : 0] sum_0 [0 : 2];
logic [32 - 1  : 0] carry_0 [0 : 2];
logic [32 - 1 : 0] sum_0_reg [0 : 2];
logic [32 - 1  : 0] carry_0_reg [0 : 2];
logic [32 - 2 : 0] hor_cout_0 [0 : 1];
logic [32 - 1 : 0] sum_1 [0 : 1];
logic [32 - 1  : 0] carry_1;
logic [32 - 1 : 0] sum_1_reg [0 : 1];
logic [32 - 1  : 0] carry_1_reg;
logic [32 - 2 : 0] hor_cout_1;
logic [32 - 1 : 0] sum_2;
logic [32 - 1  : 0] carry_2;
logic [32 - 1 : 0] sum_2_reg;
logic [32 - 1  : 0] carry_2_reg;
logic [32 - 2 : 0] hor_cout_2;
logic [31 : 0] out_t;
logic [31 : 0] out_reg;
pProdsGen #(.M(16), .N(16), .NPP(NPP)) pProdsGen(.signedFlag(signedFlag), .multiplicand(multiplicand), 
.multiplier(multiplier), .pprods(pprods), .signsLow(signsLow));

assign pprodsExt[0] = {~pprods[0][17], pprods[0][17], pprods[0][17 : 0]};

assign out = out_reg;

// pipeline
always_ff @(posedge clk)
begin
    if(run)
    begin
        sum_0_reg <= sum_0;
        carry_0_reg <= carry_0;
        sum_1_reg <= sum_1;
        carry_1_reg <= carry_1;
        sum_2_reg <= sum_2;
        carry_2_reg <= carry_2;
        out_reg <= out_t;
    end
end

// generate partial products and extend with sign compression values
genvar i;
generate
for(i = 1; i < NPP; i = i + 1)
begin: pProdsLoop
    assign pprodsExt[i] = {1'b1, ~pprods[i][17], pprods[i][16 : 0]}; 
end

////// tree


//**** level 0 ****//

///**** level 0 - row 0 ****///

genvar row_0;
for (row_0 = 0; row_0 <= 1; row_0 = row_0 + 1)
begin: row_0_1
    // y is low sign of pprod
    halfAdder ha_row0_0(.x(pprodsExt[row_0 * 4][0]), .y(signsLow[row_0 * 4]), 
        .sum(sum_0[row_0][row_0 * 8]), 
    .cout(carry_0[row_0][row_0 * 8]));

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
    for (col = 6; col <= 19 - row_0 * 8; col = col + 1)
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

    compressor_42 comp_0_0_20(
        .x1(pprodsExt[row_0 * 4 + 1][18 - row_0 * 8]), 
        .x2(pprodsExt[row_0 * 4 + 2][18 - row_0 * 8 - 2]), 
        .x3(pprodsExt[row_0 * 4 + 3][18 - row_0 * 8 - 4]), 
        .x4(pprodsExt[row_0 * 4 + 4][18 - row_0 * 8 - 6]), 
        .cin(hor_cout_0[row_0][19]), 
        .sum(sum_0[row_0][20]), 
        .carry(carry_0[row_0][20]),
    .cout(hor_cout_0[row_0][20]));

    genvar j;

    for (j = row_0 * 4 + 2; j <= 5; j = j + 1)
    begin: comp_tail_level_0_0

        // x is 1's complement of sign 
        compressor_42 comp_0_2j(.x1(pprodsExt[j][17 - row_0 * 8]), 
            .x2(pprodsExt[j + 1][17 - row_0 * 8 - 2]),
            .x3(pprodsExt[j + 2][17 - row_0 * 8 - 4]), 
            .x4(pprodsExt[j + 3][17 - row_0 * 8 - 6]),
            .cin(hor_cout_0[row_0][21 + ((j - (row_0 * 4 + 2)) * 2) - 1]), 
            .sum(sum_0[row_0][21 + ((j - (row_0 * 4 + 2)) * 2)]), 
            .carry(carry_0[row_0][21 + ((j - (row_0 * 4 + 2)) * 2)]), 
        .cout(hor_cout_0[row_0][21 + ((j - (row_0 * 4 + 2)) * 2)]));

        compressor_42 comp_0_2j_1(.x1(pprodsExt[j][17 - row_0 * 8 + 1]), 
            .x2(pprodsExt[j + 1][17 - row_0 * 8 + 1 - 2]), 
            .x3(pprodsExt[j + 2][17 - row_0 * 8 + 1 - 4]), 
            .x4(pprodsExt[j + 3][17 - row_0 * 8 + 1 - 6]), 
            .cin(hor_cout_0[row_0][21 + ((j - (row_0 * 4 + 2)) * 2)]), 
            .sum(sum_0[row_0][21 + ((j - (row_0 * 4 + 2)) * 2) + 1]), 
            .carry(carry_0[row_0][21 + ((j - (row_0 * 4 + 2)) * 2) + 1]), 
        .cout(hor_cout_0[row_0][21 + ((j - (row_0 * 4 + 2)) * 2) + 1]));

    end

    // FINAL TAIL ADDERS
    compressor_42 comp_0_final_0(.x1(pprodsExt[6][17 - 8 * row_0]), 
        .x2(pprodsExt[7][17 - 8 * row_0 - 2]), 
        .x3(pprodsExt[8][17 - 8 * row_0 - 4]), 
        .x4(1'b0), .cin(hor_cout_0[row_0][29 - 8 * row_0 - 1]), 
        .sum(sum_0[row_0][29 - 8 * row_0]), 
        .carry(carry_0[row_0][29 - 8 * row_0]), 
    .cout(hor_cout_0[row_0][29 - 8 * row_0]));

    compressor_42 comp_0_final_1(.x1(pprodsExt[6][18 - 8 * row_0]), 
        .x2(pprodsExt[7][18 - 8 * row_0 - 2]), 
        .x3(pprodsExt[8][18 - 8 * row_0 - 4]), 
        .x4(1'b0), .cin(hor_cout_0[row_0][30 - 8 * row_0 - 1]), 
        .sum(sum_0[row_0][30 - 8 * row_0]), 
        .carry(carry_0[row_0][30 - 8 * row_0]), 
    .cout(hor_cout_0[row_0][30 - 8 * row_0]));

    fullAdder fa_0_final_0(.x(pprodsExt[7][17 - 8 * row_0]), 
        .y(pprodsExt[8][17 - 8 * row_0 - 2]), 
        .cin(hor_cout_0[row_0][31 - 8 * row_0 - 1]), 
        .sum(sum_0[row_0][31 - 8 * row_0]), 
    .cout(carry_0[row_0][31 - 8 * row_0])); 

    for(j = 0; j < (row_0); j = j + 4)
    begin: fm
        halfAdder ha_0_final_1(.x(pprodsExt[7][18 - 8 * row_0]), 
            .y(pprodsExt[8][18 - 8 * row_0 - 2]),  
            .sum(sum_0[row_0][31 + 1 - 8 * row_0]), 
        .cout(carry_0[row_0][31 + 1 - 8 * row_0]));
    end

end // end row_0 for

// pprod NPP pass-through 
assign carry_0[0][1] = 1'b0;

assign sum_0[0][1] = pprodsExt[0][1];
assign sum_0[1][9] = pprodsExt[4][1];
assign sum_0[1][6] = signsLow[3];
assign sum_0[1][25] = pprodsExt[NPP - 1][9];
assign sum_0[1][26] = pprodsExt[NPP - 1][10];
assign sum_0[NPP /4][14] = signsLow[NPP - 2];

genvar j;
for(j = 0; j < 4; j = j + 1) 
begin: pProdsExtLoop
    assign sum_0[NPP / 4][16 + j] = pprodsExt[NPP - 1][j];
end
///END **** level 0 - row 0 - 1 ****///


///**** level 1 (row 0, 1)****///

// PASS-THROUGHS
// sum and carry values for final addition

for(i = 0; i <= 5; i++)
begin: level_1_sumPassThroughs
    assign sum_1[0][i] = sum_0_reg[0][i];
end
for(i = 0; i <= 4; i++)
begin: level_1_carryPassThroughs
    assign carry_1[i] = carry_0_reg[0][i];
end
assign carry_1[5] = 1'b0;

fullAdder fa_pre_row_1_6(.x(sum_0_reg[0][6]),
    .y(carry_0_reg[0][5]), 
    .cin(sum_0_reg[1][6]), 
    .sum(sum_1[0][6]), 
.cout(carry_1[6]));

halfAdder ha_pre_row_1_7(.x(sum_0_reg[0][7]),
    .y(carry_0_reg[0][6]), 
    .sum(sum_1[0][7]), 
.cout(carry_1[7]));

fullAdder fa_pre_row_1_8(.x(sum_0_reg[0][8]),
    .y(carry_0_reg[0][7]), 
    .cin(sum_0_reg[1][8]), 
    .sum(sum_1[0][8]), 
.cout(carry_1[8]));

compressor_42 ca_pre_row_1_9(.x1(sum_0_reg[0][9]), 
    .x2(carry_0_reg[0][8]), 
    .x3(sum_0_reg[1][9]),
    .x4(carry_0_reg[1][8]),
    .cin(1'b0),
    .sum(sum_1[0][9]), 
    .carry(carry_1[9]),
.cout(hor_cout_1[9]));

compressor_42 ca_pre_row_1_10(.x1(sum_0_reg[0][10]), 
    .x2(carry_0_reg[0][9]), 
    .x3(sum_0_reg[1][10]),
    .x4(1'b0),
    .cin(hor_cout_1[9]),
    .sum(sum_1[0][10]), 
    .carry(carry_1[10]),
.cout(hor_cout_1[10]));

// MIDDLE

for(j = 11; j <= 24; j = j + 1)
begin: level_1_11_24
    compressor_42 comp_1_middle(.x1(sum_0_reg[0][j]), 
        .x2(carry_0_reg[0][j - 1]), 
        .x3(sum_0_reg[1][j]), 
        .x4(carry_0_reg[1][j - 1]),
        .cin(hor_cout_1[j - 1]), 
        .sum(sum_1[0][j]), 
    .carry(carry_1[j]), .cout(hor_cout_1[j]));
end

compressor_42 comp_1_middle_25(.x1(sum_0_reg[0][25]), 
    .x2(carry_0_reg[0][24]), 
    .x3(sum_0_reg[1][25]), 
    .x4(carry_0_reg[1][24]), 
    .cin(hor_cout_1[24]), 
    .sum(sum_1[0][25]), 
    .carry(carry_1[25]), 
.cout(hor_cout_1[25]));

compressor_42 comp_1_middle_26(.x1(sum_0_reg[0][26]), 
    .x2(carry_0_reg[0][25]), 
    .x3(sum_0_reg[1][26]), 
    .x4(1'b0), .cin(hor_cout_1[25]), 
    .sum(sum_1[0][26]), 
    .carry(carry_1[26]), 
.cout(hor_cout_1[26]));

//TAIL
fullAdder fa_1_tail_27(.x(sum_0_reg[0][27]), 
    .y(carry_0_reg[0][26]), 
    .cin(hor_cout_1[26]), 
    .sum(sum_1[0][27]), 
.cout(carry_1[27]));

for(j = 28 ; j <= 31; j = j + 1)
begin: level_1_28_31
    halfAdder ha_1_tail(.x(sum_0_reg[0][j]), .y(carry_0_reg[0][j - 1]), 
        .sum(sum_1[0][j]), 
    .cout(carry_1[j]));
end

// PASS-THROUGHS

assign sum_1[1][14] = sum_0_reg[2][14];

for(j = 0; j < 4; j = j + 1) 
begin: level_1_16_PassThroughs
    assign sum_1[1][16 + j] = sum_0_reg[2][16 + j];
end
///**** END level 1 ****///

///**** level 2 ****///

// PASS-THROUGHS
// sum and carry values for final addition
for(i = 0; i <= 13; i++)
begin: level_2_sumPassThroughs
    assign sum_2[i] = sum_1_reg[0][i];
end

for(i = 0; i <= 12; i++)
begin: level_2_carryPassThroughs
    assign carry_2[i] = carry_1_reg[i];
end

assign carry_2[13] = 1'b0;

fullAdder fa_pre_2_14(.x(sum_1_reg[0][14]),
    .y(carry_1_reg[13]), 
    .cin(sum_1_reg[1][14]), 
    .sum(sum_2[14]), 
.cout(carry_2[14]));

halfAdder ha_pre_2_15(.x(sum_1_reg[0][15]),
    .y(carry_1_reg[14]), 
    .sum(sum_2[15]), 
.cout(carry_2[15]));

for(j = 16; j <= 19; j = j + 1)
begin: fa_middle_2
    fullAdder fa_middle_2_j(.x(sum_1_reg[0][j]), 
        .y(carry_1_reg[j - 1]),
        .cin(sum_1_reg[1][j]),  
        .sum(sum_2[j]), 
    .cout(carry_2[j]));
end

// TAIL
for(j = 20; j <= 31; j = j + 1)
begin: ha_tail_2
    halfAdder ha_tail_2_j(.x(sum_1_reg[0][j]), 
        .y(carry_1_reg[j - 1]),  
        .sum(sum_2[j]), 
    .cout(carry_2[j]));
end
///**** END level 2 ****///
endgenerate
//**** Final addition ****//
claAddSubGen #(.M(32)) finalCLAadder16(.sub(1'b0), .cin(1'b0),
    .x(sum_2_reg[31 : 0]), 
    .y({carry_2_reg[30 : 0], 1'b0}), 
    .out(out_t[31 : 0]), .cout(), .v(),
.g(), .p());
endmodule
