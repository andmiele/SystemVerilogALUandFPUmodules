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

// fpAdderSubtractor.sv
// IEEE Floating Point adder-subtractor

module fpAdderSubtractor
#(parameter BITS = 32, parameter MANTISSA_BITS = 23, parameter EXPONENT_BITS = 8) // MANTISSA_BITS + EXPONENT_BITS must be equal to BITS - 1 (1 bit is for sign)
(
 input logic sub,
 input logic [BITS - 1 : 0] x,
 input logic [BITS - 1 : 0] y,
 output logic [BITS - 1 : 0] out
 );

localparam exponentBias = (1 << (EXPONENT_BITS - 1)) - 1;
localparam maxExponent = (1 << (EXPONENT_BITS - 1)) - 1;
localparam minExponent = 1 - maxExponent;
localparam minBiasedExponent = minExponent + exponentBias;
localparam maxBiasedExponent = maxExponent + exponentBias;
localparam infExponent = maxExponent + 1;
localparam infBiasedExponent = maxExponent + 1 + exponentBias;
localparam zeroOrDenormBiasedExponent = minExponent - 1 + exponentBias;
localparam nanMantissa = 1 << (MANTISSA_BITS - 1); // must be different than 0

logic [MANTISSA_BITS - 1 : 0] xM;
logic [MANTISSA_BITS + 1 - 1 : 0] xMantissa; // includes hidden bit
logic [MANTISSA_BITS + 4 - 1 : 0] xAlignedMantissa; // includes hidden bit and additional 3 bits for "round to nearest"
logic [MANTISSA_BITS - 1 : 0] yM;
logic [MANTISSA_BITS + 1 - 1 : 0] yMantissa; // includes hidden bit
logic [MANTISSA_BITS + 4 - 1 : 0] yAlignedMantissa; // includes hidden bit and additional 3 bits for "round to nearest"
logic [MANTISSA_BITS + 1 - 1 : 0] normalizedMantissa; // includes hidden bit
logic [MANTISSA_BITS + 1 - 1 : 0] zMantissa; // includes hidden bit
logic [MANTISSA_BITS + 5 - 1 : 0] sum;       // includes carry bit, hidden bit and additional 3 bits for "round to nearest"
logic [MANTISSA_BITS + 5 - 1 : 0] xPlusY;    // includes carry bit, hidden bit and additional 3 bits for "round to nearest"
logic [MANTISSA_BITS + 5 - 1 : 0] xMinusY;   // includes carry bit, hidden bit and additional 3 bits for "round to nearest"
logic [MANTISSA_BITS + 5 - 1 : 0] yMinusX;   // includes carry bit, hidden bit and additional 3 bits for "round to nearest"
logic [EXPONENT_BITS - 1 : 0] xE; 
logic [EXPONENT_BITS - 1 : 0] xExponent; 
logic [EXPONENT_BITS - 1 : 0] xAlignedExponent; 
logic [EXPONENT_BITS - 1 : 0] yE; 
logic [EXPONENT_BITS - 1 : 0] yExponent; 
logic [EXPONENT_BITS - 1 : 0] yAlignedExponent; 
logic [EXPONENT_BITS - 1 : 0] tentativeExponent; 
logic [EXPONENT_BITS - 1 : 0] zExponent; 
logic [$clog2(MANTISSA_BITS + 4) - 1 : 0] normalizeShiftAmountSum;
logic [$clog2(MANTISSA_BITS + 4) - 1 : 0] shiftAmount;
logic xS;
logic xSign;
logic yS;
logic ySign;
logic xHiddenBit;
logic yHiddenBit;

logic zSign;
logic sumSign;
logic overflow;

// extra bits for round to nearest
logic guardBit;
logic roundBit;
logic stickyBit;
logic roundFlag;


// input unpacking
assign xM = x[MANTISSA_BITS - 1 : 0];
assign yM = y[MANTISSA_BITS - 1 : 0];
assign xE = x[BITS - 2 : BITS - 1 - EXPONENT_BITS];
assign yE = y[BITS - 2 : BITS - 1 - EXPONENT_BITS];
assign xS = x[BITS - 1];
assign yS = y[BITS - 1] ^ sub; // if subtraction, invert sign

// output
assign out[BITS - 1] = zSign;
assign out[BITS - 2 : BITS - 1 - EXPONENT_BITS] = zExponent;
assign out[BITS - 1 - EXPONENT_BITS - 1 : 0] = zMantissa[MANTISSA_BITS + 1 - 2 : 0];

assign xPlusY = xAlignedMantissa + yAlignedMantissa;
assign xMinusY = xAlignedMantissa - yAlignedMantissa;
assign yMinusX = yAlignedMantissa - xAlignedMantissa;

// Handle regular and denormal numbers
always_comb
begin: denormOrRegular
	xMantissa[MANTISSA_BITS - 1 : 0] = {xM};
	yMantissa[MANTISSA_BITS - 1 : 0] = {yM};
	xSign = xS;
	ySign = yS;

	if (xE == zeroOrDenormBiasedExponent) // x is denormal, set exponent to min
	begin: xDenorm
		xExponent = minBiasedExponent;
		xMantissa[MANTISSA_BITS] = 1'b0;					
	end
	else // x is regular, set hidden bit to 1
	begin: xRegular
		xExponent = xE;
		xMantissa[MANTISSA_BITS] = 1'b1;					
	end
	if (yE == zeroOrDenormBiasedExponent) // y is denormal, set exponent to min
	begin: yDenorm
		yExponent = minBiasedExponent;
		yMantissa[MANTISSA_BITS] = 1'b0;					
	end
	else // y is regular, set hidden bit to 1
	begin: yRegular
		yExponent = yE;
		yMantissa[MANTISSA_BITS] = 1'b1;					
	end
end

// Align mantissas and exponents
always_comb
begin: align
	if(xExponent > yExponent)
	begin: xExpGreater
		if((xExponent - yExponent) >= (MANTISSA_BITS + 4))
		begin: shiftAllOutYMantissa
			yAlignedMantissa[MANTISSA_BITS + 4 - 1 : 1] = 0;
			yAlignedMantissa[0] = (yMantissa != 0);
		end
		else
		begin: shiftYMantissa
			// sticky bit, use mask to check if bits shifted out after the 2nd one are not all zero
			yAlignedMantissa[0] = (xExponent - yExponent) > 2 ?  (yMantissa  & ((1 << (xExponent - yExponent - 2)) - 1)) != 0 : 1'b0; 
			yAlignedMantissa[MANTISSA_BITS + 4 - 1 : 1] = {yMantissa, 2'b00} >> (xExponent - yExponent); 
		end
		yAlignedExponent = xExponent;
        	xAlignedMantissa = {xMantissa, 3'b0};
        	xAlignedExponent = xExponent;
	end        	

	else if(yExponent > xExponent)
	begin: yExpGreater
		if(yExponent - xExponent > (MANTISSA_BITS + 4))
		begin: shiftAllOutXMantissa
			xAlignedMantissa[MANTISSA_BITS + 4 - 1 : 1] = 0;
			xAlignedMantissa[0] = (xMantissa != 0);
		end
		else
		begin: shiftXMantissa
			// sticky bit, use mask to check if bits shifted out after the 2nd one are not all zero
			xAlignedMantissa[0] = (yExponent - xExponent) > 2 ? (xMantissa & ((1 << (yExponent - xExponent - 2)) - 1)) != 0 : 1'b0; 
			xAlignedMantissa[MANTISSA_BITS + 4 - 1 : 1] = {xMantissa, 2'b00} >> (yExponent - xExponent); 
		end
		xAlignedExponent = yExponent;
        	yAlignedMantissa = {yMantissa, 3'b0};
		yAlignedExponent = yExponent;
	end
	else
	begin: sameExp
		xAlignedMantissa = {xMantissa, 3'b0};
		xAlignedExponent = xExponent;
		yAlignedMantissa = {yMantissa, 3'b0};
		yAlignedExponent = yExponent;
	end
end  	

// sum / subtract aligned mantissas and determine sign
always_comb
begin: sumAndSign
	if(xSign == ySign)
	begin: sameSign
		sum = xPlusY;
		sumSign =  xSign;
	end
	else
	begin: differentSign
		if(xAlignedMantissa >= yAlignedMantissa)
		begin: xMantissaLarger
			sum = xMinusY;
			sumSign = xSign;
		end
		else
		begin: yMantissaLarger
			sum = yMinusX;
			sumSign = ySign;
		end
	end
end

// overflow detection
assign overflow = (xSign == ySign) & sum[MANTISSA_BITS + 5 - 1];

// shift amount for normalization
zeroMSBCounter #(.N(MANTISSA_BITS + 4)) msbZerosSum(sum[MANTISSA_BITS + 4 - 1 : 0], normalizeShiftAmountSum);

// corrected shift amount for normalization
assign shiftAmount = (normalizeShiftAmountSum < xAlignedExponent) ? normalizeShiftAmountSum : xAlignedExponent - 1;

// round-to-nearest extra bits
assign guardBit = overflow ? sum[3] : (shiftAmount != 0) ? ((shiftAmount > 1) ? 1'b0 : sum[1]) : sum[2];
assign roundBit = overflow ? sum[2] : (shiftAmount != 0) ? 1'b0 : sum[1];
assign stickyBit = overflow ? sum[1] | sum[0] : sum[0];
assign roundFlag = guardBit && (normalizedMantissa[0] | roundBit | stickyBit);

// normalized mantissa
assign normalizedMantissa = overflow ? sum[MANTISSA_BITS + 5 - 1 : 4] : (sum[MANTISSA_BITS + 4 - 1 : 1] << shiftAmount) >> 2;
// tentative exponent
assign tentativeExponent = overflow ? xAlignedExponent + 1 : xAlignedExponent - shiftAmount;

always_comb
begin: handleCases
	if (((xE == infBiasedExponent) && (xM != 0)) ||  ((yE == infBiasedExponent) && (yM != 0)))
	begin: NaN
		zSign = 1'b0; 
		zExponent = infBiasedExponent;	
		zMantissa = {1'b0, nanMantissa};
	end
	// if x is infinity
	else if (xE == infBiasedExponent) // xM == 0
	begin: xInf
		if ((yE == infBiasedExponent) && (xS != yS)) // yM == 0, -inf + inf, result is NaN
		begin: oppositeInf
			zSign = 1'b1; 
			zExponent = infBiasedExponent;	
			zMantissa = {1'b0, nanMantissa};
		end
		else
		begin: xInfRes
			zSign = xS;
			zExponent = infBiasedExponent;
			zMantissa = 0;
		end
	end
	else if (yE == infBiasedExponent) // if y is infinity, result is y (plus or minus infinity)
	begin: yInf
		zSign = yS;
		zExponent = infBiasedExponent;
		zMantissa = 0;
	end
	else if ((xE == zeroOrDenormBiasedExponent) && (xM == 0) && (yE == zeroOrDenormBiasedExponent) && (yM == 0)) // both x and y are zero
	begin: xZero_yZero 
		zSign = xS & yS;
		zExponent = zeroOrDenormBiasedExponent;
		zMantissa = 0;
	end
	else if ((xE == zeroOrDenormBiasedExponent) && (xM == 0)) // x is zero, return y
	begin: xZero
		zSign = yS;
		zExponent = yE;
		zMantissa = {1'b0, yM};	
	end 
	else if ((yE == zeroOrDenormBiasedExponent) && (yM == 0)) // y is zero, return x
	begin: yZero
		zSign = xS;
		zExponent = xE;
		zMantissa = {1'b0, xM};
	end 
	else // denormal number or regular number
	begin: denormOrRegularAdd
		if(roundFlag == 1'b1)
		begin: doRounding
			zMantissa = (tentativeExponent != infBiasedExponent) ? normalizedMantissa + 1 : {(MANTISSA_BITS + 1){1'b0}};
			if(normalizedMantissa == {(MANTISSA_BITS + 1){1'b1}}) // if carry out after rounding
			begin: roundingCarry
				if(!(tentativeExponent == maxBiasedExponent || tentativeExponent == infBiasedExponent)) // if not overflow or infinity
				begin: roundingExpPlus1
					zExponent = tentativeExponent + 1;
				end
				else
				begin: roundingInf
					zExponent = infBiasedExponent;
				end
			end
			else
			begin: roundingNoCarry
				if((tentativeExponent == minBiasedExponent) && (normalizedMantissa[MANTISSA_BITS + 1 - 1] == 1'b0)) // denorm or zero
				begin: roundingDenorm
					zExponent = zeroOrDenormBiasedExponent;
				end
				else
				begin: roundingNumber
					zExponent = tentativeExponent;
				end
			end
		end
		else
		begin: noRounding
			zMantissa = (tentativeExponent != infBiasedExponent) ? normalizedMantissa : {(MANTISSA_BITS + 1){1'b0}};
			if((tentativeExponent == minBiasedExponent) && (normalizedMantissa[MANTISSA_BITS + 1 - 1] == 1'b0)) // denorm or zero
			begin: noRoundingDenorm
				zExponent = zeroOrDenormBiasedExponent;	
			end
			else
			begin: noRoundingNumber
				zExponent = tentativeExponent;
			end
		end

		// sign correction for -x + x = 0
		if((tentativeExponent == minBiasedExponent) && (normalizedMantissa == {(MANTISSA_BITS + 1){1'b0}})) // zero
		begin: zeroSignCorrection
			zSign = 1'b0;
		end
		else
		begin:  nonZeroSign
			zSign = sumSign;
		end
	end
end

endmodule
