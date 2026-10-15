# Project State

> Only record something as VERIFIED after its test has actually been run and observed passing.

## Goal
A custom RISC-V CPU running on an FPGA, built in this order:
1. The CPU itself.
2. My own systems language (with OOP, able to express merge sort) and its compiler.
3. A kernel written in that language.
4. Everything integrated and running on the FPGA.

There's no fixed deadline. **The main aim is learning**: I write the code; Claude explains, reviews and verifies.

## Frozen decisions
| Date | Decision | Reason |
|---|---|---|
| 2026-10-10 | Target ISA: RV32IM + Zicsr + Zifencei, M/S/U modes, Sv32, timer | Enough for my own kernel. Linux isn't a goal (optional stretch only). |
| 2026-10-10 | Stay with RISC-V, not Arm | Open ISA (no licensing problem, especially as an Arm employee), small enough to fully understand, open reference tools (Spike, riscv-tests) |
| 2026-10-10 | Simulator: Verilator 5.052; waves: GTKWave | Both are in Arch repos; Verilator gives strict lint |
| 2026-10-10 | Verification: riscv-tests, then a trace diff against Spike, then a random generator | Reuses my verification background |
| 2026-10-11 | Learn SystemVerilog step by step before the CPU (gates → ALU → registers → memory) | I didn't know Verilog/SystemVerilog yet |
| 2026-10-11 | Skip a custom ELF parser; load programs with `objcopy -O verilog --verilog-data-width=4` + `$readmemh` | Simpler; instruction formats are learned in the decoder instead |
| 2026-10-10 | Compiler host language: Python (tentative; confirm at Part D) | Fastest iteration |

## Schedule
- Works daily. Break 2026-10-20 to 2026-10-25.
- Estimate (made 2026-10-15): single-cycle CPU passing rv32ui around mid-November 2026; verified 5-stage pipeline around mid-December 2026 to early January 2027.

## Environment (verified 2026-10-10)
- Installed: verilator 5.052, gtkwave, riscv64-elf-binutils 2.47, riscv64-elf-gcc 16.2, riscv64-elf-newlib, spike 1.1.0, qemu-system-riscv / qemu-user 11.1.2, python-pytest.
- **Known issue:** Arch's `spike` was built without commit logging (`--log-commits` doesn't work). It needs a rebuild from source with `--enable-commitlog` before the Spike trace-diff step.
- Build commands:
  - asm: `riscv64-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -T linker/firstlinker.ld -o build/first tests/first.S`
  - run: `timeout 5 spike --isa=rv32i build/first; echo "exit = $?"` (exit code = value written to tohost >> 1)
  - HDL: `verilator --binary -Wall [--trace] --top-module <tb> <tb.sv> <rtl.sv> -o <name>`, then `./obj_dir/<name>`

## Current status
| Component | Status |
|---|---|
| Phase 0: environment | DONE |
| Lesson 0: RV32 assembly, ELF, tohost | DONE |
| HDL basics | IN PROGRESS (mux ✅, ALU ✅, counter ✅, register file ✅, memory ✅ (word access), full ALU next) |
| A: CPU core | NOT STARTED |
| B: FPGA bring-up | NOT STARTED (no board yet) |
| C: Privileged + MMU | NOT STARTED |
| D: Language + compiler | NOT STARTED |
| E: Kernel | NOT STARTED |
| F: Integration | NOT STARTED |

## What I've learned so far
- RISC-V assembly vs Arm: `lw rd, imm(rs1)`, `x0` is hardwired to zero, labels and `.global _start`, sections.
- Linker scripts: `ENTRY`, `SECTIONS`, the location counter `. = 0x80000000;`.
- `la` = `auipc` + `addi`: a 32-bit address doesn't fit in one instruction. The offset is split into top 20 + bottom 12 bits, adding 1 to the top when the bottom is 0x800 or more. PC-relative means position-independent, and offsets are signed.
- Spike's `tohost`: write `(value << 1) | 1` to exit. It's 64-bit, so RV32 needs two `sw`.
- ELF: header, sections (linking view) vs segments (loading view), symbol table; objdump vs spike `-l`.
- Sequential logic: clock, `always_ff @(posedge clk)`, `<=`, reset/enable, `@(posedge clk)`/`repeat` in testbenches, GTKWave. `always_ff`/`always_comb` = hardware (RTL only); plain `always`/`initial` with delays = testbench. The testbench must never drive a DUT output. The PC is a 32-bit counter: +4, reset 0x80000000, loads a target on jump.
- Register file at gate level: read ports = 32:1 mux trees (select = rs1/rs2 bits, fan-out lets 2 ports read at once); write = 5→32 decoder (one-hot) AND we → per-register enable mux, wd broadcast to all. x0 forced to 0 on every read port. Decoder drives rs1/rs2/rd/we; ALU uses rd1/rd2; writeback mux drives wd.
- SystemVerilog: module/ports/`logic`, `assign`, `always_comb` + `case` + `default` (avoids latches), widths, `initial`/`begin`/`end`/`$display`/`$finish`, `task automatic`, `===`, multiple `initial` blocks run in parallel.
- Verification habit: check against hand-written expected values, never the DUT's own formula.
- Memory: byte address to word index = drop the low 2 bits (`addr[11:2]` for 1024 words). The upper bits are ignored, so the `0x8000...` base costs nothing. `$readmemh` fills the array from a hex text file at time 0; an `initial` in RTL is allowed only for this. Memory has no x0-style rule: word 0 is the first instruction. Deliberately unused bits get a `lint_off` waiver rather than switching off `-Wall`.
- Testbench timing: wait on `@(posedge clk)` for anything that goes through a flip-flop (writes). Combinational paths (reads) just need a small `#1`. The `#1` after an edge avoids a race with the flip-flops.
- Use `===`/`!==` in testbench checks: `==`/`!=` return X on unknown values, and an X condition silently skips a FAIL. Use `==` in RTL.

## Next task
**Full RV32I ALU.** Extend `rtl/alu.sv` to 10 operations with a 4-bit `op` = `{funct7[5], funct3}`:

| op | operation | op | operation |
|---|---|---|---|
| `0000` | add | `0101` | srl |
| `1000` | sub | `1101` | sra |
| `0001` | sll | `0110` | or |
| `0010` | slt | `0111` | and |
| `0011` | sltu | `0100` | xor |

- Needs a `default` (16 codes, 10 used).
- Shifts use only `b[4:0]`. Signed operations use `$signed()`; arithmetic right shift is `>>>`.
- `slt`/`sltu` return a 32-bit 1 or 0.
- Update `tests/alu_tb.sv` for the new op codes, and add the edge cases with hand-written expected values:
  - `xor`
  - `sll` 1 by 4 = 0x10
  - `sll` 1 by 33 = 0x2
  - `srl`/`sra` of 0xF0000000 by 4 = 0x0F000000 / 0xFF000000
  - `sra` of 0x70000000 by 4 = 0x07000000
  - `slt` 0xFFFFFFFF,1 = 1
  - `sltu` 0xFFFFFFFF,1 = 0
  - `slt` 5,5 = 0
- Break test: `>>>` changed to `>>` in `sra`, so exactly one check fails.

Then: immediate generator (aim to finish it before the 2026-10-20 break).

**Small items still open:**
- `rtl/regfile.sv` line 13 `regs[rd]<=32'hDEAD;` (break-test leftover) must be removed. The CPU will use this file.
- `mem_tb`: `#1` + `===` on the program check; add the check 0x80000004 = 05828293; DUT break test (`[11:2]` changed to `[9:0]`).
- Optional: `rtl/pc.sv`, counter wrap-around.
- Self-study: merge sort in RV32 assembly.

## Upcoming tasks
Short version as of 2026-10-15: full ALU, immediate generator, decoder, branch compare, PC/next-PC, byte/half load/store, single-cycle CPU (`first.S` gives 55), riscv-tests, Spike diff, 5-stage pipeline, FPGA. Superscalar/OoO: discussed 2026-10-15; recommended as a later "v2 core" after the full stack works; decide once the 5-stage pipeline is done.
See the task list in the conversation from 2026-10-12. The short version: register file → memory/`$readmemh` → full RV32I ALU → decoder → PC/next-PC → single-cycle CPU runs `first.S` (exit 55) → riscv-tests → Spike diff → pipeline → FPGA.

## Known limitations
- `tests/first.S`: the limit `addi t4, zero, 10` is set inside the loop (harmless, could move above `loop:`).

## Test log
| Date | Component | Command | Result | Notes |
|---|---|---|---|---|
| 2026-10-10 | toolchain | `spike` running a test program with exit code 42 | PASS | tohost exit-code mechanism confirmed |
| 2026-10-12 | `tests/first.S` (sum 1..10) | build + `spike --isa=rv32i build/first` | PASS, exit = 55 | re-run 2026-10-12 |
| 2026-10-12 | `rtl/mux.sv` | `verilator ... mux_tb` + `./obj_dir/mux_sim` | PASS 8/8 | all `{s,a,b}` combinations, no `-Wall` warnings |
| 2026-10-12 | `rtl/alu.sv` (add/sub/and/or) | `verilator ... alu_tb` + `./obj_dir/alu_sim` | PASS 5/5 | hand-written expected values, no `-Wall` warnings |
| 2026-10-13 | `rtl/counter.sv` (8-bit, rst/en) | `verilator --trace ... counter_tb` + `./obj_dir/counter_sim` | PASS 3/3 | reset=0, 5 after 5 cycles, holds at 5; waveform checked in GTKWave |
| 2026-10-14 | `rtl/regfile.sv` (32×32, 2R/1W, x0=0) | `verilator --trace ... regfile_tb` + `./obj_dir/rf_sim` | PASS 2/2 | write x22=1, read back on port 1; x0 reads 0 on port 2 |
| 2026-10-14 | `regfile_tb` loop test (write x1-x31 = i+1; read i on port 1 and 31-i on port 2) | `verilator ... regfile_tb` + run | Broken DUT (`<=32'hDEAD`): 32/32 FAIL, so the bug is caught. Copy with the bug line removed: 32/32 PASS | The PASS was on a scratch copy only. `rtl/regfile.sv` still contains the bug line and must be re-verified. |
| 2026-10-15 | `rtl/mem.sv` (1024x32, `$readmemh` build/first.hex, word index `addr[11:2]`) | `verilator ... mem_tb` + `./obj_dir/mem_sim` | PASS 1025/1025 | word at 0x80000000 = 00000297 (from objdump); write/read 1024 words with i*i at byte address i*4. Earlier runs: an injected bad write at i=25 was caught, and a wrong expected value was caught. Lint clean. |
