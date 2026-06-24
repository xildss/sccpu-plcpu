module imem #(
    parameter INIT_FILE = "riscv_sidascsorting_fpga.dat"
)(
    input  [6:0]  a,
    output [31:0] spo
);
    reg [31:0] rom[127:0];
    integer i;

    initial begin
        for (i = 0; i < 128; i = i + 1)
            rom[i] = 32'h00000013;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, rom);
    end

    assign spo = rom[a];
endmodule
