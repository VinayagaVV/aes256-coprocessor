import aes_pkg::*;
import sha_pkg::*;

module crypto_top (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        aes_key_valid,
    input  logic [1:0]  aes_mode,
    input  logic        aes_data_valid,
    input  logic [255:0] aes_key,
    input  logic [127:0] aes_data_in,
    output logic        aes_ready,
    output logic        aes_busy,
    output logic        aes_done,
    output logic [127:0] aes_data_out,

    input  logic        sha_msg_valid,
    input  logic [31:0] sha_msg_words [0:15],
    output logic        sha_ready,
    output logic        sha_busy,
    output logic        sha_done,
    output logic [31:0] sha_digest [0:7]
);

    aes_accelerator aes_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .key_valid (aes_key_valid),
        .mode      (aes_mode),
        .data_valid(aes_data_valid),
        .key       (aes_key),
        .data_in   (aes_data_in),
        .ready     (aes_ready),
        .busy      (aes_busy),
        .done      (aes_done),
        .data_out  (aes_data_out)
    );

    sha_accelerator sha_inst (
        .clk       (clk),
        .rst_n     (rst_n),
        .msg_valid (sha_msg_valid),
        .msg_words (sha_msg_words),
        .ready     (sha_ready),
        .busy      (sha_busy),
        .done      (sha_done),
        .digest    (sha_digest)
    );

endmodule
