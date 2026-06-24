`timescale 1ns / 1ps

module tb_pl_test30;
    reg clk;
    reg reset;

    wire [31:0] instr;
    wire [31:0] pc;
    wire        mem_w;
    wire        mem_r;
    wire [31:0] addr;
    wire [31:0] cpu_dout;
    wire [31:0] mem_dout;
    wire [31:0] reg_data;

    integer cycle;
    reg seen_jal_store;
    reg seen_return_store;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1'b1;
        cycle = 0;
        seen_jal_store = 1'b0;
        seen_return_store = 1'b0;
        #30;
        reset = 1'b0;

        for (cycle = 0; cycle < 1500; cycle = cycle + 1) begin
            @(posedge clk);
            if (mem_w && addr == 32'd16 && cpu_dout == 32'h0000055c)
                seen_jal_store = 1'b1;
            if (mem_w && addr == 32'd12 && cpu_dout == 32'h00000561)
                seen_return_store = 1'b1;

            if (seen_jal_store && seen_return_store) begin
                if (U_DM.dmem[0] !== 32'h0000000c) begin
                    $display("PL TEST30 FAIL: mem[0]=%h", U_DM.dmem[0]);
                    $finish;
                end
                if (U_DM.dmem[1] !== 32'h98765001) begin
                    $display("PL TEST30 FAIL: mem[4]=%h", U_DM.dmem[1]);
                    $finish;
                end
                if (U_DM.dmem[2] !== 32'h00001236) begin
                    $display("PL TEST30 FAIL: mem[8]=%h", U_DM.dmem[2]);
                    $finish;
                end
                $display("PL TEST30 PASS: mem0=%h mem4=%h mem8=%h first_mem12=00000561 first_mem16=0000055c",
                         U_DM.dmem[0], U_DM.dmem[1], U_DM.dmem[2]);
                $finish;
            end
        end

        $display("PL TEST30 FAIL: timeout seen_jal_store=%b seen_return_store=%b mem0=%h mem12=%h mem16=%h",
                 seen_jal_store, seen_return_store, U_DM.dmem[0], U_DM.dmem[3], U_DM.dmem[4]);
        $finish;
    end

    PLCPU U_CPU(
        .clk(clk),
        .reset(reset),
        .inst_in(instr),
        .Data_in(mem_dout),
        .PC_out(pc),
        .Addr_out(addr),
        .Data_out(cpu_dout),
        .mem_w(mem_w),
        .mem_r(mem_r),
        .reg_sel(5'b0),
        .reg_data(reg_data)
    );

    imem #(
        .INIT_FILE("Test_30_Instr.dat")
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
