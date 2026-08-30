# AES-256 Co-Processor

A small RTL co-processor that chains a hardware AES-256 engine, a minimal RV32I CPU, and SHA-256. It decrypts two ciphertext blocks, adds the plaintext with an RV32I ALU instruction, re-encrypts the result twice, and hashes it — all through an 18-state controller.

## Block diagram

```
enc_data_0 ──┐
             ├──> AES-256-CBC decrypt ──> protected_mem ──┐
enc_data_1 ──┘                                             │
                                            RV32I CPU (ADD)
                         ┌─────────────────────────────────┘
                         v
                   shared_mem ──> AES-256-ECB encrypt x2 ──> SHA-256 ──> 512-bit TX out
```

The layout was guided by two goals: keep the AES and SHA datapaths fully pipelined (one block per cycle after latency), and make the "processing" a real load/store step done by a CPU so the design isn't just one long combinational blob.

## Directory layout

```
rtl/
  AES/
    aes_pkg.sv             S-box, key expansion, round functions
    aes_accelerator.sv     15-stage encrypt/decrypt pipeline
    crypto_top.sv          AES + SHA wrapper
  SHA/
    sha_pkg.sv             round constants, compression helpers
    sha_accelerator.sv     64-stage SHA-256 pipeline
    sha_tb.sv              standalone SHA testbench
  rv32i/
    rv32i_core.sv          register file, decode, control
    rv32i_alu.sv           ALU (ADD/SUB/SLT/SLL/...)
    RV32I.v                instruction decoder
  coprocessor_top.sv       top-level integration
  coprocessor_fsm.sv       18-state control FSM
  coprocessor_wrapper.sv   MMIO wrapper + instruction sequencer
  aes_key_bram.sv          fixed 256-bit key
  protected_mem.sv         CPU read-only / FSM write memory
  shared_mem.sv            CPU read-write / FSM read memory
sim/
  sim_pipeline.cpp         10-vector MMIO test
  sim_e2e.cpp              single-vector end-to-end test
  sim_main.cpp             RV32I ALU smoke test
```

## Build & run

The sims are Verilator C++ harnesses. A Makefile in `sim/` does the heavy lifting:

```bash
cd sim
make            # build both testbenches
make run-e2e    # end-to-end test
make run-pipeline  # 10-vector MMIO pipeline test
make sim_main   # RV32I ALU smoke test
make clean
```

`make all` / `make e2e` / `make pipeline` build into `obj_dir_e2e` / `obj_dir_pipeline`. `-Wno-fatal` is used because a couple of leftover warnings (pin/width) are treated as non-fatal in this flow.

For reference, the underlying command for each test:

```bash
# end-to-end test (module coprocessor_top)
verilator --cc --exe --build -Wno-fatal --top-module coprocessor_top \
  -I../rtl/rv32i \
  ../rtl/AES/aes_pkg.sv ../rtl/SHA/sha_pkg.sv \
  ../rtl/aes_key_bram.sv ../rtl/AES/aes_accelerator.sv \
  ../rtl/AES/crypto_top.sv ../rtl/SHA/sha_accelerator.sv \
  ../rtl/coprocessor_fsm.sv ../rtl/coprocessor_top.sv \
  ../rtl/rv32i/rv32i_alu.sv ../rtl/rv32i/rv32i_core.sv ../rtl/rv32i/RV32I.v \
  ../rtl/shared_mem.sv ../rtl/protected_mem.sv \
  sim_e2e.cpp --Mdir obj_dir_e2e

# MMIO pipeline test (module coprocessor_wrapper)
verilator --cc --exe --build -Wno-fatal --top-module coprocessor_wrapper \
  -I../rtl/rv32i \
  ../rtl/AES/aes_pkg.sv ../rtl/SHA/sha_pkg.sv \
  ../rtl/aes_key_bram.sv ../rtl/AES/aes_accelerator.sv \
  ../rtl/AES/crypto_top.sv ../rtl/SHA/sha_accelerator.sv \
  ../rtl/coprocessor_fsm.sv ../rtl/coprocessor_top.sv \
  ../rtl/coprocessor_wrapper.sv \
  ../rtl/rv32i/rv32i_alu.sv ../rtl/rv32i/rv32i_core.sv ../rtl/rv32i/RV32I.v \
  ../rtl/shared_mem.sv ../rtl/protected_mem.sv \
  sim_pipeline.cpp --Mdir obj_dir_pipeline
```

## Results

Both harnesses pass against golden AES-256 (NIST KAT) and SHA-256 vectors:

- `make run-e2e` — single vector (5 + 6 = 11), **ALL PASSED, 0 errors**
- `make run-pipeline` — 10 vectors across operand ranges, **ALL 10 TEST VECTORS PASSED**, with correct decrypted plaintexts, CPU sum, dual encrypted blocks, SHA-256 digest, and a receiver-side decrypt cross-check

**Status: complete and stable.**

## Notes

## Notes

- AES-256 key is the NIST KAT key `00010203...1c1d1e1f`, held in `aes_key_bram.sv`.
- The RV32I core here is a toy: it only walks a short hand-fed program, so there's no fetch unit or branch logic — just decode + ALU + a load/store port.
- TX output is 512 bits: `{SHA-256(256b), enc_result_1(128b), enc_result_0(128b)}`.
