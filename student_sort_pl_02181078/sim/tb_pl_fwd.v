`timescale 1ns / 1ps

module tb_pl_fwd;
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
        repeat (80) @(posedge clk);
        if (U_DM.dmem[0] !== 32'h00000005 ||
            U_CPU.U_RF.rf[7] !== 32'h00000003 ||
            U_CPU.U_RF.rf[8] !== 32'h00000005 ||
            U_CPU.U_RF.rf[9] !== 32'h00000005) begin
            $display("PL FWD FAIL: mem0=%h x7=%h x8=%h x9=%h",
                     U_DM.dmem[0], U_CPU.U_RF.rf[7], U_CPU.U_RF.rf[8], U_CPU.U_RF.rf[9]);
            $finish;
        end
        $display("PL FWD PASS: mem0=00000005 x7=00000003 x8=00000005 x9=00000005");
        $finish;
    end

    PLCPU U_CPU(.clk(clk), .reset(reset), .inst_in(instr), .Data_in(mem_dout),
        .PC_out(pc), .Addr_out(addr), .Data_out(cpu_dout), .mem_w(mem_w), .mem_r(mem_r),
        .reg_sel(5'b0), .reg_data(reg_data));
    imem #(.INIT_FILE("fwd.dat")) U_IM(.a(pc[8:2]), .spo(instr));
    dm U_DM(.clk(clk), .DMWr(mem_w), .addr(addr), .din(cpu_dout), .dout(mem_dout));
endmodule
