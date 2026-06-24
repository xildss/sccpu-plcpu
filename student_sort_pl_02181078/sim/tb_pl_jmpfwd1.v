`timescale 1ns / 1ps

module tb_pl_jmpfwd1;
    reg clk;
    reg reset;
    wire [31:0] instr, pc, addr, cpu_dout, mem_dout, reg_data;
    wire mem_w, mem_r;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        #30 reset = 1'b0;
        repeat (160) @(posedge clk);
        if (U_DM.dmem[0] !== 32'h00000005 ||
            U_DM.dmem[2] !== 32'h00000028 ||
            U_CPU.U_RF.rf[7] !== 32'h00000005 ||
            U_CPU.U_RF.rf[9] !== 32'h00000105 ||
            U_CPU.U_RF.rf[10] !== 32'h00000000 ||
            U_CPU.U_RF.rf[13] !== 32'h00000028) begin
            $display("PL JMPFWD1 FAIL: mem0=%h mem8=%h x7=%h x9=%h x10=%h x13=%h",
                     U_DM.dmem[0], U_DM.dmem[2], U_CPU.U_RF.rf[7],
                     U_CPU.U_RF.rf[9], U_CPU.U_RF.rf[10], U_CPU.U_RF.rf[13]);
            $finish;
        end
        $display("PL JMPFWD1 PASS: mem0=00000005 mem8=00000028 x7=00000005 x9=00000105 x10=00000000 x13=00000028");
        $finish;
    end

    PLCPU U_CPU(.clk(clk), .reset(reset), .inst_in(instr), .Data_in(mem_dout),
        .PC_out(pc), .Addr_out(addr), .Data_out(cpu_dout), .mem_w(mem_w), .mem_r(mem_r),
        .reg_sel(5'b0), .reg_data(reg_data));
    imem #(.INIT_FILE("jmpfwd1.dat")) U_IM(.a(pc[8:2]), .spo(instr));
    dm U_DM(.clk(clk), .DMWr(mem_w), .addr(addr), .din(cpu_dout), .dout(mem_dout));
endmodule
