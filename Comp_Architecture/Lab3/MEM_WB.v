`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/27 00:22:50
// Design Name: 
// Module Name: MEM_WB
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


module MEM_WB (
    input         clk,
    input         rst,
    input  [31:0] mem_data_in,
    input  [31:0] alu_result_in,
    input  [4:0]  rd_addr_in,
    input         reg_write_in,
    input         mem_to_reg_in,
    input         jump_in,
    output reg [31:0] mem_data_out,
    output reg [31:0] alu_result_out,
    output reg [4:0]  rd_addr_out,
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg        jump_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_data_out   <= 32'b0;
            alu_result_out <= 32'b0;
            rd_addr_out    <= 5'b0;
            reg_write_out  <= 0;
            mem_to_reg_out <= 0;
            jump_out       <= 0;
        end else begin
            mem_data_out   <= mem_data_in;
            alu_result_out <= alu_result_in;
            rd_addr_out    <= rd_addr_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            jump_out       <= jump_in; 
        end
    end
endmodule
