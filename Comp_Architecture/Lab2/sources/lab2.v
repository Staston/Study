`timescale 1ns / 1ps

module Mux(
    input  [31:0] in0,
    input  [31:0] in1,
    input  sel,
    output [31:0] out
);
    assign out = sel ? in1 : in0;
endmodule

module Adder(
    input  [31:0] in1,
    input  [31:0] in2,
    output [31:0] out
);
    assign out = in1 + in2;
endmodule

module InstructionMemory(
    input  [31:0] Address,
    output [31:0] Instruction
);
    reg [7:0] rom[127:0];
    integer i;

    // initialization
    initial begin
    for(i=0;i<128;i=i+1)begin
    rom[i] = 8'b0000_0000;
    end
    {rom[3],rom[2],rom[1],rom[0]} = 32'hff60_0293;
    {rom[7],rom[6],rom[5],rom[4]} = 32'h0052_8333;
    {rom[11],rom[10],rom[9],rom[8]} = 32'h4062_83b3;
    {rom[15],rom[14],rom[13],rom[12]} = 32'h0003_7e33;
    {rom[19],rom[18],rom[17],rom[16]} = 32'h0053_6eb3;
    {rom[23],rom[22],rom[21],rom[20]} = 32'h01d0_2023;
    {rom[27],rom[26],rom[25],rom[24]} = 32'h0050_2223;
    {rom[31],rom[30],rom[29],rom[28]} = 32'h0002_8463;
    {rom[35],rom[34],rom[33],rom[32]} = 32'h0003_0eb3;
    {rom[39],rom[38],rom[37],rom[36]} = 32'h01d3_1463;
    {rom[43],rom[42],rom[41],rom[40]} = 32'h01c3_1463;
    {rom[47],rom[46],rom[45],rom[44]} = 32'h0000_03b3;
    {rom[51],rom[50],rom[49],rom[48]} = 32'h0000_2403;
    {rom[55],rom[54],rom[53],rom[52]} = 32'h0040_2483;
    {rom[59],rom[58],rom[57],rom[56]} = 32'h0084_8493;
    {rom[63],rom[62],rom[61],rom[60]} = 32'h0094_0463;
    {rom[67],rom[66],rom[65],rom[64]} = 32'h0000_03b3;
    {rom[71],rom[70],rom[69],rom[68]} = 32'h0073_83b3;
    end

    assign Instruction = {rom[Address+3], rom[Address+2], rom[Address+1], rom[Address]};
endmodule

module DataMemory(
    input clk,
    input MemWrite,
    input MemRead,
    input  [31:0] Address,
    input  [31:0] WriteData,
    output [31:0] ReadData
);
    // 128 * 8
    reg [7:0] regs[127:0];
    integer j;

    initial begin
        for(j=0; j<128; j=j+1) begin
            regs[j] = 8'h00;
        end
    end

    // Check MemRead
    assign ReadData = (MemRead) ? {regs[Address+3], regs[Address+2], regs[Address+1], regs[Address]} : 32'h0;

    always @(posedge clk) begin
        if (MemWrite) begin
            regs[Address]   <= WriteData[7:0];
            regs[Address+1] <= WriteData[15:8];
            regs[Address+2] <= WriteData[23:16];
            regs[Address+3] <= WriteData[31:24];
        end
    end
endmodule

module RegisterFile(
    input clk,
    input RegWrite,
    input  [4:0] ReadReg1,
    input  [4:0] ReadReg2,
    input  [4:0] WriteReg,
    input  [31:0] WriteData,
    output [31:0] ReadData1,
    output [31:0] ReadData2
);
    reg [31:0] regs[31:0];
    integer k;

    initial begin
        for (k=0; k<32; k=k+1) begin
            regs[k] = 32'b0;
        end
    end
    
    // Read
    assign ReadData1 = (ReadReg1 == 5'b0) ? 32'b0 : regs[ReadReg1];
    assign ReadData2 = (ReadReg2 == 5'b0) ? 32'b0 : regs[ReadReg2];

    // Write
    always @(posedge clk) begin
        if (RegWrite && (WriteReg != 5'b0)) begin
            regs[WriteReg] <= WriteData;
        end
    end
endmodule

module ImmediateGenerator(
    input  [31:0] Instruction,
    output [31:0] Immediate
);
    wire [6:0] opcode = Instruction[6:0];
    reg  [31:0] imm_val;

    localparam OPCODE_R    = 7'b0110011; // add, sub, and, or
    localparam OPCODE_I    = 7'b0010011; // addi
    localparam OPCODE_LOAD = 7'b0000011; // lw
    localparam OPCODE_S    = 7'b0100011; // sw
    localparam OPCODE_B    = 7'b1100011; // beq/bne

    always @(*) begin
        case (opcode)
            OPCODE_I, OPCODE_LOAD:
                imm_val = { {20{Instruction[31]}}, Instruction[31:20] };
            OPCODE_S:
                imm_val = { {20{Instruction[31]}}, Instruction[31:25], Instruction[11:7] };
            OPCODE_B:
                imm_val = { {20{Instruction[31]}}, Instruction[7], Instruction[30:25], Instruction[11:8], 1'b0 };

            OPCODE_R:
                imm_val = 32'd0; 
                
            default:
                imm_val = 32'd0;
        endcase
    end
    assign Immediate = imm_val;
endmodule

module ALUControl(
    input [1:0]  ALUOp,
    input        funct7, // Using only bit 30 for sub
    input [2:0]  funct3,
    output reg [3:0] ALUSelection
);

    localparam ALU_AND  = 4'b0000;
    localparam ALU_OR   = 4'b0001;
    localparam ALU_ADD  = 4'b0010;
    localparam ALU_SUB  = 4'b0110;

    always @(*) begin
        case (ALUOp)
            // For lw, sw, addi
            2'b00: ALUSelection = ALU_ADD;
            // For beq, bne
            2'b01: ALUSelection = ALU_SUB;
            // For R-type
            2'b10: begin
                case (funct3)
                    3'b000: ALUSelection = (funct7 == 1'b1) ? ALU_SUB : ALU_ADD;
                    3'b110: ALUSelection = ALU_OR;
                    3'b111: ALUSelection = ALU_AND;
                    default: ALUSelection = 4'bxxxx;
                endcase
            end
            default: ALUSelection = 4'bxxxx;
        endcase
    end
endmodule

module ALU(
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  ALUSelection,
    output reg [31:0] Result,
    output Zero
);

    localparam ALU_AND = 4'b0000;
    localparam ALU_OR  = 4'b0001;
    localparam ALU_ADD = 4'b0010;
    localparam ALU_SUB = 4'b0110;

    always @(*) begin
        case (ALUSelection)
            ALU_AND: Result = A & B;
            ALU_OR:  Result = A | B;
            ALU_ADD: Result = A + B;
            ALU_SUB: Result = A - B;
            default: Result = 32'hxxxxxxxx;
        endcase
    end
    assign Zero = (Result == 32'b0);
endmodule

module Control(
    input  [6:0] Opcode,
    output reg   RegWrite,
    output reg   ALUSrc,
    output reg   MemtoReg,
    output reg   MemRead,
    output reg   MemWrite,
    output reg   Branch,
    // output reg   Bne,
    output reg [1:0] ALUOp
);

    localparam OPCODE_R    = 7'b0110011;
    localparam OPCODE_I    = 7'b0010011;
    localparam OPCODE_LOAD = 7'b0000011;
    localparam OPCODE_S    = 7'b0100011;
    localparam OPCODE_B    = 7'b1100011; // beq, bne

    always @(*) begin
        RegWrite = 0; ALUSrc = 0; MemtoReg = 0; MemRead = 0;
        MemWrite = 0; Branch = 0; ALUOp = 2'bxx;

        case (Opcode)
            OPCODE_R: begin // add, sub, and, or
                RegWrite = 1; ALUSrc = 0; MemtoReg = 0; MemRead = 0;
                MemWrite = 0; Branch = 0; ALUOp = 2'b10;
            end
            OPCODE_I: begin // addi
                RegWrite = 1; ALUSrc = 1; MemtoReg = 0; MemRead = 0;
                MemWrite = 0; Branch = 0; ALUOp = 2'b00;
            end
            OPCODE_LOAD: begin // lw
                RegWrite = 1; ALUSrc = 1; MemtoReg = 1; MemRead = 1;
                MemWrite = 0; Branch = 0; ALUOp = 2'b00;
            end
            OPCODE_S: begin // sw
                RegWrite = 0; ALUSrc = 1; MemtoReg = 0; MemRead = 0;
                MemWrite = 1; Branch = 0; ALUOp = 2'b00;
            end
            OPCODE_B: begin // beq, bne
                RegWrite = 0; ALUSrc = 0; MemtoReg = 0; MemRead = 0;
                MemWrite = 0; Branch = 1;
                ALUOp = 2'b01;
            end
        endcase
    end
endmodule

module SingleCycleProcessor(
    input clk
    );

    // Internal Wires
    wire [31:0] current_PC, next_PC, PC_plus_4, PC_branch_target;
    wire [31:0] Inst, Imm;
    wire [31:0] ReadData1, ReadData2, ALUResult, MemReadData, WriteBackData;
    wire [4:0]  rs1_addr, rs2_addr, rd_addr;

    // Control Signals
    wire RegWrite, ALUSrc, MemtoReg, MemRead, MemWrite, Branch;
    wire [1:0] ALUOp;
    wire [3:0] ALUSelection;
    wire Zero;
    wire PCSrc;
    wire is_bne;

    // PC Register
    reg [31:0] PC_reg;
    initial PC_reg = 32'b0;
    always @(posedge clk) begin
        PC_reg <= next_PC;
    end
    assign current_PC = PC_reg;

    InstructionMemory InstMem1 (
        .Address(current_PC),
        .Instruction(Inst)
    );

    assign rs1_addr = Inst[19:15];
    assign rs2_addr = Inst[24:20];
    assign rd_addr  = Inst[11:7];

    Control Ctrl1 (
        .Opcode(Inst[6:0]),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .ALUOp(ALUOp)
    );

    RegisterFile RF1 (
        .clk(clk),
        .RegWrite(RegWrite),
        .ReadReg1(rs1_addr),
        .ReadReg2(rs2_addr),
        .WriteReg(rd_addr),
        .WriteData(WriteBackData),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );

    ImmediateGenerator ImmGen1 (
        .Instruction(Inst),
        .Immediate(Imm)
    );

    ALUControl ALU_Ctrl1 (
        .ALUOp(ALUOp),
        .funct7(Inst[30]),
        .funct3(Inst[14:12]),
        .ALUSelection(ALUSelection)
    );
    
    wire [31:0] ALU_B_Input;
    Mux ALU_B_sel_mux (
        .in0(ReadData2),
        .in1(Imm),
        .sel(ALUSrc),
        .out(ALU_B_Input)
    );

    ALU ALU1 (
        .A(ReadData1),
        .B(ALU_B_Input),
        .ALUSelection(ALUSelection),
        .Result(ALUResult),
        .Zero(Zero)
    );

    DataMemory DataMem1 (
        .clk(clk),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .Address(ALUResult),
        .WriteData(ReadData2),
        .ReadData(MemReadData)
    );
    
    Mux WB_sel_mux (
        .in0(ALUResult),
        .in1(MemReadData),
        .sel(MemtoReg),
        .out(WriteBackData)
    );

    // Adder for PC + 4
    Adder PC_plus_4_adder (
        .in1(current_PC),
        .in2(32'd4),
        .out(PC_plus_4)
    );

    // Adder for branch target address
    Adder PC_branch_adder (
        .in1(current_PC),
        .in2(Imm),
        .out(PC_branch_target)
    );
    
    // beq or bne ?
    assign is_bne = (Inst[14:12] == 3'b001);
    assign PCSrc = (Branch & Zero & ~is_bne) | (Branch & ~Zero & is_bne);

    // next PC value
    Mux PC_sel_mux (
        .in0(PC_plus_4),
        .in1(PC_branch_target),
        .sel(PCSrc),
        .out(next_PC)
    );
    
endmodule