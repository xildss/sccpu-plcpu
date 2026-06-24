`include "ctrl_encode_def.v"

module ctrl(Op, Funct7, Funct3, Zero,
            RegWrite, MemWrite,
            EXTOp, ALUOp, NPCOp,
            ALUSrc, WDSel);

   input  [6:0] Op;
   input  [6:0] Funct7;
   input  [2:0] Funct3;
   input        Zero;       // kept for CODExp interface compatibility

   output reg       RegWrite;
   output reg       MemWrite;
   output reg [5:0] EXTOp;
   output reg [4:0] ALUOp;
   output reg [2:0] NPCOp;
   output reg       ALUSrc;
   output reg [1:0] WDSel;

   wire rtype   = (Op == 7'b0110011);
   wire itype_r = (Op == 7'b0010011);
   wire itype_l = (Op == 7'b0000011);
   wire stype   = (Op == 7'b0100011);
   wire sbtype  = (Op == 7'b1100011);
   wire lui     = (Op == 7'b0110111);
   wire auipc   = (Op == 7'b0010111);
   wire jal     = (Op == 7'b1101111);
   wire jalr    = (Op == 7'b1100111);

   always @(*) begin
      RegWrite = 1'b0;
      MemWrite = 1'b0;
      EXTOp    = 6'b0;
      ALUOp    = `ALUOp_nop;
      NPCOp    = `NPC_PLUS4;
      ALUSrc   = 1'b0;
      WDSel    = `WDSel_FromALU;

      if (rtype) begin
         RegWrite = 1'b1;
         case ({Funct7[5], Funct3})
            4'b0000: ALUOp = `ALUOp_add;
            4'b1000: ALUOp = `ALUOp_sub;
            4'b0001: ALUOp = `ALUOp_sll;
            4'b0010: ALUOp = `ALUOp_slt;
            4'b0011: ALUOp = `ALUOp_sltu;
            4'b0100: ALUOp = `ALUOp_xor;
            4'b0101: ALUOp = `ALUOp_srl;
            4'b1101: ALUOp = `ALUOp_sra;
            4'b0110: ALUOp = `ALUOp_or;
            4'b0111: ALUOp = `ALUOp_and;
            default: ALUOp = `ALUOp_nop;
         endcase
      end else if (itype_r) begin
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_ITYPE;
         case (Funct3)
            3'b000: ALUOp = `ALUOp_add;   // addi
            3'b010: ALUOp = `ALUOp_slt;   // slti
            3'b011: ALUOp = `ALUOp_sltu;  // sltiu
            3'b100: ALUOp = `ALUOp_xor;   // xori
            3'b110: ALUOp = `ALUOp_or;    // ori
            3'b111: ALUOp = `ALUOp_and;   // andi
            3'b001: ALUOp = `ALUOp_sll;   // slli
            3'b101: ALUOp = Funct7[5] ? `ALUOp_sra : `ALUOp_srl; // srai/srli
            default: ALUOp = `ALUOp_nop;
         endcase
      end else if (itype_l) begin
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_ITYPE;
         ALUOp    = `ALUOp_add;
         WDSel    = `WDSel_FromMEM;
      end else if (stype) begin
         MemWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_STYPE;
         ALUOp    = `ALUOp_add;
      end else if (sbtype) begin
         EXTOp = `EXT_CTRL_BTYPE;
         NPCOp = `NPC_BRANCH;
         case (Funct3)
            3'b000: ALUOp = `ALUOp_sub;   // beq
            3'b001: ALUOp = `ALUOp_bne;
            3'b100: ALUOp = `ALUOp_blt;
            3'b101: ALUOp = `ALUOp_bge;
            3'b110: ALUOp = `ALUOp_bltu;
            3'b111: ALUOp = `ALUOp_bgeu;
            default: ALUOp = `ALUOp_nop;
         endcase
      end else if (lui) begin
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_UTYPE;
         ALUOp    = `ALUOp_lui;
      end else if (auipc) begin
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_UTYPE;
         ALUOp    = `ALUOp_auipc;
      end else if (jal) begin
         RegWrite = 1'b1;
         EXTOp    = `EXT_CTRL_JTYPE;
         NPCOp    = `NPC_JUMP;
         WDSel    = `WDSel_FromPC;
      end else if (jalr) begin
         RegWrite = 1'b1;
         ALUSrc   = 1'b1;
         EXTOp    = `EXT_CTRL_ITYPE;
         NPCOp    = `NPC_JALR;
         ALUOp    = `ALUOp_add;
         WDSel    = `WDSel_FromPC;
      end
   end
endmodule
