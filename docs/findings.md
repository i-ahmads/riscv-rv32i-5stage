# Design Notes, Findings, and Known Limitations

## Bugs found during simulation (not just code review)

- **JAL/JALR forwarding used the ALU output instead of PC+4.** The link register write-back for `JAL`/`JALR` was sourced from the ALU result path instead of the dedicated `PC+4` value, which is only correct by coincidence for some instruction sequences. Caught by running the actual test program through simulation and checking architectural register values, not by inspecting the RTL alone.
- **Instruction memory address decode was too narrow.** An early version of `instr_mem.vhd`'s address decoding didn't cover the full range needed by the test program, silently aliasing some fetches. Also only surfaced once the full test program was actually simulated end-to-end.

Both bugs are consistent with this project's general verification approach: run the actual simulation and cross-check against expected architectural state, rather than relying on code review or partial unit tests alone.

## Key design decisions

- **Two branch-resolution variants, one shared philosophy.** `cpu_top`/`datapath.vhd` resolves branches in EX; `cpu_top_idres`/`datapath_idres.vhd` resolves in ID. Both are built from the same building blocks (ALU, register file, pipeline registers, control unit) — the ID-stage variant simply adds `hazard_detection_unit_idres.vhd` and `id_forward_unit.vhd` to handle the extra forwarding that earlier resolution requires. See `results/cycle_count_comparison.md` for the resulting cycle/area/frequency trade-off.
- **Debug port for architectural verification.** Both CPU tops expose a `dbg_addr`/`dbg_data` port into the register file (and `dbg_pc`) purely for testbench observability — this is what lets `tb_cpu_top(_idres)` check all 26 final register values without needing to add memory-mapped I/O to the design.
- **Worked-example variant (`cpu_top_worked`).** A deliberately minimal 3-instruction configuration (`cpu_top_worked.vhd` / `datapath_worked.vhd` / `instr_mem_worked.vhd`) exists specifically to support a fully-traceable, hand-checkable walkthrough (used in the report's worked-example section) — it is not a third "real" CPU variant, just a small teaching configuration built on the same datapath structure.

## Verification approach

- All five core testbenches (`tb_alu`, `tb_register_file`, `tb_hazard_forwarding`, `tb_cpu_top`, `tb_cpu_top_idres`) plus `tb_worked_example` are self-checking and were re-run fresh under GHDL 4.1.0 for this repository (see `results/testbench_results.md` and `results/ghdl_run_log.txt`).
- The custom assembler (`tools/asm_full.py`) was used to build the RV32I test program(s) loaded into `instr_mem.vhd`, with results cross-checked against an independent golden model before being treated as ground truth for the architectural register checks.
- Both GHDL (for fast, scriptable regression) and Xilinx ISim (for the waveform captures under `results/waveforms/`) were used — some simulator-specific issues only surface in one tool, so cross-checking both was part of the verification discipline on this project (see the companion ALU project's notes for a concrete example of an ISim-only bug).

## Explicitly out of scope

- This is a standalone 5-stage RV32I pipeline project, kept independent in both implementation and citation sourcing from the separate 16-bit ALU coursework project (see that project's own repository).

## What's included vs. not in this repository

- **Included:** all VHDL source and testbenches, the custom assembler, real GHDL run logs (fresh + prior), real XST synthesis reports/scripts/summaries, and a selected set of RTL and ISim screenshots.
- **Not included (by request):** the written project report (`.docx`) and the presentation slide deck — these are maintained separately.
- **Not included (tool-specific build junk):** Xilinx ISE intermediate/binary artifacts (`.ngc`, `.ngr`, `.stx`, `.prj`, `.lso`, `.cmd_log`, ISim `.exe`/`.wdb` binaries) were left out as non-portable, regenerable build output — the human-readable `.syr`/`.xst`/`.html` reports and the log files that matter for provenance are kept instead.
