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

// pProdsGen.sv
// Partial product generation for radix-4 Booth multiplier

// Generate all partial products 

module pProdsGen
#(parameter M = 16, parameter N = 16, parameter NPP = N / 2 + 1)
(
	input logic signedFlag,
	input logic [M - 1 : 0] multiplicand,
	input logic [N - 1 : 0] multiplier,
	output logic [M + 2 - 1 : 0] pprods [0 : NPP - 1],
	output logic [0 : NPP - 1] signsLow
);

// Pad msb with 2 zeros if N is even and 1 zero if N is odd
	// add 1 0 lsb
	localparam msbZeroPadding = 2 - (N % 2);
	logic [N + msbZeroPadding : 0] paddedMultiplier;
	// sign extend for signed mul with odd N
	assign paddedMultiplier = {{msbZeroPadding{multiplier[N - 1] && (N % 2 == 1)}}, multiplier, 1'b0};

	genvar i;
	generate
	for (i = 0; i < NPP; i = i + 1)
	begin: pps
		logic zero, neg, two;
		boothRecoder3 br(paddedMultiplier[2 * (i + 1) : 2 * i], zero, neg, two);
		pProd #(.INPUT_SIZE(M), .OUTPUT_SIZE(M + 2)) pp_i (.signedFlag(signedFlag),.in(multiplicand), 
			.out(pprods[i]), .signLow(signsLow[i]), .zero(zero | ((i == (NPP - 1)) & signedFlag & (N % 2 == 0))), .neg(neg), .two(two));
	end
	endgenerate
	endmodule
