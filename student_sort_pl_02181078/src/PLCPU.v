`include "ctrl_encode_def.v"

module PLCPU(
    input         clk,
    input         reset,
    input  [31:0] inst_in,
    input  [31:0] Data_in,
    output [31:0] PC_out,
    output [31:0] Addr_out,
    output [31:0] Data_out,
    output        mem_w,
    output        mem_r,
    input  [4:0]  reg_sel,
    output [31:0] reg_data
);
    localparam NOP = 32'h00000013;

    reg [31:0] pc;
    assign PC_out = pc;

    reg [31:0] IF_ID_pc;
    reg [31:0] IF_ID_instr;

    wire [6:0] ID_Op     = IF_ID_instr[6:0];
    wire [4:0] ID_rd     = IF_ID_instr[11:7];
    wire [2:0] ID_Funct3 = IF_ID_instr[14:12];
    wire [4:0] ID_rs1    = IF_ID_instr[19:15];
    wire [4:0] ID_rs2    = IF_ID_instr[24:20];
    wire [6:0] ID_Funct7 = IF_ID_instr[31:25];

    wire [11:0] ID_iimm = IF_ID_instr[31:20];
    wire [11:0] ID_simm = {IF_ID_instr[31:25], IF_ID_instr[11:7]};
    wire [11:0] ID_bimm = {IF_ID_instr[31], IF_ID_instr[7], IF_ID_instr[30:25], IF_ID_instr[11:8]};
    wire [19:0] ID_uimm = IF_ID_instr[31:12];
    wire [19:0] ID_jimm = {IF_ID_instr[31], IF_ID_instr[19:12], IF_ID_instr[20], IF_ID_instr[30:21]};

    wire        ID_RegWrite;
    wire        ID_MemWrite;
    wire        ID_MemRead;
    wire [5:0]  ID_EXTOp;
    wire [4:0]  ID_ALUOp;
    wire [2:0]  ID_NPCOp;
    wire        ID_ALUSrc;
    wire [1:0]  ID_WDSel;
    wire [31:0] ID_immout;
    wire [31:0] ID_RD1;
    wire [31:0] ID_RD2;

    reg  [4:0]  WB_rd;
    reg  [31:0] WB_pc;
    reg  [31:0] WB_aluout;
    reg  [31:0] WB_memdata;
    reg         WB_RegWrite;
    reg  [1:0]  WB_WDSel;
    wire [31:0] WB_data;

    assign WB_data = (WB_WDSel == `WDSel_FromMEM) ? WB_memdata :
                     (WB_WDSel == `WDSel_FromPC)  ? (WB_pc + 32'd4) :
                                                    WB_aluout;

    ctrl U_ctrl(
        .Op(ID_Op), .Funct7(ID_Funct7), .Funct3(ID_Funct3), .Zero(1'b0),
        .RegWrite(ID_RegWrite), .MemWrite(ID_MemWrite), .MemRead(ID_MemRead),
        .EXTOp(ID_EXTOp), .ALUOp(ID_ALUOp), .NPCOp(ID_NPCOp),
        .ALUSrc(ID_ALUSrc), .WDSel(ID_WDSel)
    );

    EXT U_EXT(
        .iimm(ID_iimm),
        .simm(ID_simm),
        .bimm(ID_bimm),
        .uimm(ID_uimm),
        .jimm(ID_jimm),
        .EXTOp(ID_EXTOp),
        .immout(ID_immout)
    );

    RF U_RF(
        .clk(clk),
        .rst(reset),
        .RFWr(WB_RegWrite),
        .A1(ID_rs1),
        .A2(ID_rs2),
        .A3(WB_rd),
        .WD(WB_data),
        .RD1(ID_RD1),
        .RD2(ID_RD2),
        .reg_sel(reg_sel),
        .reg_data(reg_data)
    );

    reg [31:0] ID_EX_pc;
    reg [31:0] ID_EX_instr;
    reg [31:0] ID_EX_immout;
    reg [31:0] ID_EX_RD1;
    reg [31:0] ID_EX_RD2;
    reg [4:0]  ID_EX_rs1;
    reg [4:0]  ID_EX_rs2;
    reg [4:0]  ID_EX_rd;
    reg        ID_EX_RegWrite;
    reg        ID_EX_MemWrite;
    reg        ID_EX_MemRead;
    reg [4:0]  ID_EX_ALUOp;
    reg [2:0]  ID_EX_NPCOp;
    reg        ID_EX_ALUSrc;
    reg [1:0]  ID_EX_WDSel;
    reg        ID_EX_UsePC;

    reg [31:0] EX_MEM_pc;
    reg [31:0] EX_MEM_aluout;
    reg [31:0] EX_MEM_writedata;
    reg [4:0]  EX_MEM_rs2;
    reg [4:0]  EX_MEM_rd;
    reg        EX_MEM_RegWrite;
    reg        EX_MEM_MemWrite;
    reg        EX_MEM_MemRead;
    reg [1:0]  EX_MEM_WDSel;

    wire id_uses_rs1 = (ID_Op == 7'b0110011) || (ID_Op == 7'b0010011) ||
                       (ID_Op == 7'b0000011) || (ID_Op == 7'b0100011) ||
                       (ID_Op == 7'b1100011) || (ID_Op == 7'b1100111);
    wire id_uses_rs2 = (ID_Op == 7'b0110011) || (ID_Op == 7'b0100011) ||
                       (ID_Op == 7'b1100011);
    wire load_use_hazard = ID_EX_MemRead && (ID_EX_rd != 5'b0) &&
                           ((id_uses_rs1 && ID_EX_rd == ID_rs1) ||
                            (id_uses_rs2 && ID_EX_rd == ID_rs2));

    wire [31:0] EX_MEM_forward_data = (EX_MEM_WDSel == `WDSel_FromPC) ?
                                      (EX_MEM_pc + 32'd4) : EX_MEM_aluout;

    wire forwardA_MEM = EX_MEM_RegWrite && !EX_MEM_MemRead && (EX_MEM_rd != 5'b0) &&
                        (EX_MEM_rd == ID_EX_rs1);
    wire forwardA_WB  = WB_RegWrite && (WB_rd != 5'b0) && (WB_rd == ID_EX_rs1);
    wire forwardB_MEM = EX_MEM_RegWrite && !EX_MEM_MemRead && (EX_MEM_rd != 5'b0) &&
                        (EX_MEM_rd == ID_EX_rs2);
    wire forwardB_WB  = WB_RegWrite && (WB_rd != 5'b0) && (WB_rd == ID_EX_rs2);

    wire [31:0] EX_rs1_data = forwardA_MEM ? EX_MEM_forward_data :
                              forwardA_WB  ? WB_data : ID_EX_RD1;
    wire [31:0] EX_rs2_data = forwardB_MEM ? EX_MEM_forward_data :
                              forwardB_WB  ? WB_data : ID_EX_RD2;

    wire [31:0] EX_alu_A = ID_EX_UsePC ? ID_EX_pc : EX_rs1_data;
    wire [31:0] EX_alu_B = ID_EX_ALUSrc ? ID_EX_immout : EX_rs2_data;
    wire [31:0] EX_aluout;
    wire        EX_branch_true;

    alu U_alu(
        .A(EX_alu_A),
        .B(EX_alu_B),
        .ALUOp(ID_EX_ALUOp),
        .C(EX_aluout),
        .Zero(EX_branch_true)
    );

    wire EX_is_branch = (ID_EX_NPCOp == `NPC_BRANCH);
    wire EX_redirect = (ID_EX_NPCOp == `NPC_JUMP) ||
                       (ID_EX_NPCOp == `NPC_JALR) ||
                       (EX_is_branch && EX_branch_true);
    wire [31:0] EX_redirect_pc = (ID_EX_NPCOp == `NPC_JALR) ?
                                 ((EX_rs1_data + ID_EX_immout) & 32'hffff_fffe) :
                                 (ID_EX_pc + ID_EX_immout);

    wire [31:0] MEM_store_data = (EX_MEM_MemWrite && WB_RegWrite &&
                                  (WB_rd != 5'b0) && (WB_rd == EX_MEM_rs2)) ?
                                 WB_data : EX_MEM_writedata;

    assign Addr_out = EX_MEM_aluout;
    assign Data_out = MEM_store_data;
    assign mem_w = EX_MEM_MemWrite;
    assign mem_r = EX_MEM_MemRead;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'b0;
            IF_ID_pc <= 32'b0;
            IF_ID_instr <= NOP;

            ID_EX_pc <= 32'b0;
            ID_EX_instr <= NOP;
            ID_EX_immout <= 32'b0;
            ID_EX_RD1 <= 32'b0;
            ID_EX_RD2 <= 32'b0;
            ID_EX_rs1 <= 5'b0;
            ID_EX_rs2 <= 5'b0;
            ID_EX_rd <= 5'b0;
            ID_EX_RegWrite <= 1'b0;
            ID_EX_MemWrite <= 1'b0;
            ID_EX_MemRead <= 1'b0;
            ID_EX_ALUOp <= `ALUOp_nop;
            ID_EX_NPCOp <= `NPC_PLUS4;
            ID_EX_ALUSrc <= 1'b0;
            ID_EX_WDSel <= `WDSel_FromALU;
            ID_EX_UsePC <= 1'b0;

            EX_MEM_pc <= 32'b0;
            EX_MEM_aluout <= 32'b0;
            EX_MEM_writedata <= 32'b0;
            EX_MEM_rs2 <= 5'b0;
            EX_MEM_rd <= 5'b0;
            EX_MEM_RegWrite <= 1'b0;
            EX_MEM_MemWrite <= 1'b0;
            EX_MEM_MemRead <= 1'b0;
            EX_MEM_WDSel <= `WDSel_FromALU;

            WB_pc <= 32'b0;
            WB_aluout <= 32'b0;
            WB_memdata <= 32'b0;
            WB_rd <= 5'b0;
            WB_RegWrite <= 1'b0;
            WB_WDSel <= `WDSel_FromALU;
        end else begin
            if (EX_redirect)
                pc <= EX_redirect_pc;
            else if (!load_use_hazard)
                pc <= pc + 32'd4;

            if (EX_redirect) begin
                IF_ID_pc <= 32'b0;
                IF_ID_instr <= NOP;
            end else if (!load_use_hazard) begin
                IF_ID_pc <= pc;
                IF_ID_instr <= inst_in;
            end

            if (EX_redirect || load_use_hazard) begin
                ID_EX_pc <= 32'b0;
                ID_EX_instr <= NOP;
                ID_EX_immout <= 32'b0;
                ID_EX_RD1 <= 32'b0;
                ID_EX_RD2 <= 32'b0;
                ID_EX_rs1 <= 5'b0;
                ID_EX_rs2 <= 5'b0;
                ID_EX_rd <= 5'b0;
                ID_EX_RegWrite <= 1'b0;
                ID_EX_MemWrite <= 1'b0;
                ID_EX_MemRead <= 1'b0;
                ID_EX_ALUOp <= `ALUOp_nop;
                ID_EX_NPCOp <= `NPC_PLUS4;
                ID_EX_ALUSrc <= 1'b0;
                ID_EX_WDSel <= `WDSel_FromALU;
                ID_EX_UsePC <= 1'b0;
            end else begin
                ID_EX_pc <= IF_ID_pc;
                ID_EX_instr <= IF_ID_instr;
                ID_EX_immout <= ID_immout;
                ID_EX_RD1 <= ID_RD1;
                ID_EX_RD2 <= ID_RD2;
                ID_EX_rs1 <= ID_rs1;
                ID_EX_rs2 <= ID_rs2;
                ID_EX_rd <= ID_rd;
                ID_EX_RegWrite <= ID_RegWrite;
                ID_EX_MemWrite <= ID_MemWrite;
                ID_EX_MemRead <= ID_MemRead;
                ID_EX_ALUOp <= ID_ALUOp;
                ID_EX_NPCOp <= ID_NPCOp;
                ID_EX_ALUSrc <= ID_ALUSrc;
                ID_EX_WDSel <= ID_WDSel;
                ID_EX_UsePC <= (ID_Op == 7'b0010111);
            end

            EX_MEM_pc <= ID_EX_pc;
            EX_MEM_aluout <= EX_aluout;
            EX_MEM_writedata <= EX_rs2_data;
            EX_MEM_rs2 <= ID_EX_rs2;
            EX_MEM_rd <= ID_EX_rd;
            EX_MEM_RegWrite <= ID_EX_RegWrite;
            EX_MEM_MemWrite <= ID_EX_MemWrite;
            EX_MEM_MemRead <= ID_EX_MemRead;
            EX_MEM_WDSel <= ID_EX_WDSel;

            WB_pc <= EX_MEM_pc;
            WB_aluout <= EX_MEM_aluout;
            WB_memdata <= Data_in;
            WB_rd <= EX_MEM_rd;
            WB_RegWrite <= EX_MEM_RegWrite;
            WB_WDSel <= EX_MEM_WDSel;
        end
    end
endmodule
