# The Grammar of Silicon: Lexical Elements & Data Types

> **Repository:** VLSI & Digital Design — Interview Preparation & Conceptual Reference  
> **Author:** Shravana HS  
> **Standard:** IEEE 1364-2005 (Verilog-2005) / IEEE 1800-2017 (SystemVerilog)  
> **Status:** 🟢 Active — Last Reviewed April 2026

---

## Table of Contents

1. [Comments — The Designer's Intent](#1-comments--the-designers-intent)
2. [Identifiers — Naming the Hardware](#2-identifiers--naming-the-hardware)
3. [Keywords — The Reserved Lexicon](#3-keywords--the-reserved-lexicon)
4. [Ports — The Silicon Gateway](#4-ports--the-silicon-gateway)
5. [Number Representation — The Interview Minefield](#5-number-representation--the-interview-minefield)
6. [Data Types — Nets vs. Variables](#6-data-types--nets-vs-variables)
7. [Handling `integer` and `real`](#7-handling-integer-and-real)
8. [Vectors vs. Arrays — Buses vs. Memories](#8-vectors-vs-arrays--buses-vs-memories)
9. [Strings — The Hardware Illusion](#9-strings--the-hardware-illusion)
10. [Special Characters & Simulation Time](#10-special-characters--simulation-time)

---

## 1. Comments — The Designer's Intent

The purpose of a comment is not to explain *what* the code does — the code already says that. The purpose of a comment is to explain **why** the hardware is built this way: the architectural decision, the protocol constraint, the silicon limitation, or the corner case being handled.

```verilog
// ❌ BAD — explains WHAT the code does (redundant, adds no value)
assign cout = (a & b) | (b & cin) | (a & cin);  // OR the AND results

// ✅ GOOD — explains WHY this implementation was chosen
// Majority-3 function: avoids 2-level AND-OR by relying on the PDK's
// sky130_fd_sc_hd__maj3_1 cell which implements this as a single gate,
// saving ~2.4µm² vs. AND2+OR3 decomposition. Verified by area report.
assign cout = (a & b) | (b & cin) | (a & cin);
```

### 1.1 Single-Line Comment (`//`)

Extends from the `//` marker to the end of the current line. Safe to nest, immune to multi-line comment anomalies, and can appear anywhere after a statement on the same line.

```verilog
input wire clk,      // Rising-edge active — 100 MHz system clock
input wire rst_n,    // Active-LOW synchronous reset (industry standard)
```

### 1.2 Block Comment (`/* ... */`)

Spans from `/*` to the **first** `*/` encountered. Intended for multi-line banners, header blocks, and structured module documentation.

```verilog
/*
 * Module:   uart_tx
 * Protocol: UART 8N1 (8 data bits, No parity, 1 stop bit)
 * Timing:   Validated for baud rates up to 921600 at 100MHz clk
 * Author:   Shravana HS — April 2026
 */
module uart_tx ( ... );
```

> **🔥 Interview Trap 1 — Block Comments Do Not Nest**
>
> **Q: I used `/* ... */` to comment out a debug block, but now I'm getting cascade syntax errors elsewhere in the file. Why?**
>
> **Because block comments do not nest in Verilog.** The `*/` that terminates a comment is always the *first* one found — it does not match the most recent `/*`. When you comment out a region that already contains a block comment, the first `*/` inside that region closes the *outer* comment, leaving everything after it as live, unexpectedly active code.
>
> ```verilog
> /* Attempting to disable this debug block:
>
>    wire debug_en;
>    /* Old debug note explaining the flag */   ← This */ closes the OUTER /*
>    assign debug_out = debug_en & data;        ← Now LIVE CODE — synthesized!
>
> */  ← Dangling */ — the parser has no matching open, syntax error cascade
> ```
>
> The synthesizer may quietly accept it with warnings, producing a subtly broken netlist. This class of bug is notoriously hard to find in large files.
>
> **Rule:** Always use `//` for disabling code. Most IDEs provide `Ctrl+/` (toggle line comment) for bulk selection. Reserve `/* */` exclusively for structural header banners.

> **🔥 Interview Trap 2 — The Safe Alternative: `` `ifdef `` Macros**
>
> **Q: What is the production-safe way to conditionally exclude large logic blocks from synthesis?**
>
> **Use conditional compilation macros.** The `` `ifdef `` / `` `else `` / `` `endif `` directives are evaluated by the Verilog preprocessor *before* the parser sees the code, making the exclusion completely safe — no nesting issues, no syntax cascades.
>
> ```verilog
> // Define this macro in the compile command to enable debug logic:
> // iverilog -DDEBUG_ENABLE fulladder.v ...
>
> `ifdef DEBUG_ENABLE
>     // This entire block is invisible to the synthesizer unless
>     // -DDEBUG_ENABLE is passed. No risk of accidental synthesis.
>     always @(posedge clk) begin
>         $display("[DEBUG] t=%0t | state=%b | out=%h", $time, state, data_out);
>     end
> `else
>     // Production code path — synthesized
>     assign debug_out = 1'b0;  // Tie off debug output in production
> `endif
> ```
>
> In industry flows, debug logic that should never reach silicon is always gated behind `` `ifdef `` macros checked in the synthesis Makefile — ensuring a single-flag switch between simulation and production netlists.

---

## 2. Identifiers — Naming the Hardware

An **identifier** is the name given to a module, signal, parameter, task, function, or any other hardware element. Verilog identifier rules are strict and mechanical.

### 2.1 Identifier Rules

| Rule | Detail |
|:---|:---|
| **First character** | Must be a letter (`A–Z`, `a–z`) or underscore (`_`) |
| **Subsequent characters** | Letters, digits (`0–9`), underscores (`_`), and dollar signs (`$`) |
| **Cannot start with** | A digit (`0–9`) or a dollar sign (`$`) |
| **Length limit** | Technically unlimited; practical limit is tool-dependent (~1024 chars) |
| **Case sensitivity** | Fully case-sensitive — `reset`, `Reset`, and `RESET` are three distinct identifiers |

### 2.2 Valid vs. Invalid Identifiers

| Identifier | Valid? | Reason |
|:---|:---|:---|
| `data_in` | ✅ Valid | Starts with letter, uses underscores |
| `_int_node` | ✅ Valid | Starts with `_`, legal |
| `clk2x` | ✅ Valid | Digit after first char is fine |
| `state$q` | ✅ Valid | `$` allowed after first char |
| `3bit_cnt` | ❌ Invalid | Starts with digit |
| `$enable` | ❌ Invalid | Starts with `$` (reserved for system tasks) |
| `my-signal` | ❌ Invalid | Hyphen `-` is not permitted |
| `wire` | ❌ Invalid | Reserved keyword |

### 2.3 Industry Naming Conventions

| Suffix / Prefix | Meaning | Example |
|:---|:---|:---|
| `_n` | Active-low signal | `rst_n`, `ce_n`, `oe_n` |
| `_r` or `_q` | Registered output (DFF output) | `data_r`, `valid_q` |
| `_d` | Data input to a register (D input) | `data_d`, `count_d` |
| `_p` | Pipelined version (stage N+1) | `addr_p`, `cmd_p` |
| `clk_` | Clock signal prefix | `clk_sys`, `clk_axi` |
| `i_` / `o_` | Port direction prefix | `i_data`, `o_valid` |
| `UPPER_CASE` | Parameters and constants | `DATA_WIDTH`, `CLK_FREQ` |

> **🔥 Interview Trap 1 — Strict Case-Sensitivity**
>
> **Q: My lint check is flagging a signal mismatch, but I can't see any typo. What could cause this?**
>
> **Case mismatch is the most common invisible bug in complex RTL.** Verilog is completely case-sensitive:
>
> ```verilog
> module glitch_example (
>     input  wire reset,   // Signal 'reset' (lowercase)
>     input  wire Reset,   // Signal 'Reset' (capital R) — DIFFERENT wire!
>     output wire q
> );
>     // A junior engineer writing this can accidentally connect the wrong one:
>     always @(posedge clk or posedge Reset) begin  // Using 'Reset' — intended 'reset'?
>         if (Reset) q <= 1'b0;
>     end
> endmodule
> ```
>
> The synthesizer compiles this perfectly. The lint tool may or may not catch it depending on its rules. The bug only surfaces in functional simulation when `reset` fires but the always block doesn't respond (because it's listening to `Reset`).
>
> **Mitigation:** Enforce a single naming convention globally. Never have identifiers that differ only in capitalization. Most RTL style guides (lowRISC, Google's) explicitly prohibit it.

> **🔥 Interview Trap 2 — Escaped Identifiers**
>
> **Q: I see identifiers like `\cpu.alu_out ` (starting with backslash, ending with space) in synthesis netlists. What are these?**
>
> **These are escaped identifiers** — a Verilog mechanism to allow *any* printable character sequence as an identifier, including characters that are normally illegal (spaces, periods, hyphens, brackets).
>
> An escaped identifier begins with `\` and ends with the first whitespace character encountered.
>
> ```verilog
> // Escaped identifiers — legal in Verilog, valid in synthesis netlists:
> wire \cpu.data_out ;    // Contains a period
> wire \32bit-adder ;     // Starts with digit, contains hyphen
> wire \net[0] ;          // Contains brackets
>
> // Using them in expressions:
> assign result = \cpu.data_out  & enable;   // The space after the name is required
> ```
>
> **Where you encounter them:** Synthesis tools (Yosys, DC) use escaped identifiers in gate-level netlists when hierarchical path names from the RTL (e.g., `cpu_block.alu.carry_out`) are flattened into a single top-level namespace. They are **not** intended for use in RTL source — if you see them in original user-written code, it is a style violation.

---

## 3. Keywords — The Reserved Lexicon

### 3.1 The Golden Rule

> **All standard Verilog/SystemVerilog keywords are strictly lowercase.**

`module`, `wire`, `always`, `posedge`, `assign` — every one of them is in lowercase. This is not convention; it is the language specification.

### 3.2 Keyword Categories

| Category | Keywords |
|:---|:---|
| **Structural** | `module`, `endmodule`, `input`, `output`, `inout`, `parameter`, `localparam`, `generate`, `endgenerate` |
| **Data Types** | `wire`, `reg`, `integer`, `real`, `realtime`, `time`, `supply0`, `supply1`, `tri`, `wand`, `wor` |
| **Procedural** | `always`, `initial`, `begin`, `end`, `assign`, `if`, `else`, `case`, `casex`, `casez`, `endcase`, `for`, `while`, `repeat`, `forever`, `fork`, `join`, `task`, `endtask`, `function`, `endfunction` |
| **Edge/Event** | `posedge`, `negedge`, `or` (in sensitivity lists) |
| **Primitives** | `and`, `or`, `not`, `nand`, `nor`, `xor`, `xnor`, `buf`, `bufif0`, `bufif1`, `notif0`, `notif1` |
| **Timing** | `specify`, `endspecify`, `specparam` |

> **🔥 Interview Trap 1 — The Capitalization Loophole**
>
> **Q: Does `wire Reg;` compile in Verilog?**
>
> **Yes — and that is exactly the problem.** Because `Reg` (capital R) is not a keyword (only `reg` lowercase is), the Verilog parser accepts it as a valid user-defined identifier. The declaration `wire Reg;` creates a net named `Reg`.
>
> ```verilog
> wire Reg;    // Legal: 'Reg' is a user identifier, not the keyword 'reg'
> wire Module; // Legal: 'Module' is an identifier, 'module' is the keyword
> wire Always; // Legal: 'Always' is an identifier, 'always' is the keyword
>
> // But this is:
> // 1. A catastrophic naming convention violation
> // 2. A human reading trap — 'Reg' looks like it should be a register
> // 3. A lint error in any professional codebase
> ```
>
> All professional RTL coding standards explicitly prohibit naming signals with capitalizations of keywords.

> **🔥 Interview Trap 2 — System Tasks and Directives Are Not Keywords**
>
> **Q: Are `$display` and `` `define `` Verilog keywords?**
>
> **No — they occupy separate namespaces and have different parsing rules.**
>
> | Category | Prefix | Example | Parsed By |
> |:---|:---|:---|:---|
> | **Verilog Keywords** | None | `always`, `wire`, `if` | Language parser |
> | **System Tasks / Functions** | `$` | `$display`, `$finish`, `$random` | Simulator system interface |
> | **Compiler Directives** | `` ` `` (backtick) | `` `define ``, `` `ifdef ``, `` `timescale `` | Preprocessor (before parsing) |
>
> System tasks (`$`) are simulation constructs — the synthesizer ignores all `$`-prefixed calls. Compiler directives (`` ` ``) are preprocessor text substitutions resolved before the Verilog parser even runs.

> **🔥 Interview Trap 3 — The `reg` Misconception**
>
> **Q: Does declaring a signal as `reg` mean it will be synthesized as a flip-flop?**
>
> **No — this is one of the most persistent misconceptions in digital design.**
>
> `reg` in Verilog means "a variable that can be assigned in a procedural block (`always`, `initial`)." Whether it synthesizes to a **combinational latch, a flip-flop, or pure combinational logic** depends entirely on the *coding style* of the always block — not the `reg` keyword.
>
> ```verilog
> // CASE 1: reg → FLIP-FLOP (clocked always block)
> always @(posedge clk)
>     data_q <= data_d;   // 'data_q' is reg → synthesizes to D Flip-Flop ✅
>
> // CASE 2: reg → COMBINATIONAL LOGIC (combinational always block, complete case)
> always @(*) begin
>     case (sel)
>         2'b00: out = a;
>         2'b01: out = b;
>         2'b10: out = c;
>         default: out = d;
>     endcase
> end
> // 'out' is reg → synthesizes to a 4:1 MUX — purely combinational ✅
>
> // CASE 3: reg → LATCH (combinational always block, INCOMPLETE case — BUG)
> always @(*) begin
>     if (enable) out = data;   // No else branch!
> end
> // 'out' is reg → synthesizes to a LATCH — almost certainly a bug ❌
> ```
>
> The `reg` keyword is a simulation artifact of Verilog's procedural assignment rules. **SystemVerilog fixed this confusion** by introducing `logic` (which replaces both `wire` and `reg` in most contexts) and requiring `always_ff`, `always_comb`, and `always_latch` to explicitly declare the synthesizer's intent.

---

## 4. Ports — The Silicon Gateway

Ports are the interface through which a module communicates with the outside world. Every port has a **direction** (`input`, `output`, `inout`) and a **type** (`wire` or `reg`), and these combinations are not freely interchangeable.

### 4.1 Port Direction to Type Mapping

| Direction | Allowed Type | Driven By | Notes |
|:---|:---|:---|:---|
| `input` | **`wire` only** | External driver (parent module or TB) | The module reads this; it may never be assigned internally |
| `output` | `wire` (continuous) or `reg` (procedural) | This module's internal logic | `wire` output → driven by `assign`. `reg` output → driven by `always` block |
| `inout` | **`wire` only** | Either direction — requires tri-state control | Requires `Z` state management |

```verilog
module port_example #(parameter W = 8) (
    input  wire           clk,        // ✅ input → always wire
    input  wire           rst_n,      // ✅ input → always wire
    input  wire [W-1:0]   data_in,    // ✅ input bus → wire
    output wire [W-1:0]   data_out,   // output wire → driven by assign below
    output reg            valid,      // output reg → driven by always block below
    inout  wire           bus_line    // inout → must be wire (tri-state)
);
    assign data_out = data_in;                // Wire output via continuous assign
    always @(posedge clk) valid <= data_in[0]; // Reg output via clocked block
endmodule
```

> **🔥 Interview Trap 1 — Driving an Input Port**
>
> **Q: What happens if I write `assign clk = 1'b0;` inside a module that has `input wire clk` in its port list?**
>
> **It is illegal and results in a multiple-driver contention.** An `input` port represents a physical wire whose driver is external — outside this module's boundary. Attempting to also drive it from inside the module places two drivers on the same wire, creating an `X` (unknown/contention) state in simulation and a DRC violation in synthesis.
>
> ```verilog
> module bad_design (
>     input wire clk,
>     output reg q
> );
>     assign clk = 1'b0;  // ❌ Illegal: driving an input port from inside
>     // Some tools emit a warning, others a hard error.
>     // The simulation result is X (undefined) on clk.
>     always @(posedge clk) q <= ~q;
> endmodule
> ```
>
> Synthesis tools may silently ignore the internal driver and route the external signal, creating a mismatch between simulation and silicon behavior — the most dangerous class of bug.

> **🔥 Interview Trap 2 — The `inout` Synthesis Myth**
>
> **Q: Can `inout` ports be used freely inside an FPGA for bidirectional on-chip communication between two internal modules?**
>
> **Absolutely not — and this is a fundamental architectural constraint.**
>
> `inout` requires **tri-state bus logic**: a driver that can actively drive `0`, actively drive `1`, or *release the bus to high impedance* (`Z`). In an FPGA, tri-state buffers exist **only at the I/O boundary** (chip pins). Internal FPGA routing fabric has no tri-state capability — all internal wires must have exactly one active driver.
>
> **The correct tri-state pattern for chip pins:**
> ```verilog
> module bidirectional_pin (
>     input  wire       clk,
>     input  wire       drive_en,   // 1 = this module drives; 0 = release bus
>     input  wire [7:0] tx_data,    // Data to send when driving
>     output reg  [7:0] rx_data,    // Data captured when receiving
>     inout  wire [7:0] bus_pin     // Bidirectional chip I/O pin
> );
>     // Tri-state driver: drive when enabled, release (Z) when not
>     assign bus_pin = drive_en ? tx_data : 8'hZZ;   // Z = release bus
>
>     // Receiver: sample bus when not driving
>     always @(posedge clk) begin
>         if (!drive_en) rx_data <= bus_pin;
>     end
> endmodule
> ```
>
> Attempting to use `inout` between two internal FPGA modules results in a synthesis error. For on-chip bidirectional handshaking, use two separate unidirectional signals and a direction-control register.

---

## 5. Number Representation — The Interview Minefield

### 5.1 The Four Logic States

Verilog is a **four-valued logic** system. Every net and variable can hold one of four states at any point in simulation:

| State | Name | Meaning | Physical Cause |
|:---|:---|:---|:---|
| `0` | Logic Zero | Boolean false, driven low | NMOS pull-down, GND connection |
| `1` | Logic One | Boolean true, driven high | PMOS pull-up, VDD connection |
| `X` | Unknown / Contention | Indeterminate — could be 0 or 1 | Two drivers fighting (short), uninitialized flip-flop |
| `Z` | High Impedance | No driver — bus released | Tri-state buffer output, floating net |

**Critical distinction:** `X` is not a "don't care" in synthesis (that's `casex`/`casez`). During simulation, `X` is a contamination — it propagates through logic, converting outputs to `X` to warn the designer that the result is non-deterministic.

### 5.2 Number Literal Syntax

The formal syntax for a sized number literal is:

```
<size>'<signed_flag><base><value>

Where:
  <size>         = Bit-width (decimal integer, e.g., 8, 16, 32)
  '              = Apostrophe separator — mandatory
  <signed_flag>  = Optional 's' for signed interpretation (e.g., 8'sd)
  <base>         = b (binary), o (octal), d (decimal), h (hexadecimal)
  <value>        = Digits valid for the base; _ separators allowed for readability
```

```verilog
8'b1010_0011    // 8-bit binary: 0xA3
8'hA3           // 8-bit hex: 163 decimal — same value as above
8'd163          // 8-bit decimal: explicit
8'o243          // 8-bit octal
16'h0000        // 16-bit hex zero
8'bxxxxxxxx     // 8-bit unknown (all X) — used in resets and don't-cares
8'hzz           // 8-bit high-Z (floating)
8'sd150         // 8-bit SIGNED decimal — valid range [-128, +127]; 150 overflows
```

> **🔥 Interview Trap 1 — The Bloated ALU (Unsized Numbers)**
>
> **Q: What is the bit width of the number `5` in Verilog? What synthesis problem does this cause?**
>
> **The default width of an unsized integer literal in Verilog is 32 bits.** If you write `5`, it is treated as `32'h00000005`.
>
> ```verilog
> // ❌ DANGEROUS — unsized number in a comparison
> always @(*) begin
>     if (count == 5)  // '5' is 32'h00000005
>         done = 1'b1;
> end
> // If 'count' is 4 bits wide, the synthesizer zero-extends 'count' to 32 bits
> // for the comparison. This synthesizes a 32-bit comparator — 10–30× larger
> // than the intended 4-bit comparator. Zero silicon waste.
>
> // ✅ CORRECT — explicitly sized
> if (count == 4'd5)   // 4-bit comparison → 4-bit comparator in silicon
> ```
>
> In a complex design with hundreds of such comparisons, unsized literals can silently bloat area by adding unnecessary wide logic cones throughout the netlist.

> **🔥 Interview Trap 2 — Size Mismatches: Truncation and Extension**
>
> **Q: What happens when you assign a wider value to a narrower `reg`, or a narrower value to a wider `reg`?**
>
> **The behavior is deterministic but silent — no runtime error, no warning from many tools.**
>
> **Truncation (Value too wide for target):**
> ```verilog
> reg [3:0] nibble;
> nibble = 8'hAB;   // 8'b1010_1011 assigned to 4-bit reg
> // Result: nibble = 4'b1011 (0xB) — the upper 4 bits (0xA) are SILENTLY DROPPED
> // The MSBs are discarded. No warning. No error. Your data is corrupted.
> ```
>
> **Extension (Value too narrow for target):**
> ```verilog
> reg [7:0] byte_val;
> byte_val = 4'b1011;     // 4-bit value assigned to 8-bit reg
> // Zero-extension: byte_val = 8'b0000_1011 ✅ (MSB of value is 0)
>
> byte_val = 4'bx011;     // Value with X in MSB
> // X-extension:   byte_val = 8'bxxxx_0011 — X propagates into upper bits
>
> byte_val = 4'bz011;     // Value with Z in MSB
> // Z-extension:   byte_val = 8'bzzzz_0011 — Z propagates into upper bits
> ```
>
> The extension rule is: **zero-extend if the MSB of the source is `0` or `1`; X-extend if MSB is `X`; Z-extend if MSB is `Z`.**

> **🔥 Interview Trap 3 — Negative Numbers and 2's Complement**
>
> **Q: How do you represent -5 as an 8-bit number in Verilog? Where does the minus sign go?**
>
> **The minus sign goes BEFORE the size specifier, not inside the number string.**
>
> ```verilog
> // ✅ CORRECT syntax: minus sign before size
> reg signed [7:0] val;
> val = -8'd5;     // 2's complement: 8'b11111011 = 0xFB ✅
>
> // ❌ WRONG — the minus is applied AFTER reading the base value,
> //             producing unexpected results:
> val = 8'd-5;     // SYNTAX ERROR — illegal
>
> // ❌ SUBTLE BUG — negative value in unsigned context
> reg [7:0] u_val;
> u_val = -8'd5;   // Stores 8'hFB (251) — correct bit pattern,
>                  // but unsigned context means printing gives 251, not -5
>
> // For signed arithmetic, ALWAYS declare the reg as signed:
> reg signed [7:0] s_val = -8'sd5;  // Correct: signed literal, signed declaration
> $display("%d", s_val);  // Prints: -5
> ```
>
> Mixing signed and unsigned contexts without explicit declarations produces silent arithmetic bugs that survive synthesis and appear only at corner cases in silicon.

---

## 6. Data Types — Nets vs. Variables

Verilog data types divide cleanly into two fundamental categories reflecting two different hardware concepts.

### 6.1 Nets — Physical Connections

A **net** represents a physical wire in the circuit — a continuous electrical connection driven by its source. Nets *have no memory*; their value at any moment is determined entirely by their current driver(s).

**Default value: `Z` (high-impedance — no driver connected)**

| Net Type | Behavior | Use Case |
|:---|:---|:---|
| `wire` | Standard net — value = driver's output | All standard connections |
| `wand` | Wired-AND: multiple drivers → AND their values | Open-collector bus (e.g., I²C) |
| `wor` | Wired-OR: multiple drivers → OR their values | Open-drain bus (e.g., NMI lines) |
| `tri` | Identical to `wire` but semantically marks tri-state intent | Tri-state buses |
| `supply0` | Permanently driven to logic `0` | VSS/GND connections |
| `supply1` | Permanently driven to logic `1` | VDD/power connections |

```verilog
wire        data_net;     // Standard net — default for most connections
wand        i2c_sda;      // Wired-AND: multiple I2C masters share the SDA line
wor         irq_line;     // Wired-OR: any peripheral can assert interrupt
tri  [7:0]  mem_bus;      // Tri-state data bus
supply0     vss;          // Hard-wired ground
supply1     vdd;          // Hard-wired power
```

### 6.2 Variables — Procedural Storage

A **variable** holds its last assigned value — it retains state between assignments. It can only be assigned inside a procedural block (`always`, `initial`, `task`, `function`).

**Default value: `X` (unknown — uninitialized)**

```verilog
reg              flip_flop_output;   // Retains value between clock edges
reg [7:0]        accumulator;        // 8-bit variable — maps to DFF bank if clocked
integer          loop_counter;       // 32-bit signed (simulation/loop use only)
```

> **🔥 Interview Trap 1 — Multiple Drivers on a `wire`**
>
> **Q: I have two `assign` statements both driving the same `wire`. What is the simulation result?**
>
> **The result is `X` — a contention condition.** A standard `wire` with two active conflicting drivers sits in an undefined state because Verilog's resolution function for `wire` is "unknown if both drivers disagree."
>
> ```verilog
> wire out;
> assign out = a & b;   // Driver 1
> assign out = c | d;   // Driver 2 — both driving 'out' simultaneously
>
> // If (a & b) = 0 and (c | d) = 1:
> //   Driver 1 pulls to 0, Driver 2 pulls to 1 → CONTENTION → out = X
>
> // If (a & b) = 1 and (c | d) = 1:
> //   Both agree on 1 → out = 1 (no contention by luck, still a design error)
> ```
>
> **When is multiple-driving intentional?** Only with `wand`/`wor` net types (which have defined resolution functions) or with tri-state logic (`assign out = en ? data : 1'bZ`). In all other cases, multiple drivers are a bug and must be resolved with multiplexers.

> **🔥 Interview Trap 2 — Mixing Signed and Unsigned Arithmetic**
>
> **Q: What happens when you perform arithmetic mixing a `signed` and an `unsigned` value?**
>
> **The entire expression is forced to unsigned evaluation**, destroying the 2's complement semantics of the signed operand.
>
> ```verilog
> reg signed   [7:0] s = -8'd10;   // s = 8'hF6 = 8'b11110110 (two's complement of -10)
> reg unsigned [7:0] u = 8'd5;
>
> reg signed   [7:0] result;
> result = s + u;
>
> // Expected (signed math): -10 + 5 = -5 → 8'hFB
> // Actual (unsigned forced): 8'hF6 + 8'h05 = 8'hFB = 251 (unsigned interpretation)
> // The bit result is the same (0xFB), BUT:
> // → If 'result' is later used in a signed comparison, it reads as -5 ✅
> // → If 'result' is used in an unsigned comparison (e.g., > 200), it reads as 251 ❌
>
> // The danger: intermediate expressions in mixed-signed arithmetic are silently
> // promoted to unsigned, changing comparison results invisibly.
>
> // Safe pattern: always cast explicitly
> result = s + $signed(u);   // Forces 'u' into signed context first
> ```
>
> Mixed signed/unsigned arithmetic is the single most common source of silent arithmetic bugs in production RTL. All signal declarations in a datapath should consistently use either all `signed` or all `unsigned`.

---

## 7. Handling `integer` and `real`

### 7.1 `integer` — The 32-Bit Signed Variable

`integer` is a 32-bit signed Verilog variable. It is a **simulation-centric** type — its strict intended use is as a loop counter or index variable in `for` loops and `generate` constructs.

```verilog
// ✅ CORRECT: 'integer' as a generate/loop counter
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : gen_pipeline
        dff stage (
            .clk(clk), .d(pipe[i]), .q(pipe[i+1])
        );
    end
endgenerate

// ✅ CORRECT: loop counter in a task
integer j;
initial begin
    for (j = 0; j < 256; j = j + 1) begin
        mem[j] = 8'h00;   // Initialize memory in testbench
    end
end
```

**Critical rule:** Do not use `integer` in synthesizable RTL datapaths. Use sized `reg [N-1:0]` vectors instead. `integer` in a datapath synthesizes to a 32-bit structure regardless of the actual value range needed — wasting area.

### 7.2 `real` — The 64-bit IEEE 754 Float

`real` holds a double-precision floating-point value. It is used exclusively in simulation for high-precision numerical computation (e.g., reference model golden values, timing calculations, SPICE-like behavioral models).

```verilog
real pi    = 3.14159265358979;
real freq  = 1.0e9;              // 1 GHz in Hz
real period = 1.0 / freq;        // period = 1ns — used only in testbench timing
```

> **🔥 Interview Trap — Synthesizing Floating Point**
>
> **Q: Can I use `real` variables in my synthesizable RTL to implement floating-point arithmetic?**
>
> **No — `real` is completely unsynthesizable.** Synthesis tools ignore `real` declarations and will either emit an error or silently drop the logic.
>
> **Why?** Floating-point arithmetic requires circuits implementing the IEEE 754 standard: mantissa extraction, exponent comparison, normalization, rounding — all of which are complex multi-stage pipelines with dozens of adders, shifters, and comparators. No synthesis tool can infer this from a Verilog `real` type.
>
> **The hardware solution is Fixed-Point Arithmetic:**
>
> ```verilog
> // Instead of: real gain = 0.75;
> // Use fixed-point with an implicit binary point:
>
> // Q7 format: 1 sign bit + 7 fractional bits (value range: -1.0 to +0.9921875)
> // 0.75 in Q7 = 0_1100000 = 8'b0110_0000 = 8'h60
>
> reg signed [7:0] gain_q7 = 8'sh60;   // Represents +0.75 in Q7.0 fixed-point
>
> // Multiplication: Q7 × Q7 → Q14, then right-shift 7 to return to Q7
> reg signed [15:0] product;
> product = (data_q7 * gain_q7) >>> 7;  // Arithmetic right shift preserves sign
> ```
>
> Fixed-point designed synthesizes cleanly to standard multipliers, adders, and shifters. Understanding Q-format arithmetic is a hard requirement for any DSP or ML accelerator RTL role.

---

## 8. Vectors vs. Arrays — Buses vs. Memories

These two constructs look similar but represent fundamentally different hardware structures.

### 8.1 Vectors — Data Buses

A **vector** is a multi-bit single variable — a bus. The bit-range specifier goes **before** the identifier name.

```verilog
//        [MSB:LSB]   name
reg       [7:0]       data_byte;    // 8-bit bus → can map to 8-bit DFF bank or datapath
wire      [31:0]      axi_addr;     // 32-bit AXI address wire
reg       [0:7]       rev_byte;     // 8-bit bus, bit 0 is MSB (little-endian style — unusual)

// Bit-slicing and part-select:
data_byte[7]       // MSB — single bit
data_byte[3:0]     // Lower nibble — 4-bit part-select
data_byte[7:4]     // Upper nibble
axi_addr[31:24]    // Byte 3 (most significant byte)
```

**Standard convention:** `[MSB:LSB]` i.e., `[N-1:0]` with bit 0 as the LSB. Reversed ranges (`[0:N-1]`) are legal but confusing and should be avoided.

### 8.2 Arrays — Memory Banks

An **array** is a collection of variables (a memory). The depth specifier goes **after** the identifier name.

```verilog
//       [element_width] name    [depth]
reg      [7:0]           mem     [0:255];    // 256 × 8-bit = 2 Kbits of memory
reg      [31:0]          regfile [0:31];     // 32-entry × 32-bit register file
reg                      bit_mem [0:1023];   // 1024 single-bit cells

// Array read:  variable = array[address];
data_out = mem[addr_in];                     // Read byte from address 'addr_in'

// Array write (in procedural block):
always @(posedge clk) begin
    if (write_en) mem[write_addr] <= write_data;
end
```

### 8.3 2D Arrays — Banked Memories

```verilog
reg [7:0] cache [0:3][0:63];  // 4 banks × 64 locations × 8 bits = 2 Kbits
data = cache[bank_sel][line_addr];
```

> **🔥 Interview Trap — Array Assignment Bug**
>
> **Q: Can I copy an entire array to another with a single assignment like `memB = memA;`?**
>
> **No — this is illegal in standard Verilog (IEEE 1364).** Verilog does not support aggregate array assignment. Each element must be copied individually.
>
> ```verilog
> reg [7:0] memA [0:255];
> reg [7:0] memB [0:255];
>
> // ❌ ILLEGAL in Verilog-2005:
> memB = memA;   // Syntax error: arrays cannot be assigned as a whole
>
> // ✅ CORRECT: element-by-element copy (simulation only — NOT synthesizable)
> integer idx;
> initial begin
>     for (idx = 0; idx < 256; idx = idx + 1)
>         memB[idx] = memA[idx];
> end
> ```
>
> **SystemVerilog relaxation:** IEEE 1800 allows packed arrays of the same type and dimensions to be assigned with `=` when both are declared identically. But this is a SystemVerilog feature, not Verilog-2005, and is restricted to packed (contiguous bit-field) arrays — not unpacked memory arrays.
>
> In synthesized designs, memory initialization is handled by `$readmemh`/`$readmemb` in testbenches, or by reset FSMs and DMA controllers in RTL — never by bulk array assignment.

---

## 9. Strings — The Hardware Illusion

Verilog has **no dedicated string data type.** Strings exist only as ASCII character sequences stored in a `reg` vector wide enough to hold them. Each character occupies exactly 8 bits (one ASCII byte).

### 9.1 String Storage Rule

```
Required reg width = Number_of_characters × 8
Range: reg [(Chars × 8) - 1 : 0]
```

```verilog
// Storing the string "VLSI" (4 characters → 4 × 8 = 32 bits)
reg [31:0] label;
label = "VLSI";
// Storage (MSB to LSB): V='V'=8'h56, L='L'=8'h4C, S='S'=8'h53, I='I'=8'h49
// label = 32'h564C5349

// Storing "Hi" (2 characters → 16 bits)
reg [15:0] greeting;
greeting = "Hi";
// greeting = 16'h4869 ('H'=0x48, 'i'=0x69)

// Displaying strings in simulation:
initial $display("Label: %s | Hex: %h", label, label);
// Output: Label: VLSI | Hex: 564c5349
```

> **🔥 Interview Trap 1 — String Truncation**
>
> **Q: What happens if I store a 6-character string in a 32-bit (4-character) reg?**
>
> **The left-most (most significant) characters are silently truncated.** The reg stores only the rightmost N characters that fit.
>
> ```verilog
> reg [31:0] short_label;   // 32 bits = 4 characters maximum
> short_label = "SILICON";  // 7 characters = 56 bits — doesn't fit!
>
> // Truncation: only the RIGHTMOST 4 characters are retained
> // "SILICON" → drop 'S','I','L' → store "ICON"
> // short_label = 32'h49434F4E = "ICON"
>
> // No warning from most simulators. No error. "SIL" is silently gone.
> ```
>
> This is particularly dangerous when storing error codes, state names, or protocol identifiers in simulation — the meaningful prefix may be quietly dropped.

> **🔥 Interview Trap 2 — String Padding**
>
> **Q: What if the reg is larger than the string needs?**
>
> **The MSBs are padded with ASCII null characters (`8'h00`), not spaces.**
>
> ```verilog
> reg [63:0] wide_label;   // 64 bits = 8 characters
> wide_label = "AB";       // Only 2 characters = 16 bits
>
> // Padding: MSBs filled with 8'h00 (null bytes)
> // wide_label = 64'h0000000000004142  ('A'=0x41, 'B'=0x42)
> //              ├──────────────────┤  ├────────┤
> //              6 null bytes (pad)    "AB"
>
> // $display with %s will stop at the first printable character
> // but $display with %h reveals the null padding:
> $display("%s", wide_label);  // Prints: AB
> $display("%h", wide_label);  // Prints: 0000000000004142
> ```
>
> When comparing strings for equality, null-padded wider regs will NOT match narrower regs containing the same character content, even though they visually print identically.

---

## 10. Special Characters & Simulation Time

### 10.1 Special Character Reference

| Symbol | Name | Simulation Role | Synthesis Role |
|:---|:---|:---|:---|
| `#N` | Delay | Pause simulation by N time units | **Ignored** — synthesizer discards |
| `@(event)` | Event trigger | Block until signal event fires | Used structurally in `always` sensitivity lists |
| `$name` | System task | Simulator built-in (display, finish) | **Ignored** — not synthesized |
| `` `name `` | Directive | Preprocessor: define, ifdef, timescale | `` `define ``, `` `include `` apply pre-synthesis |
| `a ? b : c` | Ternary MUX | Conditional expression | Synthesizes to a 2:1 MUX |

### 10.2 Concatenation `{}` and Replication `{{N{}}}`

**Concatenation** joins bit vectors:
```verilog
wire [3:0] high  = 4'b1010;
wire [3:0] low   = 4'b0101;
wire [7:0] full  = {high, low};   // full = 8'b10100101
wire [2:0] flags = {carry, zero, overflow};  // Join individual bits into a bus
```

**Replication** repeats a value N times:
```verilog
wire [7:0] all_ones  = {8{1'b1}};      // 8'b11111111
wire [7:0] pattern   = {4{2'b10}};     // 8'b10101010
wire [15:0] sign_ext = {8{data[7]}, data}; // (see trap below)
```

> **🔥 Interview Trap 1 — Sign Extension via Replication**
>
> **Q: How do you correctly sign-extend a 4-bit signed number `a[3:0]` to 8 bits in Verilog without using `$signed()`?**
>
> **Use replication of the MSB (sign bit):**
>
> ```verilog
> wire signed [3:0]  a       = 4'sb1011;   // -5 in two's complement
> wire signed [7:0]  a_ext;
>
> // ❌ WRONG — zero extension loses the sign:
> // a_ext = {4'b0000, a};   // 8'b00001011 = +11 (wrong for negative input)
>
> // ✅ CORRECT — replicate the sign bit (MSB) 4 times:
> assign a_ext = {{4{a[3]}}, a};
> // a[3] = 1 (sign bit) → replicated 4 times → {1111, 1011} = 8'hFB = -5 ✅
>
> // For positive input (a = 4'b0101 = +5):
> // a[3] = 0 → replicated 4 times → {0000, 0101} = 8'h05 = +5 ✅
> ```
>
> This is the canonical, synthesizable sign-extension pattern. The replication `{4{a[3]}}` synthesizes to four wires tied to the same bit — zero hardware cost.

> **🔥 Interview Trap 2 — `time` vs `realtime`**
>
> **Q: What is the difference between the `time` and `realtime` data types?**
>
> | Property | `time` | `realtime` |
> |:---|:---|:---|
> | **Bit width** | 64-bit unsigned integer | 64-bit IEEE 754 double |
> | **Fractional delays** | **Rounded** to nearest time unit | **Preserved** as floating-point |
> | **`$time` system task** | Returns current simulation time as integer | N/A (use `$realtime`) |
> | **Use case** | General event timestamps, cycle counting | High-precision timing analysis |
>
> ```verilog
> `timescale 1ns / 100ps   // 1ns unit, 100ps precision
>
> time      t_int;
> realtime  t_real;
>
> #1.3;   // Delay of 1.3 time units = 1.3ns
>
> t_int  = $time;      // Rounded: t_int = 1 (fractional part dropped)
> t_real = $realtime;  // Exact:  t_real = 1.3
> ```

> **🔥 Interview Trap 3 — The `$time` Rounding Error**
>
> **Q: My testbench uses `$time` to measure a propagation delay, but I'm getting slightly wrong values. What could cause this?**
>
> **The `` `timescale `` precision setting is truncating your sub-unit delays.**
>
> `` `timescale <time_unit> / <time_precision> `` controls how finely the simulator tracks time. All delays are rounded to the nearest multiple of `<time_precision>`. If your precision is coarse and your design has sub-precision delays, `$time` returns a rounded (incorrect) value.
>
> ```verilog
> `timescale 1ns / 1ns   // ❌ 1ns precision — ALL delays rounded to whole nanoseconds
>
> #0.7;   // 0.7ns — rounded DOWN to 0ns (no delay!)
> #1.3;   // 1.3ns — rounded DOWN to 1ns
> #2.9;   // 2.9ns — rounded DOWN to 2ns
>
> // If your setup/hold requirement is 0.5ns and you're measuring with 1ns precision,
> // a 0.3ns violation is INVISIBLE — $time rounds it away.
> ```
>
> ```verilog
> `timescale 1ns / 1ps   // ✅ 1ps precision — delays resolved to 0.001ns granularity
>
> #0.7;   // 0.700ns — stored correctly ✅
> #1.3;   // 1.300ns — stored correctly ✅
> ```
>
> **Rule:** Always set time precision to at least 1/10 of your minimum delay of interest. For sub-nanosecond timing analysis (setup/hold margins in multi-GHz designs), use `1ns / 1fs` (femtosecond precision) or `1ps / 1fs`. Mismatched timescales across included files (a common issue in large multi-file designs) is a separate but equally dangerous source of simulation inaccuracies.

---

*Next → Module 5: The Anatomy of a Verilog Module & Instantiation*
