import sha_pkg::*;

module sha_accelerator (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        msg_valid,
    input  logic [31:0] msg_words [0:15],

    output logic        ready,
    output logic        busy,
    output logic        done,
    output logic [31:0] digest [0:7]
);

    /* verilator lint_off UNOPTFLAT */
    logic [31:0] msg_words_reg[0:15];
    wire [31:0] w_comb[0:63];
    /* verilator lint_on UNOPTFLAT */

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 16; i++) msg_words_reg[i] <= '0;
        end else if (msg_valid && ready) begin
            for (int i = 0; i < 16; i++) msg_words_reg[i] <= msg_words[i];
        end
    end

    generate
        for (genvar gi = 0; gi < 1; gi++) begin : w_init
            assign w_comb[gi] = (msg_valid && ready) ? msg_words[gi] : msg_words_reg[gi];
        end
        for (genvar gi = 1; gi < 16; gi++) begin : w_init_reg
            assign w_comb[gi] = msg_words_reg[gi];
        end
        for (genvar gi = 16; gi < 64; gi++) begin : w_sched
            assign w_comb[gi] = w_schedule(w_comb[gi-2], w_comb[gi-7], w_comb[gi-15], w_comb[gi-16]);
        end
    endgenerate

    logic [255:0] comp_pipe[0:63];
    logic [63:0]  comp_valid;
    logic         internal_busy;

    generate
        for (genvar gi = 0; gi < 64; gi++) begin : cstage
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    comp_pipe[gi] <= '0;
                    comp_valid[gi] <= 1'b0;
                end else if (gi == 0) begin
                    if (msg_valid && ready) begin
                        comp_pipe[gi] <= sha_round(
                            {H_INIT[0], H_INIT[1], H_INIT[2], H_INIT[3],
                             H_INIT[4], H_INIT[5], H_INIT[6], H_INIT[7]},
                            w_comb[0], 0
                        );
                        comp_valid[gi] <= 1'b1;
                    end else begin
                        comp_valid[gi] <= 1'b0;
                    end
                end else begin
                    if (comp_valid[gi-1]) begin
                        comp_pipe[gi] <= sha_round(comp_pipe[gi-1], w_comb[gi], gi);
                    end else begin
                        comp_pipe[gi] <= comp_pipe[gi];
                    end
                    comp_valid[gi] <= comp_valid[gi-1];
                end
            end
        end
    endgenerate

    logic [255:0] state_out;
    assign state_out = comp_pipe[63];

    assign ready = !internal_busy;
    assign done  = comp_valid[63];
    assign busy  = internal_busy;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            internal_busy <= 1'b0;
        end else if (msg_valid && ready) begin
            internal_busy <= 1'b1;
        end else if (done) begin
            internal_busy <= 1'b0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 8; i++) digest[i] <= '0;
        end else if (done) begin
            digest[0] <= state_out[255:224] + H_INIT[0];
            digest[1] <= state_out[223:192] + H_INIT[1];
            digest[2] <= state_out[191:160] + H_INIT[2];
            digest[3] <= state_out[159:128] + H_INIT[3];
            digest[4] <= state_out[127:96]  + H_INIT[4];
            digest[5] <= state_out[95:64]   + H_INIT[5];
            digest[6] <= state_out[63:32]   + H_INIT[6];
            digest[7] <= state_out[31:0]    + H_INIT[7];
        end
    end

endmodule
