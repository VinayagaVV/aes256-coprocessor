module aes_key_bram (
    output logic [255:0] key
);
    initial begin
        key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    end
endmodule
