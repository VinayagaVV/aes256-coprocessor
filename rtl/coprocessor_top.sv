module coprocessor_top (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start,
    input  logic [127:0] enc_data_0,
    input  logic [127:0] enc_data_1,

    output logic        tx_valid,
    output logic [511:0] tx_data,

    output logic        core_irq,
    output logic        busy,

    input  logic [31:0] ctrl_instr,
    input  logic        ctrl_instr_valid,

    output logic [4:0]  dbg_state,
    output logic [127:0] dbg_aes_data_out,
    output logic [255:0] dbg_enc_result,
    output logic [255:0] dbg_sha_result
);
    import aes_pkg::*;
    import sha_pkg::*;

    logic [255:0] aes_key;

    logic        aes_key_valid;
    logic [1:0]  aes_mode;
    logic        aes_data_valid;
    logic [127:0] aes_data_in;
    logic        aes_ready;
    logic        aes_done;
    logic [127:0] aes_data_out;

    logic        sha_msg_valid;
    logic [31:0] sha_msg_words [0:15];
    logic        sha_ready;
    logic        sha_done;
    logic [31:0] sha_digest [0:7];

    logic        core_done;
    logic        pmem_wr;
    logic [3:0]  pmem_addr;
    logic [127:0] pmem_wdata;
    logic [3:0]  smem_fsm_addr;
    logic [127:0] smem_fsm_rdata;
    logic [3:0]  fsm_state;

    logic        core_done_sig;
    logic [31:0] core_instr;
    logic        core_instr_valid;
    logic [7:0]  core_mem_addr;
    logic [31:0] core_mem_rdata;
    logic [31:0] core_mem_wdata;
    logic        core_mem_we;
    logic        core_mem_valid;

    assign core_instr       = ctrl_instr;
    assign core_instr_valid = ctrl_instr_valid;

    logic [31:0] prot_cpu_rdata;
    logic [31:0] shar_cpu_rdata;
    logic        prot_fsm_wr;
    logic [3:0]  prot_fsm_addr;
    logic [127:0] prot_fsm_wdata;

    aes_key_bram key_bram (.key(aes_key));

    crypto_top aes_sha (
        .clk           (clk),
        .rst_n         (rst_n),
        .aes_key_valid (aes_key_valid),
        .aes_mode      (aes_mode),
        .aes_data_valid(aes_data_valid),
        .aes_key       (aes_key),
        .aes_data_in   (aes_data_in),
        .aes_ready     (aes_ready),
        .aes_busy      (),
        .aes_done      (aes_done),
        .aes_data_out  (aes_data_out),
        .sha_msg_valid (sha_msg_valid),
        .sha_msg_words (sha_msg_words),
        .sha_ready     (sha_ready),
        .sha_busy      (),
        .sha_done      (sha_done),
        .sha_digest    (sha_digest)
    );

    coprocessor_fsm fsm (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start),
        .enc_data_0   (enc_data_0),
        .enc_data_1   (enc_data_1),
        .busy         (busy),
        .core_irq     (core_irq),
        .core_done    (core_done),
        .tx_valid     (tx_valid),
        .tx_data      (tx_data),
        .aes_key_valid(aes_key_valid),
        .aes_mode     (aes_mode),
        .aes_data_valid(aes_data_valid),
        .aes_data_in  (aes_data_in),
        .aes_ready    (aes_ready),
        .aes_done     (aes_done),
        .aes_data_out (aes_data_out),
        .sha_msg_valid(sha_msg_valid),
        .sha_msg_words(sha_msg_words),
        .sha_ready    (sha_ready),
        .sha_done     (sha_done),
        .sha_digest   (sha_digest),
        .pmem_wr      (prot_fsm_wr),
        .pmem_addr    (prot_fsm_addr),
        .pmem_wdata   (prot_fsm_wdata),
        .smem_addr    (smem_fsm_addr),
        .smem_rdata   (smem_fsm_rdata),
        .dbg_state    (fsm_state),
        .dbg_enc_result(dbg_enc_result),
        .dbg_sha_result(dbg_sha_result)
    );

    assign dbg_state       = fsm_state;
    assign dbg_aes_data_out = aes_data_out;

    assign prot_fsm_wr    = pmem_wr;
    assign prot_fsm_addr  = pmem_addr;
    assign prot_fsm_wdata = pmem_wdata;

    protected_mem prot_mem (
        .clk       (clk),
        .rst_n     (rst_n),
        .cpu_addr  (core_mem_addr[4:0]),
        .cpu_rdata (prot_cpu_rdata),
        .fsm_wr    (prot_fsm_wr),
        .fsm_addr  (prot_fsm_addr),
        .fsm_wdata (prot_fsm_wdata)
    );

    shared_mem shar_mem (
        .clk       (clk),
        .rst_n     (rst_n),
        .cpu_addr  (core_mem_addr[4:0]),
        .cpu_wdata (core_mem_wdata),
        .cpu_wr    (core_mem_we && (core_mem_addr < 8'hFC)),
        .fsm_addr  (smem_fsm_addr),
        .fsm_rdata (smem_fsm_rdata)
    );

    rv32i_core core (
        .clk          (clk),
        .rst_n        (rst_n),
        .instr        (core_instr),
        .instr_valid  (core_instr_valid),
        .done         (core_done_sig),
        .mem_addr     (core_mem_addr),
        .mem_rdata    (core_mem_rdata),
        .mem_wdata    (core_mem_wdata),
        .mem_we       (core_mem_we),
        .mem_valid    (core_mem_valid)
    );

    logic prot_sel, shar_sel, done_sel;
    assign prot_sel = (core_mem_addr[7] == 1'b0);
    assign shar_sel = (core_mem_addr[7] == 1'b1 && core_mem_addr < 8'hFC);
    assign done_sel = (core_mem_addr == 8'hFC);

    assign core_mem_rdata = prot_sel ? prot_cpu_rdata :
                            shar_sel ? shar_cpu_rdata : 32'h0;

    logic core_done_r;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            core_done_r <= 1'b0;
        else if (start)
            core_done_r <= 1'b0;
        else if (core_mem_we && done_sel)
            core_done_r <= 1'b1;
    end
    assign core_done = core_done_r;

endmodule
