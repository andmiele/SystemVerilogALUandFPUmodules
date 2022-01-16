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

// clAddSub4_tb.sv
// Testbench: clAddSub4

`timescale 1 ns / 10 ps

module claAddSub8_tb;
localparam M = 8;
localparam I = {M{1'b1}};
localparam J = {M{1'b1}};
localparam period = 5; // clock period for testbench
logic [M - 1 : 0] x;
logic [M - 1 : 0] y;
logic [M - 1 : 0] out;
logic cout;
logic v;
logic [M - 1 : 0] e_out;
logic e_cout;
logic e_v;
logic sub;
logic cin;

logic passed;

claAddSub8 UUT(.sub(sub), .cin(cin), .x(x), .y(y), 
    .out(out), .cout(cout), .v(v),
.g(), .p());

logic [2 * M : 0] i;
logic [2 * M : 0] j;

initial begin
    passed = 1'b1;
    sub = 1'b0;
    cin = 1'b1;
    for(i = 0; i <= I; i = i + 1) 
    begin: i_add
        x = i;
        for(j = 0; j <= J; j = j + 1)
        begin: j_add
            y = j;
            {e_cout, e_out} = x + y + cin;
            #period;
            if ((out !== e_out) || (cout !== e_cout))
            begin: fail_add
                passed = 1'b0;
                $display("ADD TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nout: %b (cout: %b) \nexp: %b (cout: %b)\n", i, j, x, y, 
                out, cout, e_out, e_cout);
                $stop;
            end
        end
        // subtraction
        sub = 1'b1;
        cin = 1'b0;
        for(i = 0; i <= I; i = i + 1) 
        begin: i_sub
            x = i;
            for(j = 0; j <= J; j = j + 1)
            begin: j_sub
                y = j;
                {e_cout, e_out} = x - y;
                e_v = ((x[M - 1] == 1'b0) && (y[M - 1] == 1'b1) && e_out[M - 1] == 1'b1) || ((x[M - 1] == 1'b1) && (y[M - 1] == 1'b0) && e_out[M - 1] == 1'b0);
                #period;
                if ((out !== e_out) || (v !== e_v))
                begin: fail_sub
                    passed = 1'b0;
                    $display("SUB TEST FAILED [i :%d, j :%d]\n x: %b y :%b\nout: %b (v: %b) \nexp: %b (v: %b)\n", i, j, x, y, 
                    out, v, e_out, e_v);
                    $stop;
                end
            end
        end
    end
    if (passed == 1'b1)
        $display("TEST PASSED!\n");
    else
        $display("TEST FAILED!\n");
end

endmodule
