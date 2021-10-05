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

// boothRecoder3.sv
// 3-bits Booth recoder (radix-4)
// 0,0,0 -> multiplicand * 0
// 0,0,1 -> multiplicand * 1
// 0,1,0 -> multiplicand * 1
// 0,1,1 -> multiplicand * 2
// 1,0,0 -> multiplicand * -2
// 1,0,1 -> multiplicand * -1
// 1,1,0 -> multiplicand * -1
// 1,1,1 -> multipilcand * 0

module boothRecoder3 
(
    input logic [2:0] in,
    output logic zero,
    output logic neg,
    output logic two
);

always_comb
begin
    case (in)
        3'b000 : begin  zero = 1;  neg = 0;  two = 0; end
        3'b001 : begin  zero = 0;  neg = 0;  two = 0; end
        3'b010 : begin  zero = 0;  neg = 0;  two = 0; end
        3'b011 : begin  zero = 0;  neg = 0;  two = 1; end
        3'b100 : begin  zero = 0;  neg = 1;  two = 1; end
        3'b101 : begin  zero = 0;  neg = 1;  two = 0; end
        3'b110 : begin  zero = 0;  neg = 1;  two = 0; end
        3'b111 : begin  zero = 1;  neg = 1;  two = 0; end
    endcase
end
endmodule
