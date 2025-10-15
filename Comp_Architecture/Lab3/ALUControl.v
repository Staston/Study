`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/26 00:48:54
// Design Name: 
// Module Name: ALUControl
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


module ALUControl(
    input  [1:0] alu_op,
    input  [2:0] funct3,
    input  [6:0] funct7,
    output reg [3:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0010; // default: add (lw, lb, lbu, sw, sb, jal)
            2'b01: alu_ctrl = 4'b0110; // sub£¨beq, bne, blt, bge)
            2'b10: begin
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? 4'b0110 : 4'b0010; // sub or add
                    3'b111: alu_ctrl = 4'b0000; // and / andi
                    3'b110: alu_ctrl = 4'b0001; // or
                    3'b001: alu_ctrl = 4'b1000; // sll / slli
                    3'b101: alu_ctrl = (funct7[5]) ? 4'b1010 : 4'b1001; // sra / srl
                    default: alu_ctrl = 4'b1111; // invalid
                endcase
            end
            2'b11: begin
                case (funct3)
                    3'b000: alu_ctrl = 4'b0010; // addi, jalr
                    3'b111: alu_ctrl = 4'b0000; // andi
                    3'b110: alu_ctrl = 4'b0001; // ori
                    3'b001: alu_ctrl = 4'b1000; // slli
                    3'b101: alu_ctrl = 4'b1001; // srli
                    default: alu_ctrl = 4'b1111; // invalid
                endcase
            end
            default: alu_ctrl = 4'b1111;
        endcase
    end

endmodule
