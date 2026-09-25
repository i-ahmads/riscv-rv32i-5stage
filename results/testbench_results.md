# Verification Results

All testbenches are self-checking (assert + report PASS/FAIL) and were re-run for this repository snapshot under **GHDL 4.1.0** (Ubuntu package, mcode JIT backend), `--std=93 -fsynopsys` (the `-fsynopsys` flag is required for `std_logic_textio`, used for `write`/`hwrite` trace logging in these testbenches).

## Summary (freshly re-run, all passing)

| Testbench | DUT | Assertions | Result |
|---|---|---:|---|
| `tb_alu.vhd` | `alu` | 25 | 25/25 PASS |
| `tb_register_file.vhd` | `register_file` | 4 | 4/4 PASS |
| `tb_hazard_forwarding.vhd` | `hazard_detection_unit` + `forwarding_unit` | 9 | 9/9 PASS |
| `tb_cpu_top.vhd` | `cpu_top` (EX-stage branch resolution) | 26 | 26/26 PASS |
| `tb_cpu_top_idres.vhd` | `cpu_top_idres` (ID-stage branch resolution) | 26 | 26/26 PASS |
| **Subtotal (core 5 testbenches)** | | **90** | **90/90 PASS** |
| `tb_worked_example.vhd` | `cpu_top_worked` (minimal illustrative variant, used for the report's worked example) | 3 | 3/3 PASS |
| **Total (all 6 testbenches)** | | **93** | **93/93 PASS** |

Raw run output is in [`ghdl_run_log.txt`](ghdl_run_log.txt). Full instruction-by-instruction PC traces and per-register final-state dumps from the original verification pass are preserved in [`prior_sim_logs/`](prior_sim_logs/) for reference.

## What each testbench covers

- **`tb_alu`** — all RV32I ALU operations (ADD/SUB/AND/OR/XOR/SLT/SLTU/SLL/SRL/SRA), including signed vs. unsigned comparison edge cases and sign-fill vs. zero-fill shift behavior.
- **`tb_register_file`** — x0 hard-wired to zero even under attempted writes, basic write-then-read, the debug read port, and write-through (same-cycle read-during-write) bypass behavior.
- **`tb_hazard_forwarding`** — EX/MEM and MEM/WB forwarding priority (EX/MEM wins when both match), x0 never forwarded, load-use hazard stalling (PC/IF-ID held, ID/EX bubbled), no false stall when the loaded register isn't actually used next, and branch-taken flush behavior (IF/ID + ID/EX flushed, PC not stalled).
- **`tb_cpu_top`** / **`tb_cpu_top_idres`** — full-pipeline integration test: runs a real RV32I test program covering arithmetic, logic, shifts, loads/stores, and branches, then checks 26 architectural registers against expected final values via the CPU's debug port. Identical test program and expected values used for both branch-resolution variants.
- **`tb_worked_example`** — a small, deliberately minimal 3-instruction program run through the simplified `cpu_top_worked` variant used for the report's worked-example walkthrough (Section 7.7), checking 3 final register values.

## Two RV32I core variants, one shared datapath design

- **`cpu_top` / `datapath.vhd`** — branch/jump resolution in the **EX stage**.
- **`cpu_top_idres` / `datapath_idres.vhd`** — branch/jump resolution moved up to the **ID stage** (with its own `hazard_detection_unit_idres.vhd` and `id_forward_unit.vhd` to handle the extra forwarding this requires).

Both variants pass the identical 26-register architectural check in `tb_cpu_top(_idres)`, confirming the ID-stage-resolution variant is functionally equivalent while resolving branches one stage earlier (see `results/cycle_count_comparison.md` and `results/synthesis_results.md` for the resulting timing/cycle-count trade-off).
