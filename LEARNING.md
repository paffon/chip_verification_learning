# LEARNING.md

Running log of hardware/verification concepts, one short entry per concept.
Doubles as study notes and raw material for the final README.

---

## M0 — Foundations & toolchain

### Toolchain setup (2026-06-16)
- **Environment:** WSL2 + Ubuntu 24.04 hosts the Linux-first EDA tools; the repo
  stays on the Windows side and tools run against it via `/mnt/c/...`.
- **OSS CAD Suite** (YosysHQ prebuilt bundle, build 2026-06-15) gives us all tools
  in one tarball: Yosys, SymbiYosys (`sby`), Verilator, Icarus (`iverilog`), SMT solvers.
- Sourced automatically via `~/.profile` -> `source ~/oss-cad-suite/environment`.
- Verified: Yosys 0.66, sby 0.66, Verilator 5.049, Icarus 14.0.

### The four tools, by role
- **Verilator / Icarus** = *simulators*. Apply specific input signals over simulated
  clock ticks, observe outputs. Dynamic verification: only tests cases you stimulate.
- **Yosys** = synthesis + the front-end that parses (System)Verilog into a formal netlist.
- **SymbiYosys (`sby`)** = *formal* driver. Proves an assertion holds for *all* inputs,
  or returns a concrete counterexample. (This is the "FV" in the job title.)
