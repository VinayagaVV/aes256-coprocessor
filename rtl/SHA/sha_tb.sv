import sha_pkg::*;

module sha_tb;
    logic clk, rst_n;
    logic msg_valid, ready, busy, done;
    logic [31:0] msg_words[0:15];
    logic [31:0] digest[0:7];

    sha_accelerator dut (.*);

    always #5 clk = ~clk;

    initial begin
        $display("========================================");
        $display("SHA-256 Accelerator Testbench");
        $display("NIST Test Vector: SHA-256(\"abc\")");
        $display("========================================\n");

        clk = 0; rst_n = 0;
        msg_valid = 0;
        for (int i = 0; i < 16; i++) msg_words[i] = '0;
        #10 rst_n = 1;
        #10;

        // Load padded message block for "abc"
        msg_words[0]  = 32'h61626380;
        msg_words[1]  = 32'h00000000;
        msg_words[2]  = 32'h00000000;
        msg_words[3]  = 32'h00000000;
        msg_words[4]  = 32'h00000000;
        msg_words[5]  = 32'h00000000;
        msg_words[6]  = 32'h00000000;
        msg_words[7]  = 32'h00000000;
        msg_words[8]  = 32'h00000000;
        msg_words[9]  = 32'h00000000;
        msg_words[10] = 32'h00000000;
        msg_words[11] = 32'h00000000;
        msg_words[12] = 32'h00000000;
        msg_words[13] = 32'h00000000;
        msg_words[14] = 32'h00000000;
        msg_words[15] = 32'h00000018;
        msg_valid = 1; #10 msg_valid = 0;

        // Wait 64 cycles for pipeline to fill
        @(posedge done);
        #1;

        $display("Digest: %h %h %h %h %h %h %h %h",
                 digest[0], digest[1], digest[2], digest[3],
                 digest[4], digest[5], digest[6], digest[7]);

        if (digest[0] === 32'hba7816bf && digest[1] === 32'h8f01cfea &&
            digest[2] === 32'h414140de && digest[3] === 32'h5dae2223 &&
            digest[4] === 32'hb00361a3 && digest[5] === 32'h96177a9c &&
            digest[6] === 32'hb410ff61 && digest[7] === 32'hf20015ad) begin
            $display("\nRESULT: PASS - Digest matches NIST SHA-256(\"abc\")");
        end else begin
            $display("\nRESULT: FAIL");
            $display("Expected: ba7816bf 8f01cfea 414140de 5dae2223 b00361a3 96177a9c b410ff61 f20015ad");
        end

        // Test with reference function
        $display("\n--- Reference SHA-256(\"abc\") ---");
        logic [31:0] ref_digest[0:7];
        {ref_digest[0], ref_digest[1], ref_digest[2], ref_digest[3],
         ref_digest[4], ref_digest[5], ref_digest[6], ref_digest[7]} = sha256_ref(msg_words);
        $display("Reference: %h %h %h %h %h %h %h %h",
                 ref_digest[0], ref_digest[1], ref_digest[2], ref_digest[3],
                 ref_digest[4], ref_digest[5], ref_digest[6], ref_digest[7]);

        $finish;
    end

    always @(posedge clk) begin
        if (done) begin
            $display("[%0d] digest valid = %h %h %h %h %h %h %h %h",
                     $time, digest[0], digest[1], digest[2], digest[3],
                     digest[4], digest[5], digest[6], digest[7]);
        end
    end
endmodule
