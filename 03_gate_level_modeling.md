# Silicon Wiring: Advanced Gate-Level Modeling & Primitives

> **Repository:** VLSI & Digital Design — Interview Preparation & Conceptual Reference  
> **Author:** Shravana HS  
> **Standard:** IEEE 1364-2001 (Verilog-2001) / IEEE 1364-2005  
> **Status:** 🟢 Active — Last Reviewed April 2026

---

## Table of Contents

1. [What is Gate-Level Modeling?](#1-what-is-gate-level-modeling)
2. [The Built-in Primitive Families & Port Mapping](#2-the-built-in-primitive-families--port-mapping)
3. [Complete Truth Tables for All Primitives](#3-complete-truth-tables-for-all-primitives)
4. [The `X` and `Z` Logic Rules — The 4-State System in Depth](#4-the-x-and-z-logic-rules--the-4-state-system-in-depth)
5. [Gate Delays & Physical Time](#5-gate-delays--physical-time)
6. [Advanced Instantiation — Arrays of Instances](#6-advanced-instantiation--arrays-of-instances)
7. [User-Defined Primitives (UDPs)](#7-user-defined-primitives-udps)
8. [Structural Modeling — Full Design Examples](#8-structural-modeling--full-design-examples)
9. [Gate Strength & Drive Strength System](#9-gate-strength--drive-strength-system)
10. [Specify Blocks & Path Delays](#10-specify-blocks--path-delays)
11. [Gate-Level Simulation & SDF Annotation](#11-gate-level-simulation--sdf-annotation)
12. [Common Interview Scenarios & Design Patterns](#12-common-interview-scenarios--design-patterns)
13. [Summary Cheat Sheet](#13-summary-cheat-sheet)

---

## 1. What is Gate-Level Modeling?

### The Three Levels of Verilog Abstraction

Verilog supports three distinct levels of design description, each mapping to a different phase of the RTL-to-GDSII flow:

| Level | Also Called | What You Write | What it Represents |
|---|---|---|---|
| **Behavioral** | RTL / Algorithmic | `always`, `assign`, `if/case` | *What* the logic does — intent |
| **Dataflow** | Continuous Assignment | `assign out = a & b;` | Information flow between nets |
| **Gate-Level** | Structural | Primitive instances, module instances | Exact gate connections — the netlist |

**Gate-Level Modeling** is the lowest software-expressible abstraction — the direct description of a circuit as an interconnection of logic gates, buffers, and flip-flops. It sits just above the transistor level.

### Why Gate-Level Modeling Matters for Interviews

You will encounter gate-level Verilog in three critical real-world contexts:

1. **Post-Synthesis Netlists:** After synthesis, tools like Synopsys DC and Cadence Genus output the design as a gate-level netlist — a flat or hierarchical collection of technology primitive instances from the PDK standard cell library. Reading and debugging these is a core VLSI engineer skill.

2. **Gate-Level Simulation (GLS):** Before tape-out, the synthesized netlist is re-simulated with SDF (Standard Delay Format) back-annotated timing to verify that the design still functions correctly with real gate delays. Gate-level modeling syntax governs this flow.

3. **Hand-Crafted Critical Paths:** In rare, performance-critical scenarios, architects hand-instantiate specific standard cells to force the synthesizer to use particular implementations for hold-time fixing, critical path restructuring, or test logic insertion.

### Gate-Level vs RTL — The Key Mental Shift

```
RTL (Behavioral):
    always @(posedge clk) q <= d;         // Designer expresses INTENT

Gate-Level (Structural):
    sky130_fd_sc_hd__dfxtp_1 u_dff (      // Tool/designer specifies EXACT CELL
        .Q   (q),
        .CLK (clk),
        .D   (d)
    );
```

At gate-level, there are **no implicit flop inferences, no synthesis decisions, no optimizations**. Every wire, every gate, every instance is explicitly named and connected. What you write is exactly what silicon contains.

---

## 2. The Built-in Primitive Families & Port Mapping

### The Three Families of Verilog Built-in Primitives

Verilog defines 26 built-in gate primitives, organized into three functional families. These are language keywords, not library cells — they are the fundamental atomic building blocks of structural modeling.

---

### Family 1: Logic Gates

Multi-input, single-output combinational logic gates. All have exactly **one output port** and **one or more input ports**.

| Primitive | Function | Truth Summary |
|---|---|---|
| `and` | N-input AND | Output `1` only when ALL inputs are `1` |
| `nand` | N-input NAND | Complement of AND |
| `or` | N-input OR | Output `1` when ANY input is `1` |
| `nor` | N-input NOR | Complement of OR |
| `xor` | N-input XOR | Output `1` when ODD number of inputs are `1` |
| `xnor` | N-input XNOR | Complement of XOR (even parity) |

```verilog
// Port order for ALL logic gates:
// gate_type [instance_name] (OUTPUT, input1, input2, ..., inputN);
//                             ^^^^^^ — OUTPUT IS ALWAYS FIRST

and  u_and2  (out,   a, b);          // 2-input AND
and  u_and3  (out,   a, b, c);       // 3-input AND — same primitive, more inputs!
nand u_nand2 (n_out, a, b);
or   u_or4   (out,   a, b, c, d);   // 4-input OR
xor  u_xor2  (sum,   a, b);         // Used in adders
xnor u_xnor2 (eq,    a, b);         // Used in comparators

// With delay specification:
and  #(2) u_and_delayed (out, a, b); // 2 time-unit propagation delay
```

---

### Family 2: Buffer & Inverter Primitives

Single-input, single-output gates. Used for signal inversion and **drive strength amplification** — the primary physical use of `buf`.

| Primitive | Function | Use Case |
|---|---|---|
| `buf` | Non-inverting buffer | Increase drive strength for high-fanout nets |
| `not` | Inverting buffer | Signal inversion |

```verilog
// Port order for buf and not:
// buf [instance_name] (output1, ..., output_N, input);
//                      ^^^^^^^^^^^^^^^^^^^^^^^^ OUTPUTS first, then ONE INPUT last

// IMPORTANT: buf and not can have MULTIPLE OUTPUTS, ONE INPUT
buf  u_buf1  (out,  in);                     // 1 output buffer
buf  u_buf2  (out1, out2, in);               // 2 outputs — same input fans to both
not  u_inv   (n_out, in);                    // Inverter

// Physical reality: buf amplifies drive strength
// A standard INV cell can drive ~4 loads (fanout-of-4, FO4)
// A high-drive buf (e.g., sky130_fd_sc_hd__buf_8) drives 8x more load
// Gate-level structural code reflects this by choosing the right primitive/cell
buf  u_clock_buf (clk_buffered, clk_raw);   // Clock net buffer — critical in layout
```

> ### 🔥 Interview Trap 1: Primitive Port Mapping — Named Mapping Is Forbidden
>
> **Question:** *"How do you connect ports when instantiating a Verilog built-in primitive? Can you use named port mapping like `.a(sig_a)`?"*
>
> **Answer:** **Absolutely not. Named port mapping is strictly forbidden for all built-in primitives.** You MUST use positional mapping, and the output port MUST be the first positional argument.
>
> This is one of the most common interview traps because engineers who work exclusively at the RTL level are trained to always use named mapping — then they are asked about gate-level instantiation and fail.
>
> ```verilog
> // ❌ ILLEGAL — Named mapping for primitives causes a COMPILE ERROR
> and u_bad (.out(result), .a(sig_a), .b(sig_b));  // SYNTAX ERROR
>
> // ✅ CORRECT — Positional mapping, OUTPUT is argument #1
> and u_good (result, sig_a, sig_b);
> //           ^^^^^^  First argument MUST be the output
>
> // ❌ ILLEGAL — Output in wrong position
> and u_bad2 (sig_a, sig_b, result);  // Compiles but is FUNCTIONALLY WRONG
>                                      // sig_a is now the output! Wrong net driven.
>
> // ✅ Multiple inputs — all positional, output always first
> or  u_or3  (result, sig_a, sig_b, sig_c);  // result = sig_a | sig_b | sig_c
> ```
>
> **Why this rule exists:** Built-in primitives were defined before named port syntax existed in Verilog. They are language constructs, not user-defined modules, and the language parser does not assign names to their ports — it only knows position-based semantics.
>
> **Memory trick:** Think of it as a **function call** in C: `and(output, input1, input2)` — the return value always comes first.
>
> **Contrast with Modules:** User-defined modules and standard cell instances (from PDK libraries) **must** use named mapping in professional RTL. The rule flips completely at the primitive boundary.

---

### Family 3: Tri-State Buffer Primitives

The only primitives capable of outputting the `Z` (high-impedance) state. Essential for bidirectional buses, open-drain configurations, and I/O pad modeling.

| Primitive | Enable Polarity | Description |
|---|---|---|
| `bufif1` | Active-HIGH enable | Buffer: drives when `en=1`, Hi-Z when `en=0` |
| `bufif0` | Active-LOW enable | Buffer: drives when `en=0`, Hi-Z when `en=1` |
| `notif1` | Active-HIGH enable | Inverting buffer: drives `~in` when `en=1`, Hi-Z when `en=0` |
| `notif0` | Active-LOW enable | Inverting buffer: drives `~in` when `en=0`, Hi-Z when `en=1` |

```verilog
// Port order for tri-state buffers:
// bufif1 [instance] (output, data_input, enable);

bufif1 u_tsbuf  (bus_line, data_out, oe_n_inv); // Active-HIGH enable
bufif0 u_tsbuf2 (bus_line, data_out, oe_n);     // Active-LOW enable (more common)
notif1 u_tsinv  (bus_line, data_in,  en);        // Inverting tri-state driver

// Complete bidirectional I/O pad model:
module bidir_pad (
    inout  pad,        // Physical bond wire connection
    input  data_out,   // Core drives this to pad
    input  oe,         // Output Enable (active HIGH)
    output data_in     // Pad level read back into core
);
    // Output driver: tri-state buffer
    bufif1 u_od (pad, data_out, oe);

    // Input receiver: standard buffer (always receives)
    buf    u_id (data_in, pad);

endmodule
```

**The Physical Picture:**

```
            oe=1 (drive mode):
data_out ──→[bufif1]──→ pad ──→ bond wire ──→ PCB trace

            oe=0 (receive mode):
                  pad ──→ [buf] ──→ data_in (reads bus)
                   ↑
              High-Z: output driver disconnected
```

---

## 3. Complete Truth Tables for All Primitives

### AND Gate — 2-Input Truth Table (4-State Logic)

The 4-state nature means every primitive must define behavior for `X` and `Z` inputs.

| `and` | 0 | 1 | X | Z |
|:---:|:---:|:---:|:---:|:---:|
| **0** | 0 | 0 | 0 | 0 |
| **1** | 0 | 1 | X | X |
| **X** | 0 | X | X | X |
| **Z** | 0 | X | X | X |

**Key rule encoded in this table:** `0 AND anything = 0`. The zero **dominates** AND operations. This is a critical simulation property used in synthesis for don't-care optimization.

### OR Gate — 2-Input Truth Table (4-State Logic)

| `or` | 0 | 1 | X | Z |
|:---:|:---:|:---:|:---:|:---:|
| **0** | 0 | 1 | X | X |
| **1** | 1 | 1 | 1 | 1 |
| **X** | X | 1 | X | X |
| **Z** | X | 1 | X | X |

**Key rule encoded in this table:** `1 OR anything = 1`. The one **dominates** OR operations.

### XOR Gate — 2-Input Truth Table (4-State Logic)

| `xor` | 0 | 1 | X | Z |
|:---:|:---:|:---:|:---:|:---:|
| **0** | 0 | 1 | X | X |
| **1** | 1 | 0 | X | X |
| **X** | X | X | X | X |
| **Z** | X | X | X | X |

**Note:** XOR has **no dominator**. Any `X` or `Z` input poisons the output to `X`.

### XNOR Gate — 2-Input Truth Table

| `xnor` | 0 | 1 | X | Z |
|:---:|:---:|:---:|:---:|:---:|
| **0** | 1 | 0 | X | X |
| **1** | 0 | 1 | X | X |
| **X** | X | X | X | X |
| **Z** | X | X | X | X |

### NAND Gate — 2-Input Truth Table

| `nand` | 0 | 1 | X | Z |
|:---:|:---:|:---:|:---:|:---:|
| **0** | 1 | 1 | 1 | 1 |
| **1** | 1 | 0 | X | X |
| **X** | 1 | X | X | X |
| **Z** | 1 | X | X | X |

**Key rule:** `0 NAND anything = 1` (because NAND inverts AND, and 0 dominates AND).

### NOR Gate — 2-Input Truth Table

| `nor` | 0 | 1 | X | Z |
|:---:|:---:|:---:|:---:|:---:|
| **0** | 1 | 0 | X | X |
| **1** | 0 | 0 | 0 | 0 |
| **X** | X | 0 | X | X |
| **Z** | X | 0 | X | X |

**Key rule:** `1 NOR anything = 0` (because NOR inverts OR, and 1 dominates OR).

### Tri-State Buffer `bufif1` Truth Table

| `bufif1` | `en=0` | `en=1` | `en=X` | `en=Z` |
|:---:|:---:|:---:|:---:|:---:|
| **`in=0`** | Z | 0 | 0/Z(L) | 0/Z(L) |
| **`in=1`** | Z | 1 | 1/Z(H) | 1/Z(H) |
| **`in=X`** | Z | X | X | X |
| **`in=Z`** | Z | X | X | X |

*Note: `L` and `H` represent weak logic states in the full strength system.*

### `bufif0` Truth Table

| `bufif0` | `en=0` | `en=1` | `en=X` | `en=Z` |
|:---:|:---:|:---:|:---:|:---:|
| **`in=0`** | 0 | Z | 0/Z(L) | 0/Z(L) |
| **`in=1`** | 1 | Z | 1/Z(H) | 1/Z(H) |
| **`in=X`** | X | Z | X | X |
| **`in=Z`** | X | Z | X | X |

---

## 4. The `X` and `Z` Logic Rules — The 4-State System in Depth

### The Four Logic States Revisited

| State | Symbol | Physical Meaning | Who Produces It |
|---|---|---|---|
| Logic Zero | `0` | Strongly driven LOW (VSS) | Active driver output |
| Logic One | `1` | Strongly driven HIGH (VDD) | Active driver output |
| Unknown | `X` | Multiple conflicting drivers, or uninitialized | Contention / Reset not applied |
| High-Impedance | `Z` | No driver connected — floating node | Tri-state buffer OFF state |

### Dominator Rules — The Simulator's Decision Algorithm

The most important X/Z rule set for interviews is understanding **dominator states** — values that override all other inputs in an expression:

```
AND GATE:
  0 AND 0 = 0   ← Both zero
  0 AND 1 = 0   ← Zero DOMINATES: 0 wins
  0 AND X = 0   ← Zero still DOMINATES: 0 wins even over unknown!
  0 AND Z = 0   ← Zero still DOMINATES: 0 wins even over Hi-Z!
  1 AND Z = X   ← No dominator: result is unknown
  1 AND X = X   ← No dominator: result is unknown
  X AND X = X   ← Still unknown

OR GATE:
  1 OR 0 = 1    ← One DOMINATES: 1 wins
  1 OR X = 1    ← One still DOMINATES: 1 wins even over unknown!
  1 OR Z = 1    ← One still DOMINATES: 1 wins even over Hi-Z!
  0 OR Z = X    ← No dominator: result is unknown
  0 OR X = X    ← No dominator: result is unknown
```

### Why Dominators Matter in Real Silicon

The **physical simulation model** is the key: if one input to an AND gate is physically shorted to GND (logic 0), the output MUST be 0 regardless of what other inputs do — even if they are floating (`Z`) or in contention (`X`). The Verilog truth tables faithfully model this electrical reality.

```verilog
// Practical example: Reset logic analysis
wire rst_n;     // Not yet connected — defaults to Z in simulation
wire data;      // Some valid signal
wire gated;

and u_gate (gated, data, rst_n);   // gated = data & rst_n

// At simulation start:
// rst_n = Z (undriven)
// data  = 1 (driven)
// gated = 1 AND Z = X  ← Unknown propagates!

// This is why EVERY synchronous design requires explicit reset trees
// with defined initial states — to eliminate startup X propagation.
```

> ### 🔥 Interview Trap 2: Standard Gates Can Never Output `Z`
>
> **Question:** *"Can an AND gate output a `Z` (high-impedance) value?"*
>
> **Answer:** **No — never, under any input combination.** This is a fundamental rule of digital logic that many candidates confuse.
>
> Standard combinational logic gates (`and`, `or`, `xor`, `nand`, `nor`, `xnor`, `buf`, `not`) can **only output `0`, `1`, or `X`**. They can NEVER output `Z`.
>
> **The physical reason:** Every logic gate is connected to both VDD (supply) and GND through its transistor network. At any given moment, the pull-up network (PMOS) or pull-down network (NMOS) is active, providing a low-impedance path to power or ground. There is NO transistor configuration in a standard CMOS logic gate that leaves the output disconnected — the output is always driven.
>
> ```
> CMOS Inverter (the simplest gate):
>
>     VDD ─── [PMOS] ───┐
>                       ├──── out (always driven to VDD or GND)
>     in ────[NMOS]  ───┘
>     │                 
>    GND
>
> When in=1: NMOS on, PMOS off → out strongly connected to GND (logic 0)
> When in=0: PMOS on, NMOS off → out strongly connected to VDD (logic 1)
> In NEITHER case is the output floating (Z)!
> ```
>
> **The ONLY way to output `Z` in Verilog** is through:
> 1. **Tri-state buffer primitives:** `bufif0`, `bufif1`, `notif0`, `notif1`
> 2. **Explicit `1'bZ` or `1'bz` assignment in continuous assign:** `assign out = en ? data : 1'bZ;`
> 3. **An undriven wire** (which gets its default value of `Z`)
>
> ```verilog
> // These CAN output Z:
> bufif1 u_ts  (bus, data, en);              // ✅ Tri-state primitive
> assign bus = en ? data : 1'bZ;             // ✅ Conditional assign
>
> // These CANNOT output Z — ever:
> and   u_and  (out, a, b);                  // ❌ Never Z output
> or    u_or   (out, a, b);                  // ❌ Never Z output
> buf   u_buf  (out, in);                    // ❌ Never Z output
> not   u_inv  (out, in);                    // ❌ Never Z output
> ```
>
> **The corollary trap:** *"What if I apply a Z input to an AND gate?"* The gate still cannot output Z. It will output either the dominator value (if one input is `0`) or `X` (from the truth table), but never `Z`.

### X-Propagation — The Silent Simulation Epidemic

`X` propagation is one of the most dangerous phenomena in RTL simulation:

```verilog
module x_propagation_demo;
    reg a, b, c;
    wire w1, w2, w3, final_out;

    and u1 (w1, a, b);    // w1 = a & b
    or  u2 (w2, w1, c);   // w2 = w1 | c
    not u3 (w3, w2);      // w3 = ~w2
    buf u4 (final_out, w3);

    initial begin
        a = 1'bx;   // Uninitialized register — starts as X
        b = 1'b1;
        c = 1'b0;
        #1;
        // w1 = X AND 1 = X    (no dominator)
        // w2 = X OR  0 = X    (no dominator)
        // w3 = NOT   X = X    (complement of unknown is unknown)
        // final_out = X       (entire chain poisoned!)
        $display("final_out = %b", final_out); // Prints: x
    end
endmodule
```

**X-propagation is simulation-only:** In real silicon, `a` would power up to either 0 or 1 (indeterminate, but a definite logic value). The simulation `X` is the designer's tool to track "I don't know what this is yet." A design with good reset architecture will clear all registers to known values, eliminating X-propagation at startup.

---

## 5. Gate Delays & Physical Time

### Why Gate Delays Matter

In real silicon, no logic gate switches instantaneously. The finite time for signals to propagate through transistors creates:
- **Propagation delay** — time from input change to stable output
- **Critical paths** — the longest combinational delay chain, limiting clock frequency
- **Hold-time violations** — when data arrives too quickly after a clock edge
- **Glitches** — transient incorrect output states during input transitions

Gate-level Verilog provides a rich delay specification syntax to model all of these.

### The Three Delay Types

| Delay Type | Symbol | Meaning | Physical Event |
|---|---|---|---|
| **Rise Delay** | `tr` | Time for output to transition from `0` or `X` to `1` | PMOS pull-up charging output capacitance |
| **Fall Delay** | `tf` | Time for output to transition from `1` or `X` to `0` | NMOS pull-down discharging output capacitance |
| **Turn-Off Delay** | `toff` | Time for tri-state output to go to `Z` | Tri-state buffer disabling (only for `bufifX`, `notifX`) |

**Physical asymmetry:** In CMOS, rise and fall delays are typically different because PMOS transistors (responsible for pull-up / rising transition) have lower carrier mobility (~2-3× less) than NMOS (responsible for pull-down / falling transition). This is why `tr ≠ tf` in real cells.

### Delay Specification Syntax

```verilog
// ============================================================
// SYNTAX:  gate_type #(delay_spec) instance_name (port_list);
// ============================================================

// --- Single Delay (applies to all transitions equally) ---
and  #5        u_and   (out, a, b);     // Rise=5, Fall=5, TurnOff=5

// --- Two Delays (rise and fall specified separately) ---
and  #(3, 7)   u_and2  (out, a, b);    // Rise=3, Fall=7

// --- Three Delays (rise, fall, turn-off — meaningful for tri-state) ---
bufif1 #(2, 4, 6) u_tri (out, in, en); // Rise=2, Fall=4, TurnOff=6

// --- Min:Typ:Max Delay Specification ---
// Represents: Minimum (best-case), Typical, Maximum (worst-case) delay
// Selected by the +mindelays / +typdelays / +maxdelays simulator switch
and  #(1:2:3)          u_and3  (out, a, b); // Single delay: min=1, typ=2, max=3
and  #(1:2:3, 2:3:5)   u_and4  (out, a, b); // Rise: 1:2:3, Fall: 2:3:5
nand #(1:2:3, 2:3:5, 3:4:7) u_nand (out, a, b); // Rise:Fall:TurnOff all min:typ:max

// --- Zero Delay (explicit) ---
and  #0        u_zd    (out, a, b);     // Zero delay — functionally equivalent to assign
```

### Min:Typ:Max — The Process Corner System

The three delay values map directly to **process corners** in silicon manufacturing:

| Delay | Process Corner | Transistor Characteristic | Temperature | Voltage |
|---|---|---|---|---|
| **Min** | Fast (FF) | Fast-Fast (strongest transistors) | Low (-40°C) | High (+10%) |
| **Typ** | Typical (TT) | Nominal |Nominal (25°C) | Nominal |
| **Max** | Slow (SS) | Slow-Slow (weakest transistors) | High (+125°C) | Low (-10%) |

```tcl
# Simulator invocation with corner selection:
vcs +maxdelays -f rtl_files.f     # Worst-case timing (setup time analysis)
vcs +mindelays -f rtl_files.f     # Best-case timing (hold time analysis)
vcs +typdelays -f rtl_files.f     # Nominal (default)
```

**The critical insight:** Setup time violations occur when the *maximum* delay exceeds the clock period. Hold time violations occur when the *minimum* delay is less than the hold time requirement. You must simulate both corners.

### Delay Behavior at Different Transitions

```verilog
`timescale 1ns/100ps

module delay_demo;
    reg a, b;
    wire out_single, out_asym;

    // Single delay: same for all transitions
    and #(5) u1 (out_single, a, b);

    // Asymmetric: rise=3ns, fall=7ns
    and #(3, 7) u2 (out_asym, a, b);

    initial begin
        a = 0; b = 0;
        #10;
        a = 1; b = 1;    // Both inputs go HIGH → output should rise
        // out_single: output rises at t=10+5=15ns
        // out_asym:   output rises at t=10+3=13ns (faster rise transistor)
        #10;
        a = 0;           // Input drops → output should fall
        // out_single: output falls at t=20+5=25ns
        // out_asym:   output falls at t=20+7=27ns (slower fall transistor)
    end
endmodule
```

> ### 🔥 Interview Trap 3: Inertial Delay and Glitch Absorption
>
> **Question:** *"If an input glitch (a pulse narrower than the gate's propagation delay) occurs, does the gate's output change?"*
>
> **Answer:** **No — the gate's output does NOT change.** This behavior is called **Inertial Delay**, and it is the default delay model in Verilog gate-level simulation.
>
> **The Inertial Delay Model:** A gate with propagation delay `Tp` will only propagate an input transition to its output if the input remains stable for at least `Tp` time units. Input pulses narrower than `Tp` are **absorbed by the gate** — they cause no output change.
>
> ```
> Input waveform:
>     ─────┐  ┌──────────────────────────────────
>          └──┘
>           ↑ ↑
>          3ns (pulse width = 3ns)
>
> Gate delay: Tp = 5ns
>
> Expected output (if transport delay):
>     ─────────┐  ┌──────────────────────────
>              └──┘   (shifted by 5ns, same pulse width)
>
> Actual output (inertial delay — Verilog default):
>     ──────────────────────────────────────────
>              (NO OUTPUT CHANGE! Glitch absorbed)
>
> The 3ns pulse is shorter than the 5ns gate delay → ABSORBED.
> ```
>
> **Physical basis:** A CMOS gate's output is determined by charging/discharging the output capacitance. If the input reverses before enough charge has transferred to cross the logic threshold, the output never completes the transition and returns to its original value.
>
> **Contrast with Transport Delay:** The alternative model — **Transport Delay** — passes ALL input pulses through, regardless of width, just shifted in time. In Verilog, transport delay is modeled using the `transport` keyword in `assign` statements:
>
> ```verilog
> // Inertial delay (DEFAULT for primitives) — absorbs narrow glitches:
> and #5 u_inertial (out1, a, b);
>
> // Transport delay — passes ALL pulses, just shifts them in time:
> wire #5 transport_wire;                  // Wire delay — always transport model
> assign #5 out2 = a & b;                  // assign delays use inertial by default too
>
> // EXPLICIT transport delay keyword (Verilog syntax):
> assign (weak0, weak1) #5 out3 = a & b;  // Full transport semantics
> ```
>
> **Interview relevance:** Glitch absorption is why synthesis tools can sometimes accept designs with combinational hazards — the gate delays in silicon naturally filter pulses shorter than the propagation delay. However, this is unpredictable across corners (a glitch that's absorbed at SS-corner might propagate at FF-corner, violating hold time). Always eliminate combinational hazards by design, not by relying on inertia.

### The Turn-Off Delay in Detail

The turn-off delay is exclusive to tri-state primitives and models the time for a bus to float to `Z` after being disconnected:

```verilog
// Physical bus release: when 'en' goes LOW, the bufif1 output goes Z
// But it doesn't happen instantly — there's a turn-off delay

bufif1 #(2, 4, 6) u_tri (bus, data, en);
//                  ↑         Turn-off delay = 6ns
//                  Rise=2, Fall=4

// Sequence:
// t=0:  en=1, data=1  → bus=1 (strongly driven)
// t=10: en=0           → bus transitions to Z after 6ns
// t=16: bus=Z          → now floating; another driver can take over
```

---

## 6. Advanced Instantiation — Arrays of Instances

### The Problem: Repetitive Gate Instantiation

Without array instantiation, implementing a 32-bit bitwise AND requires 32 separate lines:

```verilog
// WITHOUT arrays — verbose, error-prone, unmaintainable:
and u_and0  (out[0],  a[0],  b[0]);
and u_and1  (out[1],  a[1],  b[1]);
and u_and2  (out[2],  a[2],  b[2]);
// ... 29 more lines ...
and u_and31 (out[31], a[31], b[31]);
```

### Array Instantiation Syntax

Verilog allows instantiating a primitive or module multiple times with a single declaration, using a range specifier on the instance name:

```verilog
// SYNTAX: gate_type instance_name [range] (output_bus, input_bus1, input_bus2);

// 32-bit bitwise AND — one line of code, 32 parallel AND gates:
and u_and32 [31:0] (out_bus, a_bus, b_bus);
//            ↑↑↑↑↑ — Range creates 32 independent AND instances
//  u_and32[0] gets: out_bus[0] = a_bus[0] & b_bus[0]
//  u_and32[1] gets: out_bus[1] = a_bus[1] & b_bus[1]
//  ...
//  u_and32[31] gets: out_bus[31] = a_bus[31] & b_bus[31]
```

### Complete Array Instantiation Examples

```verilog
module bitwise_ops_32bit (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] and_out,
    output [31:0] or_out,
    output [31:0] xor_out,
    output [31:0] not_a
);

    // 32 independent AND gates — one line each
    and  u_and  [31:0] (and_out, a, b);

    // 32 independent OR gates
    or   u_or   [31:0] (or_out, a, b);

    // 32 independent XOR gates (bit-wise parity)
    xor  u_xor  [31:0] (xor_out, a, b);

    // 32 independent NOT gates (bit-inversion of a)
    not  u_not  [31:0] (not_a, a);

endmodule
```

### Mixed Scalar and Bus Connections

Array instantiation has powerful semantics when inputs have different widths:

```verilog
// Scenario: Gate an 8-bit bus with a SINGLE control bit
wire [7:0] data_bus;
wire       enable;      // Single 1-bit wire
wire [7:0] gated_bus;

// The single 'enable' bit is BROADCAST to all 8 AND instances:
and u_gate [7:0] (gated_bus, data_bus, enable);
// Equivalent to:
// and u_gate0 (gated_bus[0], data_bus[0], enable); ← same 'enable' for all
// and u_gate1 (gated_bus[1], data_bus[1], enable);
// ...
// and u_gate7 (gated_bus[7], data_bus[7], enable);

// This models an 8-bit bus with a common gate enable — a tristate bus controller pattern
```

### Module Array Instantiation

Array instantiation is not limited to primitives — it also works with user modules:

```verilog
module full_adder (
    input  a, b, cin,
    output sum, cout
);
    // ... implementation ...
endmodule

module ripple_carry_adder_4bit (
    input  [3:0] a, b,
    input        cin,
    output [3:0] sum,
    output [3:0] cout_chain  // internal carries
);
    wire [3:0] carry;

    // Array of 4 full adder instances — each gets corresponding bit
    // NOTE: When using modules (not primitives), NAMED mapping is still allowed/preferred
    // But array syntax forces positional for primitive-like connection
    full_adder u_fa [3:0] (         // 4 instances: u_fa[0..3]
        .a   (a),
        .b   (b),
        .cin ({carry[2:0], cin}),    // carry chain wiring — complex connection
        .sum (sum),
        .cout(carry)
    );

    assign cout_chain = carry;

endmodule
```

---

## 7. User-Defined Primitives (UDPs)

### What is a UDP?

A **User-Defined Primitive (UDP)** is a custom logic element defined by a truth table (called a `table`), not by RTL code. UDPs are the gate-level designer's mechanism for creating **custom atomic primitives** — logic that will be treated by the simulator as a single entity, just like built-in `and` or `or`.

**Use cases for UDPs:**
- Modeling complex standard cells not covered by built-in primitives (custom latches, complex gates like AOI22, OAI21)
- Creating optimized simulation models for technology-specific cells
- Defining sequential elements (latches, flip-flops) at the lowest abstraction level
- Post-synthesis netlist library modeling

### UDP Rules — The Non-Negotiable Constraints

| Rule | Detail |
|---|---|
| **Single output** | UDPs can have exactly ONE output port |
| **Output must be first** | The output port is **always** declared first in the port list |
| **Keyword pair** | Use `primitive / endprimitive` — NOT `module / endmodule` |
| **Table specification** | Logic is defined inside `table / endtable` — no RTL expressions |
| **Port types** | All ports are implicitly 1-bit. No multi-bit (vector) ports allowed |
| **No `Z` I/O** | UDPs **cannot** process or output the `Z` state (see Interview Trap) |
| **Instantiation** | UDP instances look identical to built-in primitives — positional mapping, output first |

### Combinational UDP

A combinational UDP maps a truth table of inputs to an output. The `?` symbol represents a **don't care** — the output value is the same regardless of whether that input is 0, 1, or X.

```verilog
// ============================================================
// COMBINATIONAL UDP: 2-to-1 Multiplexer
//   out = sel ? b : a
//
// Table format: input1 input2 ... inputN : output;
// ============================================================
primitive mux2to1_udp (
    output out,     // ← OUTPUT MUST BE FIRST PORT
    input  a,       // Data input 0 (selected when sel=0)
    input  b,       // Data input 1 (selected when sel=1)
    input  sel      // Select line
);
    table
    //  a   b   sel  :  out
    //  ─── ─── ───  :  ───
        0   ?   0    :  0;   // sel=0 → out=a=0  (b is don't care)
        1   ?   0    :  1;   // sel=0 → out=a=1  (b is don't care)
        ?   0   1    :  0;   // sel=1 → out=b=0  (a is don't care)
        ?   1   1    :  1;   // sel=1 → out=b=1  (a is don't care)
        0   0   x    :  0;   // sel=X, but both a=b=0 → output must be 0
        1   1   x    :  1;   // sel=X, but both a=b=1 → output must be 1
    endtable

endprimitive
```

### Advanced Combinational UDP: AOI21 (AND-OR-INVERT)

AOI cells are common in standard cell libraries — they implement `~((a & b) | c)` in a single complex gate with better area and speed than decomposed logic:

```verilog
// AOI21: out = ~((a & b) | c)
primitive aoi21_udp (
    output out,
    input  a, b, c
);
    table
    //  a   b   c   :  out = ~((a&b)|c)
        0   ?   0   :  1;   // a=0 → (a&b)=0; c=0 → out=~0=1
        ?   0   0   :  1;   // b=0 → (a&b)=0; c=0 → out=~0=1
        1   1   ?   :  0;   // a=b=1 → (a&b)=1 → out=~1=0 (c don't care)
        ?   ?   1   :  0;   // c=1 → output=~1=0 regardless of a,b
        0   ?   x   :  x;   // a=0 but c=X — indeterminate
        ?   0   x   :  x;   // b=0 but c=X — indeterminate
        x   1   0   :  x;   // a=X, b=1, c=0 — indeterminate
        1   x   0   :  x;   // b=X, a=1, c=0 — indeterminate
    endtable

endprimitive
```

### Sequential UDP

Sequential UDPs model storage elements (latches, flip-flops). They have:
- An **output that is also a registered state** (declared `reg`)
- A **current state** column in the truth table (the value before the transition)
- An additional column separator `:` for state transitions

```verilog
// ============================================================
// SEQUENTIAL UDP: Level-Sensitive D Latch
//   When clk=1: Q follows D
//   When clk=0: Q holds
// ============================================================
primitive d_latch_udp (
    output reg q,   // ← 'reg' declares q as a state variable
    input      d,   // Data input
    input      clk  // Level-sensitive clock (active HIGH)
);
    initial q = 0;  // Initial state declaration — allowed in sequential UDPs

    table
    //  d    clk  :  current_q  :  next_q
    //  ────────── :  ───────── :  ──────
        1    1    :     ?       :  1;   // clk=1, d=1 → latch: Q=1
        0    1    :     ?       :  0;   // clk=1, d=0 → latch: Q=0
        ?    0    :     ?       :  -;   // clk=0, any d → Q holds (no change)
    endtable

endprimitive
```

**The `-` symbol in sequential tables** represents "no change" — the output retains its current value. This is how latch hold behavior is modeled.

### Sequential UDP: Positive-Edge Triggered D Flip-Flop

Edge-triggered UDPs use a special notation for clock edges in the table:

```verilog
// ============================================================
// SEQUENTIAL UDP: Positive-Edge D Flip-Flop (no reset)
// ============================================================
primitive dff_udp (
    output reg q,
    input      d,
    input      clk
);
    initial q = 1'bx;  // Unknown at powerup — forces proper reset in design

    table
    //  d    clk          :  q     :  next_q
    //  ─────────────────── :  ─── :  ──────
        1    (01)         :  ?     :  1;   // posedge clk, d=1 → Q=1
        0    (01)         :  ?     :  0;   // posedge clk, d=0 → Q=0
        ?    (0x)         :  1     :  1;   // clk 0→X, Q=1: retain (conservative)
        ?    (0x)         :  0     :  0;   // clk 0→X, Q=0: retain (conservative)
        ?    (x1)         :  1     :  1;   // clk X→1, Q=1: retain
        ?    (x1)         :  0     :  0;   // clk X→1, Q=0: retain
        ?    (10)         :  ?     :  -;   // negedge clk → no change
        ?    (?0)         :  ?     :  -;   // falling edge → no change
        ?    (1x)         :  ?     :  -;   // 1→X transition → no change
        d    b            :  ?     :  -;   // clock stable, d changes → no change
    endtable

endprimitive
```

**Edge notation in table entries:**

| Symbol | Meaning |
|---|---|
| `(01)` | Rising edge: 0→1 transition |
| `(10)` | Falling edge: 1→0 transition |
| `(0x)` | 0→X transition |
| `(x1)` | X→1 transition |
| `(1x)` | 1→X transition |
| `r` | Shorthand for `(01)` — rising edge |
| `f` | Shorthand for `(10)` — falling edge |
| `p` | Any potential rising edge: `(01)`, `(0x)`, `(x1)` |
| `n` | Any potential falling edge: `(10)`, `(1x)`, `(x0)` |
| `b` | Both edges: `r` or `f` |
| `*` | Any transition on this input: same as `(??)`|

```verilog
// Simplified DFF using shorthand edge symbols:
primitive dff_simple_udp (
    output reg q,
    input      d, clk
);
    table
    //  d    clk  :  q   :  next_q
        1    r    :  ?   :  1;    // r = (01) = rising edge
        0    r    :  ?   :  0;
        ?    f    :  ?   :  -;    // f = (10) = falling edge → hold
        *    b    :  ?   :  -;    // input d changing when clock stable → hold
    endtable

endprimitive
```

> ### 🔥 Interview Trap 4: UDPs and the `Z` State Limitation
>
> **Question:** *"You need to model a tri-state bus driver using a UDP. Can you do it?"*
>
> **Answer:** **No — this is a fundamental and absolute limitation of UDPs.** UDPs are strictly confined to the 3-state logic space: `0`, `1`, and `X`. The `Z` (high-impedance) state **cannot appear anywhere** in a UDP:
>
> - A UDP **cannot have a `Z` in its input table** — it cannot even receive a `Z` input
> - A UDP **cannot produce a `Z` output** — the output can only be `0`, `1`, or `X`
>
> ```verilog
> // ILLEGAL UDP — attempting to use Z:
> primitive illegal_tristate_udp (
>     output out,
>     input  data, en
> );
>     table
>         1  1  :  1;
>         0  1  :  0;
>         ?  0  :  z;   // ❌ ILLEGAL — 'z' is NOT a valid output in a UDP table!
>     endtable
> endprimitive
> ```
>
> **Why this limitation exists:** The UDP simulation model is built on a finite state machine with states {0, 1, X}. The `Z` state represents a physical absence of driving — a fundamentally different concept that requires the full 4-state resolution logic of the Verilog simulator, not a simple table lookup. UDPs don't have access to this resolution logic.
>
> **What to use instead:** For tri-state modeling, you **must** use the built-in tri-state primitives (`bufif0`, `bufif1`, `notif0`, `notif1`) or an explicit conditional assignment:
>
> ```verilog
> // CORRECT approach for tri-state — use built-in primitive:
> bufif1 u_tristate (bus, data, enable);      // ✅ Built-in primitive handles Z
>
> // Or continuous assignment with Z:
> assign bus = enable ? data : 1'bZ;           // ✅ Assign handles Z
>
> // NEVER use a UDP for tri-state logic:
> // illegal_tristate_udp u_bad (.out(bus), .data(data), .en(enable)); // ❌ Won't compile
> ```
>
> **The practical impact:** Any PDK standard cell that involves tristating (multiplexed I/O pads, bus keepers, repeaters) must be modeled with either built-in Verilog primitives or full SystemVerilog interface constructs — UDPs are insufficient for this entire class of circuit.

---

## 8. Structural Modeling — Full Design Examples

### Example 1: 1-bit Full Adder — Complete Gate-Level Implementation

A full adder is the canonical structural modeling example, requiring exactly:
- 2× XOR gates (sum computation)
- 2× AND gates (partial carry generation)
- 1× OR gate (final carry merge)

```verilog
// ============================================================
// GATE-LEVEL 1-BIT FULL ADDER
//
// Boolean equations:
//   sum  = a ^ b ^ cin
//   cout = (a & b) | (b & cin) | (a & cin)
//
// Optimized implementation using only 2-input gates:
//   sum  = a ^ b ^ cin          (2 XOR gates)
//   cout = (a & b) | ((a ^ b) & cin) (reuses XOR result — CSE)
// ============================================================
module full_adder_gate (
    input  wire a, b, cin,
    output wire sum, cout
);
    // Internal wires — every intermediate signal must be declared
    wire xor1_out;  // = a ^ b
    wire and1_out;  // = a & b
    wire and2_out;  // = (a ^ b) & cin

    // Stage 1: XOR for intermediate sum and AND for partial carry
    xor u_xor1 (xor1_out, a, b);       // xor1_out = a XOR b
    and u_and1 (and1_out, a, b);       // and1_out = a AND b

    // Stage 2: Final sum and second partial carry
    xor u_xor2 (sum,      xor1_out, cin); // sum = (a^b) XOR cin
    and u_and2 (and2_out, xor1_out, cin); // and2_out = (a^b) AND cin

    // Stage 3: Carry output merge
    or  u_or1  (cout, and1_out, and2_out); // cout = (a&b) | ((a^b)&cin)

endmodule
```

### Example 2: 4-bit Carry-Ripple Adder — Hierarchical Structural

```verilog
// ============================================================
// GATE-LEVEL 4-BIT RIPPLE CARRY ADDER
// Built by structurally instantiating 4 full adders
// ============================================================
module rca_4bit (
    input  wire [3:0] a, b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout
);
    // Internal carry chain — carries between stages
    wire c1, c2, c3;   // c1=carry from bit0, c2=carry from bit1, c3=carry from bit2

    // Structural instantiation of 4 full adders
    // Named mapping — module instances (not primitives) use named ports
    full_adder_gate u_fa0 (.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c1));
    full_adder_gate u_fa1 (.a(a[1]), .b(b[1]), .cin(c1),  .sum(sum[1]), .cout(c2));
    full_adder_gate u_fa2 (.a(a[2]), .b(b[2]), .cin(c2),  .sum(sum[2]), .cout(c3));
    full_adder_gate u_fa3 (.a(a[3]), .b(b[3]), .cin(c3),  .sum(sum[3]), .cout(cout));

endmodule
```

### Example 3: 4-to-1 MUX using Gate-Level Primitives

```verilog
// ============================================================
// GATE-LEVEL 4-to-1 MULTIPLEXER
//
// Boolean equation:
//   out = (~s1 & ~s0 & i0) | (~s1 & s0 & i1) |
//         ( s1 & ~s0 & i2) | ( s1 & s0 & i3)
// ============================================================
module mux4to1_gate (
    input  wire i0, i1, i2, i3,   // Data inputs
    input  wire s0, s1,            // Select lines (s1 is MSB)
    output wire out
);
    wire ns0, ns1;       // Inverted selects
    wire t0, t1, t2, t3; // AND terms

    // Invert select lines
    not u_inv_s0 (ns0, s0);
    not u_inv_s1 (ns1, s1);

    // Generate each AND term (3-input AND for each minterm)
    and u_and0 (t0, ns1, ns0, i0);  // s1=0, s0=0: select i0
    and u_and1 (t1, ns1, s0,  i1);  // s1=0, s0=1: select i1
    and u_and2 (t2, s1,  ns0, i2);  // s1=1, s0=0: select i2
    and u_and3 (t3, s1,  s0,  i3);  // s1=1, s0=1: select i3

    // OR all terms to form output
    or  u_or4  (out, t0, t1, t2, t3);

endmodule
```

### Example 4: D Flip-Flop with Synchronous Reset — Gate Level

```verilog
// ============================================================
// D FLIP-FLOP WITH SYNCHRONOUS RESET
// Built from NAND gates (the physical implementation approach)
//
// Architecture: Master-slave flip-flop using NAND latches
// Note: This is simplified — real DFFs use more complex topologies
// ============================================================
module dff_sync_rst_gate (
    input  wire clk,
    input  wire rst_n,   // Active-LOW synchronous reset
    input  wire d,
    output wire q,
    output wire qn
);
    // Gated D using AND-NAND: d_gated = d & rst_n
    wire d_gated;
    and u_rst_gate (d_gated, d, rst_n);   // Block D when rst_n=0

    // Master latch (transparent when clk=0)
    wire clk_n;
    wire m_s, m_r;   // Master latch set, reset
    wire m_q, m_qn;  // Master outputs

    not   u_clk_inv  (clk_n, clk);
    nand  u_master_s (m_s, d_gated, clk_n);   // NAND-based S-R latch
    nand  u_master_r (m_r, m_s,     clk_n);   // (Gated with inverted clock)
    nand  u_master_q (m_q,  m_s, m_qn);
    nand  u_master_qn(m_qn, m_r, m_q);

    // Slave latch (transparent when clk=1)
    wire s_s, s_r;
    nand  u_slave_s  (s_s, m_q,  clk);
    nand  u_slave_r  (s_r, m_qn, clk);
    nand  u_slave_q  (q,   s_s,  qn);
    nand  u_slave_qn (qn,  s_r,  q);

endmodule
```

---

## 9. Gate Strength & Drive Strength System

### The Verilog Strength System

Verilog models not just logic values but also the **drive strength** with which each value is driven. This models real physical phenomena like bus contention, pull-up resistors, and open-drain configurations.

The complete strength hierarchy (strongest to weakest):

| Strength Number | Strength Name | Symbol | Physical Model |
|:---:|---|---|---|
| 7 | Supply | `supply` | VDD/GND direct connection |
| 6 | Strong | `strong` | Standard CMOS gate output (DEFAULT) |
| 5 | Pull | `pull` | Pull-up/pull-down resistor |
| 4 | Large | `large` | Large capacitive storage |
| 3 | Weak | `weak` | Weak pull (high-value resistor) |
| 2 | Medium | `medium` | Medium capacitive storage |
| 1 | Small | `small` | Small capacitive storage |
| 0 | High Impedance | `highz` | No drive — floating (Hi-Z) |

### Strength Specification Syntax

```verilog
// Standard gate with default (strong) drive — most common
and  u_and  (out, a, b);       // Output strength: strong0, strong1

// Gate with explicit drive strength specification
// SYNTAX: gate_type (strength0, strength1) #delay instance (ports);
//         strength0 = strength when output is logic 0
//         strength1 = strength when output is logic 1

and  (strong0, strong1) u_strong_and (out, a, b);  // Explicit default
and  (weak0,   weak1)   u_weak_and   (out, a, b);  // Weak drive

// Supply drive (for power/ground connections):
buf  (supply0, supply1) u_supply_driver (out, in);

// Pull-up and pull-down primitives (resistive connections):
pullup   (pull1) u_pu  (net);    // Connects net weakly to 1 (pull-up resistor)
pulldown (pull0) u_pd  (net);    // Connects net weakly to 0 (pull-down resistor)
```

### Strength Resolution on Multi-Driver Nets

When two drivers of different strengths drive the same wire to different values, the **stronger driver wins**:

```verilog
wire bus;

buf  (strong0, strong1) u_driver1 (bus, 1'b1);    // Drives bus to 1 (strong)
pulldown                u_pull    (bus);            // Pulls bus to 0 (pull)

// Resolution: strong1 vs pull0 → strong wins → bus = 1 (strong1)
```

When two drivers of equal strength fight:

```verilog
wire bus;
buf  (strong0, strong1) u_a (bus, 1'b1);  // Drives 1 at strong strength
buf  (strong0, strong1) u_b (bus, 1'b0);  // Drives 0 at strong strength

// Resolution: strong1 vs strong0 → CONTENTION → bus = X (unknown)
// Physical reality: current flows between the two drivers — potential latch-up!
```

### `trireg` — Capacitive Storage Net

`trireg` is a special net type that **models capacitive charge storage** — the net retains its last driven value when all drivers go Hi-Z:

```verilog
trireg cap_node;             // Capacitive node — retains charge

bufif1 u_driver (cap_node, data, en);

// Sequence:
// en=1: cap_node driven to 'data' value
// en=0: all drivers off → cap_node retains LAST VALUE (not Z!)
//       Strength degrades to 'medium' (capacitive decay modeled)
```

---

## 10. Specify Blocks & Path Delays

### What are Specify Blocks?

A `specify` block is a dedicated section inside a module that **precisely characterizes timing relationships** — independent of the behavioral RTL. Specify blocks are consumed by:
- **Gate-level simulation** — to annotate actual propagation delays
- **STA (Static Timing Analysis)** — via SDF extraction
- **Timing verification** — setup and hold checks

Specify blocks are the primary mechanism for **library cell timing characterization** in `.v` simulation models.

```verilog
module my_and_with_timing (
    input  wire a, b,
    output wire out
);
    // Behavioral description
    and u_and (out, a, b);

    // Timing specification — completely separate from behavior
    specify
        // Simple path delay: from any input to output
        // Syntax: (input => output) = delay_value;
        (a => out) = 2;     // a-to-out propagation: 2 time units
        (b => out) = 2;     // b-to-out propagation: 2 time units

        // Asymmetric (rise ≠ fall):
        // (a => out) = (2, 3);  // Rise=2, Fall=3

        // Min:Typ:Max:
        // (a => out) = (1:2:3, 2:3:5);  // Rise and Fall with corners
    endspecify

endmodule
```

### Path Delay Types

```verilog
specify
    // ─── 1. Simple Connection Path (point-to-point) ───
    // Delay is purely based on input→output connectivity
    (a => out) = 3;         // a-to-out: 3 time units, all transitions

    // ─── 2. Full Connection Path ───
    // Specifies delays for all input-to-output combinations
    (a, b *> out) = 3;      // Both a and b to out: same delay
                             // (*> applies the same delay to all combinations)

    // ─── 3. Edge-Sensitive Path ───
    // Delay triggered by specific input edge, not just any change
    (posedge clk => (q +: d)) = 5;  // posedge clk triggers q rising if d=1
    (posedge clk => (q -: d)) = 6;  // posedge clk triggers q falling if d=0

    // ─── 4. Conditional Path Delay ───
    // Different delays based on logic state of other signals
    if (sel)    (a => out) = 2;   // When sel=1, a-to-out = 2
    if (!sel)   (a => out) = 3;   // When sel=0, a-to-out = 3 (slower path)
    ifnone      (a => out) = 3;   // Default if no 'if' condition matches

endspecify
```

### Setup and Hold Timing Checks

```verilog
module dff_with_timing (
    input  clk, d, rst_n,
    output reg q
);
    always @(posedge clk)
        q <= rst_n ? d : 1'b0;

    specify
        // Setup check: D must be stable Tsu before clock edge
        $setup(d, posedge clk, 2);      // Setup time = 2ns

        // Hold check: D must be stable Th after clock edge
        $hold(posedge clk, d, 1);       // Hold time = 1ns

        // Combined setuphold check (more common in library cells):
        $setuphold(posedge clk, d, 2, 1);   // setup=2, hold=1

        // Width check: minimum pulse width on clock
        $width(posedge clk, 3);         // Minimum HIGH pulse width = 3ns
        $width(negedge clk, 3);         // Minimum LOW pulse width = 3ns

        // Period check: minimum clock period
        $period(posedge clk, 8);        // Minimum clock period = 8ns

        // Clock-to-Q path delay (registered output):
        (posedge clk => (q +: d)) = 4; // clk-to-Q rise = 4ns
        (posedge clk => (q -: d)) = 5; // clk-to-Q fall = 5ns

    endspecify

endmodule
```

---

## 11. Gate-Level Simulation & SDF Annotation

### What is Gate-Level Simulation (GLS)?

After synthesis, the design exists as a **gate-level netlist** — a flat collection of standard cell instances connected by wires. Gate-Level Simulation re-verifies the design using this netlist, with realistic timing from the PDK standard cell library.

**Why GLS is mandatory before tape-out:**

| Issue | RTL Simulation Catches? | GLS Catches? |
|---|---|---|
| Functional logic errors | ✅ Yes | ✅ Yes |
| Synthesis-introduced bugs | ❌ No | ✅ Yes |
| Clock domain crossing (CDC) errors | Partial | ✅ Better (with real delays) |
| Hold time violations (functional) | ❌ No | ✅ Yes (with SDF) |
| Glitch-induced errors | ❌ No | ✅ Yes |
| X-propagation from real power-up | ❌ Limited | ✅ Yes (with library X models) |

### SDF (Standard Delay Format) Back-Annotation

SDF is an IEEE standard (IEEE 1497) file format that carries timing data extracted from the post-layout tool (Primetime, Tempus). It annotates the gate-level netlist with *actual* delay values, replacing the idealized zero/unit delays.

```sdf
// Excerpt from a .sdf file:
(DELAYFILE
    (SDFVERSION "2.1")
    (DESIGN "rca_4bit")
    (TIMESCALE 1ps)

    (CELL
        (CELLTYPE "full_adder_gate")
        (INSTANCE u_fa0)
        (DELAY
            (ABSOLUTE
                (IOPATH a sum (120:145:180) (110:135:165))  // a-to-sum: rise/fall min:typ:max
                (IOPATH b sum (115:140:175) (108:132:160))
                (IOPATH cin sum (95:120:150) (90:115:145))
                (IOPATH a cout (85:105:130) (80:100:125))
            )
        )
    )
)
```

**Invoking GLS with SDF in VCS:**

```bash
# Compile gate-level netlist with library model
vcs -full64 \
    -v /path/to/pdk/sky130_fd_sc_hd.v \    # Standard cell behavioral models
    netlists/rca_4bit_synth.v \             # Synthesized gate-level netlist
    tb/rca_4bit_tb.v \                      # Testbench
    +maxdelays \                            # Use maximum (worst-case) delays
    -o gls_sim

# Run simulation with SDF annotation
./gls_sim \
    +sdf_file=timing/rca_4bit.sdf \         # SDF back-annotation file
    +sdf_verbose \                           # Print SDF annotation status
    -l gls_sim.log
```

### X-Pessimism in GLS

A known challenge with GLS is **X-pessimism** — the simulation produces more unknown (`X`) values than the actual silicon because:

1. **Library model conservatism:** Standard cell `.v` models may propagate `X` more aggressively than real silicon (which resolves to either 0 or 1)
2. **Uninitialized memory elements:** Gate-level cells have no `initial` blocks — all state elements start as `X`
3. **X-propagation through complex cells:** AOI/OAI cells composed of multiple transistors can produce `X` outputs even when a careful timing analysis shows the real output would be deterministic

**Tools like Synopsys VCS XPROP** mode provides algorithms to selectively resolve X values using logical analysis, reducing X-pessimism while maintaining functional accuracy.

---

## 12. Common Interview Scenarios & Design Patterns

### Pattern 1: Converting RTL `assign` to Gate-Level

**Question:** Convert `assign out = (a & b) | (~a & c);` to gate-level primitives.

```verilog
// RTL (behavioral):
assign out = (a & b) | (~a & c);

// Gate-level equivalent:
wire not_a;     // ~a
wire and1_out;  // a & b
wire and2_out;  // ~a & c

not  u_inv  (not_a,    a);
and  u_and1 (and1_out, a, b);
and  u_and2 (and2_out, not_a, c);
or   u_or   (out,      and1_out, and2_out);
```

### Pattern 2: Inferring the Logic from a Netlist

**Question:** What is the Boolean function implemented by this gate-level code?

```verilog
wire w1, w2, w3;
xor u1 (w1, a, b);
xor u2 (w2, w1, c);
and u3 (w3, a, b);
or  u4 (out, w2, w3);
```

**Answer:**
- `w1 = a XOR b`
- `w2 = (a XOR b) XOR c = a XOR b XOR c` — this is a **SUM** bit
- `w3 = a AND b` — partial carry
- `out = (a XOR b XOR c) OR (a AND b)` — this is a **FULL ADDER COUT** (actually, this implements `sum | partial_carry` — a specific carry function)

This is the **carry output of a full adder using a non-standard OR approximation** — a classic interview netlist-reading question.

### Pattern 3: Tri-State Bus with Multiple Drivers

```verilog
// Shared bus with three tri-state drivers:
// Only one enable should be active at a time (bus arbitration guaranteed externally)

wire [7:0] shared_bus;

bufif1 u_dev0 [7:0] (shared_bus, data0, en0);  // Device 0 drives when en0=1
bufif1 u_dev1 [7:0] (shared_bus, data1, en1);  // Device 1 drives when en1=1
bufif1 u_dev2 [7:0] (shared_bus, data2, en2);  // Device 2 drives when en2=1

// When no en is asserted: bus = 8'hZZ (floating)
// When en0=1 only: bus = data0 (driven)
// When en0=1 AND en1=1: bus = 8'hXX (contention — BUS FIGHT)

// Bus hold: prevent floating when no driver active
pullup u_hold [7:0] (shared_bus);  // Weak pull-up holds bus at 1 when floating
```

### Pattern 4: Propagation Delay Chain Analysis

```verilog
// Critical path delay analysis:
and  #(2, 3) u1 (w1, a, b);     // Rise=2, Fall=3
or   #(1, 2) u2 (w2, w1, c);   // Rise=1, Fall=2
xor  #(3, 3) u3 (out, w2, d);  // Rise=3, Fall=3

// Worst-case path (all falling transitions):
// a→w1: 3ns (fall) + w1→w2: 2ns (fall) + w2→out: 3ns (fall) = 8ns total
// This sets the maximum clock frequency: f_max = 1/8ns = 125MHz
```

### Pattern 5: Identifying Glitches in Gate Networks

```verilog
// This circuit has a GLITCH hazard on 'out' when input 'a' transitions:
wire w1, w2;
not u_inv (w1, a);          // w1 = ~a (with propagation delay)
and u_and (w2, a, b);       // w2 = a & b (with propagation delay)
or  u_or  (out, w1, w2);    // out = ~a | (a & b)

// Boolean simplification: ~a | (a & b) = ~a | b   (Shannon expansion)
// The function is equivalent to ~a | b — which has NO glitch for b=1.
// BUT: due to propagation delays between the NOT and AND paths,
//      when a transitions 0→1 with b=1:
//          w1 transitions 1→0 (after NOT delay)
//          w2 transitions 0→1 (after AND delay)
//      If NOT delay > AND delay, there's a brief moment where both w1=0 AND w2=0
//      → out momentarily goes 0 (GLITCH!) before returning to 1.
```

---

## 13. Summary Cheat Sheet

### Built-in Primitive Quick Reference

| Category | Primitives | Port Order | Named Mapping? |
|---|---|---|---|
| Logic Gates | `and`, `nand`, `or`, `nor`, `xor`, `xnor` | Output first, then ≥1 inputs | ❌ Forbidden |
| Buffers | `buf`, `not` | ≥1 Outputs first, then 1 input | ❌ Forbidden |
| Tri-State | `bufif0`, `bufif1`, `notif0`, `notif1` | Output, data input, enable | ❌ Forbidden |

### Key Logic Rules

| Expression | Result | Rule |
|---|---|---|
| `0 & Z` | `0` | Zero dominates AND |
| `0 & X` | `0` | Zero dominates AND |
| `1 \| Z` | `1` | One dominates OR |
| `1 \| X` | `1` | One dominates OR |
| `1 & Z` | `X` | No dominator — unknown |
| `0 \| Z` | `X` | No dominator — unknown |
| `X ^ anything` | `X` | XOR has no dominator |
| Standard gate & `Z` output | **Never** | Gates cannot output Z |
| Tri-state & `Z` output | ✅ Only way | Bufif/notif primitives |

### Delay Specification Summary

| Syntax | Meaning |
|---|---|
| `#5` | Single delay: rise = fall = turnoff = 5 |
| `#(3, 7)` | Two delays: rise=3, fall=7 |
| `#(2, 4, 6)` | Three delays: rise=2, fall=4, turnoff=6 |
| `#(1:2:3)` | Min:Typ:Max single delay |
| `#(1:2:3, 2:3:5)` | Min:Typ:Max rise and fall |
| `transport` keyword | Transport delay model (no glitch absorption) |
| Default (no keyword) | Inertial delay model (absorbs narrow glitches) |

### UDP Limits at a Glance

| Feature | Combinational UDP | Sequential UDP |
|---|---|---|
| Output type | `output` | `output reg` |
| Output position | First port (always) | First port (always) |
| `Z` in table inputs | ❌ Forbidden | ❌ Forbidden |
| `Z` in table outputs | ❌ Forbidden | ❌ Forbidden |
| Don't care symbol | `?` | `?` (inputs), `-` (no state change) |
| Edge notation | N/A | `r`, `f`, `p`, `n`, `b`, `(xy)` |
| Initial value | ❌ Not possible | ✅ `initial q = 1'bx;` |
| Vector ports | ❌ Only 1-bit | ❌ Only 1-bit |

### The 5 Golden Rules of Gate-Level Modeling

1. **Output is ALWAYS first** in positional port mapping for all built-in primitives and UDPs.
2. **Named mapping is FORBIDDEN** for primitives — positional only.
3. **Standard gates NEVER output `Z`** — only `bufifX` and `notifX` can.
4. **Gate delays are inertial by default** — narrow glitches shorter than `Tp` are absorbed.
5. **UDPs cannot use `Z` anywhere** — only `{0, 1, X}` in table entries.

---

*Document authored for: RTL Design Interview Preparation Repository*  
*Standard: IEEE 1364-2001 (Verilog-2001)*  
*Prerequisite: Module 6 — Lexical Elements & Data Types*  
*Follow-on reading: Combinational Logic, Karnaugh Maps & Critical Path Analysis*
