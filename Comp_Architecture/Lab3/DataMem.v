`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/26 01:15:49
// Design Name: 
// Module Name: DataMem
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


module DataMem(
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [2:0]  funct3,
    input  [31:0] addr,
    input  [31:0] write_data,
    output reg [31:0] read_data
);

    reg [7:0] mem [0:1023];

    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: mem[addr] <= write_data[7:0];                // sb
                3'b010: begin                                        // sw
                    mem[addr]     <= write_data[7:0];
                    mem[addr + 1] <= write_data[15:8];
                    mem[addr + 2] <= write_data[23:16];
                    mem[addr + 3] <= write_data[31:24];
                end
            endcase
        end
    end

    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: read_data = {{24{mem[addr][7]}}, mem[addr]};             // lb
                3'b100: read_data = {24'b0, mem[addr]};                          // lbu
                3'b010: read_data = {mem[addr + 3], mem[addr + 2],               // lw
                                     mem[addr + 1], mem[addr]};
                default: read_data = 32'b0;
            endcase
        end else begin
            read_data = 32'b0;
        end
    end

endmodule

