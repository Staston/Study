`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/27 00:02:49
// Design Name: 
// Module Name: ID_EX
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


module ID_EX (
    input         clk,
    input         rst,
    input  [31:0] pc_in,
    input  [31:0] imm_in,
    input  [31:0] rs1_in,
    input  [31:0] rs2_in,
    input  [4:0]  rd_addr_in,
    input  [3:0]  funct3_in, // Instruction[30, 14:12]
    input  [1:0]  alu_op_in,
    input         alu_src_in,
    input         mem_read_in,
    input         mem_write_in,
    input         reg_write_in,
    input         mem_to_reg_in,
    input         branch_in,
    input         jump_in,
    output reg [31:0] pc_out,
    output reg [31:0] imm_out,
    output reg [31:0] rs1_out,
    output reg [31:0] rs2_out,
    output reg [4:0]  rd_addr_out,
    output reg [3:0]  funct3_out,
    output reg [1:0]  alu_op_out,
    output reg        alu_src_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg        branch_out,
    output reg        jump_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'b0; imm_out <= 32'b0; rs1_out <= 32'b0; rs2_out <= 32'b0;
            rd_addr_out <= 5'b0; funct3_out <= 3'b0; alu_op_out <= 2'b0;
            alu_src_out <= 0; mem_read_out <= 0; mem_write_out <= 0;
            reg_write_out <= 0; mem_to_reg_out <= 0; branch_out <= 0;
            jump_out <= 0;
        end else begin
            pc_out <= pc_in; imm_out <= imm_in; rs1_out <= rs1_in; rs2_out <= rs2_in;
            rd_addr_out <= rd_addr_in; funct3_out <= funct3_in; alu_op_out <= alu_op_in;
            alu_src_out <= alu_src_in; mem_read_out <= mem_read_in; mem_write_out <= mem_write_in;
            reg_write_out <= reg_write_in; mem_to_reg_out <= mem_to_reg_in; branch_out <= branch_in;
            jump_out <= jump_in;
        end
    end
endmodule
