#include <verilated.h>
#include "Vrv32i_core.h"
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

// R-type: opcode=0x33
uint32_t rtype(unsigned funct7, unsigned rs2, unsigned rs1, unsigned funct3, unsigned rd) {
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33;
}
// I-type ALU: opcode=0x13
uint32_t itype(unsigned imm12, unsigned rs1, unsigned funct3, unsigned rd) {
    return (imm12 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x13;
}
// LUI: opcode=0x37
uint32_t lui(unsigned imm20, unsigned rd) {
    return (imm20 << 12) | (rd << 7) | 0x37;
}

// Exec one instruction: capture debug outputs BEFORE posedge (after clk=0 eval)
void exec(Vrv32i_core* dut, vluint64_t& t, uint32_t instr,
          int& rd, uint32_t& rd_val) {
    dut->instr = instr;
    dut->instr_valid = 1;
    dut->clk = 0; dut->eval(); t += 5;
    // Combinational values stable now, before any regfile write
    rd    = dut->debug_rd_addr;
    rd_val = dut->debug_rd_data;
    dut->clk = 1; dut->eval(); t += 5;  // posedge: regfile write happens
    dut->instr_valid = 0;
    dut->clk = 0; dut->eval(); t += 5;  // settle
    dut->clk = 1; dut->eval(); t += 5;
}

void chk(const char* label, uint32_t got, uint32_t exp) {
    if (got != exp) {
        std::cout << "  FAIL: " << label << " = " << h32(got)
                  << " (expected " << h32(exp) << ")\n";
        errors++;
    } else {
        std::cout << "  PASS: " << label << " = " << h32(got) << "\n";
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vrv32i_core* dut = new Vrv32i_core;
    vluint64_t t = 0;
    int rd; uint32_t rdv;

    // Reset
    dut->rst_n = 0; dut->instr = 0; dut->instr_valid = 0;
    for (int i = 0; i < 4; i++) {
        dut->clk = 0; dut->eval(); t += 5;
        dut->clk = 1; dut->eval(); t += 5;
    }
    dut->rst_n = 1;
    dut->clk = 0; dut->eval(); t += 5;
    dut->clk = 1; dut->eval(); t += 5;

    std::cout << "=== RV32I Core ALU Verification ===\n\n";

    // === Load x1 = 0x12345678, x2 = 0x00000009 ===
    std::cout << "--- Setup ---\n";
    exec(dut, t, lui(0x12345, 1), rd, rdv);                        // LUI x1, 0x12345000
    exec(dut, t, itype(0x678, 1, 0, 1), rd, rdv);                  // ADDI x1, x1, 0x678
    std::cout << "  x1 = " << h32(rdv) << "\n";

    exec(dut, t, itype(0x009, 0, 0, 2), rd, rdv);                  // ADDI x2, x0, 9
    std::cout << "  x2 = " << h32(rdv) << "\n";

    // === R-type: x1 op x2 -> x10 ===
    std::cout << "\n--- R-type (x1=0x12345678, x2=9) ---\n";

    struct { const char* n; unsigned f7, f3; uint32_t exp; } rt[] = {
        {"ADD",  0x00, 0x0, 0x12345681},
        {"SUB",  0x20, 0x0, 0x1234566F},
        {"SLL",  0x00, 0x1, 0x68ACF000},
        {"SLT",  0x00, 0x2, 0x00000000},
        {"SLTU", 0x00, 0x3, 0x00000000},
        {"XOR",  0x00, 0x4, 0x12345671},
        {"SRL",  0x00, 0x5, 0x00091A2B},
        {"SRA",  0x20, 0x5, 0x00091A2B},
        {"OR",   0x00, 0x6, 0x12345679},
        {"AND",  0x00, 0x7, 0x00000008},
    };

    for (auto& r : rt) {
        exec(dut, t, rtype(r.f7, 2, 1, r.f3, 10), rd, rdv);
        chk(r.n, rdv, r.exp);
    }

    // === I-type: x1 op imm12 -> x11 ===
    std::cout << "\n--- I-type (x1=0x12345678) ---\n";

    exec(dut, t, itype(0x111, 1, 0, 11), rd, rdv);
    chk("ADDI 0x111",  rdv, 0x12345789);

    exec(dut, t, itype(0x7FF, 1, 2, 11), rd, rdv);
    chk("SLTI 0x7FF",  rdv, 0x00000000);

    exec(dut, t, itype(0x7FF, 1, 3, 11), rd, rdv);
    chk("SLTIU 0x7FF", rdv, 0x00000000);

    exec(dut, t, itype(0xFF0, 1, 4, 11), rd, rdv);
    chk("XORI 0xFF0",  rdv, 0xEDCBA988);  // imm=0xFF0 sign-ext → 0xFFFFFFF0

    exec(dut, t, itype(0x0F0, 1, 6, 11), rd, rdv);
    chk("ORI 0x0F0",   rdv, 0x123456F8);

    exec(dut, t, itype(0xF00, 1, 7, 11), rd, rdv);
    chk("ANDI 0xF00",  rdv, 0x12345600);  // imm=0xF00 sign-ext → 0xFFFFFF00

    exec(dut, t, itype(0x004, 1, 1, 11), rd, rdv);
    chk("SLLI 4",      rdv, 0x23456780);

    exec(dut, t, itype(0x008, 1, 5, 11), rd, rdv);
    chk("SRLI 8",      rdv, 0x00123456);

    exec(dut, t, itype(0x408, 1, 5, 11), rd, rdv);
    chk("SRAI 8",      rdv, 0x00123456);

    // === Edge cases ===
    std::cout << "\n--- Edge cases ---\n";
    exec(dut, t, itype(0xFFF, 1, 2, 12), rd, rdv);
    chk("SLTI(-1)",      rdv, 0x00000000);

    exec(dut, t, itype(0xFFF, 1, 3, 12), rd, rdv);
    chk("SLTIU(-1)",     rdv, 0x00000001);

    exec(dut, t, lui(0xA0000, 13), rd, rdv);
    chk("LUI",           rdv, 0xA0000000);

    // === Summary ===
    std::cout << "\n=== " << (errors ? "FAILED" : "ALL PASSED")
              << " with " << errors << " error(s) ===\n";

    dut->final(); delete dut;
    return errors ? 1 : 0;
}
