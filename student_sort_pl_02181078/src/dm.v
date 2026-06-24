module dm(clk, DMWr, addr, din, dout);
   input          clk;
   input          DMWr;
   input  [31:0] addr;
   input  [31:0] din;
   output [31:0] dout;

   reg [31:0] dmem[127:0];
   integer i;

   initial begin
      for (i = 0; i < 128; i = i + 1)
         dmem[i] = 32'b0;
   end

   always @(posedge clk) begin
      if (DMWr)
         dmem[addr[8:2]] <= din;
   end

   assign dout = dmem[addr[8:2]];
endmodule
