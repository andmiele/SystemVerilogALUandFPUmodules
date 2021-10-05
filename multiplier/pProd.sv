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

// pProd.sv
// Single partial product generation for radix-4 Booth multiplier

// Generate input, -input, 0, 2 * input or - 2 * input based on input flags
// negative values are just 1's complement, remember to add 1 in addition tree

module pProd
#(parameter INPUT_SIZE = 16, parameter OUTPUT_SIZE = INPUT_SIZE + 2)
(
	input logic signedFlag,
	input logic [INPUT_SIZE - 1 : 0] in,
	output logic [OUTPUT_SIZE - 1 : 0] out,
	output logic signLow,
	input logic zero,
	input logic neg,
	input logic two
);

logic [OUTPUT_SIZE - 1 : 0] res;
always_comb
begin
	if (zero == 1)
	begin
		out = {OUTPUT_SIZE {1'b0}};
		res = {OUTPUT_SIZE {1'b0}};		
		signLow = 1'b0;
	end

	else
	begin
		if (two == 1)
			res = {{OUTPUT_SIZE - INPUT_SIZE - 1 {signedFlag & in[INPUT_SIZE - 1]}}, in[INPUT_SIZE - 1 : 0], 1'b0};
		else
			res = {{OUTPUT_SIZE - INPUT_SIZE {signedFlag & in[INPUT_SIZE - 1]}}, in}; 
		if (neg == 1)
			res[OUTPUT_SIZE - 1 : 0] = ~res[OUTPUT_SIZE - 1 : 0];
		else
			res[OUTPUT_SIZE - 1 : 0] = res[OUTPUT_SIZE - 1 : 0];
		out[OUTPUT_SIZE - 2 : 0] = res[OUTPUT_SIZE - 2 : 0];
		if (signedFlag == 1)
			out[OUTPUT_SIZE - 1] = neg != in[INPUT_SIZE - 1];
		else
			out[OUTPUT_SIZE - 1] = res[OUTPUT_SIZE - 1];
		signLow = neg;
	end

end
endmodule
