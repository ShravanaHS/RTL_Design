# Module 6: Keywords & Verification Fundamentals

> **Repository:** VLSI & Digital Design — Interview Preparation & Conceptual Reference  
> **Author:** Shravana HS  
> **Standard:** IEEE 1364-2005 / IEEE 1800-2017 (SystemVerilog)  
> **Status:** 🟢 Active — Last Reviewed April 2026

---

## Table of Contents

1. [Verilog Keywords — The Reserved Vocabulary](#1-verilog-keywords--the-reserved-vocabulary)
2. [The Simulation Engine — How Verilog Actually Runs](#2-the-simulation-engine--how-verilog-actually-runs)
3. [Abstract Time: The `#delay` Construct](#3-abstract-time-the-delay-construct)
4. [The Testbench — A Closed Simulation Universe](#4-the-testbench--a-closed-simulation-universe)
5. [The `initial` Block — Simulation-Only Stimulus](#5-the-initial-block--simulation-only-stimulus)
6. [Testbench Anatomy — Complete Example](#6-testbench-anatomy--complete-example)
7. [Summary Cheat Sheet](#summary-cheat-sheet)

---

## 1. Verilog Keywords — The Reserved Vocabulary

Verilog defines a set of **reserved keywords** — identifiers that the language specification has pre-assigned a specific syntactic meaning. The designer cannot use them as signal names, module names, or parameter names.

**The critical rule about Verilog keywords:**

> **All Verilog keywords are strictly lowercase.**

This is a direct consequence of Verilog being a **case-sensitive language**. `wire`, `reg`, `module`, `always`, `assign`, and `if` are keywords. `Wire`, `REG`, `ALWAYS` are valid user-defined identifiers — they are not keywords and will not be treated as such by the compiler.

```verilog
// ✅ CORRECT — keyword in lowercase
wire        q_out;
reg  [7:0]  data_bus;
assign      q_out = data_in & enable;

// ✅ ALSO VALID — 'Wire' and 'Reg' are NOT keywords; they are identifiers
// (But DO NOT do this — it is confusingly bad style)
// wire Wire;  // Legal but catastrophically misleading

// Complete list of common reserved keywords (all lowercase):
// module   endmodule   input    output    inout
// wire     reg         integer  parameter localparam
// always   initial     assign   begin     end
// if       else        case     casex     casez
// endcase  for         while    repeat    forever
// posedge  negedge     and      or        not
// nand     nor         xor      xnor      buf
// #        @           $        ?         :
```

> **🔥 Interview Trap**
>
> **Q: Is Verilog case-sensitive? Give an example where this matters.**
>
> **Yes — completely and unambiguously case-sensitive.** Every identifier, keyword, and signal name is distinct based on exact character case.
>
> ```verilog
> wire reset;   // 'reset' — a signal
> wire Reset;   // 'Reset' — a DIFFERENT signal (capital R)
> wire RESET;   // 'RESET' — a THIRD, entirely separate signal
>
> // 'always' is a keyword. 'Always' is a valid (if terrible) signal name.
> // wire Always;  // Legal. The synthesizer won't confuse it with the keyword.
> ```
>
> In practice, **naming conventions prevent this chaos**: all signals are `snake_case`, parameters are `UPPER_CASE`, module names are `PascalCase` or `snake_case`. Consistent style makes case-sensitivity irrelevant as a source of bugs.

---

## 2. The Simulation Engine — How Verilog Actually Runs

Verilog simulation is executed by an **event-driven simulator**. Understanding the simulation execution model is essential for correctly writing testbenches and debugging race conditions.

### 2.1 Event-Driven Simulation

Rather than stepping through time nanosecond by nanosecond (which would be computationally wasteful during inactive periods), the simulator maintains an **event queue**:

```
Simulation Time Model:

Simulation time t₀ ──────────────────────────────────────────►
                   │         │              │
                 t=0ns     t=10ns         t=25ns
                   │         │              │
               Events:   Events:         Events:
               - rst_n=0  - rst_n=1       - data_in=8'hAB
               - clk=0   - clk=1→0       - clk posedge
                          - always block  - DFF captures data_in
                            triggers
```

**The simulation loop:**
1. Pick the lowest-time event from the queue.
2. Advance simulation time to that event's timestamp.
3. Execute all processes triggered by that event (update signals, evaluate `always` blocks).
4. If those updates generate new events, enqueue them for the same or future time.
5. If the queue is empty at the current time, advance to the next populated time slot.
6. Repeat until `$finish` or simulation end.

### 2.2 The Verilog Scheduling Regions

Within a single simulation time step, Verilog defines multiple **scheduling regions** to resolve ordering:

```
Single Simulation Time Step (e.g., t = 10ns):
┌──────────────────────────────────────────────────────────────┐
│  1. Active Region                                            │
│     → Non-blocking RHS evaluated, blocking assignments exec  │
│     → assign statements re-evaluated                         │
│                                                              │
│  2. NBA Region (Non-Blocking Assignment Update)              │
│     → Non-blocking LHS updated (<=)                          │
│     → This is WHY non-blocking assignments model DFF behavior│
│                                                              │
│  3. Postponed Region                                         │
│     → $monitor, $strobe execute — observe stable final values│
└──────────────────────────────────────────────────────────────┘
```

This scheduling model is exactly why `<=` (non-blocking) is mandatory for sequential logic — it separates the RHS read from the LHS write, preventing the "write before neighbor reads" race condition that `=` (blocking) causes in `always @(posedge clk)` blocks.

---

## 3. Abstract Time: The `#delay` Construct

Verilog's `#N` construct specifies an **abstract time unit** — a pure simulation delay with no physical meaning. The `timescale` directive maps this to real time solely for waveform display purposes.

```verilog
`timescale 1ns / 1ps
// 1ns = time unit (what #1 means)
// 1ps = time precision (resolution of simulation timestamps)

initial begin
    #10;       // Wait 10 × 1ns = 10ns of simulation time
    a = 1'b1;  // Change signal 'a' after 10ns
    #5;        // Wait 5 more ns
    b = 1'b0;
end
```

> **🔥 Interview Trap**
>
> **Q: If I write `assign #5 out = in;` in my RTL, what happens after synthesis?**
>
> **The `#5` is completely and silently ignored by every synthesis tool.** Timing delays specified with `#` in RTL are purely simulation artifacts. The synthesizer discards them because:
>
> 1. **Real propagation delays are determined by the physical standard cells** chosen during synthesis, characterized in the `.lib` timing model — not by the RTL designer's arbitrary `#5`.
> 2. **The foundry's silicon process determines timing**, not the Verilog source code.
>
> Writing `assign #5 out = in;` does not give you a 5ns delay in silicon. It gives you the delay of whatever gate the synthesizer maps `assign out = in` to — typically a buffer with ~0.1–0.5ns delay.
>
> **The correct way to constrain timing** in synthesis is through SDC (Synopsys Design Constraints) files:
> ```tcl
> # SDC — the real way to specify timing requirements
> create_clock -name sys_clk -period 10.0 [get_ports clk] ; # 10ns period = 100MHz
> set_input_delay  2.0 -clock sys_clk [get_ports data_in]
> set_output_delay 1.5 -clock sys_clk [get_ports data_out]
> ```

---

## 4. The Testbench — A Closed Simulation Universe

A **testbench** is a special Verilog module that exists purely within the simulation environment. It has no synthesis-equivalent hardware reality — it is the simulation wrapper that exercises your Design Under Test (DUT).

### Testbench Defining Characteristics

| Property | Testbench | Synthesizable RTL Module |
|:---|:---|:---|
| **Port List** | **None — no ports whatsoever** | Has input/output/inout ports |
| **DUT Inputs** | Declared as `reg` (testbench drives them) | Declared as `input wire` |
| **DUT Outputs** | Declared as `wire` (testbench observes them) | Declared as `output reg/wire` |
| **Stimulus Method** | `initial` blocks (run once, simulation-only) | `always` blocks (run forever, synthesizable) |
| **Time Control** | `#delay`, `@(event)`, `wait()` — all ignored by synth | None (no simulation delays in RTL) |
| **Clock Generation** | `always #5 clk = ~clk;` (toggle every 5 time units) | Clock is an `input wire`, driven externally |
| **Synthesized?** | **Never** | Yes — maps to gates/flip-flops |

### Why DUT Inputs are `reg` in the Testbench

In a testbench, the signals connected to the DUT's input ports are driven by the testbench's `initial` block — a procedural context. In Verilog, **only `reg` types can be driven from procedural blocks** (`initial`, `always`). Therefore, every signal the testbench drives into the DUT must be declared `reg`.

Conversely, the DUT's output signals are received (observed) by the testbench, not driven. They must be `wire` — they are continuously assigned by the DUT's internal logic.

```
Testbench Signal Declarations:
  reg  a_tb, b_tb, cin_tb;    ← Testbench DRIVES these → DUT inputs
  wire sum_tb, cout_tb;       ← DUT DRIVES these → Testbench observes
```

---

## 5. The `initial` Block — Simulation-Only Stimulus

The `initial` block is syntactically similar to `always` but executes exactly **once**, starting at time `t = 0` and running to completion (or until `$finish`). It has no hardware equivalent — it does not map to any repeating real-world process. It is the primary tool for providing testbench stimulus.

```verilog
initial begin
    // t=0: Initialize all DUT inputs to known state
    {a_tb, b_tb, cin_tb} = 3'b000;

    // t=0 → t=10ns: Wait, then apply first test vector
    #10;
    {a_tb, b_tb, cin_tb} = 3'b011;   // Expect: Sum=1, Cout=1

    // t=10ns → t=20ns: Wait, apply next vector
    #10;
    {a_tb, b_tb, cin_tb} = 3'b111;   // Expect: Sum=1, Cout=1

    #10;
    $finish;   // Terminate simulation — no equivalent in hardware
end
```

> **🔥 Interview Trap**
>
> **Q: Can an `initial` block be synthesized? Why or why not?**
>
> **No — `initial` blocks are not synthesizable** (with one narrow exception for FPGA BRAM initialization).
>
> The reason is fundamental: an `initial` block describes **a one-shot sequential process that starts at time zero**. In real hardware, there is no concept of "time zero" or "running once at power-up and stopping." Hardware is a network of continuously active elements — flip-flops hold state via feedback, combinational gates continuously evaluate inputs.
>
> **The exception:** Some FPGA synthesis tools (Xilinx Vivado, Intel Quartus) allow `initial` blocks inside `always @*` or in specific register declarations to set power-up initial values for Block RAMs and distributed LUTs. But this is an FPGA-specific vendore extension — not general synthesizability. In ASIC flows (the domain of Synopsys DC, Cadence Genus), `initial` blocks are ignored entirely.
>
> **For ASIC design:** Power-up state is controlled by reset logic (`rst_n`), not `initial` blocks.

---

## 6. Testbench Anatomy — Complete Example

```verilog
// ============================================================
// TESTBENCH: Parameterized N-Bit Adder
// File: adder_tb.v
//
// Demonstrates all testbench conventions:
//  - No port list (closed universe)
//  - reg for DUT inputs, wire for DUT outputs
//  - initial block for one-shot stimulus
//  - always block for clock generation
//  - $dumpfile/$dumpvars for GTKWave waveform capture
//  - Self-checking with $error assertions
// ============================================================
`timescale 1ns / 1ps

module adder_tb;   // ← No port list — a testbench has ZERO ports

    // -------------------------------------------------------
    // Parameters — must match DUT parameters
    // -------------------------------------------------------
    localparam DATA_W = 8;

    // -------------------------------------------------------
    // Signal declarations
    // DUT inputs → reg (driven by initial block)
    // DUT outputs → wire (driven by DUT, observed by TB)
    // -------------------------------------------------------
    reg                   clk_tb;    // System clock
    reg                   rst_n_tb;  // Active-low reset
    reg  [DATA_W-1:0]     a_tb;      // Operand A
    reg  [DATA_W-1:0]     b_tb;      // Operand B
    wire [DATA_W:0]       sum_tb;    // Sum (N+1 bits to capture carry)

    // -------------------------------------------------------
    // DUT Instantiation — ALWAYS use named port mapping
    // -------------------------------------------------------
    ripple_adder #(.DATA_WIDTH(DATA_W)) DUT (
        .clk   (clk_tb),
        .rst_n (rst_n_tb),
        .a     (a_tb),
        .b     (b_tb),
        .sum   (sum_tb)
    );

    // -------------------------------------------------------
    // Clock Generation — 10ns period (100 MHz)
    // This 'always' block runs forever in simulation.
    // The synthesizer ignores this when synthesizing the TB
    // (TBs are never synthesized anyway).
    // -------------------------------------------------------
    initial clk_tb = 1'b0;
    always #5 clk_tb = ~clk_tb;    // Toggle every 5ns → 10ns period

    // -------------------------------------------------------
    // Waveform Capture — for GTKWave post-simulation viewing
    // -------------------------------------------------------
    initial begin
        $dumpfile("adder_dump.vcd");
        $dumpvars(0, adder_tb);   // Dump all signals in this scope
    end

    // -------------------------------------------------------
    // Stimulus & Self-Checking — one-shot initial block
    // -------------------------------------------------------
    task apply_and_check;
        input [DATA_W-1:0] a_in, b_in;
        input [DATA_W:0]   expected_sum;
        begin
            a_tb = a_in;
            b_tb = b_in;
            @(posedge clk_tb);    // Synchronize to clock edge
            #1;                   // Small delay to let outputs settle
            if (sum_tb !== expected_sum) begin
                $error("FAIL: a=%0d b=%0d | Got=%0d Expected=%0d",
                        a_in, b_in, sum_tb, expected_sum);
            end else begin
                $display("PASS: a=%0d b=%0d | sum=%0d", a_in, b_in, sum_tb);
            end
        end
    endtask

    initial begin
        // --- Reset sequence ---
        rst_n_tb = 1'b0;
        a_tb     = '0;
        b_tb     = '0;
        @(posedge clk_tb); @(posedge clk_tb);  // Hold reset 2 cycles
        rst_n_tb = 1'b1;

        // --- Test vectors ---
        apply_and_check(8'd0,   8'd0,   9'd0);
        apply_and_check(8'd127, 8'd1,   9'd128);
        apply_and_check(8'd255, 8'd1,   9'd256);   // Overflow case
        apply_and_check(8'd200, 8'd100, 9'd300);

        $display("==============================");
        $display("  Simulation Complete.");
        $display("==============================");
        $finish;
    end

endmodule
```

---

## Summary Cheat Sheet

| Concept | Key Takeaway |
|:---|:---|
| **Keywords** | All Verilog keywords are strictly lowercase. Verilog is fully case-sensitive. |
| **Event-Driven Simulation** | Simulator maintains an event queue; only processes events at active timestamps. |
| **`#delay`** | Abstract simulation time. Synthesizer ignores ALL `#` delays in RTL. Use SDC for real timing. |
| **Testbench ports** | A testbench module has **zero ports** — it is a closed system instantiating the DUT internally. |
| **DUT inputs in TB** | Declared as `reg` — driven from procedural `initial`/`always` blocks. |
| **DUT outputs in TB** | Declared as `wire` — driven by the DUT's internal logic, passively observed by the TB. |
| **`initial` block** | Executes once at t=0. **Not synthesizable** in ASIC flows. Simulation-only stimulus. |
| **Clock in TB** | Generated by `always #(HALF_PERIOD) clk = ~clk;` — TB-local, never feeds real synthesis. |

---

*Module 7 → Design Methodologies & Advanced Synthesis*
