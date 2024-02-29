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

// fpMultiplier.sv
// IEEE Floating Point multiplier

module fpMultiplier
#(parameter BITS = 32, parameter MANTISSA_BITS = 23, parameter EXPONENT_BITS = 8) // MANTISSA_BITS + EXPONENT_BITS must be equal to BITS - 1 (1 bit is for sign)
(
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
logic [MANTISSA_BITS - 1 : 0] yM;
logic [MANTISSA_BITS + 1 - 1 : 0] yMantissa; // includes hidden bit
logic [MANTISSA_BITS + 1 - 1 : 0] normalizedMantissa; // includes hidden bit
logic [MANTISSA_BITS + 1 - 1 : 0] normalizedMantissa2; // includes hidden bit
logic [MANTISSA_BITS + 1 - 1 : 0] zMantissa; // includes hidden bit
logic [2 * (MANTISSA_BITS + 1) - 1 : 0] prod; // includes hidden bit * 2
logic [EXPONENT_BITS - 1 : 0] xE; 
logic [EXPONENT_BITS - 1 : 0] xExponent; 
logic [EXPONENT_BITS - 1 : 0] yE; 
logic [EXPONENT_BITS - 1 : 0] yExponent; 
logic [EXPONENT_BITS + 1 : 0] tentativeExponent; // includes carry bit and sign bit to handle overflow and underflow
logic [EXPONENT_BITS + 1 : 0] tentativeExponent2; // includes carry bit and sign bit to handle overflow and underflow
logic [EXPONENT_BITS - 1 : 0] zExponent; 
logic [$clog2((MANTISSA_BITS + 1) * 2) - 1 : 0] normalizeShiftAmount;
logic [EXPONENT_BITS + 1 : 0] rightShiftAmount;
logic xS;
logic yS;

logic zSign;

// extra bits for round to nearest
// normalization
logic guardBit;
logic roundBit;
logic stickyBit;
// underflow recovery / right shift
logic guardBit2;
logic roundBit2;
logic stickyBit2;
logic roundFlag;

logic shiftUnderflowFlag;

// input unpacking
assign xM = x[MANTISSA_BITS - 1 : 0];
assign yM = y[MANTISSA_BITS - 1 : 0];
assign xE = x[BITS - 2 : BITS - 1 - EXPONENT_BITS];
assign yE = y[BITS - 2 : BITS - 1 - EXPONENT_BITS];
assign xS = x[BITS - 1];
assign yS = y[BITS - 1];

// output
assign out[BITS - 1] = zSign;
assign out[BITS - 2 : BITS - 1 - EXPONENT_BITS] = zExponent;
assign out[BITS - 1 - EXPONENT_BITS - 1 : 0] = zMantissa[MANTISSA_BITS + 1 - 2 : 0];

assign prod = xMantissa * yMantissa;

// Handle regular and denormal numbers
always_comb
begin: denormOrRegular
	xMantissa[MANTISSA_BITS - 1 : 0] = {xM};
	yMantissa[MANTISSA_BITS - 1 : 0] = {yM};

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

// shift amount for normalization
zeroMSBCounter #(.N(((MANTISSA_BITS + 1) * 2))) msbZerosSum(prod[(MANTISSA_BITS + 1) * 2 - 1 : 0], normalizeShiftAmount);

// round-to-nearest extra bits
//assign guardBit = (normalizeShiftAmount != 0) ? ((normalizeShiftAmount > 1) ? 1'b0 : prod[MANTISSA_BITS - 1]) : prod[MANTISSA_BITS];
assign guardBit = (normalizeShiftAmount <= MANTISSA_BITS) ? prod[MANTISSA_BITS - normalizeShiftAmount] : 1'b0;
assign roundBit = (normalizeShiftAmount <= MANTISSA_BITS - 1) ? prod[MANTISSA_BITS - 1 - normalizeShiftAmount] : 1'b0;
assign stickyBit = prod[MANTISSA_BITS - 2 : 0] != 0;

// normalized mantissa
assign normalizedMantissa = (prod[((MANTISSA_BITS + 1) * 2) - 1 : 0] << normalizeShiftAmount) >> (MANTISSA_BITS + 1);

// tentative exponent, add 1 to exponent to "move decimal point one digit to the left" as prod has form DD.ddd....d and will be interpreted as D.Dddd....d
assign tentativeExponent = {2'b00, xExponent} + {2'b00, yExponent} - exponentBias + 1 - normalizeShiftAmount;

assign shiftUnderflowFlag = $signed(tentativeExponent) < $signed(minBiasedExponent); 

assign rightShiftAmount = minBiasedExponent - tentativeExponent;

assign tentativeExponent2 = shiftUnderflowFlag ? tentativeExponent + rightShiftAmount : tentativeExponent;

assign guardBit2 = (shiftUnderflowFlag) ? (normalizedMantissa >> (rightShiftAmount - 1)) & 1 : guardBit;
assign roundBit2 = (shiftUnderflowFlag) ? rightShiftAmount > 1 ? (normalizedMantissa >> rightShiftAmount - 2) & 1 : guardBit : roundBit;
assign stickyBit2 = stickyBit | (shiftUnderflowFlag ? ((rightShiftAmount > 2) ? (normalizedMantissa >> rightShiftAmount - 3) & 1 : ((rightShiftAmount > 1) ? guardBit : roundBit)) : 0);

// normalized mantissa
assign normalizedMantissa2 = shiftUnderflowFlag ? normalizedMantissa >> rightShiftAmount : normalizedMantissa;

assign roundFlag = guardBit2 && (normalizedMantissa2[0] | roundBit2 | stickyBit2);

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
		if ((yE == zeroOrDenormBiasedExponent) && (yM == 0)) // if y is zero return NaN
		begin: infTimesZero
			zSign = 1'b0; 
			zExponent = infBiasedExponent;	
			zMantissa = {1'b0, nanMantissa};
		end
		else
		begin: xInfRes
			zSign = xS ^ yS;
			zExponent = infBiasedExponent;
			zMantissa = 0;
		end
	end
	else if (yE == infBiasedExponent) // if y is infinity
	begin: yInf
		if ((xE == zeroOrDenormBiasedExponent) && (xM == 0)) // if x is zero return NaN
		begin: ZeroTimesInf
			zSign = 1'b0;
			zExponent = infBiasedExponent;
			zMantissa = {1'b0, nanMantissa};
		end
		else
		begin: yInfRes
			zSign = xS ^ yS; 
			zExponent = infBiasedExponent;	
			zMantissa = 0;
		end
	end
	else if (((xE == zeroOrDenormBiasedExponent) && (xM == 0)) || ((yE == zeroOrDenormBiasedExponent) && (yM == 0))) // either x or y are zero
	begin: xZeroOryZero 
		zSign = xS ^ yS;
		zExponent = zeroOrDenormBiasedExponent;
		zMantissa = 0;
	end
	else // denormal number or regular number
	begin: denormOrRegularAdd
		if(roundFlag == 1'b1)
		begin: doRounding
			zMantissa = (tentativeExponent2 < infBiasedExponent) ? normalizedMantissa2 + 1 : {(MANTISSA_BITS + 1){1'b0}};
			if(normalizedMantissa2 == {(MANTISSA_BITS + 1){1'b1}}) // if carry out after rounding
			begin: roundingCarry
				if(!(tentativeExponent2 == maxBiasedExponent || tentativeExponent2 == infBiasedExponent)) // if not overflow or infinity
				begin: roundingExpPlus1
					zExponent = tentativeExponent2[EXPONENT_BITS - 1 : 0] + 1;
				end
				else
				begin: roundingInf
					zExponent = infBiasedExponent;
				end
			end
			else
			begin: roundingNoCarry
				if((tentativeExponent2 == minBiasedExponent) && (normalizedMantissa2[MANTISSA_BITS + 1 - 1] == 1'b0)) // denorm or zero
				begin: roundingDenorm
					zExponent = zeroOrDenormBiasedExponent;
				end
				else
				begin: roundingNumber
					zExponent = (tentativeExponent2 < infBiasedExponent) ? tentativeExponent2[EXPONENT_BITS - 1 : 0] : infBiasedExponent;
				end
			end
		end
		else
		begin: noRounding
			zMantissa = (tentativeExponent2 < infBiasedExponent) ? normalizedMantissa2 : {(MANTISSA_BITS + 1){1'b0}};
			if((tentativeExponent2 == minBiasedExponent) && (normalizedMantissa2[MANTISSA_BITS + 1 - 1] == 1'b0)) // denorm or zero
			begin: noRoundingDenorm
				zExponent = zeroOrDenormBiasedExponent;	
			end
			else
			begin: noRoundingNumber
				zExponent = (tentativeExponent2 < infBiasedExponent) ? tentativeExponent2[EXPONENT_BITS - 1 : 0] : infBiasedExponent;
			end
		end

		zSign = xS ^ yS;
	end
end

endmodule
