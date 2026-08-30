module coprocessor_fsm (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start,
    input  logic [127:0] enc_data_0,
    input  logic [127:0] enc_data_1,
    output logic        busy,
    output logic        core_irq,
    input  logic        core_done,

    output logic [4:0]  dbg_state,
    output logic [255:0] dbg_enc_result,
    output logic [255:0] dbg_sha_result,

    output logic        tx_valid,
    output logic [511:0] tx_data,

    output logic        aes_key_valid,
    output logic [1:0]  aes_mode,
    output logic        aes_data_valid,
    output logic [127:0] aes_data_in,
    input  logic        aes_ready,
    input  logic        aes_done,
    input  logic [127:0] aes_data_out,

    output logic        sha_msg_valid,
    output logic [31:0] sha_msg_words [0:15],
    input  logic        sha_ready,
    input  logic        sha_done,
    input  logic [31:0] sha_digest [0:7],

    output logic        pmem_wr,
    output logic [3:0]  pmem_addr,
    output logic [127:0] pmem_wdata,

    output logic [3:0]  smem_addr,
    input  logic [127:0] smem_rdata
);

    typedef enum logic [4:0] {
        IDLE,
        LOAD_KEY,
        DECRYPT_0,
        STORE_0,
        DECRYPT_1,
        STORE_1,
        WAIT_CORE,
        READ_SMEM_0,
        ENCRYPT_0,
        WAIT_ENCR_0,
        READ_SMEM_1,
        ENCRYPT_1,
        WAIT_ENCR_1,
        DO_SHA_PREP,
        DO_SHA,
        WAIT_SHA,
        CAPTURE_SHA,
        TX_OUT
    } state_t;

    state_t state, next;
    logic [127:0] enc_result_0;
    logic [127:0] enc_result_1;
    logic [255:0] sha_result;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            enc_result_0 <= '0;
            enc_result_1 <= '0;
        end else begin
            state <= next;
            if (state == WAIT_ENCR_0 && aes_done)
                enc_result_0 <= aes_data_out;
            if (state == WAIT_ENCR_1 && aes_done)
                enc_result_1 <= aes_data_out;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sha_result <= '0;
        end else if (state == CAPTURE_SHA) begin
            sha_result <= {sha_digest[7], sha_digest[6], sha_digest[5], sha_digest[4],
                           sha_digest[3], sha_digest[2], sha_digest[1], sha_digest[0]};
        end
    end

    always_comb begin
        next = state;
        aes_key_valid  = 1'b0;
        aes_mode       = 2'b00;
        aes_data_valid = 1'b0;
        aes_data_in    = '0;
        sha_msg_valid  = 1'b0;
        sha_msg_words  = '{16{32'h0}};
        pmem_wr        = 1'b0;
        pmem_addr      = '0;
        pmem_wdata     = '0;
        smem_addr      = '0;
        busy           = 1'b1;
        core_irq       = 1'b0;
        tx_valid       = 1'b0;
        tx_data        = '0;

        case (state)
            IDLE: begin
                busy = 1'b0;
                if (start)
                    next = LOAD_KEY;
            end

            LOAD_KEY: begin
                aes_key_valid = 1'b1;
                next = DECRYPT_0;
            end

            DECRYPT_0: begin
                aes_mode       = 2'b10;
                aes_data_valid = 1'b1;
                aes_data_in    = enc_data_0;
                if (aes_ready)
                    next = STORE_0;
            end

            STORE_0: begin
                aes_mode = 2'b10;
                if (aes_done) begin
                    pmem_wr    = 1'b1;
                    pmem_addr  = 4'd0;
                    pmem_wdata = aes_data_out;
                    next = DECRYPT_1;
                end
            end

            DECRYPT_1: begin
                aes_mode       = 2'b10;
                aes_data_valid = 1'b1;
                aes_data_in    = enc_data_1;
                if (aes_ready)
                    next = STORE_1;
            end

            STORE_1: begin
                aes_mode = 2'b10;
                if (aes_done) begin
                    pmem_wr    = 1'b1;
                    pmem_addr  = 4'd1;
                    pmem_wdata = aes_data_out;
                    next = WAIT_CORE;
                end
            end

            WAIT_CORE: begin
                core_irq = 1'b1;
                if (core_done)
                    next = READ_SMEM_0;
            end

            READ_SMEM_0: begin
                smem_addr = 4'd0;
                next = ENCRYPT_0;
            end

            ENCRYPT_0: begin
                aes_mode       = 2'b01;
                aes_data_valid = 1'b1;
                aes_data_in    = smem_rdata;
                if (aes_ready)
                    next = WAIT_ENCR_0;
            end

            WAIT_ENCR_0: begin
                aes_mode = 2'b01;
                if (aes_done)
                    next = READ_SMEM_1;
            end

            READ_SMEM_1: begin
                smem_addr = 4'd1;
                next = ENCRYPT_1;
            end

            ENCRYPT_1: begin
                aes_mode       = 2'b01;
                aes_data_valid = 1'b1;
                aes_data_in    = smem_rdata;
                if (aes_ready)
                    next = WAIT_ENCR_1;
            end

            WAIT_ENCR_1: begin
                aes_mode = 2'b01;
                if (aes_done)
                    next = DO_SHA_PREP;
            end

            DO_SHA_PREP: begin
                next = DO_SHA;
            end

            DO_SHA: begin
                sha_msg_words[0] = enc_result_1[127:96];
                sha_msg_words[1] = enc_result_1[95:64];
                sha_msg_words[2] = enc_result_1[63:32];
                sha_msg_words[3] = enc_result_1[31:0];
                sha_msg_words[4] = 32'h80000000;
                sha_msg_words[5] = 32'h00000000;
                sha_msg_words[6] = 32'h00000000;
                sha_msg_words[7] = 32'h00000000;
                sha_msg_words[8] = 32'h00000000;
                sha_msg_words[9] = 32'h00000000;
                sha_msg_words[10] = 32'h00000000;
                sha_msg_words[11] = 32'h00000000;
                sha_msg_words[12] = 32'h00000000;
                sha_msg_words[13] = 32'h00000000;
                sha_msg_words[14] = 32'h00000000;
                sha_msg_words[15] = 32'd128;
                sha_msg_valid = 1'b1;
                if (sha_ready)
                    next = WAIT_SHA;
            end

            WAIT_SHA: begin
                if (sha_done)
                    next = CAPTURE_SHA;
            end

            CAPTURE_SHA: begin
                next = TX_OUT;
            end

            TX_OUT: begin
                tx_valid = 1'b1;
                tx_data  = {sha_result, enc_result_1, enc_result_0};
                next = IDLE;
            end
        endcase
    end

    assign dbg_state = state;
    assign dbg_enc_result = {enc_result_1, enc_result_0};
    assign dbg_sha_result = sha_result;

endmodule
