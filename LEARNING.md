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

---

## M1 — Hand-written assertions on a stateful DUT

DUT: `rtl/fifo_ctrl.v` — a synchronous depth-4 FIFO *controller* (tracks occupancy
`count` only, no data payload). All the interesting properties live in the control
logic, and ignoring the payload keeps the formal state space tiny. Wrapper +
properties in `formal/fifo_ctrl_formal.sv`; two-task `.sby` in `formal/fifo_ctrl.sby`.

### Concept 5 — State: clocked sequential logic
- M0 was **combinational** (output = f(inputs now)). Real chips **remember**.
- A **flip-flop** is a 1-bit register; it updates only on the **clock edge**
  (`always @(posedge clk)`). Between edges it holds. That memory *is* "state".
- `reg` in RTL = real hardware state (a flop), distinct from the testbench `reg` of M0.
- `<=` (non-blocking): sample all RHS using *old* values, update all flops together
  at the edge — models parallel flop update. (`=` was the combinational M0 form.)
- **Reset** pins down cycle 0: with no init, a flop powers up as `X` (unknown), so
  formal would start from garbage states. `if (rst) count <= 0;` gives a known start.

### Concept 6 — Safety vs liveness
- **Safety** = "nothing bad ever happens" — violated by a *finite* trace (point to the
  cycle). E.g. `count` never exceeds 4. **BMC checks exactly this.**
- **Liveness** = "something good eventually happens" — violated only by an *infinite*
  trace that stalls forever. BMC (finite unrolling) *cannot* refute liveness alone;
  needs k-induction / fairness. M1 stays in safety; open-tool liveness is thin.

### Concept 7 — Clocked assertions in the open-tool subset
- Open Yosys supports **immediate** assertions inside procedural blocks, NOT full
  concurrent SVA (`assert property (@(posedge clk) ...)`, `|->`, `$past`). That needs
  a commercial front-end (Verific → JasperGold/VC Formal). **Honest limitation.**
- Idiom: sample on the clock with `always @(posedge clk)`; `if (!rst) assert(...)` is
  our hand-written `disable iff (rst)`. Temporal "after X" properties: build the
  history yourself with a 1-cycle flop (what `$past` compiles to anyway).

### Concept 8 — BMC depth
- `mode bmc depth N` unrolls the circuit N cycles and searches for a violating input
  sequence within them. A bug needing >N cycles is **missed → false PASS**. Set depth
  to the design's timescale. A clean BMC is *evidence*, not an unbounded proof
  (`mode prove` / k-induction gives all-time; deferred).

### Concept 9 — assert / assume, and the counterexample
- Built a **trusting** controller (`count <= count + wr - rd`, no self-protection).
- `assert (count <= 4)` → **FAIL** at once. The dumped counterexample (`trace_tb.v` is
  a runnable testbench) showed **underflow**: one `rd` while `empty` → `0 - 1` wraps to
  `3'b111 = 7 > 4`. The solver returns the *shortest* counterexample (1 read), not the
  overflow we expected (5 writes). Free uninit values in a trace (`count = 6` at init)
  are solver don't-cares — reset overwrote it.
- **`assume (P)`**: prune the input space to inputs satisfying P — models a well-behaved
  environment. We assumed `if (full) !wr` and `if (empty) !rd` (the usage contract).
  Same assertion then **PASSED**. Key caveat: an assume is a promise you do NOT check
  here; if the real environment breaks it, the proof guarantees nothing.

### Concept 10 — cover & vacuity
- **`cover (P)`** is the dual of assert: assert succeeds by finding *no* bad trace;
  cover succeeds by *finding* a trace that reaches P (witness dumped). Ran as a separate
  `mode cover` task. `cover (full)` reached at step 6 → the FIFO genuinely can fill.
- **Vacuity**: an assertion that PASSES only because the situations testing it are
  unreachable (usually over-strong assumes). Demonstrated: adding `if (count==3) !wr`
  made `count <= 4` still PASS — but on a FIFO that can never reach 4. The `cover (full)`
  task then **FAILED** (unreached), exposing the hollow PASS. **Lesson: pair every
  assert with covers proving the interesting states stay reachable. A passing assert
  suite with failing covers is a red flag, not success.**
- Two distinct failure modes seen: a *false* property → counterexample; a *true*
  property proved *vacuously* → meaningless PASS.

**M1 COMPLETE:** stateful DUT; assert/assume/cover; safety vs liveness; BMC depth;
read a counterexample and a cover witness; induced and caught vacuity. Open-tool SVA
limits documented. Next: M2 — the LLM generation loop (generate SVAs, check syntax,
simulate/prove, feed failures back).
