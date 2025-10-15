`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/25 17:35:31
// Design Name: 
// Module Name: RegFile
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


module RegFile(
    input clk,
    input reset,
    input RegWrite,
    input [4:0] rs1, rs2, rd,
    input [31:0] write_data,
    output [31:0] read_data1, read_data2
);

    reg [31:0] regs [31:0];
    integer i;
    
    initial begin
        for(i=0;i<32;i=i+1)begin
            regs[i] = 8'h0000_0000;
        end
        i=0;
    end
    
    always @(posedge reset) begin
        for(i=0;i<32;i=i+1)begin
            regs[i] = 8'h0000_0000;
        end
        i=0;
    end
    
    assign read_data1 = (rs1 != 0) ? regs[rs1] : 0;
    assign read_data2 = (rs2 != 0) ? regs[rs2] : 0;
    
    always @(posedge clk)
        if (RegWrite && rd != 0) regs[rd] <= write_data;

endmodule

