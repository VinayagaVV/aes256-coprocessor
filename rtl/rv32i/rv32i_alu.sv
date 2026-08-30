module rv32i_alu (
    input  logic [31:0] src_a,
    input  logic [31:0] src_b,
    input  logic [4:0]  alu_op,
    output logic [31:0] result
);
    always_comb begin
        unique casez (alu_op)
            5'b0_0000: result = src_a + src_b;
            5'b0_1000: result = src_a - src_b;
            5'b0_?001: result = src_a << src_b[4:0];
            5'b0_?010: result = {31'b0, $signed(src_a) < $signed(src_b)};
            5'b0_?011: result = {31'b0, src_a < src_b};
            5'b0_?100: result = src_a ^ src_b;
            5'b0_0101: result = src_a >> src_b[4:0];
            5'b0_1101: result = $signed(src_a) >>> src_b[4:0];
            5'b0_?110: result = src_a | src_b;
            5'b0_?111: result = src_a & src_b;
            default:   result = '0;
        endcase
    end
endmodule
