`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/26 00:24:42
// Design Name: 
// Module Name: Control
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


module Control(
    input [6:0] opcode,
    output reg Branch, MemRead, MemtoReg,
    output reg [1:0] ALUOp,
    output reg MemWrite, ALUSrc, RegWrite,
    output reg Jump
);

    always @(*) begin
        case (opcode)
            7'b0110011: begin // R-type (add, sub, and, or, sll, srl, sra)
                ALUSrc   = 0; RegWrite = 1;
                MemRead = 0; MemWrite = 0;
                MemtoReg = 0; Branch = 0;
                ALUOp = 2'b10; Jump = 0;
            end
            7'b0010011: begin // I-type (addi, andi, slli, srli)
                ALUSrc   = 1; RegWrite = 1;
                MemRead = 0; MemWrite = 0;
                MemtoReg = 0; Branch = 0;
                ALUOp = 2'b11; Jump = 0;
            end
            7'b0000011: begin // lw, lb, lbu
                ALUSrc   = 1; RegWrite = 1;
                MemRead = 1; MemWrite = 0;
                MemtoReg = 1; Branch = 0;
                ALUOp = 2'b00; Jump = 0;
            end
            7'b0100011: begin // sw, sb
                ALUSrc   = 1; RegWrite = 0;
                MemRead = 0; MemWrite = 1;
                MemtoReg = 0; Branch = 0;
                ALUOp = 2'b00; Jump = 0;
            end
            7'b1100011: begin // beq, bne, bge, blt
                ALUSrc   = 0; RegWrite = 0;
                MemRead = 0; MemWrite = 0;
                MemtoReg = 0; Branch = 1;
                ALUOp = 2'b01; Jump = 0;
            end
            7'b1101111: begin // jal
                ALUSrc   = 0; RegWrite = 1;
                MemRead = 0; MemWrite = 0;
                MemtoReg = 0; Branch = 1;
                ALUOp = 2'b00; Jump = 1;
            end
            7'b1100111: begin // jalr
                ALUSrc   = 1; RegWrite = 1;
                MemRead = 0; MemWrite = 0;
                MemtoReg = 0; Branch = 1;
                ALUOp = 2'b11; Jump = 1;
            end
            default: begin
                ALUSrc = 0; RegWrite = 0; MemRead = 0;
                MemWrite = 0; MemtoReg = 0; Branch = 0;
                ALUOp = 2'b00; Jump = 0;
            end
        endcase
    end
endmodule
