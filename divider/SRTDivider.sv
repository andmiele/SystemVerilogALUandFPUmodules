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

// SRTDivider.sv
// generic integer SRT divider

module SRTDivider
#(
    parameter N = 32
)
(
    input logic rst,
    input logic clk,
    input logic start,
    input logic signedInput,
    input logic [N - 1 : 0] x,
    input logic [N - 1 : 0] y,
    output logic [N - 1 : 0] q,
    output logic [N - 1 : 0] r,
    output logic done,
    output logic divByZeroEx
);

typedef enum {RESET, START, RUN, DONE} State;
State state;
logic doneReg;
logic divByZeroExReg;
logic [N - 1 : 0] qnReg;
logic [N - 1 : 0] yReg;
logic [2 * N + 1 : 0] rxqReg;
logic [$size(N) : 0] counter;
logic ySign;
logic [$size(N) : 0] shiftY;
logic [$size(N) : 0] shiftYReg;
logic [N - 1 : 0] yAbs;
logic [N + 1 : 0] cReg;
logic [N + 1: 0] ca;
logic [N + 1: 0] sa;
logic [N + 1: 0] cs;
logic [N + 1: 0] ss;
logic [3 : 0] r4;
logic [2 * N + 1 : 0] rxVar;
logic [N : 0] sum;

// outputs
assign q = rxqReg[N - 1 : 0];
assign r = rxqReg[2 * N - 1 : N];
assign done = doneReg;
assign divByZeroEx = divByZeroExReg;

assign sum = rxqReg[2 * N : N] + {cReg[N : 0]};
assign r4 = rxqReg[2 * N + 1 : 2 * N - 2] + cReg[N + 1  : N - 2];
assign yAbs = (y[N - 1] & signedInput) ? -y : y;

zeroMSBCounter #(N) zmsb(.x(yAbs), .out(shiftY));
csAddSubGen #(N + 2) csadd(.sub(!r4[3]), .cin({cReg[N : 0], 1'b0}), .x(rxqReg[2 * N : N - 1]), .y({2'b00, yReg}), 
.s(sa), .c(ca));

// signed shift
always_comb
begin: signedShift
    rxVar = x <<< shiftY;
end

always_ff @(posedge clk)
begin: FSM
    integer i;
    if(rst)
    begin
        state <= RESET;
        doneReg <= 1'b0;
    end
    else 
    begin
        case (state)
            RESET:
            begin
                counter <= '0;
                rxqReg <= '0;
                yReg <= '0;
                qnReg <= '0;
                cReg <= '0;
                doneReg <= 1'b0;
                divByZeroExReg <= 1'b0;
                if(start)
                    state <= START;
                else 
                    state <= RESET;  
            end
            START:
            begin
                shiftYReg <= shiftY;
                yReg      <= yAbs << shiftY;
                ySign <= y[N - 1];
                rxqReg  <=   rxVar;
                if (y == {N{1'b0}})
                begin
                    doneReg <= 1'b1;
                    divByZeroExReg <= 1'b1;
                    state <= DONE;  
                end
                else
                    state <= RUN;
            end
            DONE:
            begin
                state <= DONE;
            end
            RUN:
            begin
                if (counter == N)
                begin
                    if(sum[N])
                    begin
                        rxqReg[2 * N - 1 : N] <= N'((sum + yReg) >> shiftYReg); 
                    end
                    else
                    begin
                        rxqReg[2 * N - 1 : N] <= N'(sum >> shiftYReg); 
                    end  
                    if(signedInput & ySign)
                        rxqReg[N - 1 : 0] <= -(rxqReg[N - 1 : 0] - sum[N]);   
                    else            
                        rxqReg[N - 1 : 0] <= rxqReg[N - 1 : 0] - sum[N];   
                    doneReg <= 1'b1;
                    counter <= 0;    
                    state <= DONE;
                end
                else
                begin
                    if(!r4[3]) // >= 0
                    begin
                        rxqReg <= {sa, rxqReg[N - 2 : 0], 1'b1};
                        cReg <= ca;                         
                        qnReg <= {rxqReg[N - 2 : 0], 1'b0};   
                    end
                    else
                    if(r4 != 4'b1111) // < - 1 / 2
                    begin
                        rxqReg <= {sa, qnReg[N - 2 : 0], 1'b1};
                        cReg <= ca;                      
                        qnReg <= {qnReg[N - 2 : 0], 1'b0};  
                    end    
                    //                1 / 2 <= r < 0
                    else
                    begin
                        rxqReg <= {rxqReg[2 * N : 0], 1'b0};  
                        cReg <= {cReg[N : 0], 1'b0};                     
                        qnReg <= {qnReg[N - 2 : 0], 1'b1}; 
                    end   

                    state <= RUN;
                    counter <= counter + 1'b1;                
                end
            end
        endcase
    end
end // end FSM
endmodule
