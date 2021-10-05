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

// intSqrt.sv
// generic integer square root

module intSqrt
#(
	parameter N = 32
)
(
	input logic rst,
	input logic clk,
	input logic start,
	input logic [N - 1 : 0] in,
	output logic [N - 1 : 0] out,
	output logic done
);

logic [N - 1 : 0] rem;
logic [N - 1 : 0] prod;
logic [N - 1 : 0] sqrt;
logic [N - 1 : 0] currentBit;
logic [$size(N) : 0] count;
typedef enum {RESET, START, RUN, DONE} State;
State state;
logic doneReg;



assign done = doneReg;
assign out = sqrt;
assign prod = sqrt + currentBit;

always_ff @(posedge clk)
begin: FSM

	if(rst)
	begin
		doneReg <= 1'b0;
		state <= RESET;
	end
	else
	begin
		case (state)
			RESET:
			begin
				sqrt <= 'b0;
				rem <= 'b0;
				doneReg <= 1'b0;
				count <= 0;
				currentBit <= 'b0;        
				if(start)
					state <= START;
				else 
					state <= RESET;  
			end
			START:
			begin
				// largest power of 4 less than 2^N
				currentBit <= {(N & 1), !(N & 1), {(N - 2) {1'b0}}};
				rem <= in;
				state <= RUN;
			end
			RUN:
			begin
				if(count == $size(N) / 2 + N % 2 + 1)
				begin
					state <= DONE;
					doneReg <= 1'b1;
				end
				else
				begin

					if(rem >= prod)
					begin
						rem <= rem - prod;
						sqrt <= sqrt[N - 1 : 1] + currentBit;
					end
					else
					begin
						// right shift
						sqrt <= {1'b0, sqrt[N - 1 : 1]};
					end
					// shift by 2
					currentBit[N - 1 : 0] <= {2'b00, currentBit[N - 1 : 2]};

					count <= count + 1;
				end
			end
			DONE:
			begin
				state <= DONE;
			end
		endcase

	end
end

endmodule
