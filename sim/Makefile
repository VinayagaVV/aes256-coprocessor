RTL := ../rtl

CPP_BASE := AES/aes_pkg.sv SHA/sha_pkg.sv aes_key_bram.sv \
            AES/aes_accelerator.sv AES/crypto_top.sv \
            SHA/sha_accelerator.sv coprocessor_fsm.sv \
            coprocessor_top.sv rv32i/rv32i_alu.sv rv32i/rv32i_core.sv \
            rv32i/RV32I.v shared_mem.sv protected_mem.sv

SRCS   := $(foreach f,$(CPP_BASE),$(RTL)/$(f))
COMMON := $(SRCS) -I$(RTL)/rv32i

VERILATOR := verilator
FLAGS := --cc --exe --build -Wno-fatal

.PHONY: all e2e pipeline run-e2e run-pipeline clean sim_main

all: e2e pipeline

e2e: obj_dir_e2e/Vcoprocessor_top

pipeline: obj_dir_pipeline/Vcoprocessor_wrapper

obj_dir_e2e/Vcoprocessor_top: sim_e2e.cpp
	$(VERILATOR) $(FLAGS) --top-module coprocessor_top \
		$(COMMON) $< --Mdir obj_dir_e2e

obj_dir_pipeline/Vcoprocessor_wrapper: sim_pipeline.cpp
	$(VERILATOR) $(FLAGS) --top-module coprocessor_wrapper \
		$(COMMON) $(RTL)/coprocessor_wrapper.sv $< --Mdir obj_dir_pipeline

run-e2e: e2e
	./obj_dir_e2e/Vcoprocessor_top

run-pipeline: pipeline
	./obj_dir_pipeline/Vcoprocessor_wrapper

sim_main: obj_dir_main/Vrv32i_core

obj_dir_main/Vrv32i_core: sim_main.cpp
	$(VERILATOR) $(FLAGS) --top-module rv32i_core \
		-I$(RTL)/rv32i $(RTL)/rv32i/rv32i_alu.sv $(RTL)/rv32i/rv32i_core.sv \
		$(RTL)/rv32i/RV32I.v $< --Mdir obj_dir_main

clean:
	rm -rf obj_dir_e2e obj_dir_pipeline obj_dir_main
