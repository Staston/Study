`timescale 1ns / 1ps

module Adder (
    input      [31:0] a,
    input      [31:0] b,
    output     [31:0] sum
);

    assign sum = a + b;

endmodule

module ALU(
    input [31:0] a, b,
    input [3:0] alu_control,
    output reg [31:0] result
);
    always @(*) begin
        case (alu_control)
            4'b0000: result = a & b;
            4'b0001: result = a | b;
            4'b0010: result = a + b;
            4'b0110: result = a - b;
            4'b1000: result = a << b[4:0];
            4'b1001: result = a >> b[4:0];
            4'b1010: result = $signed(a) >>> b[4:0]; // sra
            default: result = 0;
        endcase
    end
endmodule

module ALUControl(
    input  [1:0] alu_op,
    input  [2:0] funct3,
    // input  [6:0] funct7,         // <-- 删除或注释掉此行
    input        funct7_bit5,      // <-- 增加此行，用于接收 instr[30]
    output reg [3:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0010;
            2'b01: alu_ctrl = 4'b0110;
            2'b10: begin // R-type
                case (funct3)
                    // 使用新的单比特输入 funct7_bit5
                    3'b000: alu_ctrl = (funct7_bit5) ? 4'b0110 : 4'b0010; // sub or add
                    3'b111: alu_ctrl = 4'b0000; // and
                    3'b110: alu_ctrl = 4'b0001; // or
                    3'b001: alu_ctrl = 4'b1000; // sll
                    // 使用新的单比特输入 funct7_bit5
                    3'b101: alu_ctrl = (funct7_bit5) ? 4'b1010 : 4'b1001; // sra / srl
                    default: alu_ctrl = 4'b1111; // invalid
                endcase
            end
            2'b11: begin // I-type and JALR (这部分逻辑保持你原来的代码即可)
                case (funct3)
                    3'b000: alu_ctrl = 4'b0010; // addi, jalr
                    3'b111: alu_ctrl = 4'b0000; // andi
                    3'b110: alu_ctrl = 4'b0001; // ori
                    3'b001: alu_ctrl = 4'b1000; // slli
                    3'b101: alu_ctrl = 4'b1001; // srli (无需处理srai，此行保持原样)
                    default: alu_ctrl = 4'b1111; // invalid
                endcase
            end
            default: alu_ctrl = 4'b1111;
        endcase
    end

endmodule

module Control(
    input [6:0] opcode,
    output reg Branch, MemRead, MemtoReg,
    output reg [1:0] ALUOp,
    output reg MemWrite, ALUSrc, RegWrite,
    output reg Jump,
    output reg RegSrc // <<< NEW: 0 for ALU/MEM result, 1 for PC+4
);

    always @(*) begin
        // Set default values for all signals
        Branch   = 0; MemRead  = 0; MemtoReg   = 0;
        ALUOp    = 2'b00; MemWrite = 0; ALUSrc     = 0;
        RegWrite = 0; Jump     = 0; RegSrc     = 0; // <<< NEW: Default to 0

        case (opcode)
            7'b0110011: begin // R-type
                RegWrite = 1;
                ALUOp    = 2'b10;
            end
            7'b0010011: begin // I-type (addi, etc.)
                ALUSrc   = 1; RegWrite = 1;
                ALUOp    = 2'b11;
            end
            7'b0000011: begin // Load instructions
                ALUSrc   = 1; RegWrite = 1;
                MemRead  = 1; MemtoReg = 1;
            end
            7'b0100011: begin // Store instructions
                ALUSrc   = 1;
                MemWrite = 1;
            end
            7'b1100011: begin // Branch instructions
                Branch = 1;
                ALUOp  = 2'b01;
            end
            7'b1101111: begin // jal
                RegWrite = 1; Jump     = 1;
                RegSrc   = 1; // <<< MODIFIED: Set RegSrc for jal
            end
            7'b1100111: begin // jalr
                ALUSrc   = 1; RegWrite = 1; Jump     = 1;
                RegSrc   = 1; // <<< MODIFIED: Set RegSrc for jalr
                ALUOp    = 2'b11;
            end
        endcase
    end
endmodule

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

module EX_MEM (
    input clk, rst,
    // Inputs from EX Stage
    input [31:0] pc_plus_4_in,      // <<< NEW: Pass PC+4 for JAL/JALR
    input [31:0] alu_result_in,
    input [31:0] rs2_data_in,
    input [4:0]  rd_addr_in,
    input [3:0]  funct_in,
    // Control Signals
    input mem_read_in, mem_write_in,
    input reg_write_in, mem_to_reg_in,
    input reg_src_in,               // <<< NEW

    // Outputs to MEM Stage
    output reg [31:0] pc_plus_4_out,   // <<< NEW
    output reg [31:0] alu_result_out,
    output reg [31:0] rs2_data_out,
    output reg [4:0]  rd_addr_out,
    output reg [3:0]  funct_out,
    // Control Signals
    output reg mem_read_out, mem_write_out,
    output reg reg_write_out, mem_to_reg_out,
    output reg reg_src_out              // <<< NEW
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_plus_4_out  <= 32'b0;
            alu_result_out <= 32'b0;
            rs2_data_out   <= 32'b0;
            rd_addr_out    <= 5'b0;
            funct_out      <= 4'b0;
            mem_read_out   <= 0;
            mem_write_out  <= 0;
            reg_write_out  <= 0;
            mem_to_reg_out <= 0;
            reg_src_out    <= 0;
        end else begin
            pc_plus_4_out  <= pc_plus_4_in;
            alu_result_out <= alu_result_in;
            rs2_data_out   <= rs2_data_in;
            rd_addr_out    <= rd_addr_in;
            funct_out      <= funct_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            reg_src_out    <= reg_src_in;
        end
    end
endmodule

module ID_EX (
    input clk, rst,
    // Inputs from ID Stage
    input [31:0] pc_in,
    input [31:0] imm_in,
    input [31:0] rs1_in,
    input [31:0] rs2_in,
    input [4:0]  rd_addr_in,
    input [3:0]  funct3_in,
    // Control Signals
    input [1:0]  alu_op_in,
    input alu_src_in, mem_read_in, mem_write_in,
    input reg_write_in, mem_to_reg_in, branch_in, jump_in,
    input reg_src_in,             // <<< NEW

    // Outputs to EX Stage
    output reg [31:0] pc_out,
    output reg [31:0] imm_out,
    output reg [31:0] rs1_out,
    output reg [31:0] rs2_out,
    output reg [4:0]  rd_addr_out,
    output reg [3:0]  funct3_out,
    // Control Signals
    output reg [1:0]  alu_op_out,
    output reg alu_src_out, mem_read_out, mem_write_out,
    output reg reg_write_out, mem_to_reg_out, branch_out, jump_out,
    output reg reg_src_out             // <<< NEW
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'b0; imm_out <= 32'b0; rs1_out <= 32'b0; rs2_out <= 32'b0;
            rd_addr_out <= 5'b0; funct3_out <= 3'b0; alu_op_out <= 2'b0;
            alu_src_out <= 0; mem_read_out <= 0; mem_write_out <= 0;
            reg_write_out <= 0; mem_to_reg_out <= 0; branch_out <= 0;
            jump_out <= 0; reg_src_out <= 0; // <<< NEW
        end else begin
            pc_out <= pc_in; imm_out <= imm_in; rs1_out <= rs1_in; rs2_out <= rs2_in;
            rd_addr_out <= rd_addr_in; funct3_out <= funct3_in; alu_op_out <= alu_op_in;
            alu_src_out <= alu_src_in; mem_read_out <= mem_read_in; mem_write_out <= mem_write_in;
            reg_write_out <= reg_write_in; mem_to_reg_out <= mem_to_reg_in; branch_out <= branch_in;
            jump_out <= jump_in; reg_src_out <= reg_src_in; // <<< NEW
        end
    end
endmodule

module IF_ID (
    input         clk,
    input         rst,
    input  [31:0] pc_in,
    input  [31:0] instr_in,
    output reg [31:0] pc_out,
    output reg [31:0] instr_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 0;
            instr_out <= 0;
        end else begin
            pc_out <= pc_in;
            instr_out <= instr_in;
        end
    end
endmodule

module ImmGen(
    input [31:0] instr, 
    output reg [31:0] imm
);

    wire [6:0] opcode = instr[6:0];
    always @(*) begin
        case (opcode)
            7'b0010011, 7'b0000011, 7'b1100111: // I-type
                imm = {{20{instr[31]}}, instr[31:20]};
            7'b0100011: // S-type
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011: // B-type
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            7'b1101111: // J-type
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default:
                imm = 0;
        endcase
    end
endmodule

module InstrMem(
    input [31:0] addr,
    output [31:0] instr
);

    reg [31:0] memory [0:255];
    initial $readmemb("Lab3_testcase.mem", memory);
    assign instr = memory[addr[9:2]];  // word-aligned

endmodule

module MEM_WB (
    input clk, rst,
    // Inputs from MEM Stage
    input [31:0] pc_plus_4_in,      // <<< NEW
    input [31:0] mem_data_in,
    input [31:0] alu_result_in,
    input [4:0]  rd_addr_in,
    // Control Signals
    input reg_write_in,
    input mem_to_reg_in,
    input reg_src_in,               // <<< NEW

    // Outputs to WB Stage
    output reg [31:0] pc_plus_4_out,   // <<< NEW
    output reg [31:0] mem_data_out,
    output reg [31:0] alu_result_out,
    output reg [4:0]  rd_addr_out,
    // Control Signals
    output reg reg_write_out,
    output reg mem_to_reg_out,
    output reg reg_src_out              // <<< NEW
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_plus_4_out  <= 32'b0;
            mem_data_out   <= 32'b0;
            alu_result_out <= 32'b0;
            rd_addr_out    <= 5'b0;
            reg_write_out  <= 0;
            mem_to_reg_out <= 0;
            reg_src_out    <= 0;
        end else begin
            pc_plus_4_out  <= pc_plus_4_in;
            mem_data_out   <= mem_data_in;
            alu_result_out <= alu_result_in;
            rd_addr_out    <= rd_addr_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            reg_src_out    <= reg_src_in;
        end
    end
endmodule

module Mux(
    input [31:0] i0,
    input [31:0] i1,
    input s,
    output [31:0] d
);
    
    assign d = s ? i1 : i0;
    
endmodule

module PC(
    input clk,
    input reset,
    input [31:0] next_pc,
    output reg [31:0] pc    
);

    always @(posedge clk or posedge reset) begin
        if (reset) pc <= 32'b0;
        else       pc <= next_pc;
    end

endmodule

module RegFile(
    input clk,
    input reset,
    
    // Write port from WB stage
    input        RegWrite_wb,     // <<< MODIFIED: Now receives RegWrite from WB
    input [4:0]  rd_wb,           // <<< MODIFIED: Now receives rd from WB
    input [31:0] write_data_wb,   // <<< MODIFIED: Now receives write_data from WB
    
    // Read ports from ID stage
    input [4:0]  rs1,
    input [4:0]  rs2,
    output [31:0] read_data1,
    output [31:0] read_data2
);

    reg [31:0] regs [31:0];
    integer i;

    // Internal forwarding logic for read port 1
    // If WB is writing to the register that ID is reading (rs1),
    // then forward the new data. Otherwise, read from the register array.
    assign read_data1 = (RegWrite_wb && (rd_wb == rs1) && (rs1 != 5'b0)) 
                        ? write_data_wb 
                        : regs[rs1];

    // Internal forwarding logic for read port 2
    assign read_data2 = (RegWrite_wb && (rd_wb == rs2) && (rs2 != 5'b0))
                        ? write_data_wb
                        : regs[rs2];

    // Synchronous write operation (on rising clock edge)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'h00000000;
            end
        end else begin
            // Write to the register file if RegWrite is asserted and not x0
            if (RegWrite_wb && (rd_wb != 5'b0)) begin
                regs[rd_wb] <= write_data_wb;
            end
        end
    end

endmodule

module shift_left_1(
    input  [31:0] i,
    output [31:0] o
);

    assign o = {i[30:0], 1'b0};

endmodule

module riscv_pipeline_top(
    input clk,
    input rst
);

    // 信号线声明
    // IF Stage
    wire [31:0] pc_next, pc_current;
    wire [31:0] pc_plus_4;
    wire [31:0] instruction;

    // IF/ID
    wire [31:0] pc_if_id, instr_if_id;

    // ID Stage
    wire        reg_write_id;
    wire [1:0]  alu_op_id;
    wire        alu_src_id, branch_id, mem_read_id, mem_write_id, mem_to_reg_id, jump_id;
    wire        reg_src_id; // <<< MODIFIED
    wire [31:0] imm_id;
    wire [31:0] rs1_data_id, rs2_data_id;

    // ID/EX
    wire [31:0] pc_id_ex, imm_id_ex, rs1_data_id_ex, rs2_data_id_ex;
    wire [4:0]  rd_addr_id_ex;
    wire [3:0]  funct_id_ex;
    wire [1:0]  alu_op_id_ex;
    wire        alu_src_id_ex, mem_read_id_ex, mem_write_id_ex, reg_write_id_ex, mem_to_reg_id_ex, branch_id_ex, jump_id_ex;
    wire        reg_src_id_ex; // <<< MODIFIED

    // EX Stage
    wire [3:0]  alu_ctrl_ex;
    wire [31:0] alu_b_operand;
    wire [31:0] alu_result_ex;
    wire        alu_zero_ex;
    // wire [31:0] imm_shifted_ex;
    wire [31:0] pc_branch_target;
    reg         pc_src_ex;
    wire [31:0] jump_target;

    // EX/MEM
    wire [31:0] pc_plus_4_ex_mem, alu_result_ex_mem, rs2_data_ex_mem; // <<< MODIFIED
    wire [4:0]  rd_addr_ex_mem;
    wire        mem_read_ex_mem, mem_write_ex_mem, reg_write_ex_mem, mem_to_reg_ex_mem;
    wire        reg_src_ex_mem; // <<< MODIFIED
    wire [3:0]  funct_ex_mem;

    // MEM Stage
    wire [31:0] mem_read_data_mem;

    // MEM/WB Register Outputs
    wire [31:0] pc_plus_4_mem_wb, mem_data_mem_wb, alu_result_mem_wb;
    wire [4:0]  rd_addr_mem_wb;
    wire        reg_write_mem_wb, mem_to_reg_mem_wb, reg_src_mem_wb;

    // WB Stage
    wire [31:0] write_back_data;
    wire [31:0] write_back_intermediate;


    //================================================================
    // IF Stage
    //================================================================
    PC pc_reg ( .clk(clk), .reset(rst), .next_pc(pc_next), .pc(pc_current) );
    Adder pc_adder ( .a(pc_current), .b(32'd4), .sum(pc_plus_4) );
    InstrMem instr_mem ( .addr(pc_current), .instr(instruction) );
    IF_ID if_id_reg ( .clk(clk), .rst(rst), .pc_in(pc_plus_4), .instr_in(instruction),
                      .pc_out(pc_if_id), .instr_out(instr_if_id) );

    //================================================================
    // ID Stage
    //================================================================
    Control control_unit ( .opcode(instr_if_id[6:0]), .Branch(branch_id), .MemRead(mem_read_id),
                           .MemtoReg(mem_to_reg_id), .ALUOp(alu_op_id), .MemWrite(mem_write_id),
                           .ALUSrc(alu_src_id), .RegWrite(reg_write_id), .Jump(jump_id),
                           .RegSrc(reg_src_id) ); // <<< MODIFIED

    RegFile reg_file (
    .clk(clk), .reset(rst),
    
    // WB stage signals are now wired to the register file
    .RegWrite_wb(reg_write_mem_wb),
    .rd_wb(rd_addr_mem_wb),
    .write_data_wb(write_back_data), // Use the final write_back_data
    
    // ID stage read addresses
    .rs1(instr_if_id[19:15]), 
    .rs2(instr_if_id[24:20]), 
    
    // ID stage read data outputs
    .read_data1(rs1_data_id), 
    .read_data2(rs2_data_id)
    );
    
    ImmGen imm_gen ( .instr(instr_if_id), .imm(imm_id) );
    
    ID_EX id_ex_reg (
        .clk(clk), .rst(rst),
        .pc_in(pc_if_id), .imm_in(imm_id), .rs1_in(rs1_data_id), .rs2_in(rs2_data_id),
        .rd_addr_in(instr_if_id[11:7]), .funct3_in({instr_if_id[30], instr_if_id[14:12]}),
        .alu_op_in(alu_op_id), .alu_src_in(alu_src_id), .mem_read_in(mem_read_id),
        .mem_write_in(mem_write_id), .reg_write_in(reg_write_id), .mem_to_reg_in(mem_to_reg_id),
        .branch_in(branch_id), .jump_in(jump_id), .reg_src_in(reg_src_id), // <<< MODIFIED

        .pc_out(pc_id_ex), .imm_out(imm_id_ex), .rs1_out(rs1_data_id_ex), .rs2_out(rs2_data_id_ex),
        .rd_addr_out(rd_addr_id_ex), .funct3_out(funct_id_ex), .alu_op_out(alu_op_id_ex),
        .alu_src_out(alu_src_id_ex), .mem_read_out(mem_read_id_ex), .mem_write_out(mem_write_id_ex),
        .reg_write_out(reg_write_id_ex), .mem_to_reg_out(mem_to_reg_id_ex),
        .branch_out(branch_id_ex), .jump_out(jump_id_ex), .reg_src_out(reg_src_id_ex) // <<< MODIFIED
    );

    //================================================================
    // EX Stage
    //================================================================
    Mux alu_b_mux (.i0(rs2_data_id_ex), .i1(imm_id_ex), .s(alu_src_id_ex), .d(alu_b_operand));
    ALUControl alu_ctrl_unit (
        .alu_op(alu_op_id_ex), 
        .funct3(funct_id_ex[2:0]), 
        .funct7_bit5(funct_id_ex[3]),      // <-- 正确连接 instr[30] 的值
        .alu_ctrl(alu_ctrl_ex)
    );
    ALU alu (.a(rs1_data_id_ex), .b(alu_b_operand), .alu_control(alu_ctrl_ex), .result(alu_result_ex));
    assign alu_zero_ex = (alu_result_ex == 32'b0);

    // shift_left_1 imm_shifter (.i(imm_id_ex), .o(imm_shifted_ex));
    Adder branch_adder (.a(pc_id_ex - 4), .b(imm_id_ex), .sum(pc_branch_target));

    always @(*) begin
        if (branch_id_ex) begin
            case (funct_id_ex[2:0])
                3'b000: pc_src_ex = alu_zero_ex;
                3'b001: pc_src_ex = ~alu_zero_ex;
                3'b100: pc_src_ex = alu_result_ex[31];
                3'b101: pc_src_ex = ~alu_result_ex[31];
                default: pc_src_ex = 1'b0;
            endcase
        end else begin
            pc_src_ex = 1'b0;
        end
    end
    
    assign jump_target = (jump_id_ex && alu_op_id_ex == 2'b11) ? alu_result_ex : pc_branch_target;
    assign pc_next = jump_id_ex ? jump_target : (pc_src_ex ? pc_branch_target : pc_plus_4);

    EX_MEM ex_mem_reg (
        .clk(clk), .rst(rst),
        .pc_plus_4_in(pc_id_ex), .alu_result_in(alu_result_ex), .rs2_data_in(rs2_data_id_ex), // <<< MODIFIED
        .rd_addr_in(rd_addr_id_ex), .funct_in(funct_id_ex),
        .mem_read_in(mem_read_id_ex), .mem_write_in(mem_write_id_ex),
        .reg_write_in(reg_write_id_ex), .mem_to_reg_in(mem_to_reg_id_ex), .reg_src_in(reg_src_id_ex), // <<< MODIFIED

        .pc_plus_4_out(pc_plus_4_ex_mem), .alu_result_out(alu_result_ex_mem), .rs2_data_out(rs2_data_ex_mem), // <<< MODIFIED
        .rd_addr_out(rd_addr_ex_mem), .funct_out(funct_ex_mem),
        .mem_read_out(mem_read_ex_mem), .mem_write_out(mem_write_ex_mem),
        .reg_write_out(reg_write_ex_mem), .mem_to_reg_out(mem_to_reg_ex_mem), .reg_src_out(reg_src_ex_mem) // <<< MODIFIED
    );

    //================================================================
    // MEM Stage
    //================================================================
    DataMem data_mem ( .clk(clk), .mem_read(mem_read_ex_mem), .mem_write(mem_write_ex_mem),
                      .funct3(funct_ex_mem[2:0]), .addr(alu_result_ex_mem),
                      .write_data(rs2_data_ex_mem), .read_data(mem_read_data_mem) );

    MEM_WB mem_wb_reg (
        .clk(clk), .rst(rst),
        .pc_plus_4_in(pc_plus_4_ex_mem), .mem_data_in(mem_read_data_mem), .alu_result_in(alu_result_ex_mem), // <<< MODIFIED
        .rd_addr_in(rd_addr_ex_mem), .reg_write_in(reg_write_ex_mem),
        .mem_to_reg_in(mem_to_reg_ex_mem), .reg_src_in(reg_src_ex_mem), // <<< MODIFIED
        // .jump_in(1'b0), // This port is removed from the modified MEM_WB module

        .pc_plus_4_out(pc_plus_4_mem_wb), .mem_data_out(mem_data_mem_wb), .alu_result_out(alu_result_mem_wb), // <<< MODIFIED
        .rd_addr_out(rd_addr_mem_wb), .reg_write_out(reg_write_mem_wb),
        .mem_to_reg_out(mem_to_reg_mem_wb), .reg_src_out(reg_src_mem_wb) // <<< MODIFIED
    );

    //================================================================
    // WB Stage
    //================================================================
    // <<< MODIFIED: Changed the MUX structure for JAL write-back
    Mux write_back_intermediate_mux (
        .i0(alu_result_mem_wb), .i1(mem_data_mem_wb),
        .s(mem_to_reg_mem_wb), .d(write_back_intermediate)
    );

    Mux write_back_final_mux (
        .i0(write_back_intermediate), .i1(pc_plus_4_mem_wb),
        .s(reg_src_mem_wb), .d(write_back_data)
    );

endmodule