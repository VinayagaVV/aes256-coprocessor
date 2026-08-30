module rv32i_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] instr,
    input  logic        instr_valid,
    output logic        done,

    output logic [7:0]  mem_addr,
    input  logic [31:0] mem_rdata,
    output logic [31:0] mem_wdata,
    output logic        mem_we,
    output logic        mem_valid,

    output logic [4:0]  debug_rd_addr,
    output logic [31:0] debug_rd_data,
    output logic        debug_reg_write,
    output logic [31:0] debug_alu_result,
    output logic [4:0]  debug_alu_op,
    output logic [31:0] debug_rs1_data,
    output logic [31:0] debug_alu_src_b
);

    logic [6:0]  opcode;
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] imm;
    logic [4:0]  alu_op;
    logic [1:0]  custom_op;

    RV32I dec (
        .instr_i    (instr),
        .opcode_o   (opcode),
        .rs1_addr_o (rs1_addr),
        .rs2_addr_o (rs2_addr),
        .rd_addr_o  (rd_addr),
        .funct3_o   (funct3),
        .funct7_o   (funct7),
        .imm_o      (imm),
        .alu_op_o   (alu_op),
        .custom_op_o(custom_op)
    );

    logic [31:0] regfile[31:0];
    logic [31:0] rs1_data, rs2_data;
    logic [4:0]  rd_waddr;
    logic [31:0] rd_wdata;
    logic        reg_write;

    assign rs1_data = (rs1_addr == 5'b0) ? '0 : regfile[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? '0 : regfile[rs2_addr];

    initial for (int i = 0; i < 32; i++) regfile[i] = '0;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 1; i < 32; i++) regfile[i] <= '0;
        end else if (reg_write && rd_waddr != 5'b0) begin
            regfile[rd_waddr] <= rd_wdata;
        end
    end

    logic [31:0] alu_src_b;
    logic [31:0] alu_result;

    assign alu_src_b = (opcode == 7'b0010011) ? imm : rs2_data;

    rv32i_alu alu (
        .src_a  (rs1_data),
        .src_b  (alu_src_b),
        .alu_op (alu_op),
        .result (alu_result)
    );

    logic is_rtype, is_imm, is_load, is_store, is_branch, is_jal, is_jalr, is_lui, is_auipc, is_custom;

    assign is_rtype = (opcode == 7'b0110011);
    assign is_imm   = (opcode == 7'b0010011);
    assign is_load  = (opcode == 7'b0000011);
    assign is_store = (opcode == 7'b0100011);
    assign is_branch= (opcode == 7'b1100011);
    assign is_jal   = (opcode == 7'b1101111);
    assign is_jalr  = (opcode == 7'b1100111);
    assign is_lui   = (opcode == 7'b0110111);
    assign is_auipc = (opcode == 7'b0010111);
    assign is_custom = (opcode == 7'b0001011);

    always_comb begin
        unique case (1'b1)
            is_rtype:   rd_wdata = alu_result;
            is_imm:     rd_wdata = alu_result;
            is_custom:  rd_wdata = alu_result;
            is_lui:     rd_wdata = imm;
            is_auipc:   rd_wdata = imm;
            is_jal:     rd_wdata = 32'b0;
            is_jalr:    rd_wdata = 32'b0;
            is_load:    rd_wdata = mem_rdata;
            default:    rd_wdata = '0;
        endcase
    end

    assign reg_write = instr_valid && !is_store && !is_branch && (opcode != 7'b0000000);
    assign rd_waddr  = rd_addr;
    assign done      = instr_valid;

    assign mem_addr  = rs1_data[7:0] + imm[7:0];
    assign mem_wdata = rs2_data;
    assign mem_we    = instr_valid && is_store;
    assign mem_valid = instr_valid && (is_load || is_store);

    assign debug_rd_addr    = rd_waddr;
    assign debug_rd_data    = rd_wdata;
    assign debug_reg_write  = reg_write;
    assign debug_alu_result = alu_result;
    assign debug_alu_op     = alu_op;
    assign debug_rs1_data   = rs1_data;
    assign debug_alu_src_b  = alu_src_b;

endmodule
