# Module 6: The Grammar of Silicon — Lexical Elements & Data Types

> **Module Level:** Advanced Reference | **Prerequisite:** Module 5 — Verilog Fundamentals  
> **Purpose:** A circuit-accurate, interview-hardened deep dive into Verilog's foundational grammar, syntax rules, and data type system. Every section ends with curated `🔥 Interview Trap` callouts sourced from real silicon design failures.

---

## Table of Contents

1. [Comments — The Designer's Intent](#1-comments--the-designers-intent)
2. [Identifiers — Naming the Hardware](#2-identifiers--naming-the-hardware)
3. [Keywords — The Reserved Lexicon](#3-keywords--the-reserved-lexicon)
4. [Ports — The Silicon Gateway](#4-ports--the-silicon-gateway)
5. [Number Representation — The Interview Minefield](#5-number-representation--the-interview-minefield)
6. [Data Types — Nets vs Variables](#6-data-types--nets-vs-variables)
7. [Handling `integer` and `real`](#7-handling-integer-and-real)
8. [Vectors vs Arrays — Buses vs Memories](#8-vectors-vs-arrays--buses-vs-memories)
9. [Strings — The Hardware Illusion](#9-strings--the-hardware-illusion)
10. [Special Characters & Simulation Time](#10-special-characters--simulation-time)

---

## 1. Comments — The Designer's Intent

### The Philosophy

In hardware design, a comment is not documentation for the *computer* — it is engineering intent preserved for the next human who must debug your silicon under a deadline. The cardinal rule of professional RTL commenting is:

> **Comments explain *WHY* the hardware is built that way, not *WHAT* the code mechanically does.**

A senior engineer reading `assign data_out = data_in & mask;` already knows what the AND gate does. What they *need* to know is:
- *Why is this mask needed? Is this a CDC (Clock Domain Crossing) qualifier?*
- *What happens to the downstream logic if this mask is removed?*

Poor commenting produces orphaned logic — gates and registers whose purpose is unknown, making refactoring impossible without risking a silicon re-spin.

### Single-Line Comments

The `//` token causes the lexer to ignore everything on the rest of that line. It is the preferred style for inline and single-thought annotations.

```verilog
// Toggle FF: captures the rising edge of the UART start bit
// This CANNOT be an async set/reset — spec section 4.2.1 forbids it
always @(posedge clk) begin
    q <= d;  // registered output — combinational path ends here
end
```

### Block (Multi-Line) Comments

The `/* ... */` token pair allows comments to span multiple lines. Useful for section headers, module-level documentation, and port list descriptions.

```verilog
/*
 * Module   : priority_encoder_8to3
 * Author   : Design Team A
 * Rev      : 1.2.0
 * Date     : 2026-04-19
 *
 * Description:
 *   Encodes the highest-priority active request from an 8-bit
 *   request bus into a 3-bit binary index. Index 7 is highest
 *   priority. Output is valid only when 'valid_o' is asserted.
 *
 * Assumptions:
 *   - Input is registered upstream; no glitch filtering needed here.
 *   - If all inputs are 0, output index is 0 and valid_o is LOW.
 */
module priority_encoder_8to3 (
    input  [7:0] req_i,    // active-high request bus
    output [2:0] index_o,  // encoded highest-priority index
    output       valid_o   // HIGH when at least one request is active
);
```

---

> ### 🔥 Interview Trap 1: Nested Block Comments
>
> **Question:** *"What happens when you nest a block comment inside another block comment?"*
>
> **Answer:** Verilog's block comments **do not nest**. The lexer is a simple state machine — it enters comment mode on `/*` and **exits on the very first `*/`** it encounters, regardless of depth.
>
> **Dangerous Example:**
> ```verilog
> /* Outer comment begin
>    /* Inner comment — this does NOT work */
>    assign x = a & b;   // ← This line is now LIVE CODE, not commented
> */                      // ← This is now a SYNTAX ERROR
> ```
> The inner `*/` terminates the outer `/*`. Everything after it — including live RTL assignments — is now compiled. The closing `*/` becomes an orphaned token and causes a **syntax cascade**: the parser reports errors on lines *far* below where the actual problem is, making this one of the most time-consuming bugs to track during tape-out debugging.
>
> **The Rule:** Never nest block comments. Use `//` for inner annotations inside a `/* */` block.

---

> ### 🔥 Interview Trap 2: The Safe Way to Disable Large Logic Blocks
>
> **Question:** *"You need to completely comment out 200 lines of experimental logic during regression. Block comments are unsafe. What's the professional approach?"*
>
> **Answer:** Use **Compiler Directives** — specifically `` `ifdef `` / `` `ifndef `` macros. This is the industry-standard technique used by every RTL library and IP vendor.
>
> ```verilog
> `ifdef ENABLE_EXPERIMENTAL_LOGIC
>     // This entire block is invisible to the compiler unless the
>     // macro is explicitly defined. Zero risk of syntax corruption.
>     always @(posedge clk) begin
>         // ... 200 lines of experimental logic ...
>         exp_out <= complex_function(data_in);
>     end
> `endif
> ```
>
> To activate: compile with `` `define ENABLE_EXPERIMENTAL_LOGIC `` at the top of the file, or pass `-DENABLE_EXPERIMENTAL_LOGIC` to your simulator (VCS/ModelSim/Xcelium). This technique is also used for **technology-specific synthesis paths** (e.g., ASIC vs FPGA behavioral differences), **debug instrumentation** (assertions, `$display` logging), and **feature flags** in large design subsystems.

---

## 2. Identifiers — Naming the Hardware

### The Strict Lexical Rules

An **identifier** is the name given to any hardware object: modules, ports, wires, registers, parameters, generate blocks, tasks, and functions. The Verilog LRM (Language Reference Manual) specifies that identifiers obey the following rules without exception:

1. **Must begin with:** An uppercase letter (`A–Z`), a lowercase letter (`a–z`), or an underscore (`_`).
2. **Cannot begin with:** A decimal digit (`0–9`) or a dollar sign (`$`). Dollar-prefixed names are reserved for system tasks and functions.
3. **Subsequent characters may include:** Letters, digits, underscores, and dollar signs (after the first character).
4. **Maximum length:** Implementation-defined, but the LRM recommends tools support at least 1024 characters.
5. **Case-sensitive:** `Reset` and `reset` are two completely different, unrelated identifiers.

### Valid vs. Invalid Identifier Table

| Identifier | Valid? | Reason |
|---|---|---|
| `clk_25mhz` | ✅ Valid | Starts with letter, uses only legal characters |
| `_n_reset` | ✅ Valid | Underscore is a legal first character |
| `data_out_q` | ✅ Valid | Standard registered-output convention |
| `FSM_STATE_IDLE` | ✅ Valid | All-caps constants are conventional |
| `8b_fifo` | ❌ Invalid | Starts with a digit |
| `$clk` | ❌ Invalid | `$` is reserved for system tasks |
| `my-wire` | ❌ Invalid | Hyphen `-` is not a legal identifier character |
| `module` | ❌ Invalid | Reserved keyword |

### Standard Industry Naming Conventions

Professional RTL design teams enforce naming conventions via lint rules (Spyglass, Ascent Lint). The most widely adopted conventions are:

| Convention | Meaning | Example |
|---|---|---|
| `_n` or `_b` suffix | Active-LOW signal | `rst_n`, `cs_n`, `oe_b` |
| `_q` suffix | Registered (flip-flop) output | `data_q`, `count_q` |
| `_d` suffix | Next-state (D-input of FF) | `data_d`, `count_d` |
| `clk_` prefix | Clock signal | `clk_sys`, `clk_mem` |
| `i_` / `o_` prefix | Module input / output | `i_data`, `o_valid` |
| `_c` suffix | Combinational logic output | `sum_c`, `carry_c` |
| `UPPERCASE` | Parameters and constants | `DATA_WIDTH`, `FIFO_DEPTH` |
| `sm_` prefix | State machine signals | `sm_state`, `sm_next` |

---

> ### 🔥 Interview Trap 1: Strict Case-Sensitivity
>
> **Question:** *"A module instantiation fails at simulation with 'port connection mismatch'. You see `Reset` used in the testbench and `reset` in the DUT. Is that the bug?"*
>
> **Answer:** **Yes, absolutely.** Verilog is case-sensitive at the lexical level. `Reset`, `RESET`, and `reset` are three distinct, unrelated identifiers that the compiler treats as three separate wires.
>
> ```verilog
> // DUT Module Definition
> module dut (input reset, ...);  // declares identifier 'reset' (lowercase)
>
> // Testbench Instantiation
> dut u_dut (.Reset(rst_tb), ...); // 'Reset' != 'reset' — port NOT connected!
>                                  // 'Reset' is an unresolved reference → WARNING or ERROR
> ```
>
> This is an insidious bug in large designs where hundreds of ports are connected. Modern lint tools flag this as a **port-name mismatch** error, but a sloppy flow can miss it until simulation produces X-propagation failures. Always enforce a lowercase-only convention for all non-constant identifiers.

---

> ### 🔥 Interview Trap 2: Escaped Identifiers
>
> **Question:** *"You open a synthesized netlist and see `\carry_lookahead[4] `. What is that backslash? Is this a Verilog error?"*
>
> **Answer:** That is an **Escaped Identifier** — a legal Verilog construct that allows *any printable ASCII character sequence* (including illegal characters like brackets, dots, and spaces) to be used as an identifier name, provided it is prefixed with a backslash `\` and terminated with a **mandatory whitespace character**.
>
> ```verilog
> wire \carry[4] ;      // Legal escaped identifier. Note the space before ';'
> wire \my module.out ; // Legal — includes a dot and space in the name
>
> assign \carry[4]  = a[4] & b[4]; // Must use the escape in every reference
> ```
>
> **Why do synthesis tools generate these?**  
> EDA tools (Synopsys DC, Cadence Genus) internally mangle signal names during optimization, inserting hierarchy separators (`/`), bit-indices (`[n]`), and clone suffixes that would be syntactically illegal without escaping. You will see escaped identifiers extensively in:
> - Gate-level netlists (post-synthesis)
> - SDF (Standard Delay Format) annotation files
> - Place-and-Route DEF files
>
> **Critical Rule:** The terminating whitespace is **part of the identifier's syntax**, not cosmetic. An escaped identifier without a trailing space causes a lexer error.

---

## 3. Keywords — The Reserved Lexicon

### The Golden Rule

> **Every standard Verilog keyword is strictly lowercase.**

This is a direct consequence of Verilog's case-sensitive lexer. The language has no uppercase reserved words. The complete list of Verilog-2001 keywords is defined in Annex B of the IEEE 1364-2001 standard.

### Keyword Category Table

| Category | Keywords |
|---|---|
| **Structural** | `module`, `endmodule`, `input`, `output`, `inout`, `parameter`, `localparam`, `instance`, `generate`, `endgenerate`, `port` |
| **Data Types** | `wire`, `reg`, `integer`, `real`, `realtime`, `time`, `supply0`, `supply1`, `tri`, `wand`, `wor`, `trireg` |
| **Procedural** | `always`, `initial`, `begin`, `end`, `if`, `else`, `case`, `casex`, `casez`, `endcase`, `for`, `while`, `repeat`, `forever`, `fork`, `join` |
| **Assignment** | `assign`, `force`, `release`, `deassign` |
| **Timing** | `posedge`, `negedge`, `wait` |
| **Functions/Tasks** | `function`, `endfunction`, `task`, `endtask`, `automatic` |
| **Primitives** | `and`, `or`, `not`, `nand`, `nor`, `xor`, `xnor`, `buf`, `bufif0`, `bufif1`, `notif0`, `notif1`, `pullup`, `pulldown` |
| **Specify** | `specify`, `endspecify`, `specparam`, `$setup`, `$hold` |

---

> ### 🔥 Interview Trap 1: The Capitalization Loophole
>
> **Question:** *"Does `wire Reg;` compile in Verilog? What does it declare?"*
>
> **Answer:** **Yes, it compiles perfectly — and that is exactly the danger.**  
> Since `Reg` (capital R) is not the keyword `reg` (lowercase), the compiler treats `Reg` as a perfectly legal user-defined identifier for a `wire` type.
>
> ```verilog
> wire Reg;    // Compiles! 'Reg' is a wire named "Reg", NOT the keyword 'reg'
> wire Wire;   // Also compiles! A wire named "Wire"
> wire Input;  // A wire named "Input" — entirely legal, entirely horrible practice
> ```
>
> This passes synthesis, passes simulation, and produces a correct netlist. The danger is purely human: the next engineer reading the code sees `Reg` and assumes it is a `reg`-type variable, leading to gross misunderstandings of the data flow. **Lint tools flag this as a style violation (W-level warning)**. Never name signals with capitalised versions of keywords.

---

> ### 🔥 Interview Trap 2: System Tasks and Directives Are NOT Keywords
>
> **Question:** *"Is `$display` a Verilog keyword? What about `` `define ``?"*
>
> **Answer:** **Neither is a standard keyword** as defined by the LRM. They belong to separate namespaces:
>
> - **System Tasks/Functions** (`$display`, `$monitor`, `$finish`, `$random`, `$fopen`, `$time`): These are predefined system-level routines provided by the simulator. They are distinguished by the leading `$`. They exist in simulation context only and most are **not synthesizable**.
>
> - **Compiler Directives** (`` `define ``, `` `include ``, `` `timescale ``, `` `ifdef ``, `` `undef ``): These are preprocessor macros, distinguished by the backtick `` ` ``. They are processed *before* lexical analysis begins, in a separate preprocessing phase. They are not keywords; they are text-substitution instructions to the compiler.
>
> | Token | Category | Synthesizable? |
> |---|---|---|
> | `wire`, `reg`, `always` | Standard Keyword | ✅ Yes |
> | `$display`, `$finish` | System Task | ❌ No (simulation only) |
> | `` `define ``, `` `timescale `` | Compiler Directive | N/A (preprocessor) |

---

> ### 🔥 Interview Trap 3: The `reg` Misconception
>
> **Question:** *"Does declaring a signal as `reg` mean it will synthesize to a flip-flop?"*
>
> **Answer:** **Absolutely not.** This is one of the most prevalent misconceptions in entry-level Verilog interviews, and it costs engineers dearly in synthesis reviews.
>
> `reg` is a **procedural variable type** — it simply means the signal can be assigned a value inside a procedural block (`always`, `initial`). Whether it synthesizes to a **flip-flop** or **combinational logic** is determined *entirely by the sensitivity list and assignment structure*, not by the `reg` keyword.
>
> ```verilog
> // 'q' is declared reg — but synthesizes to COMBINATIONAL LOGIC (a mux)
> reg q;
> always @(*) begin   // Sensitivity list: all inputs — purely combinational
>     q = a & b;      // Blocking assignment, no clock edge → MUX/gate, not FF
> end
>
> // 'q' is declared reg — and synthesizes to a FLIP-FLOP
> reg q;
> always @(posedge clk) begin  // Sensitivity list: clock edge only → FF inferred
>     q <= d;                   // Non-blocking assignment on clock edge → D-FF
> end
> ```
>
> **The synthesis rules:**
> - `always @(posedge clk)` + `reg` → **D-type Flip-Flop**
> - `always @(*)` + `reg` → **Combinational Logic** (LUT on FPGA)
> - `reg` in `initial` block → **Simulation-only** (not synthesizable)

---

## 4. Ports — The Silicon Gateway

### Port Direction to Type Mapping

Ports are the physical I/O boundaries of a module — the pins of the silicon die. Each port direction has strict rules about what net/variable type it may assume, because these rules map directly to the physical hardware's driving capability.

| Port Direction | Legal Type | Default Type | Physical Meaning |
|---|---|---|---|
| `input` | `wire` only | `wire` | Receives signal; cannot drive |
| `output` | `wire` or `reg` | `wire` | Drives signal outward |
| `inout` | `wire` only | `wire` | Bi-directional; requires tri-state |

```verilog
module spi_slave (
    input             clk,        // input → wire (default, no type needed)
    input             mosi,       // data from master
    input             cs_n,       // chip select, active low
    output reg  [7:0] rx_data,    // reg: driven from always block
    output wire       rx_valid,   // wire: driven from assign statement
    inout             sda         // must be wire: needs tri-state capability
);
    // Tri-state assignment for inout port
    wire sda_oe;    // output enable
    wire sda_out;   // data to drive onto bus
    
    assign sda = sda_oe ? sda_out : 1'bZ; // Drive or release to Hi-Z
    
endmodule
```

### The `output reg` Pattern

When a port's value is generated inside an `always` block, it *must* be declared `reg`. The `output reg` combined declaration is Verilog-2001 syntax (ANSI-style port declaration) and is universally preferred over the older, separated declaration style.

```verilog
// Old-style (Verilog-1995) — verbose and error-prone
module old_style(clk, data_out);
    input clk;
    output data_out;
    reg data_out;    // separate declaration required
    ...

// New-style (Verilog-2001 ANSI) — preferred in all modern RTL
module new_style (
    input        clk,
    output reg   data_out  // direction + type in one declaration
);
```

---

> ### 🔥 Interview Trap 1: Driving an Input Port
>
> **Question:** *"What happens if you write `assign clk = 1'b0;` inside a module that has `input clk`?"*
>
> **Answer:** This is a **fundamental violation of hardware semantics** and is illegal in Verilog.  
> An `input` port is, by definition, a receiver. It models a physical pad or pin where the signal originates *outside* the module. Assigning to it from within the module would mean trying to drive a signal that has an external source — creating a **multiple-driver conflict** on the net.
>
> ```verilog
> module illegal_drive (input clk, output q);
>     assign clk = 1'b0;  // ILLEGAL: 'clk' is an input — it has an external driver
>                         // Simulator: X or warning. Synthesizer: ERROR
>     always @(posedge clk) q <= ~q;
> endmodule
> ```
>
> Simulators may issue a warning and resolve to `X`. Synthesis tools will **reject this with an error**. The physical reason: you cannot fight the external clock buffer driving the chip's clock pad from inside the core logic.

---

> ### 🔥 Interview Trap 2: The `inout` Synthesis Myth
>
> **Question:** *"A junior engineer uses `inout` to create internal module-to-module connections on an FPGA, arguing it saves wires. Will it work?"*
>
> **Answer:** **No. This will fail in synthesis on all major FPGA families (Xilinx, Intel/Altera).** This is a critical misconception about what `inout` physically means.
>
> **The Hardware Reality:**  
> `inout` is synthesizable **only at the top-level I/O boundary** of a design, where it maps to a physical **Tri-State I/O buffer (IOB)**. The circuit model is:
>
> ```verilog
> // The ONLY synthesizable pattern for inout
> module i2c_master (
>     inout sda,      // Physical I2C data line (open-drain bus)
>     input sda_en,   // Output enable from controller
>     input sda_out   // Data to transmit
> );
>     // MANDATORY: Tri-state buffer assignment
>     assign sda = sda_en ? sda_out : 1'bZ;  // Drive or release to Hi-Z
>     
>     wire sda_in = sda;  // Reading back the bus state
> endmodule
> ```
>
> **Why internal `inout` is prohibited on FPGAs:**  
> FPGA routing fabrics use **dedicated unidirectional routing tracks**. There is no physical mechanism for a routed internal connection to go high-impedance — only the IOBs at the chip boundary have tri-state buffers. Synthesis tools will either **error out** or silently **corrupt the design** by substituting incorrect logic. The synthesizer cannot place a tri-state buffer in the middle of the fabric.
>
> For internal bus arbitration that needs tri-state semantics, use a **multiplexer** instead.

---

## 5. Number Representation — The Interview Minefield

### The 4-State Logic System

Verilog models real silicon behavior with four distinct logic states:

| State | Symbol | Physical Meaning | Source |
|---|---|---|---|
| Logic Zero | `0` | Driven LOW (GND connection) | Active driver |
| Logic One | `1` | Driven HIGH (VDD connection) | Active driver |
| Unknown | `X` | Contention or uninitialized | Multiple drivers / no reset |
| High Impedance | `Z` | Floating — not driven by anyone | Tri-state / disconnected |

`X` is the most dangerous state in simulation. It propagates through logic like a cancer — `1 & X = X`, `0 | X = X` — and can cause entire datapaths to become unknown if any register is left uninitialized. In physical silicon, `X` does not exist; every node is either `0` or `1`. The gap between `X` in simulation and resolved states in silicon is a leading cause of **simulation-synthesis mismatches (sim-synth divergence)**.

### Formal Number Syntax

The complete formal syntax for a Verilog literal is:

```
<size>'<signed_flag><base><value>
```

| Field | Description | Options |
|---|---|---|
| `<size>` | Bit-width of the literal (decimal integer) | Any positive integer |
| `'` | Mandatory separator tick | — |
| `<signed_flag>` | Optional: marks as signed | `s` or `S` |
| `<base>` | Number system | `b/B` (binary), `o/O` (octal), `d/D` (decimal), `h/H` (hex) |
| `<value>` | The digits, `x`, `z`, or `_` for readability | Format-dependent |

```verilog
// Standard literal examples
8'b1010_0011    // 8-bit binary: underscores for readability (ignored by compiler)
8'hA3           // 8-bit hex: same value as above
8'd163          // 8-bit decimal: same value
12'o243         // 12-bit octal
16'hDEAD        // 16-bit hex: classic debug pattern
8'bxxxx_1010    // 8-bit: upper nibble is UNKNOWN (X state)
8'bz000_0001    // 8-bit: MSB is Hi-Z
16'sb1000_0000_0000_0000  // 16-bit SIGNED binary: -32768 in 2's complement
```

---

> ### 🔥 Interview Trap 1: The Bloated ALU — Unsized Numbers
>
> **Question:** *"You write `assign result = data + 5;` where `data` is an 8-bit wire. What is the bit-width of the literal `5`? What are the consequences?"*
>
> **Answer:** The literal `5` is an **unsized decimal number**. Per the Verilog LRM, unsized numbers default to the **host machine's integer width — typically 32 bits**.
>
> This means the addition `data + 5` is computed as:
> - `data` zero-extended to 32 bits
> - `5` as a 32-bit integer
> - Result is 32 bits
>
> **The Silicon Consequences:**
> 1. **Synthesis Explosion:** A synthesis tool sees a 32-bit addition and generates a **32-bit ripple-carry or carry-lookahead adder** — consuming hundreds of LUTs/cells for what should be a simple 8-bit operation.
> 2. **Unexpected Truncation:** If `result` is declared as `reg [7:0]`, the 32-bit result is *silently truncated to 8 bits* (MSBs dropped), which may or may not be correct depending on the datapath.
>
> ```verilog
> // WRONG: 32-bit adder inferred, then truncated
> wire [7:0] result;
> assign result = data + 5;    // 5 = 32'h00000005 → wasteful, risky
>
> // CORRECT: Explicitly sized literal
> assign result = data + 8'd5; // 8-bit addition → correct-width adder
> ```
>
> **Rule:** Always size your literals. This is one of the most common causes of area bloat caught in synthesis reviews.

---

> ### 🔥 Interview Trap 2: Size Mismatches — Truncation and Extension
>
> **Question:** *"What happens when you assign a 12-bit value to an 8-bit register? What about assigning a 4-bit value to an 8-bit register?"*
>
> **Answer:** The Verilog LRM defines two behaviors for bit-width mismatches:
>
> **Case 1: Value is WIDER than target → Silent Truncation (MSBs dropped)**
> ```verilog
> reg [7:0] byte_reg;
> assign byte_reg = 12'hABC;  // 12-bit: 1010_1011_1100
>                              // 8-bit result: 1011_1100 = 8'hBC
>                              // The upper nibble 'A' is SILENTLY LOST
>                              // No warning issued by most simulators!
> ```
>
> **Case 2: Value is NARROWER than target → Extension (type depends on MSB)**
>
> | MSB of Source | Extension Type | Padding Bits |
> |---|---|---|
> | `0` or `1` | Zero-extension | Fills with `0` |
> | `x` (Unknown) | X-extension | Fills with `x` |
> | `z` (Hi-Z) | Z-extension | Fills with `z` |
>
> ```verilog
> reg [7:0] byte_reg;
>
> byte_reg = 4'b1010;   // MSB=1 → Zero-extend → 8'b0000_1010 ✓
> byte_reg = 4'bx101;   // MSB=x → X-extend    → 8'bxxxx_x101 ⚠ X PROPAGATION!
> byte_reg = 4'bz011;   // MSB=z → Z-extend    → 8'bzzzz_z011 ⚠ Hi-Z PROPAGATION!
> ```
>
> The X/Z-extension case is a **hidden simulation bomb**: a 4-bit value with an unknown MSB suddenly poisons the upper 4 bits of your 8-bit register with unknowns.

---

> ### 🔥 Interview Trap 3: Negative Number Representation
>
> **Question:** *"How do you write the decimal value -5 as a signed 8-bit Verilog literal? Where does the minus sign go?"*
>
> **Answer:** Negative literals use **two's complement representation**. The minus sign is an **operator applied to the entire sized literal** — it must appear *before* the size specification, not between the size and the base.
>
> ```verilog
> // CORRECT: minus sign goes BEFORE the size
> reg signed [7:0] val;
> val = -8'd5;     // ✅ -5 in 8-bit 2's complement = 8'b1111_1011 = 8'hFB
>
> // TECHNICALLY LEGAL but confusing — avoid:
> val = 8'sb1111_1011; // Explicit 2's complement encoding — verbose but unambiguous
>
> // WRONG — syntax error:
> val = 8'-d5;   // ❌ Illegal position for minus sign
> ```
>
> **The 2's Complement Mechanics:**  
> `-8'd5` in hardware means: invert all bits of `8'd5` and add 1.  
> `8'd5` = `0000_0101` → Invert → `1111_1010` → Add 1 → `1111_1011` = `8'hFB`
>
> **Critical warning:** If you assign `-8'd5` to an *unsigned* `reg`, the bit pattern `8'hFB` is stored, but interpreted as **251** (not -5) in any unsigned arithmetic operation. Always declare signed registers and use the `signed` modifier on ports and operations that process two's complement data.

---

## 6. Data Types — Nets vs Variables

### The Fundamental Dichotomy

Verilog's type system has a clean conceptual split that mirrors physical hardware. Understanding this split is the foundation of all RTL reasoning:

| Category | Keyword(s) | Physical Model | Default Value | Assignment Context |
|---|---|---|---|---|
| **Net** | `wire`, `wand`, `wor`, `supply0`, `supply1`, `tri`, `trireg` | Physical wire/connection | `Z` (floating) | `assign` statements, port connections |
| **Variable** | `reg`, `integer`, `real`, `time` | Procedural storage element | `X` (unknown) | `always`, `initial`, `task`, `function` blocks |

### Net Types In Depth

Nets model physical conductors. They have no memory — their value is *continuously computed* from whatever drives them.

```verilog
wire data_bus;          // Standard unresolved wire: one driver expected
wire [31:0] addr;       // 32-bit bus

// Resolved Net Types (multiple driver semantics)
wand  open_drain;       // Wired-AND: multiple drivers → AND all values
                        // Used for: open-drain I2C, JTAG buses

wor   bus_req;          // Wired-OR: multiple drivers → OR all values
                        // Used for: shared request lines, interrupt collectors

supply1 vdd;            // Permanently tied to logic 1 (VDD)
supply0 gnd;            // Permanently tied to logic 0 (GND)

trireg capacitive_node; // Retains last driven value when all drivers go Hi-Z
                        // Models: capacitive coupling, bus hold circuits
```

**Default Net Value:** `Z` — because a wire that no one is driving is physically floating (high-impedance). This is physically accurate.

### Variable Types In Depth

Variables model storage. They retain their last assigned value until explicitly changed.

```verilog
reg          flag;          // 1-bit storage, default value: X (unknown)
reg [7:0]    data_byte;     // 8-bit unsigned, default: 8'bXXXX_XXXX
reg signed [15:0] acc;      // 16-bit signed accumulator
integer      loop_idx;      // 32-bit signed — for loop counters only
```

**Default Variable Value:** `X` — because an uninitialised flip-flop or register in real silicon has an indeterminate power-up state. This is physically accurate and important for reset analysis.

---

> ### 🔥 Interview Trap 1: Multiple Drivers on a Standard `wire`
>
> **Question:** *"Two `assign` statements drive the same `wire`. What value does the wire take in simulation? What happens in synthesis?"*
>
> **Answer:** This is one of the most dangerous bugs in RTL design — a **multiple-driver conflict**.
>
> ```verilog
> wire out;
> assign out = a & b;  // Driver 1
> assign out = c | d;  // Driver 2 — ← BUG: two continuous assignments to same wire
> ```
>
> **In Simulation:** Verilog applies resolution logic. For a standard `wire`:
> - If both drivers agree (both `0` or both `1`) → that value
> - If drivers disagree (one drives `0`, other drives `1`) → **`X` (contention/short circuit)**
>
> **In Synthesis:** The synthesizer may:
> - Emit an **error** and abort
> - Infer a **bus contention** condition and generate a warning
> - Silently generate **incorrect gate-level logic**
>
> The physical analog is a **short circuit between two logic gates** — in real silicon, this would cause excessive current draw and potential device damage (latch-up). Use `wor`/`wand` only if multi-driver semantics are intentional and understood.

---

> ### 🔥 Interview Trap 2: Mixing Signed and Unsigned Operations
>
> **Question:** *"You have `reg signed [7:0] a = -5;` and `reg [7:0] b = 200;`. What does `a + b` evaluate to?"*
>
> **Answer:** **The result is computed as unsigned arithmetic, destroying the signed semantics of `a`.**
>
> The Verilog LRM Rule: **If any operand in an expression is unsigned, the entire expression is treated as unsigned.**
>
> ```verilog
> reg signed   [7:0] a = -8'd5;   // Stored as 8'hFB (251 unsigned, -5 signed)
> reg unsigned [7:0] b = 8'd200;  // Stored as 8'hC8
>
> // Expression: a + b
> // LRM forces UNSIGNED context because 'b' is unsigned
> // -5 (0xFB = 251) treated as 251, not -5
> // Result: 251 + 200 = 451 → truncated to 8 bits → 451 - 256 = 195 = 0xC3
>
> // What you likely INTENDED: -5 + 200 = 195 (which happens to be numerically correct here,
> // but for other inputs the semantic difference causes wrong results!)
> ```
>
> **The Fix:** Explicitly cast or ensure all operands in a signed expression are declared `signed`:
> ```verilog
> wire signed [8:0] result = $signed(a) + $signed(b); // Control the signedness explicitly
> ```
>
> This is a **silent bug** — no simulator warning is issued. It only manifests as wrong simulation results on specific input patterns, making it extremely difficult to catch during directed testing.

---

## 7. Handling `integer` and `real`

### `integer` — The Loop Counter Type

`integer` is a 32-bit **signed** variable type built into Verilog. It is a convenient shorthand for `reg signed [31:0]` but carries important semantic restrictions.

```verilog
integer i;         // 32-bit signed, initialized to 0 at simulation start
integer byte_cnt;  // Use only for behavioral counting, not RTL datapaths
```

**The canonical and sole legitimate use of `integer` in synthesizable RTL is as a `for` loop index:**

```verilog
// Correct use: loop counter in generate or always block
parameter WIDTH = 8;
reg [WIDTH-1:0] reversed;
integer i;

always @(*) begin
    for (i = 0; i < WIDTH; i = i + 1) begin
        reversed[i] = data_in[WIDTH-1-i];  // Bit-reversal logic
    end
end
```

**Why `integer` is not for datapaths:**
1. It is always 32 bits — you cannot control its width for area optimization.
2. It is always signed — may produce unexpected sign-extension in mixed expressions.
3. Synthesis tools **will** synthesize `integer`-based arithmetic, but the resulting circuits are 32 bits wide regardless, causing massive area waste identical to the unsized-literal problem.

### `real` — The Floating Point Illusion

`real` is a 64-bit IEEE 754 double-precision floating-point variable. It is purely a **simulation construct** for modeling analog behaviors, reference models, and mathematical testbench calculations.

```verilog
real pi = 3.14159265358979;
real period_ns;
real duty_cycle;

initial begin
    period_ns = 1.0e9 / 100.0e6;  // 10.0 ns period for 100 MHz clock
    duty_cycle = 0.5;              // 50% duty cycle
    #(period_ns * duty_cycle) clk = ~clk;
end
```

---

> ### 🔥 Interview Trap 1: Synthesizing Floating Point
>
> **Question:** *"An intern declares `real gain = 1.5;` and uses it in an `assign` statement. What happens during synthesis?"*
>
> **Answer:** **The synthesis tool will reject it or silently produce incorrect results.** `real` is **completely un-synthesizable** in standard Verilog/SystemVerilog flows.
>
> There is no standard cell library in any ASIC PDK or FPGA primitive library that implements IEEE 754 floating-point arithmetic directly from a `real` variable assignment. The synthesis tool has no physical representation to map it to.
>
> **The Professional Solution: Fixed-Point Arithmetic**  
> Real hardware that requires fractional values uses **fixed-point representation** — a standard `reg` vector where the binary point is implicitly placed by the designer.
>
> ```verilog
> // Example: Q4.4 fixed-point format (4 integer bits, 4 fractional bits)
> // Value 1.5 = 1 + 0.5 = 0001.1000 in binary = 8'b0001_1000
>
> parameter SCALE = 4;  // 4 fractional bits: divide by 2^4 = 16 to get real value
>
> reg [7:0] gain_fixed = 8'b0001_1000;  // Represents 1.5 in Q4.4 format
> reg [7:0] data_in;
> reg [15:0] result_raw;  // 16-bit to hold full precision of multiplication
>
> always @(*) begin
>     result_raw = data_in * gain_fixed;       // 8x8 = 16-bit product
>     data_out   = result_raw[11:4];           // Shift right by SCALE bits → divide by 16
>                                              // Extracts the Q4.4 integer portion
> end
> ```
>
> Fixed-point DSP design is a discipline unto itself, involving careful management of dynamic range, overflow, and quantization error — but it is the *only way* to do fractional arithmetic in synthesizable RTL.

---

## 8. Vectors vs Arrays — Buses vs Memories

### The Critical Syntactic Difference

Verilog distinguishes between **parallel data buses** (vectors) and **sequential storage arrays** (memories) through the *position* of the range declaration relative to the identifier name. This positional rule is one of the most confusing aspects of Verilog for newcomers.

### Vectors — Data Buses

The range specifier goes **before the name**:

```verilog
// Syntax: reg [MSB:LSB] name;
reg  [7:0]   data_byte;      // 8-bit bus, MSB is bit 7
reg  [31:0]  alu_result;     // 32-bit ALU output bus
wire [15:0]  address_bus;    // 16-bit address wire
reg  [0:7]   big_endian_data;// Range reversed: bit 0 is MSB (big-endian convention)
```

**Accessing Vectors:**
```verilog
data_byte[7]     // Single bit—the MSB
data_byte[3:0]   // Part-select: lower nibble
data_byte[7:4]   // Part-select: upper nibble

// Variable Part-Select (Verilog-2001): Essential for parameterized RTL
reg [3:0] sel;
data_byte[sel*2 +: 2]   // Selects 2 bits starting at bit (sel*2): ascending
data_byte[sel*2+1 -: 2] // Selects 2 bits ending at bit (sel*2+1): descending
```

### Arrays — Memory Banks

The depth specifier goes **after the name**:

```verilog
// Syntax: reg [MSB:LSB] name [start:end];
reg [7:0]  mem_256x8  [0:255];    // 256 entries of 8-bit width = 2KB memory
reg [31:0] rf_32x32   [0:31];     // 32-entry, 32-bit register file
reg [0:0]  bit_array  [0:1023];   // 1024 single-bit storage elements
reg [7:0]  fifo_buffer[0:15];     // 16-deep byte FIFO

// Multi-dimensional array (Verilog-2001+)
reg [7:0]  cache_2d   [0:3][0:7]; // 4 rows × 8 columns of bytes
```

**Accessing Arrays:**
```verilog
mem_256x8[0]         // Read entry 0 — full 8-bit word
mem_256x8[255]       // Read last entry — full 8-bit word
mem_256x8[addr][3:0] // Read lower nibble of entry at 'addr'
mem_256x8[i] = data; // Write entry i with 'data'
```

---

> ### 🔥 Interview Trap: The Array Assignment Bug
>
> **Question:** *"Given two 256×8 memories `memA` and `memB`, can you copy the entire contents with `memA = memB`?"*
>
> **Answer:** **No. This is illegal in standard Verilog (IEEE 1364-2001) and will cause a compile error.**
>
> Unlike variables and vectors, **whole arrays cannot be assigned as a single operation** in Verilog. There is no datapath structure that could implement a bulk array copy in a single clock cycle anyway — it's not a hardware-realizable operation.
>
> ```verilog
> reg [7:0] memA [0:255];
> reg [7:0] memB [0:255];
>
> // ILLEGAL in standard Verilog:
> memA = memB;  // ❌ Error: array assignment not supported
>
> // CORRECT: Use a loop (synthesizes to a state machine or multi-cycle operation)
> integer i;
> always @(posedge clk) begin
>     if (copy_en) begin
>         for (i = 0; i < 256; i = i + 1)
>             memA[i] <= memB[i];  // Copies one entry per clock cycle... for 256 cycles
>     end
> end
> // Note: The above loop in hardware copies ALL entries simultaneously in one cycle
> // because synthesis unrolls for-loops into parallel logic. For a true sequential
> // copy, you need an explicit counter-based state machine.
> ```
>
> **SystemVerilog** (IEEE 1800) relaxes this restriction slightly with packed arrays and direct array assignment in specific contexts — but in standard Verilog RTL, array-level assignment is always element-by-element.

---

## 9. Strings — The Hardware Illusion

### The Core Reality: Verilog Has No String Type

Standard Verilog has no native string data type as found in software languages. There is no `string` keyword, no `strlen()`, no null-termination, and no dynamic string allocation. **Strings in Verilog are a simulation convenience stored as packed ASCII integers in `reg` vectors.**

### Storage Model

Each character occupies exactly **8 bits** (one byte), following the 7-bit ASCII encoding with the MSB unused. The width formula for a `reg` that holds an N-character string is:

```
bit_width = (number_of_characters × 8) - 1
```

Wait — more precisely, the `reg` declaration must be `[(N*8)-1 : 0]` to hold N characters.

```verilog
// Storing "HI" — 2 characters × 8 bits = 16-bit reg
reg [15:0] greeting;
greeting = "HI";           // Stored as: 8'h48 (H) concatenated with 8'h49 (I)
                           // greeting = 16'h4849

// Storing "VLSI" — 4 characters × 8 bits = 32-bit reg
reg [31:0] label;
label = "VLSI";            // 8'h56 8'h4C 8'h53 8'h49 = 32'h564C5349

// Using strings in simulation (NOT synthesizable)
$display("Module: %s, Value: %0d", label, data_out);
```

**Character-by-Character Access:**
```verilog
reg [31:0] word = "VLSI";
// word[31:24] = "V" = 8'h56  (Most significant character)
// word[23:16] = "L" = 8'h4C
// word[15:8]  = "S" = 8'h53
// word[7:0]   = "I" = 8'h49  (Least significant character)
```

---

> ### 🔥 Interview Trap 1: String Truncation
>
> **Question:** *"You declare `reg [15:0] chip_id = "ASIC_v2";`. What happens? What is stored?"*
>
> **Answer:** **Silent left-truncation.** The literal `"ASIC_v2"` is 7 characters = 56 bits. The `reg` is only 16 bits. Since strings are right-justified in the register (the rightmost character is at the LSBs), all characters **beyond the rightmost 2 are silently dropped** — the most significant characters are chopped off with **no warning**.
>
> ```verilog
> reg [15:0] chip_id = "ASIC_v2"; // 7 chars = 56 bits; reg is 16 bits
>
> // "ASIC_v2" in hex: 41 53 49 43 5F 76 32
> // Only the last 16 bits (2 chars) fit: "v2" → 16'h7632
>
> // What IS stored:   "v2" = 16'h7632
> // What is LOST:     "ASIC_" — silently truncated from the left (MSBs)
>
> $display("%s", chip_id); // Prints: "v2" — not "ASIC_v2"!
> ```
>
> This is identical to numeric truncation — MSBs (leftmost characters) are dropped. In simulation, this can produce completely meaningless debug messages if working with `$display` format strings stored in registers.

---

> ### 🔥 Interview Trap 2: String Padding with ASCII Nulls
>
> **Question:** *"You declare `reg [63:0] name = "RTL";`. The reg fits 8 characters but the string is only 3. How is the remaining space filled?"*
>
> **Answer:** The `reg` is zero-padded in the **most significant bits (leftmost positions)**, with the extended bits being `8'h00` — the ASCII null character.
>
> ```verilog
> reg [63:0] name = "RTL"; // 3 chars = 24 bits; reg is 64 bits
>
> // "RTL" in hex: 52 54 4C
> // 64-bit register: 00 00 00 00 00 52 54 4C
>
> // Bit layout:
> // name[63:40] = 24'h000000  (5 null characters: MSB positions)
> // name[39:32] = 8'h00       (another null)
> // name[31:24] = 8'h00
> // name[23:16] = 8'h52       'R'
> // name[15:8]  = 8'h54       'T'
> // name[7:0]   = 8'h4C       'L'
>
> $display("%s", name); // Prints: "     RTL" — with leading null chars (may show spaces)
> ```
>
> This padding behavior is harmless in most `$display` calls (simulators skip leading nulls), but is **critical to understand** when using `$fwrite` to binary files or when comparing strings in assertions. A string comparison `name == "RTL"` on a 64-bit register will **fail** because the left-side operand is `64'h0000000000524F4C`, not `24'h524F4C`.  
> **Always size your `reg` to exactly match the string length** for reliable string operations.

---

## 10. Special Characters & Simulation Time

### Special Character Reference

| Character | Name | Primary Use | Context |
|---|---|---|---|
| `#` | Hash (Delay) | `#10 clk = ~clk;` — Specifies simulation time delay | Testbench, specify blocks |
| `@` | At (Event) | `@(posedge clk)` — Triggers on signal event | `always`, `wait` |
| `$` | Dollar | `$display(...)` — Prefix for system tasks | Simulation system calls |
| `` ` `` | Backtick | `` `define ``, `` `include `` — Compiler directives | Preprocessor phase |
| `?:` | Ternary | `out = sel ? a : b;` — Multiplexer (2-to-1 MUX) | Continuous assignment |
| `{}` | Braces | Concatenation and replication operators | Expressions |

### Concatenation Operator `{}`

The concatenation operator joins multiple bit vectors into a single wider vector. It is one of the most-used operators in RTL and is synthesizable.

```verilog
wire [3:0] upper = 4'hA;
wire [3:0] lower = 4'hB;
wire [7:0] combined = {upper, lower};   // 8'hAB — upper goes to MSB

// Building byte from individual bits:
wire [7:0] byte_from_bits = {b7, b6, b5, b4, b3, b2, b1, b0};

// Swap nibbles:
wire [7:0] data = 8'hCD;
wire [7:0] swapped = {data[3:0], data[7:4]};  // 8'hDC
```

### Replication Operator `{N{}}`

The replication operator `{N{expr}}` repeats an expression N times and concatenates the copies. It must be used with a constant N.

```verilog
{8{1'b0}}          // 8'h00 — 8 zeros
{4{2'b10}}         // 8'b10101010 — repeat "10" four times
{WIDTH{1'bx}}      // WIDTH-bit X value (parameterized reset value)
{32{a[7]}}         // 32-bit sign extension of a byte's MSB
```

---

> ### 🔥 Interview Trap 1: The Sign Extension Hack Using Replication
>
> **Question:** *"You have a 4-bit signed number `a[3:0]`. You need to extend it to 8 bits preserving its signed value. How do you do this correctly in Verilog using concatenation?"*
>
> **Answer:** Use the **sign-bit replication** pattern — replicate the MSB (the sign bit in two's complement) to fill the extended positions.
>
> ```verilog
> reg signed [3:0] a;         // 4-bit signed: range -8 to +7
> reg signed [7:0] a_ext;     // 8-bit signed: range -128 to +127
>
> // CORRECT: Sign Extension using replication
> // a[3] is the sign bit: 0 for positive, 1 for negative
> assign a_ext = {{4{a[3]}}, a};
>         //        ↑             ↑
>         //  4 copies of sign bit  original 4 bits (at LSB position)
>
> // Examples:
> // a = 4'b0110 (+6): a[3] = 0 → a_ext = {4'b0000, 4'b0110} = 8'b0000_0110 = +6 ✓
> // a = 4'b1010 (-6): a[3] = 1 → a_ext = {4'b1111, 4'b1010} = 8'b1111_1010 = -6 ✓
>
> // WRONG: Zero-extension (only correct for unsigned numbers)
> assign a_ext = {4'b0000, a};  // ❌ -6 (4'b1010) → 8'b0000_1010 = +10 WRONG!
> ```
>
> The synthesis tool can also perform this automatically if operands are properly declared `signed` — but the explicit replication is the clearest and most portable way to express it.

---

> ### 🔥 Interview Trap 2: `time` vs `realtime`
>
> **Question:** *"What is the difference between the `time` and `realtime` data types? Does it matter in practice?"*
>
> **Answer:** Both are 64-bit types for storing simulation time values, but they differ fundamentally in precision:
>
> | Type | Width | Representation | Fractional Handling |
> |---|---|---|---|
> | `time` | 64-bit | Unsigned integer | Fractional delays **rounded** to nearest time unit |
> | `realtime` | 64-bit | IEEE 754 double | Fractional delays **preserved** with full floating-point precision |
>
> ```verilog
> time        t_int;      // Integer: 64-bit unsigned, stores only whole time units
> realtime    t_real;     // Float:   64-bit double, preserves fractional units
>
> // With `timescale 1ns/100ps (100ps precision):
> #1.3 clk = ~clk;   // 1.3ns delay
>
> t_int  = $time;     // Returns 13 (units of 100ps: 1.3ns / 100ps = 13) — integer
> t_real = $realtime; // Returns 1.3 — fractional nanoseconds preserved
> ```

---

> ### 🔥 Interview Trap 3: The `$time` Rounding Error and `timescale` Precision
>
> **Question:** *"Your testbench uses `#2.7` delays, but `$time` always reports integer values. You're worried you're missing a 100ps setup violation. How does this happen and how do you fix it?"*
>
> **Answer:** This is caused by the **`timescale` precision mismatch** and is one of the most insidious sources of missed timing violations in simulation.
>
> The `` `timescale `` directive has two components:
> ```verilog
> `timescale <time_unit>/<time_precision>
> //          ↑                ↑
> //    Unit for # delays   Smallest resolvable time quantum
>
> `timescale 1ns/1ns    // Precision: 1ns — anything finer is ROUNDED
> `timescale 1ns/100ps  // Precision: 100ps — 10× finer than unit
> `timescale 1ns/1ps    // Precision: 1ps — 1000× finer (slowest simulation)
> ```
>
> **The Rounding Error Scenario:**
> ```verilog
> `timescale 1ns/1ns  // ← 1ns precision: the trap is set
>
> initial begin
>     clk = 0;
>     forever #5.3 clk = ~clk;   // Intended: 5.3ns half-period = 10.6ns period
>                                 // Actual:   5ns half-period = 10ns period
>                                 // 0.3ns is SILENTLY ROUNDED AWAY
>
>     // A flip-flop that needs 0.8ns setup time and receives data at 9.9ns
>     // PASSES at 10.6ns period (10.6 - 9.9 = 0.7ns > 0.6ns... wait, still failing)
>     // But at the rounded 10ns period: 10 - 9.9 = 0.1ns (well below 0.8ns — FAULT)
>     // Simulation says PASS because $time rounded the delay!
> end
> ```
>
> ```verilog
> // CORRECT approach: match precision to your finest delay
> `timescale 1ns/1ps  // 1ps precision — now 5.3ns is accurately modeled as 5300 time quanta
>
> // Use $realtime instead of $time for fractional-aware time reporting:
> $display("Event at time: %0t ns", $realtime);
> // vs:
> $display("Event at time: %0t ns", $time); // May report rounded integer value
> ```
>
> **The Rule:** Set `time_precision` to be *at least as fine as your smallest delay*. For nanosecond-resolution designs with sub-ns delays, use `` `timescale 1ns/1ps ``. For GHz+ designs, use `` `timescale 1ps/1fs ``. **Always use `$realtime` in timing-sensitive testbenches** to avoid rounding-induced ghost passes.

---

## Quick Reference Summary

| Topic | Key Rule | Common Trap |
|---|---|---|
| **Comments** | `/* */` does not nest; use `` `ifdef `` to disable logic blocks | Nested `/* */` causes syntax cascades |
| **Identifiers** | Case-sensitive; start with letter or `_` | `Reset ≠ reset`; escaped identifiers need trailing space |
| **Keywords** | Always lowercase; `reg` ≠ flip-flop | `wire Reg` compiles; `reg` creates FF only with `posedge clk` |
| **Ports** | `input`→`wire`, `inout`→`wire`+tri-state | Can't assign to `input`; `inout` internal use fails on FPGA |
| **Numbers** | Always size your literals | Unsized → 32-bit; truncation is silent; `-` goes before size |
| **Data Types** | Nets default `Z`; Variables default `X` | Multi-driven `wire` → `X`; mixed signed/unsigned → unsigned |
| **integer/real** | `integer` for loops only; `real` is non-synthesizable | Use fixed-point (`reg` vectors) for fractional hardware |
| **Vectors vs Arrays** | Range before name = vector; range after name = array | `memA = memB` is illegal; arrays need element-wise copy |
| **Strings** | No string type; ASCII in `reg` (8 bits/char) | Too-small reg truncates left; too-large pads with `8'h00` |
| **Time** | Use `$realtime` for precision; match `` `timescale `` carefully | `$time` rounds; `1ns/1ns` timescale hides sub-ns violations |

---

*Document authored for: RTL Design Interview Preparation Repository*  
*Standard: IEEE 1364-2001 (Verilog-2001) | Synthesis target: ASIC/FPGA*  
*Follow-on reading: Module 5 — Verilog Fundamentals (Module Anatomy, Keywords, Verification & Synthesis)*
