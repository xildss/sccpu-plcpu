`include "ctrl_encode_def.v"

module alu(A, B, ALUOp, C, Zero);
   input  [31:0] A, B;
   input  [4:0]  ALUOp;
   output reg [31:0] C;
   output Zero;

   reg branch_true;

   always @(*) begin
      branch_true = 1'b0;
      case (ALUOp)
         `ALUOp_lui:   C = B;
         `ALUOp_auipc: C = A + B;
         `ALUOp_add:   C = A + B;
         `ALUOp_sub:   C = A - B;  // also used by beq
         `ALUOp_bne: begin
            branch_true = (A != B);
            C = {31'b0, branch_true};
         end
         `ALUOp_blt: begin
            branch_true = ($signed(A) < $signed(B));
            C = {31'b0, branch_true};
         end
         `ALUOp_bge: begin
            branch_true = ($signed(A) >= $signed(B));
            C = {31'b0, branch_true};
         end
         `ALUOp_bltu: begin
            branch_true = (A < B);
            C = {31'b0, branch_true};
         end
         `ALUOp_bgeu: begin
            branch_true = (A >= B);
            C = {31'b0, branch_true};
         end
         `ALUOp_slt:  C = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
         `ALUOp_sltu: C = (A < B) ? 32'd1 : 32'd0;
         `ALUOp_xor:  C = A ^ B;
         `ALUOp_or:   C = A | B;
         `ALUOp_and:  C = A & B;
         `ALUOp_sll:  C = A << B[4:0];
         `ALUOp_srl:  C = A >> B[4:0];
         `ALUOp_sra:  C = $signed(A) >>> B[4:0];
         default:     C = 32'b0;
      endcase
   end

   assign Zero = (ALUOp == `ALUOp_bne  ||
                  ALUOp == `ALUOp_blt  ||
                  ALUOp == `ALUOp_bge  ||
                  ALUOp == `ALUOp_bltu ||
                  ALUOp == `ALUOp_bgeu) ? branch_true : (C == 32'b0);

endmodule
