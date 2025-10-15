`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/26 23:45:09
// Design Name: 
// Module Name: EX_MEM
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


module EX_MEM (
    input         clk,
    input         rst,
    input  [31:0] alu_result_in,
    input  [31:0] rs2_data_in,
    input  [31:0] pc_sum_in,
    input  [4:0]  rd_addr_in,
    input         mem_read_in,
    input         mem_write_in,
    input         reg_write_in,
    input         mem_to_reg_in,
    input         branch_in,
    input         zero_in, // need to or with jump
    input         jump_in,
    output reg [31:0] alu_result_out,
    output reg [31:0] rs2_data_out,
    output reg [31:0] pc_sum_out,
    output reg [4:0]  rd_addr_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg        branch_out,
    output reg        zero_out,
    output reg        jump_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_out <= 32'b0;
            rs2_data_out   <= 32'b0;
            pc_sum_out     <= 32'b0;
            rd_addr_out    <= 5'b0;
            mem_read_out   <= 0;
            mem_write_out  <= 0;
            reg_write_out  <= 0;
            mem_to_reg_out <= 0;
            branch_out     <= 0;
            zero_out       <= 0;
            jump_out       <= 0;
        end else begin
            alu_result_out <= alu_result_in;
            rs2_data_out   <= rs2_data_in;
            pc_sum_out     <= pc_sum_in;
            rd_addr_out    <= rd_addr_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            branch_out     <= branch_in;
            zero_out       <= zero_in;
            jump_out       <= jump_in;
        end
    end
endmodule
