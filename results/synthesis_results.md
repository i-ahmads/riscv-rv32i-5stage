# Synthesis Results

**Toolchain:** Xilinx ISE 14.7 / XST
**Target device:** xc7a100t-3csg324 (Artix-7), speed grade -3

Figures below are pulled directly from the real XST synthesis reports (`.syr` files), included as-is in [`synthesis_reports/`](synthesis_reports/) alongside the `.xst` synthesis scripts and HTML design summaries used to produce them.

## Device utilization

| Resource | `cpu_top` (EX-stage resolution) | `cpu_top_idres` (ID-stage resolution) |
|---|---:|---:|
| Slice Registers | 520 | 523 |
| Slice LUTs | 1720 | 1613 |
| &nbsp;&nbsp;— used as Logic | 1616 | 1509 |
| &nbsp;&nbsp;— used as Memory (RAM) | 104 | 104 |
| LUT/FF pairs used | 1845 | 1747 |
| Device: xc7a100t-3csg324 | 63,400 LUTs available | 63,400 LUTs available |

## Timing

| | `cpu_top` | `cpu_top_idres` |
|---|---:|---:|
| Minimum period | 6.779 ns | 6.305 ns |
| **Maximum frequency (Fmax)** | **147.51 MHz** | **158.61 MHz** |
| Min. input arrival before clock | 0.808 ns | 0.809 ns |

**Takeaway:** moving branch/jump resolution from the EX stage to the ID stage (`cpu_top_idres`) reduces LUT usage by ~6% (1720 → 1613) and improves Fmax by ~7.5% (147.5 → 158.6 MHz) — resolving earlier shortens the critical path through the branch comparator/PC-mux logic. The trade-off is discussed alongside the cycle-count comparison in [`cycle_count_comparison.md`](cycle_count_comparison.md), since ID-stage resolution also changes flush cost.

## Raw report files

- [`synthesis_reports/cpu_top.syr`](synthesis_reports/cpu_top.syr) / [`cpu_top_idres.syr`](synthesis_reports/cpu_top_idres.syr) — full XST synthesis reports (device utilization, timing, macro statistics).
- [`synthesis_reports/cpu_top.xst`](synthesis_reports/cpu_top.xst) / [`cpu_top_idres.xst`](synthesis_reports/cpu_top_idres.xst) — XST synthesis option scripts, for reproducing the run.
- [`synthesis_reports/cpu_top_summary.html`](synthesis_reports/cpu_top_summary.html) / [`cpu_top_idres_summary.html`](synthesis_reports/cpu_top_idres_summary.html) — ISE Design Summary pages.
- [`schematics/design_summary/`](schematics/design_summary/) — Design Summary screenshots as originally captured.
- [`schematics/cpu_top/`](schematics/cpu_top/) / [`schematics/cpu_top_idres/`](schematics/cpu_top_idres/) — selected RTL schematic viewer screenshots of the CPU variants and major EX-stage submodules.

## Power

Not included here — per the project's own findings, XPower Analyzer before/after numbers should come from a real run rather than be asserted, and none was captured for this pipeline (unlike the companion ALU project, which explicitly flags this as outstanding too).
