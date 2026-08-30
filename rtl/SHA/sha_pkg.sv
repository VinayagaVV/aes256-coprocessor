package sha_pkg;

    localparam int NUM_ROUNDS = 64;

    localparam logic [31:0] K[0:63] = '{
        32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
        32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
        32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
        32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
        32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
        32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
        32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
        32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
        32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
        32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
        32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
        32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
        32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
        32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
        32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
        32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
    };

    localparam logic [31:0] H_INIT[0:7] = '{
        32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
        32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
    };

    function automatic logic [31:0] rot_right(input logic [31:0] x, input int n);
        return (x >> n) | (x << (32 - n));
    endfunction

    function automatic logic [31:0] Ch(input logic [31:0] x, y, z);
        return (x & y) ^ (~x & z);
    endfunction

    function automatic logic [31:0] Maj(input logic [31:0] x, y, z);
        return (x & y) ^ (x & z) ^ (y & z);
    endfunction

    function automatic logic [31:0] Sigma0(input logic [31:0] x);
        return rot_right(x, 2) ^ rot_right(x, 13) ^ rot_right(x, 22);
    endfunction

    function automatic logic [31:0] Sigma1(input logic [31:0] x);
        return rot_right(x, 6) ^ rot_right(x, 11) ^ rot_right(x, 25);
    endfunction

    function automatic logic [31:0] sigma0(input logic [31:0] x);
        return rot_right(x, 7) ^ rot_right(x, 18) ^ (x >> 3);
    endfunction

    function automatic logic [31:0] sigma1(input logic [31:0] x);
        return rot_right(x, 17) ^ rot_right(x, 19) ^ (x >> 10);
    endfunction

    function automatic logic [31:0] w_schedule(
        input logic [31:0] w2, w7, w15, w16
    );
        return sigma1(w2) + w7 + sigma0(w15) + w16;
    endfunction

    function automatic logic [255:0] sha_round(
        input logic [255:0] state,
        input logic [31:0]  w,
        input int           r
    );
        logic [31:0] a, b, c, d, e, f, g, h;
        logic [31:0] t1, t2;
        {a, b, c, d, e, f, g, h} = state;
        t1 = h + Sigma1(e) + Ch(e, f, g) + K[r] + w;
        t2 = Sigma0(a) + Maj(a, b, c);
        sha_round = {t1 + t2, a, b, c, d + t1, e, f, g};
    endfunction

    function automatic logic [255:0] sha256_ref(
        input logic [31:0] msg[0:15]
    );
        logic [31:0] w[0:63];
        logic [31:0] a, b, c, d, e, f, g, h;
        logic [31:0] t1, t2;
        logic [255:0] state;
        for (int i = 0; i < 16; i++)
            w[i] = msg[i];
        for (int i = 16; i < 64; i++)
            w[i] = w_schedule(w[i-2], w[i-7], w[i-15], w[i-16]);
        state = {H_INIT[0], H_INIT[1], H_INIT[2], H_INIT[3],
                 H_INIT[4], H_INIT[5], H_INIT[6], H_INIT[7]};
        for (int i = 0; i < 64; i++)
            state = sha_round(state, w[i], i);
        {a, b, c, d, e, f, g, h} = state;
        sha256_ref = {a + H_INIT[0], b + H_INIT[1], c + H_INIT[2], d + H_INIT[3],
                      e + H_INIT[4], f + H_INIT[5], g + H_INIT[6], h + H_INIT[7]};
    endfunction

endpackage
