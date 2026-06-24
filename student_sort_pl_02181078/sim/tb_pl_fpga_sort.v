`timescale 1ns / 1ps

module tb_pl_fpga_sort;
    reg clk;
    reg rstn;
    reg [15:0] sw_i;
    wire [7:0] disp_seg_o;
    wire [7:0] disp_an_o;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        sw_i = 16'b0;
        rstn = 1'b0;
        #100;
        rstn = 1'b1;

        sw_i[8] = 1'b0;
        repeat (100000) @(posedge clk);
        if (UUT.U_Multi.disp_data !== 32'h02181078) begin
            $display("PL FPGA SORT FAIL: SW8=0 display=%h", UUT.U_Multi.disp_data);
            $finish;
        end

        sw_i[8] = 1'b1;
        repeat (30000) @(posedge clk);
        if (UUT.U_Multi.disp_data !== 32'h00111278) begin
            $display("PL FPGA SORT FAIL: SW8=1 display=%h", UUT.U_Multi.disp_data);
            $finish;
        end

        $display("PL FPGA SORT PASS: SW8=0 display=02181078 SW8=1 display=00111278");
        $finish;
    end

    RVPLCPUSOC_Top UUT(
        .clk(clk),
        .rstn(rstn),
        .sw_i(sw_i),
        .disp_seg_o(disp_seg_o),
        .disp_an_o(disp_an_o)
    );
endmodule
