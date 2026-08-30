import aes_pkg::*;

module aes_accelerator (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       key_valid,
    input  logic [1:0] mode,
    input  logic       data_valid,

    input  logic [255:0] key,
    input  logic [127:0] data_in,

    output logic       ready,
    output logic       busy,
    output logic       done,
    output logic [127:0] data_out
);

    localparam NUM_ROUNDS = 14;
    localparam NUM_KEYS = NUM_ROUNDS + 1;

    logic [127:0] rk[NUM_KEYS];
    logic         key_loaded;

    wire [127:0] rk_comb[NUM_KEYS];
    assign rk_comb[0] = key[255:128];
    assign rk_comb[1] = key[127:0];
    generate
        for (genvar gi = 2; gi <= NUM_ROUNDS; gi++) begin : keygen
            if (gi % 2 == 0) begin : even
                assign rk_comb[gi] = aes_pkg::key_expand_step_256_even(
                    rk_comb[gi-2], rk_comb[gi-1], gi/2);
            end else begin : odd
                assign rk_comb[gi] = aes_pkg::key_expand_step_256_odd(
                    rk_comb[gi-2], rk_comb[gi-1]);
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_KEYS; i++) rk[i] <= '0;
            key_loaded <= 1'b0;
        end else if (key_valid) begin
            for (int i = 0; i < NUM_KEYS; i++) rk[i] <= rk_comb[i];
            key_loaded <= 1'b1;
        end else if (data_valid && done) begin
            key_loaded <= 1'b0;
        end
    end

    generate
        import aes_pkg::*;
        logic [127:0] enc_pipe[NUM_ROUNDS:0];
        logic [NUM_ROUNDS:0]  enc_valid;
        for (genvar i = 0; i <= NUM_ROUNDS; i++) begin : estage
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    enc_pipe[i] <= '0;
                    enc_valid[i] <= 1'b0;
                end else if (i == 0) begin
                    if (mode == 1 && key_loaded && data_valid && ready) begin
                        enc_pipe[i] <= add_round_key(data_in, rk[i]);
                        enc_valid[i] <= 1'b1;
                    end else begin
                        enc_valid[i] <= 1'b0;
                    end
                end else begin
                    enc_pipe[i] <= enc_valid[i-1]
                        ? (i == NUM_ROUNDS
                            ? aes_enc_final_round(enc_pipe[i-1], rk[i])
                            : aes_enc_round(enc_pipe[i-1], rk[i]))
                        : enc_pipe[i];
                    enc_valid[i] <= enc_valid[i-1];
                end
            end
        end
    endgenerate

    generate
        import aes_pkg::*;
        logic [127:0] dec_pipe[NUM_ROUNDS:0];
        logic [NUM_ROUNDS:0]  dec_valid;
        for (genvar i = 0; i <= NUM_ROUNDS; i++) begin : dstage
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    dec_pipe[i] <= '0;
                    dec_valid[i] <= 1'b0;
                end else if (i == 0) begin
                    if (mode == 2 && key_loaded && data_valid && ready) begin
                        dec_pipe[i] <= add_round_key(data_in, rk[NUM_ROUNDS]);
                        dec_valid[i] <= 1'b1;
                    end else begin
                        dec_valid[i] <= 1'b0;
                    end
                end else begin
                    dec_pipe[i] <= dec_valid[i-1]
                        ? (i == NUM_ROUNDS
                            ? aes_dec_final_round(dec_pipe[i-1], rk[0])
                            : aes_dec_round(dec_pipe[i-1], rk[NUM_ROUNDS-i]))
                        : dec_pipe[i];
                    dec_valid[i] <= dec_valid[i-1];
                end
            end
        end
    endgenerate

    assign ready  = key_loaded && (mode != 0);
    assign done   = (mode == 1 && enc_valid[NUM_ROUNDS]) || (mode == 2 && dec_valid[NUM_ROUNDS]);
    assign data_out = (mode == 1) ? enc_pipe[NUM_ROUNDS] :
                      (mode == 2) ? dec_pipe[NUM_ROUNDS] : '0;

endmodule
