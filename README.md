# System Verilog implementation of computer arithmetic algorithms for ALUs and FPUs
## Content
* **adder_subtractor**: Carry-Look-Ahead adder/subtractor (4-bit, 8-bit, 16-bit, 24-bit, 32-bit,  48-bit, 53-bit, 64-bit, 106-bit), generic Carry-Skip, Carry-Select and Prefix-Tree adder/subtractor
* **divider**: Radix-2 and Radix-4 SRT (Sweeney, Robertson, and Tocher) dividers based on Hennessy&Patterson, Computer Architecture: a quantitative approach, 6th edition, appendix-J: pages 54-57
* **intSqrt**: generic binary integer square root unit
* **multiplier**: combinational and pipelined Radix-4 modified-Booth/Wallace-Tree multipliers (16-bit, 24-bit, 32-bit, 53-bit, 64-bit) 
* **fp_adder_subtractor**: combinational IEEE Floating Point adder/subtractor. **Note:** it uses the System Verilog addition operator. That can be replaced with one of the above integer adders
* **fp_multiplier**: combinational IEEE Floating Point multiplier. **Note:** it uses the System Verilog multiplication operator. That needs to be replaced with an actual integer multiplier (like one of the above tree multipliers) in order to be synthesizable
* **fp_division**: combinational IEEE Floating Point divider. **Note:** it uses the System Verilog division and remainder/modulo operators. That needs to be replaced with an actual integer divider (like one of the above SRT sequential dividers) and some sequential logic to drive it in order to be synthesizable
