//-----------------------------------------------------------------------------
// Copyright 2024 Andrea Miele
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

// fpAdderSubtractor_tb.sv
// Testbench: fpAdderSubtractor.sv

`timescale 1 ns / 10 ps

module fpAdderSubtractor_tb;
localparam BITS = 32;
localparam MANTISSA_BITS = 23;
localparam EXPONENT_BITS = 8;

localparam exponentBias = (1 << (EXPONENT_BITS - 1)) - 1;
localparam maxExponent = (1 << (EXPONENT_BITS - 1)) - 1;
localparam minExponent = 1 - maxExponent;
localparam minBiasedExponent = minExponent + exponentBias;
localparam maxBiasedExponent = maxExponent + exponentBias;
localparam infExponent = maxExponent + 1;
localparam infBiasedExponent = maxExponent + 1 + exponentBias;
localparam zeroOrDenormBiasedExponent = minExponent - 1 + exponentBias;
localparam nanMantissa = 1 << (MANTISSA_BITS - 1); // must be different than 0

localparam period = 10; // clock period for testbench

logic [BITS - 1 : 0] x;
logic [BITS - 1 : 0] y;
logic [BITS - 1 : 0] out;
logic [BITS - 1 : 0] expectedOut;
logic sub;
logic passed;
integer i, j, f;
string testDescription;

fpAdderSubtractor #(.BITS(BITS), .MANTISSA_BITS(MANTISSA_BITS), .EXPONENT_BITS(EXPONENT_BITS)) UUT(.sub(sub), 
.x(x), .y(y), .out(out));

initial 
begin
    passed = 1'b1;
    f = $fopen("tv32.csv", "r");
    i = 0;
    j = $fscanf(f,"%b,%b,%b,%b,%s\n", x, y, expectedOut, sub, testDescription);
    while(j > 0) 
    begin
    #period
       	// Not-A-Number (NaN)
        if ((expectedOut[BITS - 2 : BITS - 1 - EXPONENT_BITS] == UUT.infBiasedExponent) && (expectedOut[BITS - 1 - EXPONENT_BITS - 1 : 0] != 0))
        begin: NaNInput
        	if (!((out[BITS - 2 : BITS - 1 - EXPONENT_BITS] == infBiasedExponent) && (out[BITS - 1 - EXPONENT_BITS - 1 : 0] != 0)))
		passed = 1'b0;
	end
	else
	begin: notNaNInput
        	if (out !== expectedOut)
			passed = 1'b0;
	end
	if(passed == 1'b0)
        begin: failedTest
                if(sub == 1'b0)
			$display("FP ADDITION TEST FAILED [i: %d, %s]\nx: %b\ny: %b\nout: %b\nexp: %b\n", i, testDescription, x, y, out, expectedOut);
                else
			$display("FP SUBTRACTION TEST FAILED [i: %d, %s]\nx: %b\ny: %b\nout: %b\nexp: %b\n", i, testDescription, x, y, out, expectedOut);
	        $display("xMantissa: %b\nyMantissa: %b\nxExponent: %b\nyExponent: %b\nsum: %b\n", UUT.xAlignedMantissa, UUT.yAlignedMantissa, UUT.xAlignedExponent, UUT.xExponent, UUT.sum);
                $finish;
        end
        i = i + 1;
        j = $fscanf(f,"%b,%b,%b,%b,%s\n", x, y, expectedOut, sub, testDescription);
    end

    if (passed == 1'b1)
    begin
        $display("TEST PASSED (%d tests)!\n", i);
    end
    else
    begin
        $display("TEST FAILED!\n");
    end
    $finish;
end

endmodule
