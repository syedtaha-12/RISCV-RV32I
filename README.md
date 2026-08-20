# RISC-V RV32I Core

A single-cycle RV32I RISC-V processor core, written in SystemVerilog and verified with directed and (soon) coverage-driven testbenches in Questa.

This project is a from-scratch build of the RV32I base integer instruction set — every module is designed, coded, and verified by hand, module by module, before being wired into the full datapath.

## Why this project exists

I'm building this to go deep on digital design and verification, the way it's actually done in industry: write RTL, write a rigorous testbench for it, prove it's correct, then move to the next block. The long-term goal is a fully pipelined core with hazard handling, branch prediction, and cache — but every stage along the way is being verified properly rather than rushed.

## Status

**In progress — control logic complete, datapath integration next.**

| Module | Purpose | Status |
|---|---|---|
| `pc.sv` | Program counter | ✅ Verified |
| `adder_pc.sv` | PC+4 / branch target adder | ✅ Verified |
| `alu.sv` | Arithmetic logic unit | ✅ Verified |
| `register.sv` | 32×32-bit register file | ✅ Verified |
| `instr_mem.sv` | Instruction memory (hex-loaded) | ✅ Verified |
| `data_mem.sv` | Data memory | ✅ Verified |
| `imm_gen.sv` | Immediate generator (I/S/B/U/J types) | ✅ Verified |
| `control.sv` | Main control unit | ✅ Verified |
| `alu_control.sv` | ALU operation decoder | ✅ Verified |
| `alu_input_a_mux.sv` | ALU input A select mux | ✅ Verified |
| `alu_input_b_mux.sv` | ALU input B select mux | ✅ Verified |
| `wb_mux.sv` | Writeback select mux | ✅ Verified |
| `load_extend.sv` | Load sign/zero-extension (LB/LH/LW/LBU/LHU) | ✅ Verified |
| `branch_comparator.sv` | Branch condition evaluator (BEQ/BNE/BLT/BGE/BLTU/BGEU) | ✅ Verified |

**Next steps:** wire the full single-cycle datapath, then add a top-level integration testbench running real RV32I test programs. Going forward, new modules also get functional coverage (SystemVerilog covergroups) and SVA assertions alongside directed tests — not just pass/fail testbenches.

## Repository structure

```
rv32i/
├── rtl/     — synthesizable SystemVerilog source
├── tb/      — testbenches, one per module
└── sim/     — simulation scripts / Questa project files
```

## Verification approach

Every module has its own self-checking testbench, simulated in Questa. Testing goes beyond the obvious cases — for example, edge cases around uninitialized registers, sign-extension boundaries, and persistence of memory state after writes have all caught real bugs during development, not just confirmed the happy path.

Starting with the current stage of the project, modules also get:
- **Functional coverage** — covergroups tracking that meaningful input combinations and corner cases are actually exercised, not just tested once.
- **SystemVerilog assertions (SVA)** — checking design invariants continuously during simulation (e.g. register x0 always reads zero, PC only changes in valid ways).

## Tools

- **Language:** SystemVerilog
- **Simulator:** Questa-FPGA Starter Edition
- **Version control:** Git / GitHub

## Instruction set target

RV32I base integer instruction set (RISC-V).

---

*This project is under active development as part of my preparation for hardware design and verification roles.*
