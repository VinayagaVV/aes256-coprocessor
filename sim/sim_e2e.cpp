#include <verilated.h>
#include "Vcoprocessor_top.h"
#include <iostream>
#include <iomanip>
#include <sstream>
#include <cstdint>

std::string h32(uint32_t v) {
    std::ostringstream os;
    os << "0x" << std::hex << std::setfill('0') << std::setw(8) << v;
    return os.str();
}

int errors = 0;
int steps = 0;

void tick(Vcoprocessor_top* dut) {
    dut->clk = 0; dut->eval();
    dut->clk = 1; dut->eval();
    steps++;
}

void chk32(const char* label, uint32_t got, uint32_t exp) {
    if (got != exp) {
        std::cout << "  FAIL: " << label << " = " << h32(got)
                  << " (expected " << h32(exp) << ")\n";
        errors++;
    } else {
        std::cout << "  PASS: " << label << " = " << h32(got) << "\n";
    }
}

static uint32_t R(uint32_t funct7, uint32_t rs2, uint32_t rs1, uint32_t funct3, uint32_t rd) {
    return funct7<<25 | rs2<<20 | rs1<<15 | funct3<<12 | rd<<7 | 0x33;
}
static uint32_t LW(uint32_t imm12, uint32_t rs1, uint32_t rd) {
    return (imm12 & 0xFFF)<<20 | rs1<<15 | 0x2<<12 | rd<<7 | 0x03;
}
static uint32_t SW(uint32_t imm12, uint32_t rs1, uint32_t rs2) {
    return ((imm12 & 0xFE0)<<20) | (rs2<<20) | (rs1<<15) | 0x2<<12 | ((imm12 & 0x1F)<<7) | 0x23;
}

const char* state_name(uint32_t s) {
    static const char* names[] = {
        "IDLE", "LOAD_KEY", "DECRYPT_0", "STORE_0",
        "DECRYPT_1", "STORE_1", "WAIT_CORE", "READ_SMEM_0",
        "ENCRYPT_0", "WAIT_ENCR_0", "READ_SMEM_1", "ENCRYPT_1",
        "WAIT_ENCR_1", "DO_SHA_PREP", "DO_SHA", "WAIT_SHA",
        "CAPTURE_SHA", "TX_OUT"
    };
    if (s < 18) return names[s];
    return "???";
}

void set128(VlWide<4>& sig, uint32_t w3, uint32_t w2, uint32_t w1, uint32_t w0) {
    sig.at(0) = w0; sig.at(1) = w1; sig.at(2) = w2; sig.at(3) = w3;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vcoprocessor_top* dut = new Vcoprocessor_top;
    steps = 0;

    dut->rst_n = 0;
    dut->start = 0;
    dut->ctrl_instr = 0;
    dut->ctrl_instr_valid = 0;
    set128(dut->enc_data_0, 0, 0, 0, 0);
    set128(dut->enc_data_1, 0, 0, 0, 0);
    tick(dut); tick(dut);
    dut->rst_n = 1; tick(dut);

    std::cout << "=== Co-Processor AES-256 End-to-End Test ===\n\n";

    // Test Vector 1: 5 + 6 = 11 (AES-256 with NIST key)
    std::cout << "Step 1: Load encrypted inputs, assert start\n";
    set128(dut->enc_data_0, 0xa90741e6, 0x797146a5, 0x50b63f26, 0x4a604ee4);
    set128(dut->enc_data_1, 0xe96f3e0a, 0x91d150e2, 0xd389d3c7, 0x16244899);
    dut->start = 1; tick(dut);
    dut->start = 0;

    std::cout << "Step 2: Trace FSM states (first 80 cycles)\n";
    for (int i = 0; i < 100; i++) {
        tick(dut);
        if (dut->dbg_state != 0 || i < 5)
            std::cout << "  t=" << steps << " state=" << state_name(dut->dbg_state)
                      << " irq=" << (int)dut->core_irq
                      << " busy=" << (int)dut->busy
                      << " tx=" << (int)dut->tx_valid
                      << "\n";
    }

    if (dut->core_irq) {
        std::cout << "\n  core_irq asserted at cycle " << steps << "\n";
        std::cout << "Step 3: Execute CPU program (6 instructions)\n";
        auto feed = [&](uint32_t instr) {
            dut->ctrl_instr = instr;
            dut->ctrl_instr_valid = 1; tick(dut);
            dut->ctrl_instr_valid = 0;
        };
        feed(LW(0x000, 0, 1));
        feed(LW(0x004, 0, 2));
        feed(R(0x00, 2, 1, 0, 3));
        feed(SW(0x080, 0, 3));
        feed(SW(0x084, 0, 3));
        feed(SW(0x0FC, 0, 0));

        std::cout << "Step 4: Wait for tx_valid...\n";
        int wait = 0;
        while (!dut->tx_valid && wait < 400) { tick(dut); wait++; }
        std::cout << "  tx_valid after " << wait << " cycles\n";

        if (dut->tx_valid) {
            std::cout << "\nStep 5: Verify TX output\n";
            uint32_t txw[16];
            for (int i = 0; i < 16; i++) txw[i] = dut->tx_data.at(i);

            // TX format: {sha[255:0], enc1[127:0], enc0[127:0]}
            //   txw[15:8] = SHA digest (15=MSB)
            //   txw[7:4]  = enc1 (7=MSB)
            //   txw[3:0]  = enc0 (3=MSB)
            uint32_t golden_enc0[] = {0x21584d7f, 0xdeaac3e6, 0x870a7952, 0x6e666ee2};
            uint32_t golden_enc1[] = {0x21584d7f, 0xdeaac3e6, 0x870a7952, 0x6e666ee2};
            uint32_t golden_sha[] = {
                0xf165d627, 0x6c4619d1, 0xe9a001be, 0x8e8798d8,
                0x89da1df7, 0x097a5c51, 0x4f595b62, 0x25c91b40
            };

            std::cout << "  TX words (0=LSB):\n";
            for (int i = 15; i >= 0; i--)
                std::cout << "    [" << i << "] = " << h32(txw[i]) << "\n";

            std::cout << "\n  Verifying encrypted block 0 (txw[0..3]):\n";
            for (int i = 0; i < 4; i++)
                chk32(("enc0["+std::to_string(i)+"]").c_str(), txw[3-i], golden_enc0[i]);

            std::cout << "  Verifying encrypted block 1 (txw[4..7]):\n";
            for (int i = 0; i < 4; i++)
                chk32(("enc1["+std::to_string(i)+"]").c_str(), txw[7-i], golden_enc1[i]);

            std::cout << "  Verifying SHA-256 (txw[8..15]):\n";
            for (int i = 0; i < 8; i++)
                chk32(("sha["+std::to_string(i)+"]").c_str(), txw[15-i], golden_sha[i]);
        } else {
            std::cout << "  tx_valid never asserted!\n";
            errors++;
        }
    } else {
        std::cout << "\n  core_irq never asserted!\n";
        errors++;
    }

    std::cout << "\n=== " << (errors ? "FAILED" : "ALL PASSED")
              << " with " << errors << " error(s) ===\n";
    dut->final(); delete dut;
    return errors ? 1 : 0;
}
