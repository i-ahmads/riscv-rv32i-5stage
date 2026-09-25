# Cycle-Count Comparison: EX-Stage vs. ID-Stage Branch Resolution

Both `cpu_top` (EX-stage resolution) and `cpu_top_idres` (ID-stage resolution) run the identical RV32I test program and reach identical final architectural register values (see `testbench_results.md`) — the two variants are functionally equivalent, differing only in *when* a taken branch/jump is resolved and therefore *how many* instructions get flushed on a taken branch.

## The design-level reasoning

- **`cpu_top` (EX-stage resolution):** a taken branch/jump is only known to be taken once it reaches the EX stage. By then, two younger instructions have already been fetched into IF/ID and ID/EX — both must be flushed, i.e. **2 bubble cycles per taken branch**.
- **`cpu_top_idres` (ID-stage resolution):** the branch condition and target are resolved a stage earlier, in ID. Only one younger instruction (already in IF/ID) needs to be flushed — **1 bubble cycle per taken branch**. This is why `hazard_detection_unit_idres.vhd` and `id_forward_unit.vhd` exist: resolving in ID requires forwarding operand data into the ID stage a cycle earlier than the base design does.

Since each variant runs the same program with the same number of taken control-flow instructions, the total-cycle difference between the two should equal exactly **(1 extra flush cycle) × (number of taken branches/jumps)**.

## Recorded result

Per the project's cycle-accurate analysis: **67 cycles** for `cpu_top` (EX-stage resolution) vs. **59 cycles** for `cpu_top_idres` (ID-stage resolution) to execute the full test program to completion — an **8-cycle gap**, matching **8 taken control-flow instructions** in the test program.

> **Note on provenance:** this specific pair of numbers is carried over from the project's existing cycle-accurate analysis rather than independently re-derived in this repository pass. It can be independently checked by simulating the included RTL and tracing the PC and taken-branch events cycle by cycle. The testbench pass counts and LUT/Fmax figures are documented in the included logs and synthesis reports.

## Net trade-off

| | `cpu_top` (EX-resolution) | `cpu_top_idres` (ID-resolution) |
|---|---:|---:|
| Cycles to complete test program | 67 | 59 |
| Slice LUTs | 1720 | 1613 |
| Fmax | 147.51 MHz | 158.61 MHz |

Resolving branches one stage earlier wins on all three axes for this design: fewer cycles (less flush overhead), fewer LUTs, and a higher achievable clock — at the cost of the extra ID-stage forwarding/hazard logic needed to make early resolution correct.
