module shared_mem (
    input  logic         clk,
    input  logic         rst_n,

    input  logic [4:0]   cpu_addr,
    input  logic [31:0]  cpu_wdata,
    input  logic         cpu_wr,

    input  logic [3:0]   fsm_addr,
    output logic [127:0] fsm_rdata
);
    logic [31:0] mem [0:31];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 32; i++) mem[i] <= '0;
        end else if (cpu_wr) begin
            mem[cpu_addr] <= cpu_wdata;
        end
    end

    assign fsm_rdata = {mem[{fsm_addr[2:0], 2'd3}],
                        mem[{fsm_addr[2:0], 2'd2}],
                        mem[{fsm_addr[2:0], 2'd1}],
                        mem[{fsm_addr[2:0], 2'd0}]};

endmodule
