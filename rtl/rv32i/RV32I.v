module RV32I (
    input  [31:0] instr_i,
    output [6:0]  opcode_o,
    output [4:0]  rs1_addr_o,
    output [4:0]  rs2_addr_o,
    output [4:0]  rd_addr_o,
    output [2:0]  funct3_o,
    output [6:0]  funct7_o,
    output reg [31:0] imm_o,
    output reg [4:0]  alu_op_o,
    output reg [1:0]  custom_op_o);
assign rs1_addr_o = instr_i[19:15];
assign rs2_addr_o = instr_i[24:20];
assign rd_addr_o  = instr_i[11:7];
assign funct7_o   = instr_i[31:25];
assign funct3_o   = instr_i[14:12];
assign opcode_o   = instr_i[6:0];
always @(*) begin
    case (opcode_o)
        7'b0110111,
        7'b0010111:
            imm_o = {instr_i[31:12], 12'b0};
        7'b1101111:
            imm_o = { {11{instr_i[31]}},instr_i[31],instr_i[19:12],instr_i[20], instr_i[30:21],1'b0};
        7'b1100111,
        7'b0000011,
        7'b0010011:
            imm_o = {{20{instr_i[31]}},instr_i[31:20]};
        7'b1100011:
            imm_o = {{19{instr_i[31]}},instr_i[31],instr_i[7],instr_i[30:25],instr_i[11:8],1'b0};
        7'b0100011:
            imm_o = {{20{instr_i[31]}},instr_i[31:25],instr_i[11:7]};
        default:
            imm_o = 32'b0;
    endcase
end
always @(*) begin
    if ((opcode_o == 7'b0110011) ||
        (opcode_o == 7'b0010011)) begin
        if (opcode_o == 7'b0010011 && funct3_o != 3'b001 && funct3_o != 3'b101)
            alu_op_o = {1'b0, 1'b0, funct3_o};
        else
            alu_op_o = {1'b0, instr_i[30], funct3_o};
    end
    else begin
        alu_op_o = 5'b00000;
    end
end
always @(*) begin
    custom_op_o = 2'b00;
    if (opcode_o == 7'b0001011) begin
        case (funct3_o)
            3'b000: custom_op_o = 2'b01;
            3'b001: custom_op_o = 2'b10;
            default: custom_op_o = 2'b00;
        endcase
    end
end
endmodule
