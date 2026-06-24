`include "ctrl_encode_def.v"

module NPC(PC, NPCOp, IMM, RS1, NPC);
   input  [31:0] PC;
   input  [2:0]  NPCOp;
   input  [31:0] IMM;
   input  [31:0] RS1;
   output reg [31:0] NPC;

   always @(*) begin
      case (NPCOp)
         `NPC_BRANCH: NPC = PC + IMM;
         `NPC_JUMP:   NPC = PC + IMM;
         `NPC_JALR:   NPC = (RS1 + IMM) & 32'hffff_fffe;
         default:     NPC = PC + 32'd4;
      endcase
   end
endmodule
