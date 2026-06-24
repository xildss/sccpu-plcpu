`timescale 1ns / 1ps

module tb_pl_jmpfwd0;
    reg clk;
    reg reset;
    wire [31:0] instr, pc, addr, cpu_dout, mem_dout, reg_data;
    wire mem_w, mem_r;
    integer cycle;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        #30 reset = 1'b0;
        for (cycle = 0; cycle < 140; cycle = cycle + 1) begin
            @(posedge clk);
            if (U_DM.dmem[0] === 32'h00000005 &&
                U_DM.dmem[1] === 32'h00000005 &&
                U_CPU.U_RF.rf[5] === 32'h00000103 &&
                U_CPU.U_RF.rf[10] === 32'h00000005) begin
                $display("PL JMPFWD0 PASS: mem0=00000005 mem4=00000005 x5=00000103 x10=00000005");
                $finish;
            end
        end
        $display("PL JMPFWD0 FAIL: pc=%h mem0=%h mem4=%h x5=%h x6=%h x10=%h x11=%h",
                 pc, U_DM.dmem[0], U_DM.dmem[1], U_CPU.U_RF.rf[5],
                 U_CPU.U_RF.rf[6], U_CPU.U_RF.rf[10], U_CPU.U_RF.rf[11]);
        $finish;
    end

    PLCPU U_CPU(.clk(clk), .reset(reset), .inst_in(instr), .Data_in(mem_dout),
        .PC_out(pc), .Addr_out(addr), .Data_out(cpu_dout), .mem_w(mem_w), .mem_r(mem_r),
        .reg_sel(5'b0), .reg_data(reg_data));
    imem #(.INIT_FILE("jmpfwd0.dat")) U_IM(.a(pc[8:2]), .spo(instr));
    dm U_DM(.clk(clk), .DMWr(mem_w), .addr(addr), .din(cpu_dout), .dout(mem_dout));
endmodule
