`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/25 17:25:12
// Design Name: 
// Module Name: InstrMem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module InstrMem(
    input [31:0] addr,
    output [31:0] instr
);

    reg [31:0] memory [0:255];
    initial $readmemh("program.mem", memory);
    assign instr = memory[addr[9:2]];  // word-aligned

endmodule

