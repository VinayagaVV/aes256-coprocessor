module protected_mem (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [4:0]   cpu_addr,
    output logic [31:0]  cpu_rdata,

    input  logic         fsm_wr,
    input  logic [3:0]   fsm_addr,
    input  logic [127:0] fsm_wdata
);
    logic [31:0] mem [0:31];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 32; i++) mem[i] <= '0;
        end else if (fsm_wr) begin
            for (int i = 0; i < 4; i++) mem[{fsm_addr[2:0], i[1:0]}] <= fsm_wdata[i*32 +: 32];
        end
    end

    assign cpu_rdata = mem[cpu_addr];

endmodule
