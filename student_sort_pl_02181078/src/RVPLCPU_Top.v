`timescale 1ns / 1ps

module RVPLCPUSOC_Top(
    input        clk,
    input        rstn,
    input [15:0] sw_i,
    output [7:0] disp_seg_o,
    output [7:0] disp_an_o
);
    wire rst = ~rstn;
    wire Clk_CPU;

    wire [31:0] instr;
    wire [31:0] pc;
    wire        memwrite;
    wire        memread;
    wire [31:0] dm_din;
    wire [31:0] dm_dout;
    wire [31:0] cpu_data_out;
    wire [31:0] cpu_data_addr;
    wire [31:0] cpu_data_in;
    wire [31:0] cpuseg7_data;
    wire [31:0] seg7_data;
    wire [31:0] reg_data;
    wire [6:0]  ram_addr;
    wire        ram_we;
    wire        seg7_we;

    clk_div U_CLKDIV(
        .clk(clk),
        .rst(rst),
        .SW15(sw_i[15]),
        .Clk_CPU(Clk_CPU)
    );

    PLCPU U_PLCPU(
        .clk(Clk_CPU),
        .reset(rst),
        .inst_in(instr),
        .Data_in(cpu_data_in),
        .PC_out(pc),
        .Addr_out(cpu_data_addr),
        .Data_out(cpu_data_out),
        .mem_w(memwrite),
        .mem_r(memread),
        .reg_sel(sw_i[4:0]),
        .reg_data(reg_data)
    );

    imem #(
        .INIT_FILE("riscv_sidascsorting_fpga.dat")
    ) U_IM(
        .a(pc[8:2]),
        .spo(instr)
    );

    dm U_DM(
        .clk(Clk_CPU),
        .DMWr(ram_we),
        .addr({23'b0, ram_addr, 2'b00}),
        .din(dm_din),
        .dout(dm_dout)
    );

    MIO_BUS U_MIO(
        .sw_i(sw_i),
        .mem_w(memwrite),
        .cpu_data_out(cpu_data_out),
        .cpu_data_addr(cpu_data_addr),
        .ram_data_out(dm_dout),
        .cpu_data_in(cpu_data_in),
        .ram_data_in(dm_din),
        .ram_addr(ram_addr),
        .cpuseg7_data(cpuseg7_data),
        .ram_we(ram_we),
        .seg7_we(seg7_we)
    );

    Multi_CH32 U_Multi(
        .clk(clk),
        .rst(rst),
        .EN(seg7_we),
        .ctrl(sw_i[5:0]),
        .Data0(cpuseg7_data),
        .data1({2'b0, pc[31:2]}),
        .data2(pc),
        .data3(instr),
        .data4(cpu_data_addr),
        .data5(cpu_data_out),
        .data6(dm_dout),
        .data7({23'b0, ram_addr, 2'b00}),
        .reg_data(reg_data),
        .seg7_data(seg7_data)
    );

    seg7x16 U_7SEG(
        .clk(clk),
        .rst(rst),
        .cs(1'b1),
        .i_data(seg7_data),
        .o_seg(disp_seg_o),
        .o_sel(disp_an_o)
    );
endmodule
