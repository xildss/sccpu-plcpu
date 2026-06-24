`timescale 1ns / 1ps

module tb_pl_jmpflush;
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
        repeat (100) @(posedge clk);
        if (U_CPU.U_RF.rf[7] !== 32'h00000002 ||
            U_CPU.U_RF.rf[8] !== 32'h00000000 ||
            U_CPU.U_RF.rf[9] !== 32'h00000000) begin
            $display("PL JMPFLUSH FAIL: x7=%h x8=%h x9=%h",
                     U_CPU.U_RF.rf[7], U_CPU.U_RF.rf[8], U_CPU.U_RF.rf[9]);
            $finish;
        end
        $display("PL JMPFLUSH PASS: x7=00000002 x8=00000000 x9=00000000");
        $finish;
    end

    PLCPU U_CPU(.clk(clk), .reset(reset), .inst_in(instr), .Data_in(mem_dout),
        .PC_out(pc), .Addr_out(addr), .Data_out(cpu_dout), .mem_w(mem_w), .mem_r(mem_r),
        .reg_sel(5'b0), .reg_data(reg_data));
    imem #(.INIT_FILE("jmpflush.dat")) U_IM(.a(pc[8:2]), .spo(instr));
    dm U_DM(.clk(clk), .DMWr(mem_w), .addr(addr), .din(cpu_dout), .dout(mem_dout));
endmodule
