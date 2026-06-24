`timescale 1ns / 1ps

module tb_sc_sort;
    reg clk;
    reg reset;

    wire [31:0] instr;
    wire [31:0] pc;
    wire        mem_w;
    wire [31:0] addr;
    wire [31:0] cpu_dout;
    wire [31:0] mem_dout;
    wire [31:0] reg_data;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        #30;
        reset = 1'b0;
        repeat (3000) @(posedge clk);

        if (U_DM.dmem[96] !== 32'h02181078) begin
            $display("SC FAIL: original=%h", U_DM.dmem[96]);
            $finish;
        end
        if (U_DM.dmem[97] !== 32'h00111278) begin
            $display("SC FAIL: sorted=%h", U_DM.dmem[97]);
            $finish;
        end

        $display("SC PASS: original=%h sorted=%h", U_DM.dmem[96], U_DM.dmem[97]);
        $finish;
    end

    SCCPU U_CPU(
        .clk(clk),
        .reset(reset),
        .inst_in(instr),
        .Data_in(mem_dout),
        .mem_w(mem_w),
        .PC_out(pc),
        .Addr_out(addr),
        .Data_out(cpu_dout),
        .reg_sel(5'b0),
        .reg_data(reg_data)
    );

    imem #(
        .INIT_FILE("riscv_sidascsorting_sim.dat")
    ) U_IM(
        .a(pc[8:2]),
        .spo(instr)
    );

    dm U_DM(
        .clk(clk),
        .DMWr(mem_w),
        .addr(addr),
        .din(cpu_dout),
        .dout(mem_dout)
    );
endmodule
