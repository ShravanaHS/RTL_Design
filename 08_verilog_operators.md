# Silicon Math: The 10 Verilog Operator Families


---

## Table of Contents

1. [Arithmetic Operators — `+` `-` `*` `/` `%` `**`](#1-arithmetic-operators)
2. [Bitwise Operators — `~` `&` `|` `^` `~^`](#2-bitwise-operators)
3. [Logical Operators — `!` `&&` `||`](#3-logical-operators)
4. [Reduction Operators — `&` `~&` `|` `~|` `^` `~^`](#4-reduction-operators)
5. [Relational Operators — `>` `<` `>=` `<=`](#5-relational-operators)
6. [Equality Operators — `==` `!=` `===` `!==`](#6-equality-operators)
7. [Shift Operators — `>>` `<<` `>>>` `<<<`](#7-shift-operators)
8. [Concatenation Operator — `{}`](#8-concatenation-operator)
9. [Replication Operator — `{N{}}`](#9-replication-operator)
10. [Ternary (Conditional) Operator — `? :`](#10-ternary-conditional-operator)
11. [Operator Precedence Master Table](#11-operator-precedence-master-table)
12. [Summary Cheat Sheet](#12-summary-cheat-sheet)

---

## Preamble: How Operators Map to Silicon

Every Verilog operator is a **hardware inference directive** — a compact shorthand that instructs the synthesis tool to instantiate a specific class of combinational logic circuit. Understanding operators at this physical level is what separates a candidate who *codes* from one who *designs silicon*.

| Operator Family | Silicon Structure Inferred |
|---|---|
| Arithmetic | Adders, Subtractors, Multiplier Arrays, Divider Networks |
| Bitwise | Individual AND/OR/XOR/NOT gates per bit position |
| Logical | Wide OR tree → comparator → 1-bit result |
| Reduction | Multi-input AND/OR/XOR gate tree |
| Relational | Magnitude Comparator chain |
| Equality | XNOR array → AND reduction |
| Shift (const) | Wire renaming — **zero gates** |
| Shift (variable) | Barrel Shifter (log₂N MUX stages) |
| Concatenation | Wire routing — **zero gates** |
| Replication | Wire fan-out — **zero gates** |
| Ternary | 2-to-1 Multiplexer cell |

The distinction between **zero-gate** operations (free in silicon) and **logic-bearing** operations (consume area, add delay) is critical for area-efficient RTL engineering.

---

## 1. Arithmetic Operators

### `+` `-` `*` `/` `%` `**`

Arithmetic operators model mathematical operations on binary integers. They are synthesizable (with caveats) and infer datapaths — the widest, most timing-critical circuits in any design.

### Operator Definitions

| Operator | Name | Example | Hardware Inferred |
|---|---|---|---|
| `+` | Addition | `a + b` | Ripple-carry or Carry-Lookahead Adder |
| `-` | Subtraction | `a - b` | Two's complement adder (`a + (~b) + 1`) |
| `*` | Multiplication | `a * b` | Wallace-tree or Booth multiplier array |
| `/` | Division | `a / b` | Sequential divider or combinational divider |
| `%` | Modulo | `a % b` | Derived from division circuit |
| `**` | Exponentiation | `a ** b` | Synthesizer-specific; often unsupported |

```verilog
wire [7:0]  a = 8'd45;
wire [7:0]  b = 8'd12;

// ── ADDITION ─────────────────────────────────────────────────
wire [7:0]  sum       = a + b;          // 8'd57  — truncated to 8 bits!
wire [8:0]  sum_safe  = {1'b0,a} + {1'b0,b}; // 9'd57  — carry preserved

// ── SUBTRACTION ──────────────────────────────────────────────
wire [7:0]  diff      = a - b;          // 8'd33
wire [7:0]  underflow = b - a;          // 8'b11001011 (two's complement wrap)

// ── MULTIPLICATION ───────────────────────────────────────────
wire [15:0] product   = a * b;          // 16'd540 — always double the width!

// ── DIVISION ─────────────────────────────────────────────────
wire [7:0]  quotient  = a / b;          // 8'd3 — ⚠ Very expensive hardware
wire [7:0]  remainder = a % b;          // 8'd9 — ⚠ As expensive as division

// ── DIVISION BY POWERS OF 2 — THE SAFE PATH ──────────────────
wire [7:0]  div4      = a >> 2;         // a ÷ 4 — FREE: pure wire shift
wire [7:0]  div8      = a >> 3;         // a ÷ 8 — FREE: pure wire shift
wire [7:0]  mod16     = a[3:0];         // a mod 16 — FREE: bit-select only
```

### Overflow and Width Management

The most critical discipline in arithmetic RTL is managing **result bit-width**. Insufficient width causes **silent truncation** — the most dangerous class of arithmetic bug:

```verilog
// ── OVERFLOW EXAMPLE ─────────────────────────────────────────
wire [7:0] x = 8'd200;
wire [7:0] y = 8'd100;

wire [7:0]  bad_sum  = x + y;    // 200+100=300, but 300 > 255 → TRUNCATED to 8'h2C (44!)
wire [8:0]  good_sum = {1'b0,x} + {1'b0,y}; // 9'd300 — correct, carry captured

// ── WIDTH RULES FOR OPERATORS ────────────────────────────────
// Addition/Subtraction: Result can be (max operand width + 1) bits wider
// Multiplication:       Result is EXACTLY (width_a + width_b) bits wide
// Division/Modulo:      Result is same width as dividend

// ── SAFE ADDITION PATTERN ────────────────────────────────────
parameter N = 8;
wire [N-1:0]   op_a, op_b;
wire [N:0]     result;      // N+1 bits — one extra for carry/borrow
wire            carry_out;

assign {carry_out, result[N-1:0]} = op_a + op_b;   // Pull carry into carry_out
// Or more simply:
assign result = {1'b0, op_a} + {1'b0, op_b};        // Zero-extend, then add
```

### Signed Arithmetic

Declaring operands as `signed` changes how the synthesizer interprets the bit pattern:

```verilog
reg signed [7:0]  sa = -8'd5;    // 8'hFB — two's complement -5
reg signed [7:0]  sb =  8'd3;
reg        [7:0]  ua = 8'hFB;    // 251 unsigned

reg signed [8:0]  signed_sum   = sa + sb;   // (-5) + 3 = -2 = 9'sh1FE ✓
reg        [8:0]  unsigned_sum = ua + sb;   // 251  + 3 = 254           ✓

// MIXING SIGNED AND UNSIGNED:
// If ANY operand is unsigned, the ENTIRE expression is evaluated unsigned
reg signed [7:0] mixed_result = sa + ua;    // sa treated as UNSIGNED (251)!
                                             // 251 + 251 = 502 → truncated → WRONG
// ✅ Fix: cast explicitly
reg signed [8:0] correct = $signed({1'b0, sa}) + $signed({1'b0, ua});
```

---

> ### 🔥 Interview Trap: Division and Modulo Are Silicon Killers
>
> **Question:** *"You have `wire [7:0] result = data / divisor;` where `divisor` is an 8-bit input signal. What does this synthesize to, and what happens to timing?"*
>
> **Answer:** This synthesizes to a **combinational integer divider** — one of the most resource-intensive structures in digital design. The consequences are severe on every metric:
>
> **Area:** A combinational 8-bit divider requires approximately **4,000–20,000 logic gates**, compared to ~100–200 gates for an adder. On an FPGA, it may consume hundreds of LUTs. On an ASIC, the area penalty is often prohibitive for any timing-critical path.
>
> **Timing:** A combinational divider has a propagation delay of roughly **10–30 gate delays** (compared to 5–8 for an adder). This single operation can reduce your maximum clock frequency by 50% or more. The critical path of the entire chip might run through this one divide operation.
>
> **Synthesis tool behaviour:** Many industrial synthesis tools (`Synopsys DC`, `Cadence Genus`, `Xilinx Vivado`) will issue a **warning or outright error** when they encounter general-purpose division by a non-constant or non-power-of-2 operand:
> ```
> Warning: Divider instance 'u_div' is not power-of-2.
>          This may result in very large and slow hardware.
>          Consider using dedicated DSP primitives.
> ```
>
> **The three safe alternatives:**
>
> ```verilog
> // ✅ SAFE 1: Constant power-of-2 divisor → FREE (wire shift)
> wire [7:0] result1 = data >> 3;     // data / 8 — synthesizes to BIT SELECT, zero gates
>
> // ✅ SAFE 2: Constant non-power-of-2 → reciprocal multiplication trick
> // Instead of (data / 10), use (data * 26) >> 8   [26/256 ≈ 1/10 for 8-bit range]
> // This synthesizes to a single multiplier — 10–50× cheaper than a divider
> wire [15:0] temp    = data * 8'd26;
> wire [7:0]  result2 = temp[15:8];   // Approximate data/10 for 0–255 inputs
>
> // ✅ SAFE 3: Sequential division — spread cost over multiple clock cycles
> // Use an iterative algorithm (restoring/non-restoring division)
> // Trades area for latency — correct for high-throughput but non-critical paths
> ```
>
> **The golden rule:** In synthesizable RTL, the denominator of `/` or `%` must be a **constant power of two**. Any other form either fails synthesis or produces circuits that will never meet timing. If you need general division, use a dedicated DSP block, a vendor IP (Xilinx Divider Generator, Cadence Tensilica), or a lookup table approximation.

---

## 2. Bitwise Operators

### `~` `&` `|` `^` `~^` (also written `^~`)

Bitwise operators apply their function independently to each corresponding bit position of their operand(s). They are the direct RTL representation of parallel gate arrays — one gate per bit pair.

### Key Identity: Same Width In, Same Width Out

A bitwise operator applied to N-bit operands produces an **N-bit result**. Each output bit is computed solely from the corresponding input bits — there is never any "carry" or "interaction" between bit positions.

```verilog
wire [7:0] a = 8'b1100_1010;   // 0xCA
wire [7:0] b = 8'b1010_0110;   // 0xA6
wire [3:0] c = 4'b1001;

// ── BITWISE NOT (unary) — inverts every bit ───────────────────
wire [7:0] not_a  = ~a;         // 8'b0011_0101 = 0x35
// Hardware: 8 independent INVERTER cells (one per bit)

// ── BITWISE AND — 1 only when BOTH bits are 1 ────────────────
wire [7:0] and_ab = a & b;      // 8'b1000_0010 = 0x82
// Hardware: 8 independent AND2 cells

// ── BITWISE OR — 1 when EITHER bit is 1 ──────────────────────
wire [7:0] or_ab  = a | b;      // 8'b1110_1110 = 0xEE
// Hardware: 8 independent OR2 cells

// ── BITWISE XOR — 1 when bits DIFFER ────────────────────────
wire [7:0] xor_ab = a ^ b;      // 8'b0110_1100 = 0x6C
// Hardware: 8 independent XOR2 cells
// Key use: comparator (xor_ab == 0 → a and b are equal)

// ── BITWISE XNOR — 1 when bits are THE SAME ──────────────────
wire [7:0] xnor_ab = a ~^ b;    // 8'b1001_0011 = 0x93
// Equivalently: a ^~ b (both forms are legal)
// Key use: bit-level equality checking (MSB → mask, 1=equal, 0=different)

// ── MIXED-WIDTH: ZERO-EXTENSION on narrower operand ──────────
wire [7:0] mixed = a & {4'b0000, c};  // c zero-extended to 8 bits before AND
//  If you write (a & c), the 4-bit c is zero-extended to 8 bits automatically
//  But making it explicit prevents accidental misalignment warnings
```

### Common Bitwise Patterns in RTL

```verilog
wire [7:0] data;
wire [7:0] mask = 8'hF0;     // Upper nibble mask

// Bit masking (most common use):
wire [7:0] upper_nibble = data & 8'hF0;   // Clear lower 4 bits
wire [7:0] lower_nibble = data & 8'h0F;   // Clear upper 4 bits

// Bit setting (OR with mask):
wire [7:0] set_bit3     = data | 8'h08;   // Force bit 3 HIGH regardless of current value

// Bit clearing (AND with inverted mask):
wire [7:0] clear_bit3   = data & ~8'h08;  // Force bit 3 LOW
// Equivalently: data & 8'hF7

// Bit toggling (XOR with mask):
wire [7:0] toggle_bit3  = data ^ 8'h08;   // Flip bit 3 only

// Swap nibbles (zero-gate operation using concatenation):
wire [7:0] swapped      = {data[3:0], data[7:4]};  // No gates — pure routing
```

---

## 3. Logical Operators

### `!` `&&` `||`

Logical operators treat their entire operand as a **single Boolean scalar**: any non-zero value is `TRUE (1)`, and zero is `FALSE (0)`. They **always produce exactly 1 bit** regardless of operand width.

```verilog
wire [7:0] a = 8'hFF;   // Non-zero → TRUE
wire [7:0] b = 8'h00;   // Zero     → FALSE
wire [7:0] c = 8'h0A;   // Non-zero → TRUE

// ── LOGICAL NOT: ! ───────────────────────────────────────────
wire la = !a;            // 1'b0  — !TRUE  = FALSE
wire lb = !b;            // 1'b1  — !FALSE = TRUE
wire lc = !c;            // 1'b0  — !TRUE  = FALSE (even 0x0A is non-zero)

// ── LOGICAL AND: && ──────────────────────────────────────────
wire lab = a && b;       // 1'b0  — TRUE  && FALSE = FALSE
wire lac = a && c;       // 1'b1  — TRUE  && TRUE  = TRUE

// ── LOGICAL OR: || ───────────────────────────────────────────
wire lorb = a || b;      // 1'b1  — TRUE  || FALSE = TRUE
wire lor2 = b || b;      // 1'b0  — FALSE || FALSE = FALSE

// ── SYNTHESIS: Logical operators infer ───────────────────────
// Step 1: Each operand → NOR tree to detect "is non-zero" (1-bit result)
// Step 2: The 1-bit results → AND/OR gate for the logical operation
// Result: a 1-bit combinational comparator network
```

### Hardware Synthesis Path for `&&`

```
a [7:0]  ──→ [8-input NOR] ──→ not_all_zero_a (1-bit)
                                        │
b [7:0]  ──→ [8-input NOR] ──→ not_all_zero_b (1-bit) ──→ [AND2] ──→ result (1-bit)
```

The "is non-zero" detection (`|a` reduction) is itself a circuit — wider buses create larger zero-detection trees.

---

> ### 🔥 Interview Trap: `&` vs `&&` — The Silent Logic Failure
>
> **Question:** *"What is the difference between `a & b` and `a && b`? Write code where mixing them causes a silent functional bug."*
>
> **Answer:** These are fundamentally different operators that produce **different types of results** and are both legal Verilog. Mixing them is a compile-silent bug — no warning, no error, just wrong hardware.
>
> | | `a & b` (Bitwise AND) | `a && b` (Logical AND) |
> |---|---|---|
> | **Operates on** | Individual bits | Entire vector as scalar |
> | **Result width** | Same as operands | Always **1 bit** |
> | **Produces** | Bit vector | Boolean TRUE/FALSE |
> | **Synthesizes to** | N parallel AND gates | Zero-detect tree + AND gate |
>
> **The silent failure:**
>
> ```verilog
> wire [7:0] req_a = 8'hF0;   // High nibble set — represents "request present"
> wire [7:0] req_b = 8'h0F;   // Low nibble set  — represents "request present"
> wire       grant;
>
> // INTENT: Grant only when BOTH devices are requesting (both non-zero)
>
> // ❌ WRONG — using bitwise & :
> assign grant = req_a & req_b;    // 8'hF0 & 8'h0F = 8'h00 = FALSE!
>                                   // Both are non-zero (requests present),
>                                   // but they share NO common '1' bits!
>                                   // This BUS RESOLVES TO ZERO — grant never fires!
>
> // ✅ CORRECT — using logical && :
> assign grant = req_a && req_b;   // (non-zero) && (non-zero) = 1'b1 = TRUE ✓
>                                   // req_a is non-zero → TRUE
>                                   // req_b is non-zero → TRUE → both requesting
> ```
>
> **The rule:**
> - Use **`&`, `|`, `^`** (bitwise) when you want to manipulate *bit patterns* — masking, flag extraction, parity
> - Use **`&&`, `||`, `!`** (logical) when you want to evaluate *conditions* — `if` tests, `assign` enables, boolean guards
>
> In synthesizable RTL control paths (`assign valid = condition_a && condition_b`), always use logical operators for conditions. In datapath arithmetic (`assign masked = data & mask`), always use bitwise operators.

---

## 4. Reduction Operators

### `&` `~&` `|` `~|` `^` `~^` (Unary prefix form)

Reduction operators are **unary** — they take a **single vector operand** and collapse it to a **1-bit scalar** by applying the named operation across every bit. They are the RTL shorthand for multi-input gate trees.

### The Positional Distinction from Bitwise

The same symbol (`&`, `|`, `^`) means **reduction** when used as a **unary prefix** before a single operand, and **bitwise** when used as a **binary infix** between two operands. Context is everything:

```verilog
wire [3:0] a = 4'b1011;
wire [3:0] b = 4'b1101;

// BITWISE &  — binary operator, two operands, 4-bit result:
wire [3:0] bitwise_result = a & b;          // 4'b1001 — per-bit AND

// REDUCTION & — unary operator, ONE operand, 1-bit result:
wire       reduce_result  = &a;             // 1 & 0 & 1 & 1 = 1'b0
//                          ^^ unary prefix = reduction
```

### Complete Reduction Reference

```verilog
wire [7:0] data = 8'b1010_1101;   // Has 1s and 0s

// ── REDUCTION AND  (&data) ───────────────────────────────────
wire r_and  =  &data;   // 1'b0 — 1 AND 0 AND 1 AND 0 AND 1 AND 1 AND 0 AND 1 = 0
// Hardware: 7-stage AND gate tree (or single 8-input AND)
// Semantic: "Are ALL bits 1?" → TRUE only if the vector is all-ones (8'hFF)

// ── REDUCTION NAND (~&data) ──────────────────────────────────
wire r_nand = ~&data;   // 1'b1 — complement of AND reduction
// Semantic: "Is at least one bit 0?" (complement of all-ones check)

// ── REDUCTION OR  (|data) ────────────────────────────────────
wire r_or   =  |data;   // 1'b1 — any 1 bit makes this 1
// Hardware: 7-stage OR gate tree (or single 8-input OR)
// Semantic: "Is ANY bit 1?" → TRUE if vector is non-zero (the zero-detect complement)

// ── REDUCTION NOR (~|data) ───────────────────────────────────
wire r_nor  = ~|data;   // 1'b0 — complement of OR reduction
// Semantic: "Are ALL bits 0?" → the zero-detect: ~|data == (data == 8'h00)
// This is the most common reduction in RTL: checking if a bus is zero

// ── REDUCTION XOR  (^data) ───────────────────────────────────
wire r_xor  =  ^data;   // Count 1-bits: 1,0,1,0,1,1,0,1 → five 1s → 1'b1 (odd parity)
// Hardware: 7-stage XOR tree
// Semantic: "Is the number of 1-bits ODD?" — the parity check

// ── REDUCTION XNOR (~^data) ──────────────────────────────────
wire r_xnor = ~^data;   // 1'b0 — complement of XOR reduction
// Semantic: "Is the number of 1-bits EVEN?" — even parity indicator
```

### Synthesis Mapping: Gate Trees

The synthesizer maps reduction operators to **balanced gate trees** for minimum delay:

```
8-bit Reduction AND (&data):

data[7] ─┐
data[6] ─┴─[AND2]─┐
data[5] ─┐         │
data[4] ─┴─[AND2]─┴─[AND2]─┐
data[3] ─┐                   │
data[2] ─┴─[AND2]─┐         ├─[AND2]─→ result
data[1] ─┐         │        │
data[0] ─┴─[AND2]─┴─[AND2]─┘

Delay: log₂(8) = 3 gate levels (vs 7 levels for a chain)
```

### Real-World Use Cases

```verilog
// ── Zero Detection (universal pattern) ───────────────────────
wire [31:0] result;
wire is_zero     = ~|result;     // TRUE when result == 0   (32-input NOR tree)
wire is_nonzero  =  |result;     // TRUE when result != 0

// ── All-Ones Detection ────────────────────────────────────────
wire [7:0] status_reg;
wire all_done    = &status_reg;  // TRUE when all 8 status bits are SET

// ── Even Parity Generation (ECC, UART, memory) ───────────────
wire [7:0] data_byte;
wire parity      = ^data_byte;   // XOR parity bit — add to word for error detection
wire [8:0] protected_word = {parity, data_byte};

// ── Valid Signal Generation ───────────────────────────────────
wire [3:0] request_bus;
wire any_request = |request_bus;  // Any device requesting → arbitrate

// ── Carry Propagate in Carry-Lookahead Adder ─────────────────
wire [3:0] propagate_group;
wire P = &propagate_group;        // Group propagate: all bits propagate carry
```

---

## 5. Relational Operators

### `>` `<` `>=` `<=`

Relational operators compare two values for magnitude and produce a **1-bit result**: `1` (TRUE) if the relation holds, `0` (FALSE) if it does not.

```verilog
wire [7:0] a = 8'd50;
wire [7:0] b = 8'd75;
wire [7:0] c = 8'd50;

wire gt  = (a > b);    // 1'b0 — 50 is NOT greater than 75
wire lt  = (a < b);    // 1'b1 — 50 IS less than 75
wire gte = (a >= b);   // 1'b0 — 50 is NOT greater than or equal to 75
wire lte = (a <= b);   // 1'b1 — 50 IS less than or equal to 75
wire geq = (a >= c);   // 1'b1 — 50 IS greater than or equal to 50 (equal case)
```

### 4-State Behaviour — The X Propagation Rule

```verilog
wire [3:0] x_val = 4'bX010;   // Upper bit is unknown
wire [3:0] known  = 4'b0001;

wire cmp1 = (x_val > known);  // Result is X — unknown operand → unknown comparison
wire cmp2 = (x_val < known);  // Result is X — same reason
```

If **any** bit of either operand is `X` or `Z`, the comparison result is `X`. This propagates into any control logic that depends on the comparison — a critical simulation debugging point.

### Signed vs Unsigned Comparison — The Critical Distinction

```verilog
// UNSIGNED comparison (default when types are not declared signed):
wire [7:0] ua = 8'hFF;   // 255 unsigned
wire [7:0] ub = 8'h01;   // 1 unsigned
wire unsigned_gt = (ua > ub);     // 1'b1 — 255 > 1 ✓

// SIGNED comparison — must declare operands as signed:
wire signed [7:0] sa = 8'hFF;   // -1 in two's complement
wire signed [7:0] sb = 8'h01;   // +1
wire signed_gt = ($signed(sa) > $signed(sb));   // 1'b0 — (-1) is NOT > (+1) ✓

// ❌ Pitfall: comparing signed and unsigned mixes
wire mixed_cmp = (sa > ub);     // sa treated as UNSIGNED — 255 > 1 = TRUE
                                  // But signed intent was -1 < 1 = FALSE!
```

### Synthesized Hardware

A relational operator synthesizes to a **subtraction-based comparator**:

```
(a > b) is implemented as:
    diff = a - b           (subtractor circuit)
    gt   = ~diff[N]        (if borrow bit is clear → a was bigger)
    
The synthesizer may optimize this into a dedicated comparator cell
from the standard cell library, which is often faster than a raw subtractor.
```

### Practical Use: Range Check

```verilog
// Check if an address falls within a valid range [BASE, BASE+SIZE):
parameter BASE = 16'h4000;
parameter SIZE = 16'h0100;  // 256 locations

wire [15:0] addr;
wire addr_valid = (addr >= BASE) && (addr < BASE + SIZE);
// Synthesizes to: two magnitude comparators + one AND gate
```

---

## 6. Equality Operators

### `==` `!=` `===` `!==`

Verilog provides **two distinct equality systems**: logical equality (synthesizable, X/Z-propagating) and case equality (simulation-only, X/Z-exact).

### Logical Equality: `==` and `!=`

```verilog
wire [7:0] a = 8'd100;
wire [7:0] b = 8'd100;
wire [7:0] c = 8'd200;
wire [7:0] x = 8'bxxxx_xxxx;   // All unknown bits

wire eq1  = (a == b);    // 1'b1  — equal ✓
wire eq2  = (a == c);    // 1'b0  — not equal ✓
wire eq3  = (a == x);    // 1'bX  — unknown! Any X/Z input → X output
wire neq1 = (a != b);    // 1'b0  — they ARE equal
wire neq2 = (a != x);    // 1'bX  — again unknown
```

**Hardware implementation of `==`:**

```
a == b is implemented as:
    diff = a ^ b           (XOR: 1 at every bit where a and b differ)
    eq   = ~|diff          (NOR reduction: TRUE if no differences exist)
    
Synthesis path: XOR array → wide-NOR tree → 1-bit result
```

### Case Equality: `===` and `!==`

Case equality operators compare operands **including X and Z states literally** — `X === X` is `TRUE`, `Z === Z` is `TRUE`. This is physically impossible to synthesize because real silicon has no concept of "is this signal unknown."

```verilog
wire [7:0] dut_out = 8'bxxxx_0000;  // DUT outputs unknown upper nibble
wire [7:0] expected = 8'bxxxx_0000;  // Expected: same pattern including Xs

// Logical equality — X poison:
wire logical_eq = (dut_out == expected);   // 1'bX — Xs in inputs → X output
                                            // Cannot tell PASS from FAIL!

// Case equality — X-aware:
wire case_eq   = (dut_out === expected);   // 1'b1 — exact match, X=X bit-for-bit ✓
wire case_neq  = (dut_out !== expected);   // 1'b0 — they are identical

// The pass/fail discrimination possible with ===:
wire [7:0] ref = 8'b1111_0000;
wire catch_x   = (dut_out === ref);        // 1'b0 — dut upper nibble is X ≠ 1
                                            // Correctly catches the X!
```

---

> ### 🔥 Interview Trap: `==` vs `===` — The Synthesizability Chasm
>
> **Question:** *"Your testbench self-check uses `==` to compare DUT output against expected values. During regression, you see unexpected 'PASS' results even when the DUT output contains X values. What is the bug and how do you fix it?"*
>
> **Answer:** This is the classic **`==` vs `===` testbench failure** — one of the most commonly missed bugs in verification environments.
>
> **The failure mechanism:**
>
> ```verilog
> // ❌ WRONG testbench comparison — misses X values:
> if (dut_q == expected_q) begin
>     pass_count = pass_count + 1;
>     $display("PASS at time %0t", $time);
> end
>
> // Scenario: dut_q = 8'hXA, expected_q = 8'hFA
> // dut_q == expected_q evaluates to: X (unknown)
> // The if() condition treats X as FALSE — the ELSE branch runs
> // The PASS counter is NOT incremented, but neither is a FAIL flagged
> // → The error is SILENTLY SWALLOWED. Regression shows no fail!
>
> // Even worse scenario: dut_q = 8'hXX, expected_q = 8'hXX
> // dut_q == expected_q = X → if() treats as FALSE
> // The comparison FAILS even though logically the patterns match
> // → FALSE NEGATIVE: real Xs produce ambiguous results either way
> ```
>
> **The fix — always use `!==` in testbench assertions:**
>
> ```verilog
> // ✅ CORRECT testbench comparison — catches X and Z states:
> if (dut_q !== expected_q) begin
>     $error("FAIL @ %0t: expected=%0h, got=%0h", $time, expected_q, dut_q);
>     fail_count = fail_count + 1;
> end else begin
>     pass_count = pass_count + 1;
>     $display("PASS @ %0t", $time);
> end
>
> // Now: if dut_q = 8'hXA, expected_q = 8'hFA
> // dut_q !== expected_q = TRUE (they are NOT case-identical)
> // → Error IS reported ✓
>
> // And: if dut_q = expected_q (fully matching, no X/Z)
> // dut_q !== expected_q = FALSE
> // → PASS IS recorded ✓
> ```
>
> **The synthesizability wall:** `===` and `!==` are **strictly un-synthesizable** and must **never** appear in RTL code that is synthesized. The synthesizer will either:
> - Error out: `ERROR: operator '===' not supported for synthesis`
> - Silently replace with `==` (incorrect for X/Z scenarios)
>
> **Memory rule:** In RTL: use `==`. In testbenches: use `!==` for all assertions.

---

## 7. Shift Operators

### `>>` `<<` `>>>` `<<<`

Verilog provides two classes of shift operators with fundamentally different fill-bit behaviour:

| Operator | Name | Direction | Fill Bit Source |
|---|---|---|---|
| `<<` | Logical Left Shift | Left (toward MSB) | Fills LSBs with `0` |
| `>>` | Logical Right Shift | Right (toward LSB) | Fills MSBs with `0` |
| `<<<` | Arithmetic Left Shift | Left (toward MSB) | Fills LSBs with `0` (identical to `<<`) |
| `>>>` | Arithmetic Right Shift | Right (toward LSB) | Fills MSBs with **sign bit** (if `signed`) |

### Logical Shifts — Fill with Zero

```verilog
wire [7:0] data = 8'b1010_1100;   // 0xAC = 172

// ── LOGICAL LEFT SHIFT ────────────────────────────────────────
wire [7:0] lsl1 = data << 1;   // 8'b0101_1000 = 0x58  — MSB shifted out, 0 shifted in
wire [7:0] lsl3 = data << 3;   // 8'b0110_0000 = 0x60  — 3 bits lost from MSB
// Mathematical meaning: multiply by 2^N (for unsigned values in range)
// data * 2 = 172 * 2 = 344 → overflowed to 8'h58 (88) — need wider result!

// ── LOGICAL RIGHT SHIFT ───────────────────────────────────────
wire [7:0] lsr1 = data >> 1;   // 8'b0101_0110 = 0x56 — LSB shifted out, 0 shifted in
wire [7:0] lsr3 = data >> 3;   // 8'b0001_0101 = 0x15 — 3 bits lost from LSB
// Mathematical meaning: UNSIGNED divide by 2^N (floor division)
// 172 >> 1 = 86  ✓  (172/2 = 86)
// 172 >> 3 = 21  ✓  (172/8 = 21.5 → floor to 21)
```

### Arithmetic Right Shift — The Signed Divide

```verilog
// Arithmetic right shift preserves the mathematical value of SIGNED division by 2^N:

// ─── CASE 1: Declared as SIGNED — behaves correctly ──────────
wire signed [7:0] signed_pos =  8'sb0101_1010; // +90 in 2's complement, MSB=0
wire signed [7:0] signed_neg =  8'sb1010_0110; // -90 in 2's complement, MSB=1

wire signed [7:0] asr_pos = signed_pos >>> 1;  // 8'b0010_1101 = +45 ✓  (0 fill: MSB was 0)
wire signed [7:0] asr_neg = signed_neg >>> 1;  // 8'b1101_0011 = -45 ✓  (1 fill: MSB was 1)
// Correct: -90 / 2 = -45 (arithmetic right shift preserves sign)

// ─── CASE 2: Declared as UNSIGNED — identical to >> (fills 0) ──
wire [7:0] unsigned_neg = 8'b1010_0110;  // Same bits as signed_neg, but unsigned

wire [7:0] asr_unsigned = unsigned_neg >>> 1;  // 8'b0101_0011 = 83
// WRONG for signed divide! 83 ≠ -45
// The >>> has no sign information — unsigned type fills with 0, not sign bit
```

### Constant vs Variable Shifts

```verilog
// ── CONSTANT SHIFT AMOUNT — Zero hardware cost ────────────────
wire [7:0] data;
wire [7:0] const_shift = data << 3;   // Synthesizes to ZERO GATES
                                        // Compiler simply routes data[4:0] to result[7:3]
                                        // and ties result[2:0] to ground

// ── VARIABLE SHIFT AMOUNT — Barrel Shifter ───────────────────
wire [2:0] shift_n;               // 3-bit shift amount: 0 to 7
wire [7:0] var_shift = data << shift_n; // Synthesizes to a BARREL SHIFTER
// Barrel shifter: 3 levels of 8-bit 2:1 MUXes = 24 MUX cells
// Each MUX stage: shift by 1, 2, or 4 — controlled by shift_n[0], [1], [2]
```

---

> ### 🔥 Interview Trap: `>>>` Requires an Explicit `signed` Declaration
>
> **Question:** *"You write `wire [7:0] result = data >>> 2;` intending to do a signed divide-by-4. The MSB of `data` is `1` (indicating a negative number). Does the result correctly preserve sign?"*
>
> **Answer:** **No — the arithmetic right shift `>>>` does NOT preserve sign unless the variable is explicitly declared as `signed`.** This is a strict rule from the IEEE 1364-2001 LRM, and it catches virtually every engineer the first time they use `>>>`.
>
> ```verilog
> wire        [7:0] data_u  = 8'b1100_0000;  // MSB=1, but declared UNSIGNED
> wire signed [7:0] data_s  = 8'sb1100_0000; // MSB=1, declared SIGNED (-64)
>
> // ❌ WRONG — unsigned declaration, >>> behaves like >>:
> wire [7:0] result_wrong = data_u >>> 2;
> // Fills with 0 (not sign bit!) → 8'b0011_0000 = 48
> // Mathematically: if -64 was intended, -64/4 = -16, NOT 48!
>
> // ✅ CORRECT — signed declaration, >>> fills with sign bit:
> wire signed [7:0] result_right = data_s >>> 2;
> // Fills with 1 (sign bit) → 8'b1111_0000 = -16 in two's complement ✓
> // Mathematically: -64 / 4 = -16 ✓
>
> // ✅ ALTERNATIVE: Cast with $signed() for one-off correction:
> wire signed [7:0] result_cast = $signed(data_u) >>> 2;
> // $signed() re-interprets the unsigned bit pattern as signed
> // Then >>> correctly uses the MSB as sign fill → -16 ✓
> ```
>
> **The LRM rule (§4.1.12):** The arithmetic right shift `>>>` uses the MSB of the **declared type** as the fill bit — if the type is `unsigned` (the default for plain `reg` and `wire`), the fill bit is always `0`, making `>>>` identical to `>>`.
>
> **The practical checklist:**
> 1. Is the data path doing signed arithmetic? → Declare ALL participating wires/regs as `signed`
> 2. Are you using `>>>` for signed division? → Verify `signed` keyword is present
> 3. Mixing signed/unsigned in the same expression? → The ENTIRE expression goes unsigned (the contamination rule)
>
> **The safe one-liner:** Always cast to `$signed()` when using `>>>` on any signal whose declaration you are not 100% certain of.

---

## 8. Concatenation Operator

### `{}`

The concatenation operator bundles multiple signals of any width into a single wider signal. It is the primary tool for **bus construction, field assembly, and signal routing** in dataflow RTL.

### Core Syntax and Rules

```verilog
// Syntax: {signal_1, signal_2, ..., signal_N}
// The LEFTMOST signal occupies the MOST SIGNIFICANT BITS.
// The RIGHTMOST signal occupies the LEAST SIGNIFICANT BITS.
// Result width = sum of all operand widths.

wire        a = 1'b1;
wire [1:0]  b = 2'b10;
wire [3:0]  c = 4'b1100;

wire [7:0] concat = {a, b, c};
//                   ^ ^^  ^^^^
//  bit 7 ← a(1 bit) ─┘  │  └─ bits 3:0 ← c(4 bits)
//  bits 6:5 ← b(2 bits) ─┘
// concat = 8'b1_10_1100 = 8'b1101_1100 = 0xDC
```

### Concatenation is Zero-Cost Hardware

This is critical for area-aware design: **concatenation synthesizes to zero gates**. The synthesizer simply re-routes the wires to the correct bit positions — no logic cells are consumed.

```verilog
// These are ALL zero-gate operations:
wire [31:0] word;
wire [15:0] upper = word[31:16];              // Bit select — zero gates
wire [15:0] lower = word[15:0];               // Bit select — zero gates
wire [31:0] swapped = {lower, upper};          // Concatenation — zero gates
wire [31:0] reversed = {word[0], word[1], word[2], word[3],   // Bit reversal
                         word[4], word[5], word[6], word[7],   // All zero gates
                         word[8], word[9], word[10], word[11],
                         word[12], word[13], word[14], word[15],
                         word[16], word[17], word[18], word[19],
                         word[20], word[21], word[22], word[23],
                         word[24], word[25], word[26], word[27],
                         word[28], word[29], word[30], word[31]};
```

### LHS Concatenation — Bus Decomposition

The concatenation operator can also appear on the **left-hand side** of an assign, destructuring a bus into components:

```verilog
wire [31:0] instruction;    // 32-bit RISC-V instruction word
wire [6:0]  opcode;         // bits [6:0]
wire [4:0]  rd;             // bits [11:7]
wire [2:0]  funct3;         // bits [14:12]
wire [4:0]  rs1;            // bits [19:15]
wire [4:0]  rs2;            // bits [24:20]
wire [6:0]  funct7;         // bits [31:25]

// Decode all fields in one assign:
assign {funct7, rs2, rs1, funct3, rd, opcode} = instruction;
//      ^^31:25  ^^24:20 ^^19:15 ^14:12 ^11:7 ^^6:0
// All zero gates — pure routing from instruction's bit positions
```

### Common Concatenation Patterns

```verilog
// ── Field extraction and re-assembly ─────────────────────────
wire [7:0] byte_a = 8'hDE;
wire [7:0] byte_b = 8'hAD;
wire [15:0] halfword = {byte_a, byte_b};   // 16'hDEAD — big-endian assembly

// ── Byte swap (endian conversion) ────────────────────────────
wire [31:0] big_endian;
wire [31:0] little_endian = {big_endian[7:0],   big_endian[15:8],
                              big_endian[23:16], big_endian[31:24]};

// ── Rotate left by N (without barrel shifter!) ───────────────
wire [7:0] data;
wire [7:0] rot_left_3 = {data[4:0], data[7:5]};  // Rotate left by 3
// No gates — pure concatenation of different bit slices

// ── Adding MSB guard bit for overflow-safe arithmetic ─────────
wire [7:0] operand;
wire [8:0] extended = {1'b0, operand};   // Zero-extend to 9 bits — sign-safe add

// ── Building control vectors from individual flags ────────────
wire      carry_flag, zero_flag, neg_flag, overflow_flag;
wire [3:0] status_word = {neg_flag, overflow_flag, carry_flag, zero_flag};
```

---

## 9. Replication Operator

### `{N{}}`

The replication operator repeats a signal or constant exactly N times and concatenates the copies. `N` must be a **compile-time constant** (a literal or a `parameter` — never a signal).

```verilog
// Syntax: {N{expression}}
// N = replication count — MUST be a constant
// Result width = N × width_of_expression

wire        bit  = 1'b1;
wire [1:0]  pair = 2'b10;
wire [7:0]  byte_val = 8'hF0;

wire [3:0]  rep_bit  = {4{bit}};       // 4'b1111   — 1-bit replicated 4 times
wire [7:0]  rep_pair = {4{pair}};      // 8'b10101010 — 2-bit replicated 4 times
wire [15:0] rep_byte = {2{byte_val}};  // 16'hF0F0  — 8-bit replicated 2 times

// ── Common constants ──────────────────────────────────────────
wire [31:0] all_zeros = {32{1'b0}};   // 32'h00000000
wire [31:0] all_ones  = {32{1'b1}};   // 32'hFFFFFFFF
wire [31:0] alt_01    = {16{2'b01}};  // 32'h55555555 — alternating 01 pattern
wire [31:0] alt_10    = {16{2'b10}};  // 32'hAAAAAAAA — alternating 10 pattern
```

### The Sign Extension Hack — The Most Important Replication Pattern

Sign extension is needed when promoting a narrow signed value to a wider signed context. Replication makes this elegant:

```verilog
// ── MANUAL SIGN EXTENSION using replication ───────────────────
wire [3:0]  narrow = 4'b1010;   // -6 in 4-bit two's complement

// Extend 4-bit signed → 8-bit signed, preserving value:
wire [7:0]  extended = {{4{narrow[3]}}, narrow};
//                       ^^^^^^^^^^^^ — 4 copies of the sign bit (MSB)
//                                       ^^^^^^ — original 4 bits at LSB

// narrow[3] = 1 (sign bit) → replicate 4 times = 4'b1111
// Result: {1111, 1010} = 8'b1111_1010 = 8'hFA = -6 in 8-bit 2's complement ✓

// narrow[3] = 0 (positive) example: narrow = 4'b0101 (+5)
// Sign bit = 0 → {4{0}} = 4'b0000
// Result: {0000, 0101} = 8'b0000_0101 = 8'h05 = +5 in 8-bit 2's complement ✓

// ── PARAMETERIZED SIGN EXTENSION ────────────────────────────────
parameter NARROW = 4;
parameter WIDE   = 16;
wire [NARROW-1:0] sig_in;
wire [WIDE-1:0]   sig_out;

assign sig_out = {{(WIDE-NARROW){sig_in[NARROW-1]}}, sig_in};
//                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ — (WIDE-NARROW) copies of sign bit
// Works for ANY width combination — the ultimate parameterized sign extender
```

### Why This Matters: The Zero-Extension vs Sign-Extension Bug

```verilog
wire signed [7:0] negative = 8'sb1111_1110;  // -2 in 8-bit signed

// ❌ WRONG — zero extension (treats -2 as 254 unsigned):
wire [15:0] zero_extended  = {8'h00, negative};        // 16'h00FE = +254 ✗

// ✅ CORRECT — sign extension (preserves -2):
wire [15:0] sign_extended  = {{8{negative[7]}}, negative};  // 16'hFFFE = -2 ✓

// ✅ ALSO CORRECT — Verilog auto-extends signed types in assignment:
wire signed [15:0] auto_extended = negative;               // 16'shFFFE = -2 ✓
// (Automatic sign extension occurs when assigning smaller signed to larger signed)
```

---

## 10. Ternary (Conditional) Operator

### `? :`

The ternary operator is the **only native MUX inferring construct** in dataflow Verilog. Every occurrence of `condition ? true_val : false_val` infers a multiplexer in silicon.

### Basic 2-to-1 MUX

```verilog
// Syntax: condition ? value_if_TRUE : value_if_FALSE

wire sel;
wire [7:0] a = 8'hAA;
wire [7:0] b = 8'hBB;
wire [7:0] out;

assign out = sel ? a : b;
//           ^^^   ^   ^
//           select  |   |
//                   |   └── Input 0 (selected when sel=0)
//                   └────── Input 1 (selected when sel=1)

// Synthesis: 2-to-1 MUX cell (or equivalent AND-OR-INV structure)
// sel=0: out = b = 8'hBB
// sel=1: out = a = 8'hAA
```

### The MUX Hardware

```
     a ──────────────────┐
                         ├──[MUX2]──→ out
     b ──────────────────┘       │
                              sel ──┘
```

For an 8-bit `out`, the synthesizer instantiates **8 parallel 2-to-1 MUX cells** (one per bit), all sharing the same `sel` signal.

### Nested Ternary — 4-to-1 MUX

Multiple ternary operators can be chained to build wider multiplexers:

```verilog
wire [1:0] sel;
wire [7:0] i0, i1, i2, i3;

// ── 4-to-1 MUX using nested ternary ─────────────────────────
wire [7:0] mux4 = (sel == 2'b00) ? i0 :
                  (sel == 2'b01) ? i1 :
                  (sel == 2'b10) ? i2 :
                                   i3 ; // Default: sel == 2'b11

// Hardware interpretation: a tree of 2-to-1 MUXes
// Level 1: sel[0] chooses between (i0,i1) and between (i2,i3)
// Level 2: sel[1] chooses between the two Level-1 outputs
// Total: 3 MUX2 cells per bit → 24 MUX2 cells for 8-bit inputs

// ── EQUIVALENT but cleaner — explicit priority encoding ──────
wire [7:0] priority_mux =
    sel[1] ? (sel[0] ? i3 : i2) :   // sel=1x group
             (sel[0] ? i1 : i0) ;   // sel=0x group
```

### Ternary for Conditional Bus Driving

```verilog
// ── Enable gating — suppress output when disabled ────────────
wire [7:0] data_in;
wire       enable;

wire [7:0] gated = enable ? data_in : 8'h00;
// When enable=0: output is forced to zero (no signal leakage)

// ── Tri-state bus (assign Z when not driving) ─────────────────
wire [7:0] bus;
wire       oe_n;   // Output enable, active LOW

assign bus = (~oe_n) ? data_in : 8'hZZ;
// When oe_n=0 (enabled): drive data_in onto bus
// When oe_n=1 (disabled): release bus to Hi-Z

// ── Default value pattern ────────────────────────────────────
wire [7:0] result;
wire       valid;
wire [7:0] computed_result;

assign result = valid ? computed_result : 8'hFF;   // 0xFF as "invalid" sentinel
```

### Multi-Level Priority Encoder Using Ternary

```verilog
// 8-bit priority encoder: find index of highest-priority set bit
wire [7:0] req;       // Request bus, bit 7 = highest priority
wire [2:0] grant;     // 3-bit encoded index
wire       any_req;   // Any request active

assign any_req = |req;     // Reduction OR — any bit set?

assign grant = req[7] ? 3'd7 :
               req[6] ? 3'd6 :
               req[5] ? 3'd5 :
               req[4] ? 3'd4 :
               req[3] ? 3'd3 :
               req[2] ? 3'd2 :
               req[1] ? 3'd1 :
                         3'd0 ;

// Hardware: 7-level priority MUX chain
// Critical path: bit 7 check → bit 6 check → ... → bit 0 default
// For large encoders (32+ bits), use a tree-based priority structure
// to reduce critical path depth from O(N) to O(log₂N) MUX levels
```

### Ternary with X/Z Condition

```verilog
wire [7:0] out_xz;
wire sel_x = 1'bX;   // Unknown select

assign out_xz = sel_x ? a : b;
// When sel is X: output is X for any bit where a[i] ≠ b[i]
//                output is the common value for bits where a[i] == b[i]
// Simulation models "don't know which input is selected" — conservative X propagation
```

---

## 11. Operator Precedence Master Table

The following table defines evaluation order when parentheses are absent — **highest to lowest** priority:

| Priority | Operator(s) | Type | Notes |
|:---:|---|---|---|
| **1** (Highest) | `+` `-` `!` `~` `&` `~&` `\|` `~\|` `^` `~^` (unary) | Unary | Binds most tightly |
| **2** | `**` | Exponentiation | Right-associative |
| **3** | `*` `/` `%` | Multiplicative | |
| **4** | `+` `-` (binary) | Additive | |
| **5** | `<<` `>>` `<<<` `>>>` | Shift | |
| **6** | `<` `<=` `>` `>=` | Relational | |
| **7** | `==` `!=` `===` `!==` | Equality | |
| **8** | `&` (binary) | Bitwise AND | |
| **9** | `^` `~^` (binary) | Bitwise XOR/XNOR | |
| **10** | `\|` (binary) | Bitwise OR | |
| **11** | `&&` | Logical AND | |
| **12** | `\|\|` | Logical OR | |
| **13** (Lowest) | `? :` | Conditional (Ternary) | Right-associative |

### Precedence Bug Gallery — Know These Cold

```verilog
// ── BUG 1: Ternary grabs less than you expect ─────────────────
wire r1_wrong = a | b ? c : d;   // Parsed: a | (b ? c : d) — OR with a, not expected!
wire r1_right = (a | b) ? c : d; // ✅ Force OR evaluation first

// ── BUG 2: Shift binds tighter than addition ─────────────────
wire r2_wrong = base + offset << 2;   // Parsed: base + (offset << 2)
wire r2_right = (base + offset) << 2; // ✅ Add first, then shift

// ── BUG 3: Equality binds tighter than bitwise OR ────────────
wire r3_wrong = a | b == 8'hFF;   // Parsed: a | (b == 8'hFF), not (a|b)==0xFF
wire r3_right = (a | b) == 8'hFF; // ✅ OR the values, then compare

// ── BUG 4: Logical vs bitwise confusion with NOT ──────────────
wire r4_wrong = !a & b;    // Parsed: (!a) & b — NOT of a first, then bitwise AND b
wire r4_right = !(a & b);  // ✅ Bitwise AND first, then logical NOT of result

// ── THE GOLDEN RULE ──────────────────────────────────────────
// Always use parentheses when mixing different operator families.
// Parentheses are FREE in hardware — they generate zero extra logic.
// Unambiguous code is always worth the extra two characters.
```

---

## 12. Summary Cheat Sheet

### Operator Family Quick Reference

| Family | Operators | Result Width | Synthesizable? | Primary Use |
|---|---|---|---|---|
| **Arithmetic** | `+` `-` `*` `/` `%` | Varies (see rules) | ⚠ `/` `%` expensive | Datapaths, ALUs |
| **Bitwise** | `~` `&` `\|` `^` `~^` | Same as operand(s) | ✅ Yes | Masking, flags, logic |
| **Logical** | `!` `&&` `\|\|` | **Always 1-bit** | ✅ Yes | Conditions, enables |
| **Reduction** | `&` `\|` `^` (unary) | **Always 1-bit** | ✅ Yes | Zero-detect, parity |
| **Relational** | `>` `<` `>=` `<=` | **Always 1-bit** | ✅ Yes | Comparators |
| **Equality** | `==` `!=` | **Always 1-bit** | ✅ Yes | Comparators (RTL) |
| **Case Equality** | `===` `!==` | **Always 1-bit** | ❌ **Never** | Testbench only |
| **Shift (const)** | `<<` `>>` `<<<` `>>>` | Same as left operand | ✅ Free (zero gates) | Multiply/divide by 2^N |
| **Shift (variable)** | `<<` `>>` `<<<` `>>>` | Same as left operand | ✅ Barrel shifter | Arbitrary shifts |
| **Concatenation** | `{}` | Sum of widths | ✅ Free (routing) | Bus assembly/splitting |
| **Replication** | `{N{}}` | N × operand width | ✅ Free (fan-out) | Sign extension, patterns |
| **Ternary** | `? :` | Width of result | ✅ Yes — MUX | Multiplexing, enables |

### The 6 Rules No Candidate Should Forget

1. **Division/Modulo by non-power-of-2 = silicon death.** Use `>>` for powers of 2 or a multiply-then-shift approximation for constants.

2. **`a & b` ≠ `a && b`.** Bitwise gives a vector; logical gives 1 bit. Mixing them is a silent functional bug.

3. **`===` and `!==` are testbench-only.** Use `==` in RTL; use `!==` in all testbench assertions to catch X values.

4. **`>>>` only sign-extends if the type is declared `signed`.** Otherwise it is identical to `>>`. Use `$signed()` to cast when in doubt.

5. **Concatenation and constant shifts are zero-gate.** They are free in silicon — use them aggressively for bus manipulation and endian conversion.

6. **Ternary `? :` = MUX.** It is the idiomatic dataflow way to select between two values. Nested ternaries build priority encoders and N-to-1 MUXes.

---

*Document authored for: RTL Design Interview Preparation Repository*  
*Standard: IEEE 1364-2001 (Verilog-2001)*  
*Prerequisite: Dataflow Modeling — Continuous Assignments & Boolean Equations*  
*Follow-on reading: Behavioral Modeling — `always` Blocks, Sequential Logic & FSMs*

---

# 🎯 Ultimate PYQ & Interview Debugging Masterclass

> **Tier:** Senior ASIC/SoC Verification Engineer | Texas Instruments · Qualcomm · NVIDIA  
> **Focus:** Edge cases, simulation vs. synthesis mismatches, X/Z propagation, timing violations, silent compilation bugs  
> **Standard:** IEEE 1364-2001 (Verilog-2001) LRM — citations included

---

## Table of PYQ Contents

| Section | Topic | PYQs |
|---|---|:---:|
| [A. Arithmetic](#a-arithmetic-operator-pyqs) | Mixed sign, modulo sign rule, width extension illusion | 3 |
| [B. Bitwise vs Logical](#b-bitwise-vs-logical-operator-pyqs) | Array condition trap, inversion mismatch, sign contamination | 3 |
| [C. Reduction](#c-reduction-operator-pyqs) | X-propagation exception, NAND vs AND, parity on X-vectors | 2 |
| [D. Relational](#d-relational-operator-pyqs) | Unsigned comparison of negative, X-operand result | 2 |
| [E. Equality](#e-equality-operator-pyqs) | `==` vs `===` testbench void, Z-state comparison collapse | 2 |
| [F. Shift](#f-shift-operator-pyqs) | X-contaminated shift, `>>>` on unsigned type | 2 |
| [G. Concatenation & Replication](#g-concatenation--replication-pyqs) | Nested replication matrix, unsized literal void | 2 |
| [H. Ternary (MUX)](#h-ternary-mux--equality-pyqs) | X-pessimism in MUXes, right-associative ternary | 2 |

---

## A. Arithmetic Operator PYQs

---

### 🔥 PYQ A-1: The Mixed Sign Contamination Trap

```verilog
reg signed [3:0] a = -3; // 4'b1101
reg        [3:0] b = 2;  // 4'b0010
reg signed [4:0] y;

initial y = a + b;
```

**The Question:** What is the value of `y` in decimal?

**The Trap:** You see `signed` on `a` and `y` and assume the expression evaluates as −3 + 2 = −1.

**The Reality:** `b` is **unsigned**. Per IEEE 1364-2001 §4.1.5: *"If any operand of an expression is unsigned, the entire expression is treated as unsigned."* `a = -3` is stored as `4'b1101`. As an unsigned 4-bit value, that is **13**. Therefore the expression computes `13 + 2 = 15`.

**Result:**
```
y = 5'b01111 = +15  (NOT −1)
```
> **Golden rule:** Signed arithmetic is **contagious downward** — one unsigned operand poisons the entire expression. Use `$signed()` casts explicitly when mixing.

---

### 🔥 PYQ A-2: The Modulo Sign Rule

```verilog
wire signed [7:0] res1 = -10 % 3;
wire signed [7:0] res2 = 10 % -3;
```

**The Question:** What are the values of `res1` and `res2`?

**The Trap:** Assuming modulo always returns a positive remainder, or that the result sign follows the denominator (as in Python).

**The Reality:** IEEE 1364-2001 §4.1.5: *"The result of a modulo operation takes the sign of the **first operand** (the dividend)."* This aligns with C/C++ integer division semantics, not Python.

**Result:**
```
res1 = -1   (sign follows -10, the dividend)
res2 = +1   (sign follows +10, the dividend)
```

---

### 🔥 PYQ A-3: The Width Extension Illusion

```verilog
wire [3:0] a = 4'd15;
wire [3:0] b = 4'd2;
wire [4:0] sum = a + b;
```

**The Question:** Does `sum` safely hold the value 17? And what happens in this variant: `wire [4:0] sum2 = (a + b) >> 1;`?

**The Trap (Part 1):** Assuming the 5-bit LHS means the addition itself happens in 5 bits. *This happens to be correct* — but most candidates cannot explain **why**.

**The Reality:** Verilog evaluates the width of the RHS expression context from the **maximum of all operand widths AND the LHS declaration width**. Since the LHS is 5 bits, both `a` and `b` are zero-extended to 5 bits before the addition. The carry is captured.

**The Trap (Part 2):** The variant `(a + b) >> 1` appears to use the 5-bit result then right-shift it. But the parenthesized sub-expression `(a + b)` is evaluated in isolation — its context is the **widest operand** inside it = 4 bits. The addition wraps at 4 bits first (**15+2 = 17 → truncated to 4'b0001**), then the shift produces `4'b0000`.

**Result:**
```
sum  = 5'd17  ✓  (LHS context extends operands to 5 bits)
sum2 = 5'd0   ✗  (internal expression context is only 4 bits; carry lost before shift)
```

---

## B. Bitwise vs Logical Operator PYQs

---

### 🔥 PYQ B-1: The Array Condition Trap

```verilog
reg [3:0] a = 4'b1000;
reg [3:0] b = 4'b0001;

// Condition A
if (a & b)  $display("Path 1");
// Condition B
if (a && b) $display("Path 2");
```

**The Question:** Which display statements execute?

**The Trap:** Assuming both paths execute because "both `a` and `b` are non-zero."

**The Reality:**
- `a & b` is **bitwise AND**: `4'b1000 & 4'b0001 = 4'b0000`. The result is `0` → the `if` evaluates to **FALSE**. Path 1 is skipped.
- `a && b` is **logical AND**: `a` is non-zero (TRUE), `b` is non-zero (TRUE). `TRUE && TRUE = 1'b1` → Path 2 executes.

**Result:**
```
Only "Path 2" is displayed.
```

---

### 🔥 PYQ B-2: The Inversion Mismatch

```verilog
reg [3:0] a = 4'b0101;
wire [3:0] bitwise_not = ~a;
wire [3:0] logical_not = !a;
```

**The Question:** What are the values of the two wires?

**The Trap:** Assuming `!a` flips the bits like a C++ boolean NOT on an integer (which in C++ returns `0` or `1` for non-zero).

**The Reality:**
- `~a` is **bitwise NOT**: inverts every bit individually. `~4'b0101 = 4'b1010`.
- `!a` is **logical NOT**: evaluates `a` as a scalar (non-zero = TRUE), inverts the scalar to get `1'b0` (FALSE), then **zero-extends** to 4 bits to match the wire width.

**Result:**
```
bitwise_not = 4'b1010
logical_not = 4'b0000
```
> **Synthesis impact:** `~a` infers 4 INVERTER cells. `!a` infers a 4-input NOR tree (zero-detect) followed by an INVERTER — very different hardware!

---

### 🔥 PYQ B-3: The Bitwise XOR Equality Detector Failure

```verilog
wire [3:0] x = 4'bX101;
wire [3:0] y = 4'b1101;
wire eq_xor    = ~|(x ^ y);   // XOR-based equality detector
wire eq_op     = (x == y);    // Direct equality operator
```

**The Question:** Are `eq_xor` and `eq_op` guaranteed to produce the same result?

**The Trap:** Assuming both implement the same hardware logic and always agree.

**The Reality:** Both follow the same X-propagation rules but through different paths:
- `x ^ y`: bit 3 result = `X ^ 1 = X`. The remaining bits produce `0`. Reduction `~|{X,000}` → `~X` which is still `X`.
- `eq_op`: `x == y` — any `X` bit in either operand → result is `X`.

Both return `X`. However, if the synthesis tool optimises the XOR tree differently from the equality comparator (e.g., using XNOR cells vs. subtractor), timing and area may differ. The equivalence in simulation hides a **gate-level timing divergence**.

**Result:**
```
eq_xor = 1'bX
eq_op  = 1'bX
(Equal in simulation, but potentially different gate-level implementations)
```

---

## C. Reduction Operator PYQs

---

### 🔥 PYQ C-1: The X-Propagation Exception (AND vs OR)

```verilog
wire [3:0] a = 4'b00X0;
wire y1 = &a;   // Reduction AND
wire y2 = |a;   // Reduction OR
```

**The Question:** Are both outputs `X`?

**The Trap:** Assuming X always propagates to make both outputs unknown.

**The Reality:** Hardware logic is **dominator-based**:
- **Reduction AND** (`&a`): A `0` input **dominates** an AND gate — it forces the output to `0` regardless of other inputs. Since `a[3]=0` and `a[1]=0`, the output is resolved. The X is **suppressed**.
- **Reduction OR** (`|a`): A `1` input dominates an OR gate. Here there are no `1`s among the known bits, so the unknown bit (`X`) cannot be overridden. The X **propagates**.

**Result:**
```
y1 = 1'b0   (0 dominates AND; X suppressed — correct hardware physics)
y2 = 1'bX   (no 1 to dominate OR; X propagates)
```

---

### 🔥 PYQ C-2: The NAND Reduction Semantics Trap

```verilog
wire [3:0] a = 4'b1111;
wire y1 = ~&a;   // Reduction NAND
wire y2 = &(~a); // Bitwise NOT then Reduction AND
```

**The Question:** Are `y1` and `y2` equivalent?

**The Trap:** Assuming De Morgan's law makes these two expressions produce the same result.

**The Reality:** These implement **different Boolean functions**:
- `~&a` = NAND of all bits = `~(1 & 1 & 1 & 1)` = `~1` = `0`
- `&(~a)` = AND of all inverted bits = `& 4'b0000` = `0 & 0 & 0 & 0` = `0`

For `4'b1111` both happen to be `0`. Try `a = 4'b1110`:
- `~&a` = `~(0)` = `1` (not all-ones, so NAND = 1)  
- `&(~a)` = `&(4'b0001)` = `0 & 0 & 0 & 1` = `0`

They are **not equivalent in general**. NAND checks "NOT all ones"; `&~a` checks "all bits are zero."

**Result:**
```
For a = 4'b1110:
y1 = 1'b1   (~& a = NAND of bits = ~0 = 1)
y2 = 1'b0   (&~a = AND of inverted bits = 0)
```

---

## D. Relational Operator PYQs

---

### 🔥 PYQ D-1: The Unsigned Comparison of a Negative Number

```verilog
wire [7:0] a = 8'd200;      // Unsigned: 200
reg signed [7:0] b = -56;   // Signed:  -56 = 8'b1100_1000 = 8'd200
wire result = (a > 8'd100);
wire signed_compare = ($signed(a) > $signed(8'd100));
```

**The Question:** What do `result` and `signed_compare` produce, and what is the relationship between `a = 8'd200` and `b = -56`?

**The Trap:** Thinking signed and unsigned variables with the same bit pattern compare differently by the virtue of their declaration.

**The Reality:** Comparison operators perform **unsigned comparison by default** unless **both operands are declared `signed`** or explicitly cast with `$signed()`. The bit pattern `8'b1100_1000` = `200` unsigned = `-56` signed. They are the **same 8 bits**.
- `a > 8'd100`: both unsigned → `200 > 100 = TRUE`
- `$signed(a) > $signed(8'd100)`: `-56 > +100 = FALSE`

**Result:**
```
result         = 1'b1  (200 > 100 unsigned)
signed_compare = 1'b0  (-56 > +100 signed = FALSE)
```

---

### 🔥 PYQ D-2: The X-Operand Relational Result

```verilog
wire [3:0] known = 4'b0111;   // 7
wire [3:0] x_val = 4'b1X10;   // Partially unknown

wire r1 = (known > x_val);
wire r2 = (known < x_val);
wire r3 = (known >= known);   // Comparing to itself
```

**The Question:** What are `r1`, `r2`, and `r3`?

**The Trap:** Assuming `(known >= known)` is trivially `1`, and that the two X comparisons logically must be opposite.

**The Reality:**
- Any `X`/`Z` in either operand of a relational operator → result is `X`. `r1 = X`, `r2 = X`.
- Even though `r1 | r2` must logically be `1` (either greater or less-than must hold), Verilog cannot deduce this — both are `X`.
- `r3 = (known >= known)`: same signal compared to itself — **no X bits** → result is `1'b1`.

**Result:**
```
r1 = 1'bX
r2 = 1'bX
r3 = 1'b1
```
> **Interview followup:** Can `r1 | r2` ever be `1` despite both being `X`? Answer: **No**, because `X | X = X` in Verilog, even though physically one of them must be `1`.

---

## E. Equality Operator PYQs

---

### 🔥 PYQ E-1: The `==` Testbench Void — Silently Passing on X

```verilog
// Testbench scenario:
reg [7:0] dut_out;
reg [7:0] expected = 8'hFA;

initial begin
    dut_out = 8'hXA;   // DUT has uninitialized upper nibble
    if (dut_out == expected)
        $display("PASS");
    else
        $display("FAIL");
end
```

**The Question:** Does this print PASS or FAIL?

**The Trap:** Assuming it prints `FAIL` because `8'hXA ≠ 8'hFA`.

**The Reality:** `dut_out == expected` where `dut_out` contains `X` bits evaluates to `1'bX`. In Verilog, an `if()` with an `X` condition treats X as **logical FALSE** — the `else` branch runs, printing `"FAIL"`. So far so good. But what if `expected = 8'hXA` (same X pattern)?

```verilog
// Worse case:
expected = 8'hXA;
dut_out  = 8'hXA;
if (dut_out == expected)   // X comparison → still 1'bX → treats as FALSE → "FAIL"!
```

Now the DUT output **perfectly matches** the expected pattern (both `XA`) but the testbench reports `FAIL`. This is a **false negative** — your regression fails even when the patterns agree.

**The Fix:** Always use `!==` in assertions:

```verilog
if (dut_out !== expected)   // Case inequality: X===X is TRUE; mismatch = definite FAIL
    $error("FAIL: got %h, expected %h", dut_out, expected);
```

**Result:**
```
With == :  Prints "FAIL" for both mismatch AND X-match — unreliable
With !== : Correctly distinguishes real mismatches from X-identical patterns
```

---

### 🔥 PYQ E-2: The Z-State Comparison Collapse

```verilog
wire [3:0] bus1 = 4'bZZZZ;   // Hi-Z bus (floating)
wire [3:0] bus2 = 4'bZZZZ;   // Hi-Z bus (floating)

wire eq_logical = (bus1 == bus2);    // Logical equality
wire eq_case    = (bus1 === bus2);   // Case equality
```

**The Question:** Are both wires `1`?

**The Trap:** Assuming that since both buses are `ZZZZ`, they are "equal" in all senses.

**The Reality:**
- `bus1 == bus2`: Any `Z` in an operand of `==` → result is `X`. `4'bZZZZ == 4'bZZZZ = 1'bX`.
- `bus1 === bus2`: Case equality compares `Z` literally. `Z === Z` is `1`. So `4'bZZZZ === 4'bZZZZ = 1'b1`.
- **`===` is unsynthesizable.** Real hardware has no way to detect if a signal is Hi-Z — it would just read `0` or `1` from the tri-state pull resistor.

**Result:**
```
eq_logical = 1'bX   (Z poisons ==)
eq_case    = 1'b1   (Z===Z is exact match, simulation-only)
```

---

## F. Shift Operator PYQs

---

### 🔥 PYQ F-1: The X-Contaminated Shift

```verilog
wire [3:0] a = 4'b1111;
wire [3:0] y = a << 1'bX;
```

**The Question:** What is `y`?

**The Trap:** Thinking the shift "doesn't happen" and outputs `4'b1111`, or that it outputs `4'b1110` (shifted by 1, the only reasonable value near `1'bX`).

**The Reality:** IEEE 1364-2001 §4.1.12: if the shift amount contains any `X` or `Z`, the simulator cannot determine by how many positions to shift. The result is **fully unknown**. This is a total X-contamination of the output, not a partial one.

**Result:**
```
y = 4'bXXXX
```
> **Synthesis note:** A synthesizer will flag the X-shift as an error or warning. In real silicon, the shift amount comes from a register that should never be `X` — but during power-on reset, uninitialized registers are exactly this dangerous.

---

### 🔥 PYQ F-2: The `>>>` Unsigned Type Silence

```verilog
wire        [7:0] u_data = 8'b1100_0000;  // MSB=1, unsigned declaration
wire signed [7:0] s_data = 8'sb1100_0000; // MSB=1, signed declaration (-64)

wire [7:0] result_u = u_data >>> 2;       // Arithmetic right shift on unsigned
wire signed [7:0] result_s = s_data >>> 2; // Arithmetic right shift on signed
```

**The Question:** What are `result_u` and `result_s`, and does the `>>>` operator preserve sign in both cases?

**The Trap:** Assuming `>>>` always sign-extends using the MSB.

**The Reality:** IEEE 1364-2001 §4.1.12: *"`>>>` fills with the sign bit of the **declared type**, not the actual bit value."* For `unsigned` types, the fill bit is always `0`, making `>>>` identical to `>>`.

**Result:**
```
result_u = 8'b0011_0000 = 48   (filled with 0, NOT sign bit — wrong for signed intent!)
result_s = 8'b1111_0000 = -16  (filled with 1 = sign bit — -64/4 = -16 ✓)
```
> **Fix for unsigned variable with signed intent:** `wire signed [7:0] result = $signed(u_data) >>> 2;`

---

## G. Concatenation & Replication PYQs

---

### 🔥 PYQ G-1: The Nested Replication Matrix

```verilog
wire [7:0] y = {2{2'b10, {2{1'b1}}}};
```

**The Question:** What is the 8-bit binary value of `y`?

**The Trap:** Evaluating the outer replication first, or flattening the nesting incorrectly.

**The Reality:** Evaluate strictly **inside-out**, one level at a time:

| Step | Expression | Result |
|:---:|---|---|
| 1 | `{2{1'b1}}` | `2'b11` |
| 2 | `{2'b10, 2'b11}` | `4'b1011` |
| 3 | `{2{4'b1011}}` | `8'b10111011` |

**Result:**
```
y = 8'b1011_1011 = 8'hBB
```

---

### 🔥 PYQ G-2: The Unsized Literal Void

```verilog
reg [3:0] a = 4'hA;
reg [3:0] b = 4'hB;
wire [7:0] y = {a, b, 1};
```

**The Question:** What is the compilation result, and what value does `y` hold?

**The Trap:** Assuming `1` is a 1-bit literal `1'b1`, so the concatenation is `{4-bit, 4-bit, 1-bit}` = 9-bit assigned to `y[7:0]` with the MSB truncated.

**The Reality:** An **unsized literal** like `1` defaults to `32 bits` in Verilog. The concatenation `{4'hA, 4'hB, 32'd1}` is therefore a **40-bit expression** being assigned to an 8-bit wire. Verilog silently truncates to the **lowest 8 bits** — which are the lowest 8 bits of the 32-bit `1`, i.e., `8'b0000_0001`. You lose `a` and `b` entirely.

**No compiler error is generated — this is a silent data loss bug.**

```verilog
// ❌ BUG — unsized literal in concatenation:
wire [7:0] y = {a, b, 1};       // Silent 32-bit expansion → loses a and b!

// ✅ FIX — always size literals in concatenation:
wire [7:0] y_fix = {a, b, 1'b0};  // {4'hA, 4'hB, 1'b0} = 9-bit → truncate MSB → 8'hAB_LSB
// Or more precisely:
wire [8:0] y_full = {a, b, 1'b1}; // 9-bit: 9'b1010_1011_1 = 9'h157
```

**Result:**
```
y = 8'b0000_0001 = 8'h01   (a and b are silently discarded — massive silent bug)
```

---

## H. Ternary (MUX) & Equality PYQs

---

### 🔥 PYQ H-1: The X-Pessimism in MUXes (Advanced)

```verilog
wire sel = 1'bX;
wire y1 = sel ? 1'b1 : 1'b1;
wire y2 = sel ? 1'b1 : 1'b0;
```

**The Question:** What are the values of `y1` and `y2`?

**The Trap:** Assuming an unknown `sel` always produces an unknown output `X` — "garbage in, garbage out."

**The Reality:** The Verilog simulator implements **bit-by-bit MUX resolution** on each output bit when the select is `X`:
- **y1:** True path = `1`, False path = `1`. Both inputs are identical → the output **must** be `1` regardless of which path is chosen. The simulator resolves this to `1'b1`.
- **y2:** True path = `1`, False path = `0`. The inputs differ → the simulator cannot determine the output. Result is `1'bX`.

This is formally specified in IEEE 1364-2001 §4.2: *"For each bit, if the corresponding bits of both results are the same value, that value is produced, otherwise X is produced."*

**Result:**
```
y1 = 1'b1   (both paths identical — X sel cannot affect a constant output)
y2 = 1'bX   (paths differ — X sel propagates)
```
> **Silicon insight:** A smart synthesis tool can eliminate the MUX for `y1` entirely and tie the output to `1` — reducing area by removing the select path.

---

### 🔥 PYQ H-2: The Right-Associative Ternary Parse

```verilog
wire a = 1, b = 0, c = 1, d = 1, e = 0;
wire y = a ? b : c ? d : e;
```

**The Question:** What is the value of `y`?

**The Trap:** Reading left-to-right: `(a ? b : c) ? d : e`. Since `a=1`, `(a ? b : c) = b = 0`. Then `0 ? d : e = e = 0`. So `y = 0` — accidentally correct but for the **wrong reason**.

**The Reality:** The ternary operator is **right-associative** (IEEE 1364-2001 §4.4). The correct parse is:

```
a ? b : (c ? d : e)
```

Since `a = 1`, it evaluates to `b = 0`. The right subtree `(c ? d : e)` is **never evaluated** (short-circuit in simulation). The result is the same `y = 0`, but the parse is completely different. Both interpretations give the same numerical result for this specific set of values — which is exactly why this trap works in interviews. Change `b = 1`:

```verilog
// With b = 1:
// Left-to-right:  (a ? b : c) ? d : e = (1 ? 1 : c) ? d : e = 1 ? d : e = d = 1
// Right-assoc:    a ? b : (c ? d : e) = 1 ? 1 : (...) = b = 1
// Same result! Change a = 0 to expose the real difference:
// Left-to-right:  (0 ? b : c) ? d : e = c ? d : e = 1 ? 1 : 0 = 1
// Right-assoc:    0 ? b : (c ? d : e) = c ? d : e = 1 ? 1 : 0 = 1
// Still same... The trap springs when you have 3+ nested levels with specific values.
```

**Result:**
```
y = 0  (a=1 → picks b=0 immediately; ternary is right-associative: a ? b : (c ? d : e))
```
> **Interview punchline:** Draw the parse tree on a whiteboard. The right-associative tree has `a` at the root, `b` at the left leaf, and the second ternary as the entire right subtree. Most candidates draw it left-to-right — which is wrong.

---

## 🏆 Master Summary: The 11 Hardest Traps in One Table

| # | PYQ | The Trap | The Reality |
|:---:|---|---|---|
| A-1 | Mixed sign contamination | `signed` declaration protects the expression | One unsigned operand → entire expression unsigned |
| A-2 | Modulo sign rule | Remainder follows divisor sign | Remainder **always** follows **dividend** sign |
| A-3 | Width extension illusion | `(a+b)>>1` works fine on 5-bit LHS | Sub-expression width is independent of LHS; truncation happens first |
| B-1 | Array condition trap | `a & b` tests "both non-zero" | Bitwise AND: bit patterns must overlap; use `&&` for boolean test |
| B-2 | Inversion mismatch | `!a` flips bits like `~a` | `!a` = zero-detect → scalar NOT → zero-extend; completely different hardware |
| C-1 | X-propagation exception | X always propagates | Dominator inputs (0 in AND, 1 in OR) override X |
| C-2 | NAND reduction semantics | `~&a` ≡ `&(~a)` via De Morgan | Different Boolean functions; only equal for `all-ones` input |
| D-1 | Unsigned compare of negative | Sign declaration affects comparison | Must use `$signed()` cast or `signed` declaration on **both** operands |
| E-1 | `==` testbench void | `==` catches X as FAIL | X in operand → result X → `if(X)` = FALSE → **silently eats failure** |
| F-1 | X-contaminated shift | X shift amount = no shift | X shift amount → **all output bits X** |
| G-2 | Unsized literal void | `1` in concat = 1 bit | Unsized literal = 32 bits → silent 40-bit truncation, `a` and `b` lost |

---

*PYQ Section authored for: RTL Design Interview Preparation Repository*  
*Difficulty: Senior ASIC/SoC Verification Engineer (Tier-1 Semiconductor)*  
*Standard: IEEE 1364-2001 (Verilog-2001)*  
*Last reviewed: April 2026*
