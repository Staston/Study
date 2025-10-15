`timescale 1ns / 1ps

module testcase;

    // 1. 信号声明
    reg clk;
    reg rst;

    // 2. 实例化待测设计 (DUT - Design Under Test)
    riscv_pipeline_top dut (
        .clk(clk),
        .rst(rst)
    );

    // 3. 时钟生成
    // 每10个时间单位翻转一次，产生一个周期为20ns的时钟
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // 4. 主测试流程
    initial begin
        // 开始时，施加复位信号
        rst = 1;
        #20; // 复位信号持续20ns
        rst = 0;

        // 给予足够的时间让程序运行结束
        // 测试程序大约有80条指令，加上流水线建立和排空，
        // 我们需要至少 80 + 5 = 85 个周期。
        // 一个周期20ns，因此需要 85 * 20 = 1700ns。
        // 我们设定一个更长的仿真时间以确保所有指令执行完毕。
        // #2000;

        wait (dut.pc_current == 32'h00000134);

        // 检测到最后一条指令被取指后，再等待足够长的时间让它通过整个流水线
        // 5个周期 * 20ns/周期 = 100ns
        #100;

        // 5. 按照README要求的格式输出结果
        // 使用$time获取当前仿真时间
        // 使用Verilog的分层命名(hierarchical name)来访问设计内部的寄存器值
        // dut -> riscv_pipeline_top的实例名
        // reg_file -> RegFile模块的实例名
        // regs -> RegFile模块内部的寄存器数组
        $display("time: %0t", $time);
        $display("ra = 0x%h", dut.reg_file.regs[1]);  // x1 is ra
        $display("t0 = 0x%h", dut.reg_file.regs[5]);  // x5 is t0
        $display("t1 = 0x%h", dut.reg_file.regs[6]);  // x6 is t1
        $display("t2 = 0x%h", dut.reg_file.regs[7]);  // x7 is t2
        $display("t3 = 0x%h", dut.reg_file.regs[28]); // x28 is t3
        $display("t4 = 0x%h", dut.reg_file.regs[29]); // x29 is t4

        // 结束仿真
        $finish;
    end

    

    // (可选) 调试监控
    // 您可以取消下面这行代码的注释，以便在仿真过程中实时观察PC和指令的变化
    /*
    initial begin
        $monitor("Time=%0t, PC=0x%h, Instruction=0x%h",
                 $time, dut.pc_current, dut.instruction);
    end
    */

endmodule