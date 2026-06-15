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

### Concept 1 — RTL & the Verilog module
- **RTL** (Register-Transfer Level): describe a circuit as registers + the logic moving
  bits between them each clock. Verilog *describes structure*, it does not execute steps.
- A **module** is a hardware block with named `input`/`output` ports.
- `wire` = a physical connection, holds no memory, must be continuously driven.
- `assign out = expr;` = **continuous assignment**: `out` is *permanently* wired to `expr`
  (read `=` as "is always equal to", not a one-time set).
- First modules: `rtl/inverter.v` (`~in`) and `rtl/mux2.v` (`sel ? a : b`).

### Concept 2 — Simulation & the testbench
- A module is inert alone; a **testbench** drives it. The TB is a port-less module that
  *instantiates* the DUT and pokes its inputs over simulated time.
- `reg` = a signal a procedure holds/sets (TB-driven inputs); `wire` = driven by the DUT.
- **Instantiation:** `mux2 dut ( .port(signal), ... )` connects ports by name.
- `initial begin ... end` = runs once at t=0, top-to-bottom — the only sequential corner
  of Verilog, used only for testbenches. `#1` advances sim time; `$display`/`$finish` print/stop.
- **Flow:** `iverilog -o x.vvp dut.v tb.v` (compile) -> `vvp x.vvp` (run). See `sim/mux2_tb.v`.
- Simulation = dynamic: you only verify the input cases you actually wrote.

### Concept 3 — Assertions & formal proof
- The limit of simulation: it only checks cases you stimulate. A chip with 32 input +
  100 state bits has 2^132 states — physically impossible to simulate exhaustively.
- An **assertion** states a property that must always hold. `assert(condition)` =
  immediate assertion; fires if condition is ever false.
- In **simulation**, an assert only fires if your stimulus hits a violating case.
  In **formal** (`sby`), the SMT solver checks ALL inputs: proves it, or returns a
  counterexample (a concrete violating input).
- **SymbiYosys flow:** a `.sby` file sets `mode bmc` (bounded model check), `depth`
  (time steps; 1 for combinational), an `[engines]` solver, and a Yosys `[script]`
  that `read -formal`s the files. Run: `sby -f x.sby`. See `formal/mux2.sby`,
  `formal/mux2_formal.sv`.
- Result on mux2: `DONE (PASS)`, no traces = proven for all 8 input combinations.

### Concept 4 — Counterexamples (the payoff of formal)
- Injected a bug (`sel ? b : a`, swapped). `sby` -> `DONE (FAIL)`, pinpointed the exact
  failing assertion (`mux2_formal.sv:24`) and dumped a **counterexample trace**.
- The trace gives a concrete, minimal, reproducible violating input
  (`a=1, b=0, sel=0`) — a witness you can replay in simulation to debug.
- This is what formal gives over simulation: not "wrong somewhere" but "here is the
  exact input that breaks it." Trace files: `formal/mux2/engine_0/trace.vcd`, `trace_tb.v`.
- Restoring the correct design returned the proof to PASS.

**M0 COMPLETE:** toolchain verified; built + simulated + formally proved a module;
saw a counterexample. Next: M1 — a real DUT (FIFO/arbiter), assert/assume/cover,
safety vs liveness, clocked assertions.
