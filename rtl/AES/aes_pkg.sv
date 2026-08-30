package aes_pkg;

    localparam logic [79:0] RCON_BITS = {
        8'h01, 8'h02, 8'h04, 8'h08,
        8'h10, 8'h20, 8'h40, 8'h80,
        8'h1b, 8'h36
    };

    localparam logic [111:0] RCON_BITS_256 = {
        8'h01, 8'h02, 8'h04, 8'h08,
        8'h10, 8'h20, 8'h40, 8'h80,
        8'h1b, 8'h36, 8'h6c, 8'hd8,
        8'hab, 8'h4d
    };

    function automatic logic [7:0] rcon(input int r);
        return RCON_BITS[80 - 8*r +: 8];
    endfunction

    function automatic logic [7:0] rcon_256(input int r);
        return RCON_BITS_256[112 - 8*r +: 8];
    endfunction

    function automatic logic [7:0] xtime(input logic [7:0] b);
        return {b[6:0], 1'b0} ^ (b[7] ? 8'h1B : 8'h00);
    endfunction

    function automatic logic [7:0] sbox(input logic [7:0] x);
        case (x)
            8'h00: return 8'h63; 8'h01: return 8'h7c; 8'h02: return 8'h77; 8'h03: return 8'h7b;
            8'h04: return 8'hf2; 8'h05: return 8'h6b; 8'h06: return 8'h6f; 8'h07: return 8'hc5;
            8'h08: return 8'h30; 8'h09: return 8'h01; 8'h0a: return 8'h67; 8'h0b: return 8'h2b;
            8'h0c: return 8'hfe; 8'h0d: return 8'hd7; 8'h0e: return 8'hab; 8'h0f: return 8'h76;
            8'h10: return 8'hca; 8'h11: return 8'h82; 8'h12: return 8'hc9; 8'h13: return 8'h7d;
            8'h14: return 8'hfa; 8'h15: return 8'h59; 8'h16: return 8'h47; 8'h17: return 8'hf0;
            8'h18: return 8'had; 8'h19: return 8'hd4; 8'h1a: return 8'ha2; 8'h1b: return 8'haf;
            8'h1c: return 8'h9c; 8'h1d: return 8'ha4; 8'h1e: return 8'h72; 8'h1f: return 8'hc0;
            8'h20: return 8'hb7; 8'h21: return 8'hfd; 8'h22: return 8'h93; 8'h23: return 8'h26;
            8'h24: return 8'h36; 8'h25: return 8'h3f; 8'h26: return 8'hf7; 8'h27: return 8'hcc;
            8'h28: return 8'h34; 8'h29: return 8'ha5; 8'h2a: return 8'he5; 8'h2b: return 8'hf1;
            8'h2c: return 8'h71; 8'h2d: return 8'hd8; 8'h2e: return 8'h31; 8'h2f: return 8'h15;
            8'h30: return 8'h04; 8'h31: return 8'hc7; 8'h32: return 8'h23; 8'h33: return 8'hc3;
            8'h34: return 8'h18; 8'h35: return 8'h96; 8'h36: return 8'h05; 8'h37: return 8'h9a;
            8'h38: return 8'h07; 8'h39: return 8'h12; 8'h3a: return 8'h80; 8'h3b: return 8'he2;
            8'h3c: return 8'heb; 8'h3d: return 8'h27; 8'h3e: return 8'hb2; 8'h3f: return 8'h75;
            8'h40: return 8'h09; 8'h41: return 8'h83; 8'h42: return 8'h2c; 8'h43: return 8'h1a;
            8'h44: return 8'h1b; 8'h45: return 8'h6e; 8'h46: return 8'h5a; 8'h47: return 8'ha0;
            8'h48: return 8'h52; 8'h49: return 8'h3b; 8'h4a: return 8'hd6; 8'h4b: return 8'hb3;
            8'h4c: return 8'h29; 8'h4d: return 8'he3; 8'h4e: return 8'h2f; 8'h4f: return 8'h84;
            8'h50: return 8'h53; 8'h51: return 8'hd1; 8'h52: return 8'h00; 8'h53: return 8'hed;
            8'h54: return 8'h20; 8'h55: return 8'hfc; 8'h56: return 8'hb1; 8'h57: return 8'h5b;
            8'h58: return 8'h6a; 8'h59: return 8'hcb; 8'h5a: return 8'hbe; 8'h5b: return 8'h39;
            8'h5c: return 8'h4a; 8'h5d: return 8'h4c; 8'h5e: return 8'h58; 8'h5f: return 8'hcf;
            8'h60: return 8'hd0; 8'h61: return 8'hef; 8'h62: return 8'haa; 8'h63: return 8'hfb;
            8'h64: return 8'h43; 8'h65: return 8'h4d; 8'h66: return 8'h33; 8'h67: return 8'h85;
            8'h68: return 8'h45; 8'h69: return 8'hf9; 8'h6a: return 8'h02; 8'h6b: return 8'h7f;
            8'h6c: return 8'h50; 8'h6d: return 8'h3c; 8'h6e: return 8'h9f; 8'h6f: return 8'ha8;
            8'h70: return 8'h51; 8'h71: return 8'ha3; 8'h72: return 8'h40; 8'h73: return 8'h8f;
            8'h74: return 8'h92; 8'h75: return 8'h9d; 8'h76: return 8'h38; 8'h77: return 8'hf5;
            8'h78: return 8'hbc; 8'h79: return 8'hb6; 8'h7a: return 8'hda; 8'h7b: return 8'h21;
            8'h7c: return 8'h10; 8'h7d: return 8'hff; 8'h7e: return 8'hf3; 8'h7f: return 8'hd2;
            8'h80: return 8'hcd; 8'h81: return 8'h0c; 8'h82: return 8'h13; 8'h83: return 8'hec;
            8'h84: return 8'h5f; 8'h85: return 8'h97; 8'h86: return 8'h44; 8'h87: return 8'h17;
            8'h88: return 8'hc4; 8'h89: return 8'ha7; 8'h8a: return 8'h7e; 8'h8b: return 8'h3d;
            8'h8c: return 8'h64; 8'h8d: return 8'h5d; 8'h8e: return 8'h19; 8'h8f: return 8'h73;
            8'h90: return 8'h60; 8'h91: return 8'h81; 8'h92: return 8'h4f; 8'h93: return 8'hdc;
            8'h94: return 8'h22; 8'h95: return 8'h2a; 8'h96: return 8'h90; 8'h97: return 8'h88;
            8'h98: return 8'h46; 8'h99: return 8'hee; 8'h9a: return 8'hb8; 8'h9b: return 8'h14;
            8'h9c: return 8'hde; 8'h9d: return 8'h5e; 8'h9e: return 8'h0b; 8'h9f: return 8'hdb;
            8'ha0: return 8'he0; 8'ha1: return 8'h32; 8'ha2: return 8'h3a; 8'ha3: return 8'h0a;
            8'ha4: return 8'h49; 8'ha5: return 8'h06; 8'ha6: return 8'h24; 8'ha7: return 8'h5c;
            8'ha8: return 8'hc2; 8'ha9: return 8'hd3; 8'haa: return 8'hac; 8'hab: return 8'h62;
            8'hac: return 8'h91; 8'had: return 8'h95; 8'hae: return 8'he4; 8'haf: return 8'h79;
            8'hb0: return 8'he7; 8'hb1: return 8'hc8; 8'hb2: return 8'h37; 8'hb3: return 8'h6d;
            8'hb4: return 8'h8d; 8'hb5: return 8'hd5; 8'hb6: return 8'h4e; 8'hb7: return 8'ha9;
            8'hb8: return 8'h6c; 8'hb9: return 8'h56; 8'hba: return 8'hf4; 8'hbb: return 8'hea;
            8'hbc: return 8'h65; 8'hbd: return 8'h7a; 8'hbe: return 8'hae; 8'hbf: return 8'h08;
            8'hc0: return 8'hba; 8'hc1: return 8'h78; 8'hc2: return 8'h25; 8'hc3: return 8'h2e;
            8'hc4: return 8'h1c; 8'hc5: return 8'ha6; 8'hc6: return 8'hb4; 8'hc7: return 8'hc6;
            8'hc8: return 8'he8; 8'hc9: return 8'hdd; 8'hca: return 8'h74; 8'hcb: return 8'h1f;
            8'hcc: return 8'h4b; 8'hcd: return 8'hbd; 8'hce: return 8'h8b; 8'hcf: return 8'h8a;
            8'hd0: return 8'h70; 8'hd1: return 8'h3e; 8'hd2: return 8'hb5; 8'hd3: return 8'h66;
            8'hd4: return 8'h48; 8'hd5: return 8'h03; 8'hd6: return 8'hf6; 8'hd7: return 8'h0e;
            8'hd8: return 8'h61; 8'hd9: return 8'h35; 8'hda: return 8'h57; 8'hdb: return 8'hb9;
            8'hdc: return 8'h86; 8'hdd: return 8'hc1; 8'hde: return 8'h1d; 8'hdf: return 8'h9e;
            8'he0: return 8'he1; 8'he1: return 8'hf8; 8'he2: return 8'h98; 8'he3: return 8'h11;
            8'he4: return 8'h69; 8'he5: return 8'hd9; 8'he6: return 8'h8e; 8'he7: return 8'h94;
            8'he8: return 8'h9b; 8'he9: return 8'h1e; 8'hea: return 8'h87; 8'heb: return 8'he9;
            8'hec: return 8'hce; 8'hed: return 8'h55; 8'hee: return 8'h28; 8'hef: return 8'hdf;
            8'hf0: return 8'h8c; 8'hf1: return 8'ha1; 8'hf2: return 8'h89; 8'hf3: return 8'h0d;
            8'hf4: return 8'hbf; 8'hf5: return 8'he6; 8'hf6: return 8'h42; 8'hf7: return 8'h68;
            8'hf8: return 8'h41; 8'hf9: return 8'h99; 8'hfa: return 8'h2d; 8'hfb: return 8'h0f;
            8'hfc: return 8'hb0; 8'hfd: return 8'h54; 8'hfe: return 8'hbb; 8'hff: return 8'h16;
        endcase
    endfunction

    function automatic logic [7:0] inv_sbox(input logic [7:0] x);
        case (x)
            8'h00: return 8'h52; 8'h01: return 8'h09; 8'h02: return 8'h6a; 8'h03: return 8'hd5;
            8'h04: return 8'h30; 8'h05: return 8'h36; 8'h06: return 8'ha5; 8'h07: return 8'h38;
            8'h08: return 8'hbf; 8'h09: return 8'h40; 8'h0a: return 8'ha3; 8'h0b: return 8'h9e;
            8'h0c: return 8'h81; 8'h0d: return 8'hf3; 8'h0e: return 8'hd7; 8'h0f: return 8'hfb;
            8'h10: return 8'h7c; 8'h11: return 8'he3; 8'h12: return 8'h39; 8'h13: return 8'h82;
            8'h14: return 8'h9b; 8'h15: return 8'h2f; 8'h16: return 8'hff; 8'h17: return 8'h87;
            8'h18: return 8'h34; 8'h19: return 8'h8e; 8'h1a: return 8'h43; 8'h1b: return 8'h44;
            8'h1c: return 8'hc4; 8'h1d: return 8'hde; 8'h1e: return 8'he9; 8'h1f: return 8'hcb;
            8'h20: return 8'h54; 8'h21: return 8'h7b; 8'h22: return 8'h94; 8'h23: return 8'h32;
            8'h24: return 8'ha6; 8'h25: return 8'hc2; 8'h26: return 8'h23; 8'h27: return 8'h3d;
            8'h28: return 8'hee; 8'h29: return 8'h4c; 8'h2a: return 8'h95; 8'h2b: return 8'h0b;
            8'h2c: return 8'h42; 8'h2d: return 8'hfa; 8'h2e: return 8'hc3; 8'h2f: return 8'h4e;
            8'h30: return 8'h08; 8'h31: return 8'h2e; 8'h32: return 8'ha1; 8'h33: return 8'h66;
            8'h34: return 8'h28; 8'h35: return 8'hd9; 8'h36: return 8'h24; 8'h37: return 8'hb2;
            8'h38: return 8'h76; 8'h39: return 8'h5b; 8'h3a: return 8'ha2; 8'h3b: return 8'h49;
            8'h3c: return 8'h6d; 8'h3d: return 8'h8b; 8'h3e: return 8'hd1; 8'h3f: return 8'h25;
            8'h40: return 8'h72; 8'h41: return 8'hf8; 8'h42: return 8'hf6; 8'h43: return 8'h64;
            8'h44: return 8'h86; 8'h45: return 8'h68; 8'h46: return 8'h98; 8'h47: return 8'h16;
            8'h48: return 8'hd4; 8'h49: return 8'ha4; 8'h4a: return 8'h5c; 8'h4b: return 8'hcc;
            8'h4c: return 8'h5d; 8'h4d: return 8'h65; 8'h4e: return 8'hb6; 8'h4f: return 8'h92;
            8'h50: return 8'h6c; 8'h51: return 8'h70; 8'h52: return 8'h48; 8'h53: return 8'h50;
            8'h54: return 8'hfd; 8'h55: return 8'hed; 8'h56: return 8'hb9; 8'h57: return 8'hda;
            8'h58: return 8'h5e; 8'h59: return 8'h15; 8'h5a: return 8'h46; 8'h5b: return 8'h57;
            8'h5c: return 8'ha7; 8'h5d: return 8'h8d; 8'h5e: return 8'h9d; 8'h5f: return 8'h84;
            8'h60: return 8'h90; 8'h61: return 8'hd8; 8'h62: return 8'hab; 8'h63: return 8'h00;
            8'h64: return 8'h8c; 8'h65: return 8'hbc; 8'h66: return 8'hd3; 8'h67: return 8'h0a;
            8'h68: return 8'hf7; 8'h69: return 8'he4; 8'h6a: return 8'h58; 8'h6b: return 8'h05;
            8'h6c: return 8'hb8; 8'h6d: return 8'hb3; 8'h6e: return 8'h45; 8'h6f: return 8'h06;
            8'h70: return 8'hd0; 8'h71: return 8'h2c; 8'h72: return 8'h1e; 8'h73: return 8'h8f;
            8'h74: return 8'hca; 8'h75: return 8'h3f; 8'h76: return 8'h0f; 8'h77: return 8'h02;
            8'h78: return 8'hc1; 8'h79: return 8'haf; 8'h7a: return 8'hbd; 8'h7b: return 8'h03;
            8'h7c: return 8'h01; 8'h7d: return 8'h13; 8'h7e: return 8'h8a; 8'h7f: return 8'h6b;
            8'h80: return 8'h3a; 8'h81: return 8'h91; 8'h82: return 8'h11; 8'h83: return 8'h41;
            8'h84: return 8'h4f; 8'h85: return 8'h67; 8'h86: return 8'hdc; 8'h87: return 8'hea;
            8'h88: return 8'h97; 8'h89: return 8'hf2; 8'h8a: return 8'hcf; 8'h8b: return 8'hce;
            8'h8c: return 8'hf0; 8'h8d: return 8'hb4; 8'h8e: return 8'he6; 8'h8f: return 8'h73;
            8'h90: return 8'h96; 8'h91: return 8'hac; 8'h92: return 8'h74; 8'h93: return 8'h22;
            8'h94: return 8'he7; 8'h95: return 8'had; 8'h96: return 8'h35; 8'h97: return 8'h85;
            8'h98: return 8'he2; 8'h99: return 8'hf9; 8'h9a: return 8'h37; 8'h9b: return 8'he8;
            8'h9c: return 8'h1c; 8'h9d: return 8'h75; 8'h9e: return 8'hdf; 8'h9f: return 8'h6e;
            8'ha0: return 8'h47; 8'ha1: return 8'hf1; 8'ha2: return 8'h1a; 8'ha3: return 8'h71;
            8'ha4: return 8'h1d; 8'ha5: return 8'h29; 8'ha6: return 8'hc5; 8'ha7: return 8'h89;
            8'ha8: return 8'h6f; 8'ha9: return 8'hb7; 8'haa: return 8'h62; 8'hab: return 8'h0e;
            8'hac: return 8'haa; 8'had: return 8'h18; 8'hae: return 8'hbe; 8'haf: return 8'h1b;
            8'hb0: return 8'hfc; 8'hb1: return 8'h56; 8'hb2: return 8'h3e; 8'hb3: return 8'h4b;
            8'hb4: return 8'hc6; 8'hb5: return 8'hd2; 8'hb6: return 8'h79; 8'hb7: return 8'h20;
            8'hb8: return 8'h9a; 8'hb9: return 8'hdb; 8'hba: return 8'hc0; 8'hbb: return 8'hfe;
            8'hbc: return 8'h78; 8'hbd: return 8'hcd; 8'hbe: return 8'h5a; 8'hbf: return 8'hf4;
            8'hc0: return 8'h1f; 8'hc1: return 8'hdd; 8'hc2: return 8'ha8; 8'hc3: return 8'h33;
            8'hc4: return 8'h88; 8'hc5: return 8'h07; 8'hc6: return 8'hc7; 8'hc7: return 8'h31;
            8'hc8: return 8'hb1; 8'hc9: return 8'h12; 8'hca: return 8'h10; 8'hcb: return 8'h59;
            8'hcc: return 8'h27; 8'hcd: return 8'h80; 8'hce: return 8'hec; 8'hcf: return 8'h5f;
            8'hd0: return 8'h60; 8'hd1: return 8'h51; 8'hd2: return 8'h7f; 8'hd3: return 8'ha9;
            8'hd4: return 8'h19; 8'hd5: return 8'hb5; 8'hd6: return 8'h4a; 8'hd7: return 8'h0d;
            8'hd8: return 8'h2d; 8'hd9: return 8'he5; 8'hda: return 8'h7a; 8'hdb: return 8'h9f;
            8'hdc: return 8'h93; 8'hdd: return 8'hc9; 8'hde: return 8'h9c; 8'hdf: return 8'hef;
            8'he0: return 8'ha0; 8'he1: return 8'he0; 8'he2: return 8'h3b; 8'he3: return 8'h4d;
            8'he4: return 8'hae; 8'he5: return 8'h2a; 8'he6: return 8'hf5; 8'he7: return 8'hb0;
            8'he8: return 8'hc8; 8'he9: return 8'heb; 8'hea: return 8'hbb; 8'heb: return 8'h3c;
            8'hec: return 8'h83; 8'hed: return 8'h53; 8'hee: return 8'h99; 8'hef: return 8'h61;
            8'hf0: return 8'h17; 8'hf1: return 8'h2b; 8'hf2: return 8'h04; 8'hf3: return 8'h7e;
            8'hf4: return 8'hba; 8'hf5: return 8'h77; 8'hf6: return 8'hd6; 8'hf7: return 8'h26;
            8'hf8: return 8'he1; 8'hf9: return 8'h69; 8'hfa: return 8'h14; 8'hfb: return 8'h63;
            8'hfc: return 8'h55; 8'hfd: return 8'h21; 8'hfe: return 8'h0c; 8'hff: return 8'h7d;
        endcase
    endfunction

    function automatic logic [127:0] sub_bytes(input logic [127:0] s);
        for (int i = 0; i < 16; i++)
            sub_bytes[i*8 +: 8] = sbox(s[i*8 +: 8]);
    endfunction

    function automatic logic [127:0] inv_sub_bytes(input logic [127:0] s);
        for (int i = 0; i < 16; i++)
            inv_sub_bytes[i*8 +: 8] = inv_sbox(s[i*8 +: 8]);
    endfunction

    function automatic logic [127:0] shift_rows(input logic [127:0] s);
        logic [7:0] b[16];
        for (int i = 0; i < 16; i++) b[i] = s[(15-i)*8 +: 8];
        shift_rows = {b[0], b[5], b[10], b[15], b[4], b[9], b[14], b[3],
                      b[8], b[13], b[2], b[7], b[12], b[1], b[6], b[11]};
    endfunction

    function automatic logic [127:0] inv_shift_rows(input logic [127:0] s);
        logic [7:0] b[16];
        for (int i = 0; i < 16; i++) b[i] = s[(15-i)*8 +: 8];
        inv_shift_rows = {b[0], b[13], b[10], b[7], b[4], b[1], b[14], b[11],
                          b[8], b[5], b[2], b[15], b[12], b[9], b[6], b[3]};
    endfunction

    function automatic logic [31:0] mix_column(input logic [31:0] c);
        logic [7:0] a0, a1, a2, a3;
        a0 = c[31:24]; a1 = c[23:16]; a2 = c[15:8]; a3 = c[7:0];
        mix_column = {
            xtime(a0) ^ (xtime(a1) ^ a1) ^ a2 ^ a3,
            a0 ^ xtime(a1) ^ (xtime(a2) ^ a2) ^ a3,
            a0 ^ a1 ^ xtime(a2) ^ (xtime(a3) ^ a3),
            (xtime(a0) ^ a0) ^ a1 ^ a2 ^ xtime(a3)
        };
    endfunction

    function automatic logic [127:0] mix_columns(input logic [127:0] s);
        mix_columns[127:96] = mix_column(s[127:96]);
        mix_columns[95:64]  = mix_column(s[95:64]);
        mix_columns[63:32]  = mix_column(s[63:32]);
        mix_columns[31:0]   = mix_column(s[31:0]);
    endfunction

    function automatic logic [31:0] inv_mix_column(input logic [31:0] c);
        logic [7:0] a0, a1, a2, a3;
        logic [7:0] x2_0, x4_0, x8_0, x2_1, x4_1, x8_1;
        logic [7:0] x2_2, x4_2, x8_2, x2_3, x4_3, x8_3;
        a0 = c[31:24]; a1 = c[23:16]; a2 = c[15:8]; a3 = c[7:0];

        x2_0 = xtime(a0); x4_0 = xtime(x2_0); x8_0 = xtime(x4_0);
        x2_1 = xtime(a1); x4_1 = xtime(x2_1); x8_1 = xtime(x4_1);
        x2_2 = xtime(a2); x4_2 = xtime(x2_2); x8_2 = xtime(x4_2);
        x2_3 = xtime(a3); x4_3 = xtime(x2_3); x8_3 = xtime(x4_3);

        inv_mix_column = {
            (x8_0 ^ x4_0 ^ x2_0) ^ (x8_1 ^ x2_1 ^ a1) ^ (x8_2 ^ x4_2 ^ a2) ^ (x8_3 ^ a3),
            (x8_0 ^ a0) ^ (x8_1 ^ x4_1 ^ x2_1) ^ (x8_2 ^ x2_2 ^ a2) ^ (x8_3 ^ x4_3 ^ a3),
            (x8_0 ^ x4_0 ^ a0) ^ (x8_1 ^ a1) ^ (x8_2 ^ x4_2 ^ x2_2) ^ (x8_3 ^ x2_3 ^ a3),
            (x8_0 ^ x2_0 ^ a0) ^ (x8_1 ^ x4_1 ^ a1) ^ (x8_2 ^ a2) ^ (x8_3 ^ x4_3 ^ x2_3)
        };
    endfunction

    function automatic logic [127:0] inv_mix_columns(input logic [127:0] s);
        inv_mix_columns[127:96] = inv_mix_column(s[127:96]);
        inv_mix_columns[95:64]  = inv_mix_column(s[95:64]);
        inv_mix_columns[63:32]  = inv_mix_column(s[63:32]);
        inv_mix_columns[31:0]   = inv_mix_column(s[31:0]);
    endfunction

    function automatic logic [127:0] add_round_key(input logic [127:0] s, rk);
        return s ^ rk;
    endfunction

    function automatic logic [31:0] rot_word(input logic [31:0] w);
        return {w[23:0], w[31:24]};
    endfunction

    function automatic logic [31:0] sub_word(input logic [31:0] w);
        return {sbox(w[31:24]), sbox(w[23:16]), sbox(w[15:8]), sbox(w[7:0])};
    endfunction

    function automatic logic [127:0] key_expand_step(input logic [127:0] k, input int r);
        logic [31:0] w0, w1, w2, w3;
        w0 = k[127:96];
        w1 = k[95:64];
        w2 = k[63:32];
        w3 = k[31:0];
        w0 = w0 ^ sub_word(rot_word(w3)) ^ {rcon(r), 24'h000000};
        w1 = w1 ^ w0;
        w2 = w2 ^ w1;
        w3 = w3 ^ w2;
        return {w0, w1, w2, w3};
    endfunction

    function automatic logic [127:0] key_expand_step_256_even(
        input logic [127:0] prev_prev,
        input logic [127:0] prev,
        input int           r
    );
        logic [31:0] w0, w1, w2, w3;
        w0 = prev_prev[127:96] ^ sub_word(rot_word(prev[31:0])) ^ {rcon_256(r), 24'h000000};
        w1 = prev_prev[95:64] ^ w0;
        w2 = prev_prev[63:32] ^ w1;
        w3 = prev_prev[31:0] ^ w2;
        return {w0, w1, w2, w3};
    endfunction

    function automatic logic [127:0] key_expand_step_256_odd(
        input logic [127:0] prev_prev,
        input logic [127:0] prev
    );
        logic [31:0] w0, w1, w2, w3;
        w0 = prev_prev[127:96] ^ sub_word(prev[31:0]);
        w1 = prev_prev[95:64] ^ w0;
        w2 = prev_prev[63:32] ^ w1;
        w3 = prev_prev[31:0] ^ w2;
        return {w0, w1, w2, w3};
    endfunction

    function automatic logic [127:0] aes_enc_round(input logic [127:0] s, rk);
        return add_round_key(mix_columns(shift_rows(sub_bytes(s))), rk);
    endfunction

    function automatic logic [127:0] aes_enc_final_round(input logic [127:0] s, rk);
        return add_round_key(shift_rows(sub_bytes(s)), rk);
    endfunction

    function automatic logic [127:0] aes_dec_round(input logic [127:0] s, rk);
        return inv_mix_columns(add_round_key(inv_sub_bytes(inv_shift_rows(s)), rk));
    endfunction

    function automatic logic [127:0] aes_dec_final_round(input logic [127:0] s, rk);
        return add_round_key(inv_sub_bytes(inv_shift_rows(s)), rk);
    endfunction

    function automatic logic [127:0] aes_encrypt_ref(input logic [127:0] pt, key);
        logic [127:0] rk0, rk1, rk2, rk3, rk4, rk5, rk6, rk7, rk8, rk9, rk10;
        rk0 = key;
        rk1 = key_expand_step(rk0, 1);
        rk2 = key_expand_step(rk1, 2);
        rk3 = key_expand_step(rk2, 3);
        rk4 = key_expand_step(rk3, 4);
        rk5 = key_expand_step(rk4, 5);
        rk6 = key_expand_step(rk5, 6);
        rk7 = key_expand_step(rk6, 7);
        rk8 = key_expand_step(rk7, 8);
        rk9 = key_expand_step(rk8, 9);
        rk10 = key_expand_step(rk9, 10);
        aes_encrypt_ref = add_round_key(pt, rk0);
        aes_encrypt_ref = aes_enc_round(aes_encrypt_ref, rk1);
        aes_encrypt_ref = aes_enc_round(aes_encrypt_ref, rk2);
        aes_encrypt_ref = aes_enc_round(aes_encrypt_ref, rk3);
        aes_encrypt_ref = aes_enc_round(aes_encrypt_ref, rk4);
        aes_encrypt_ref = aes_enc_round(aes_encrypt_ref, rk5);
        aes_encrypt_ref = aes_enc_round(aes_encrypt_ref, rk6);
        aes_encrypt_ref = aes_enc_round(aes_encrypt_ref, rk7);
        aes_encrypt_ref = aes_enc_round(aes_encrypt_ref, rk8);
        aes_encrypt_ref = aes_enc_round(aes_encrypt_ref, rk9);
        aes_encrypt_ref = aes_enc_final_round(aes_encrypt_ref, rk10);
    endfunction

    function automatic logic [127:0] aes_decrypt_ref(input logic [127:0] ct, key);
        logic [127:0] rk0, rk1, rk2, rk3, rk4, rk5, rk6, rk7, rk8, rk9, rk10;
        rk0 = key;
        rk1 = key_expand_step(rk0, 1);
        rk2 = key_expand_step(rk1, 2);
        rk3 = key_expand_step(rk2, 3);
        rk4 = key_expand_step(rk3, 4);
        rk5 = key_expand_step(rk4, 5);
        rk6 = key_expand_step(rk5, 6);
        rk7 = key_expand_step(rk6, 7);
        rk8 = key_expand_step(rk7, 8);
        rk9 = key_expand_step(rk8, 9);
        rk10 = key_expand_step(rk9, 10);
        aes_decrypt_ref = add_round_key(ct, rk10);
        aes_decrypt_ref = aes_dec_round(aes_decrypt_ref, rk9);
        aes_decrypt_ref = aes_dec_round(aes_decrypt_ref, rk8);
        aes_decrypt_ref = aes_dec_round(aes_decrypt_ref, rk7);
        aes_decrypt_ref = aes_dec_round(aes_decrypt_ref, rk6);
        aes_decrypt_ref = aes_dec_round(aes_decrypt_ref, rk5);
        aes_decrypt_ref = aes_dec_round(aes_decrypt_ref, rk4);
        aes_decrypt_ref = aes_dec_round(aes_decrypt_ref, rk3);
        aes_decrypt_ref = aes_dec_round(aes_decrypt_ref, rk2);
        aes_decrypt_ref = aes_dec_round(aes_decrypt_ref, rk1);
        aes_decrypt_ref = aes_dec_final_round(aes_decrypt_ref, rk0);
    endfunction

    function automatic logic [127:0] aes_encrypt_ref_256(input logic [127:0] pt, key_hi, key_lo);
        logic [127:0] rk[15];
        rk[0] = key_hi;
        rk[1] = key_lo;
        rk[2] = key_expand_step_256_even(rk[0], rk[1], 1);
        rk[3] = key_expand_step_256_odd(rk[1], rk[2]);
        rk[4] = key_expand_step_256_even(rk[2], rk[3], 2);
        rk[5] = key_expand_step_256_odd(rk[3], rk[4]);
        rk[6] = key_expand_step_256_even(rk[4], rk[5], 3);
        rk[7] = key_expand_step_256_odd(rk[5], rk[6]);
        rk[8] = key_expand_step_256_even(rk[6], rk[7], 4);
        rk[9] = key_expand_step_256_odd(rk[7], rk[8]);
        rk[10] = key_expand_step_256_even(rk[8], rk[9], 5);
        rk[11] = key_expand_step_256_odd(rk[9], rk[10]);
        rk[12] = key_expand_step_256_even(rk[10], rk[11], 6);
        rk[13] = key_expand_step_256_odd(rk[11], rk[12]);
        rk[14] = key_expand_step_256_even(rk[12], rk[13], 7);
        aes_encrypt_ref_256 = add_round_key(pt, rk[0]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[1]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[2]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[3]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[4]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[5]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[6]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[7]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[8]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[9]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[10]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[11]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[12]);
        aes_encrypt_ref_256 = aes_enc_round(aes_encrypt_ref_256, rk[13]);
        aes_encrypt_ref_256 = aes_enc_final_round(aes_encrypt_ref_256, rk[14]);
    endfunction

    function automatic logic [127:0] aes_decrypt_ref_256(input logic [127:0] ct, key_hi, key_lo);
        logic [127:0] rk[15];
        rk[0] = key_hi;
        rk[1] = key_lo;
        rk[2] = key_expand_step_256_even(rk[0], rk[1], 1);
        rk[3] = key_expand_step_256_odd(rk[1], rk[2]);
        rk[4] = key_expand_step_256_even(rk[2], rk[3], 2);
        rk[5] = key_expand_step_256_odd(rk[3], rk[4]);
        rk[6] = key_expand_step_256_even(rk[4], rk[5], 3);
        rk[7] = key_expand_step_256_odd(rk[5], rk[6]);
        rk[8] = key_expand_step_256_even(rk[6], rk[7], 4);
        rk[9] = key_expand_step_256_odd(rk[7], rk[8]);
        rk[10] = key_expand_step_256_even(rk[8], rk[9], 5);
        rk[11] = key_expand_step_256_odd(rk[9], rk[10]);
        rk[12] = key_expand_step_256_even(rk[10], rk[11], 6);
        rk[13] = key_expand_step_256_odd(rk[11], rk[12]);
        rk[14] = key_expand_step_256_even(rk[12], rk[13], 7);
        aes_decrypt_ref_256 = add_round_key(ct, rk[14]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[13]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[12]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[11]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[10]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[9]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[8]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[7]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[6]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[5]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[4]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[3]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[2]);
        aes_decrypt_ref_256 = aes_dec_round(aes_decrypt_ref_256, rk[1]);
        aes_decrypt_ref_256 = aes_dec_final_round(aes_decrypt_ref_256, rk[0]);
    endfunction

endpackage
