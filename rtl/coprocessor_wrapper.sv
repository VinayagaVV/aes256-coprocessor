module coprocessor_wrapper (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [7:0]  mmio_addr,
    input  logic [31:0] mmio_wdata,
    input  logic        mmio_we,
    output logic [31:0] mmio_rdata,

    output logic        host_irq,

    output logic [4:0]  dbg_state,
    output logic        dbg_busy,
    output logic        dbg_tx_valid
);

    logic        start;
    logic [127:0] enc_data_0;
    logic [127:0] enc_data_1;
    logic        core_irq;
    logic        busy;
    logic        tx_valid;
    logic [511:0] tx_data;
    logic [31:0] ctrl_instr;
    logic        ctrl_instr_valid;
    logic [127:0] dbg_aes_data_out;
    logic [255:0] dbg_enc_result;
    logic [255:0] dbg_sha_result;

    logic [31:0] enc0_w[0:3];
    logic [31:0] enc1_w[0:3];
    logic [31:0] tx_cap[0:15];
    logic [7:0]  status;
    logic [31:0] dbg_decrypted_vals[0:7];
    logic [31:0] dbg_cpu_result_reg;
    logic [31:0] dbg_enc_result_words[0:7];
    logic [31:0] dbg_sha_result_words[0:7];

    localparam int NUM_INSTR = 6;
    logic [31:0] instr_mem[0:NUM_INSTR-1];

    initial begin
        instr_mem[0] = 32'h00002083;
        instr_mem[1] = 32'h00402103;
        instr_mem[2] = 32'h002081b3;
        instr_mem[3] = 32'h08302023;
        instr_mem[4] = 32'h08302223;
        instr_mem[5] = 32'h0e002e23;
    end

    typedef enum { SEQ_IDLE, SEQ_FEED, SEQ_DONE } seq_t;
    seq_t seq_state;
    logic [2:0] seq_idx;
    logic       core_irq_prev;
    logic       core_irq_rise;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) core_irq_prev <= 0;
        else        core_irq_prev <= core_irq;
    end
    assign core_irq_rise = core_irq && !core_irq_prev;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seq_state <= SEQ_IDLE;
            seq_idx   <= 0;
            ctrl_instr <= 0;
            ctrl_instr_valid <= 0;
        end else begin
            case (seq_state)
                SEQ_IDLE: begin
                    ctrl_instr_valid <= 0;
                    if (core_irq_rise) begin
                        seq_state <= SEQ_FEED;
                        seq_idx   <= 3'd1;
                        ctrl_instr <= instr_mem[0];
                        ctrl_instr_valid <= 1;
                    end
                end
                SEQ_FEED: begin
                    ctrl_instr <= instr_mem[seq_idx];
                    ctrl_instr_valid <= 1;
                    if (seq_idx == NUM_INSTR-1)
                        seq_state <= SEQ_DONE;
                    else
                        seq_idx <= seq_idx + 1;
                end
                SEQ_DONE: begin
                    ctrl_instr_valid <= 0;
                    if (!core_irq) seq_state <= SEQ_IDLE;
                end
            endcase
        end
    end

    assign enc_data_0 = {enc0_w[0], enc0_w[1], enc0_w[2], enc0_w[3]};
    assign enc_data_1 = {enc1_w[0], enc1_w[1], enc1_w[2], enc1_w[3]};

    coprocessor_top core_top (
        .clk             (clk),
        .rst_n           (rst_n),
        .start           (start),
        .enc_data_0      (enc_data_0),
        .enc_data_1      (enc_data_1),
        .tx_valid        (tx_valid),
        .tx_data         (tx_data),
        .core_irq        (core_irq),
        .busy            (busy),
        .ctrl_instr      (ctrl_instr),
        .ctrl_instr_valid(ctrl_instr_valid),
        .dbg_state       (dbg_state),
        .dbg_aes_data_out(dbg_aes_data_out),
        .dbg_enc_result  (dbg_enc_result),
        .dbg_sha_result  (dbg_sha_result)
    );

    assign host_irq     = core_irq;
    assign dbg_busy     = busy;
    assign dbg_tx_valid = tx_valid;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 16; i++) tx_cap[i] <= 0;
        end else if (tx_valid) begin
            for (int i = 0; i < 16; i++)
                tx_cap[i] <= tx_data[i*32 +: 32];
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 8; i++) dbg_decrypted_vals[i] <= 0;
            dbg_cpu_result_reg <= 0;
            for (int i = 0; i < 8; i++) dbg_enc_result_words[i] <= 0;
            for (int i = 0; i < 8; i++) dbg_sha_result_words[i] <= 0;
        end else begin
            if (dbg_state == 5'd3) begin
                dbg_decrypted_vals[0] <= dbg_aes_data_out[127:96];
                dbg_decrypted_vals[1] <= dbg_aes_data_out[95:64];
                dbg_decrypted_vals[2] <= dbg_aes_data_out[63:32];
                dbg_decrypted_vals[3] <= dbg_aes_data_out[31:0];
            end
            if (dbg_state == 5'd5) begin
                dbg_decrypted_vals[4] <= dbg_aes_data_out[127:96];
                dbg_decrypted_vals[5] <= dbg_aes_data_out[95:64];
                dbg_decrypted_vals[6] <= dbg_aes_data_out[63:32];
                dbg_decrypted_vals[7] <= dbg_aes_data_out[31:0];
            end
            if (dbg_state == 5'd9) begin
                dbg_enc_result_words[0] <= dbg_enc_result[127:96];
                dbg_enc_result_words[1] <= dbg_enc_result[95:64];
                dbg_enc_result_words[2] <= dbg_enc_result[63:32];
                dbg_enc_result_words[3] <= dbg_enc_result[31:0];
            end
            if (dbg_state == 5'd12) begin
                dbg_enc_result_words[4] <= dbg_enc_result[255:224];
                dbg_enc_result_words[5] <= dbg_enc_result[223:192];
                dbg_enc_result_words[6] <= dbg_enc_result[191:160];
                dbg_enc_result_words[7] <= dbg_enc_result[159:128];
            end
            if (dbg_state == 5'd15) begin
                dbg_sha_result_words[0] <= dbg_sha_result[255:224];
                dbg_sha_result_words[1] <= dbg_sha_result[223:192];
                dbg_sha_result_words[2] <= dbg_sha_result[191:160];
                dbg_sha_result_words[3] <= dbg_sha_result[159:128];
                dbg_sha_result_words[4] <= dbg_sha_result[127:96];
                dbg_sha_result_words[5] <= dbg_sha_result[95:64];
                dbg_sha_result_words[6] <= dbg_sha_result[63:32];
                dbg_sha_result_words[7] <= dbg_sha_result[31:0];
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 4; i++) begin
                enc0_w[i] <= 0;
                enc1_w[i] <= 0;
            end
            start <= 0;
            for (int i = 0; i < NUM_INSTR; i++)
                instr_mem[i] <= instr_mem[i];
        end else begin
            start <= 1'b0;
            if (mmio_we) begin
                unique case (mmio_addr[7:0])
                    8'h00: enc0_w[0] <= mmio_wdata;
                    8'h04: enc0_w[1] <= mmio_wdata;
                    8'h08: enc0_w[2] <= mmio_wdata;
                    8'h0C: enc0_w[3] <= mmio_wdata;
                    8'h10: enc1_w[0] <= mmio_wdata;
                    8'h14: enc1_w[1] <= mmio_wdata;
                    8'h18: enc1_w[2] <= mmio_wdata;
                    8'h1C: enc1_w[3] <= mmio_wdata;
                    8'h20: start <= 1'b1;
                    8'h80: instr_mem[0] <= mmio_wdata;
                    8'h84: instr_mem[1] <= mmio_wdata;
                    8'h88: instr_mem[2] <= mmio_wdata;
                    8'h8C: instr_mem[3] <= mmio_wdata;
                    8'h90: instr_mem[4] <= mmio_wdata;
                    8'h94: instr_mem[5] <= mmio_wdata;
                endcase
            end
        end
    end

    always_comb begin
        mmio_rdata = 32'h0;
        status = {5'h0, tx_valid, core_irq, busy};
        unique case (mmio_addr[7:0])
            8'h00: mmio_rdata = enc0_w[0];
            8'h20: mmio_rdata = start;
            8'h24: mmio_rdata = {24'h0, status};
            8'h04: mmio_rdata = enc0_w[1];
            8'h08: mmio_rdata = enc0_w[2];
            8'h0C: mmio_rdata = enc0_w[3];
            8'h10: mmio_rdata = enc1_w[0];
            8'h14: mmio_rdata = enc1_w[1];
            8'h18: mmio_rdata = enc1_w[2];
            8'h1C: mmio_rdata = enc1_w[3];
            8'h28: mmio_rdata = tx_cap[0];
            8'h2C: mmio_rdata = tx_cap[1];
            8'h30: mmio_rdata = tx_cap[2];
            8'h34: mmio_rdata = tx_cap[3];
            8'h38: mmio_rdata = tx_cap[4];
            8'h3C: mmio_rdata = tx_cap[5];
            8'h40: mmio_rdata = tx_cap[6];
            8'h44: mmio_rdata = tx_cap[7];
            8'h48: mmio_rdata = tx_cap[8];
            8'h4C: mmio_rdata = tx_cap[9];
            8'h50: mmio_rdata = tx_cap[10];
            8'h54: mmio_rdata = tx_cap[11];
            8'h58: mmio_rdata = tx_cap[12];
            8'h5C: mmio_rdata = tx_cap[13];
            8'h60: mmio_rdata = tx_cap[14];
            8'h64: mmio_rdata = tx_cap[15];
            8'hA0: mmio_rdata = dbg_decrypted_vals[0];
            8'hA4: mmio_rdata = dbg_decrypted_vals[1];
            8'hA8: mmio_rdata = dbg_decrypted_vals[2];
            8'hAC: mmio_rdata = dbg_decrypted_vals[3];
            8'hB0: mmio_rdata = dbg_decrypted_vals[4];
            8'hB4: mmio_rdata = dbg_decrypted_vals[5];
            8'hB8: mmio_rdata = dbg_decrypted_vals[6];
            8'hBC: mmio_rdata = dbg_decrypted_vals[7];
            8'hC0: mmio_rdata = dbg_enc_result_words[0];
            8'hC4: mmio_rdata = dbg_enc_result_words[1];
            8'hC8: mmio_rdata = dbg_enc_result_words[2];
            8'hCC: mmio_rdata = dbg_enc_result_words[3];
            8'hD0: mmio_rdata = dbg_sha_result_words[0];
            8'hD4: mmio_rdata = dbg_sha_result_words[1];
            8'hD8: mmio_rdata = dbg_sha_result_words[2];
            8'hDC: mmio_rdata = dbg_sha_result_words[3];
            8'hE0: mmio_rdata = dbg_sha_result_words[4];
            8'hE4: mmio_rdata = dbg_sha_result_words[5];
            8'hE8: mmio_rdata = dbg_sha_result_words[6];
            8'hEC: mmio_rdata = dbg_sha_result_words[7];
            8'hF0: mmio_rdata = dbg_enc_result_words[4];
            8'hF4: mmio_rdata = dbg_enc_result_words[5];
            8'hF8: mmio_rdata = dbg_enc_result_words[6];
            8'hFC: mmio_rdata = dbg_enc_result_words[7];
        endcase
    end

endmodule
