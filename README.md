

## 📚 Modules

### [Module 1: The Silicon Paradigm & Verilog Fundamentals](./module_1_fundamentals.md)
* **The Hardware vs. Software Paradigm Shift**
* **Verilog Basics:** `wire` vs. `reg` and physical synthesis reality.
* **Levels of Abstraction:** Behavioral, Dataflow, Structural, and Switch level.
* **Sequential Logic:** Synchronous vs. Asynchronous resets, and D-Flip Flop implementation.
* **The VLSI Design Flow & Front-End Tools**

### [Module 2: Silicon Real Estate — IPs & Technology Nodes](./module_2_vlsi_ips.md)
* **VLSI IPs:** Soft, Firm, and Hard IP blocks + VIP (Verification IP) deep dive.
* **Technology Nodes:** What they are vs. the modern marketing label ("The 3nm Lie").
* **Scaling Laws:** Moore's Law vs. Dennard Scaling and the leakage power crisis.
* **Transistor Evolution:** Planar MOSFET → FinFET → GAAFET/Nanosheet architecture.

### [Module 3: The RTL-to-GDSII Toolchain & Full Adder Case Study](./module_3_rtl_to_gdsii.md)
* **Automated Digital Flow vs. Custom Analog Flow** — tool mapping and philosophy.
* **Open-Source EDA Stack:** `iverilog`, `gtkwave`, `yosys`, `OpenROAD`, `xschem`, `ngspice`, `Magic`, `netgen`.
* **Physical Signoff:** DRC (Design Rule Check) & LVS (Layout vs. Schematic).
* **Case Study:** 1-bit Full Adder traced from RTL → GDSII geometry.

### [Module 5: Verilog Fundamentals — Module Anatomy, Keywords, Verification & Synthesis](./module_5_verilog_fundamentals.md)
* **Part A: Module Anatomy & Instantiation:** ANSI-style declarations, Port mapping (Positional vs. Named), Hierarchy principles.
* **Part B: Keywords & Verification:** Reserved lowercase lexicon, Event-driven simulation engine, Testbench anatomy, and the non-synthesizable `initial` block.
* **Part C: Design Methodologies & Synthesis:** Translation vs. Optimization vs. Mapping phases, Top-Down/Bottom-Up/Meet-in-the-Middle workflows.
* **Silicon Realities:** Why `#delay` is ignored in synthesis and how `reg` doesn't always equal a flip-flop.

### [Module 6: The Grammar of Silicon — Lexical Elements & Data Types](./lexical_elements.md)
A standalone masterclass reference covering the fundamental grammar, syntax, and data types of Verilog for rapid pre-interview review.
* **Comments & Identifiers:** Intent over description, non-nesting traps, and synthesis-escaped names.
* **Data Types:** Nets (`wire`, `wand`, `wor`) vs. Variables (`reg`), and the multiple-driver `X` contention.
* **Number Representation:** 4-logic states, unsized literal bloat, and silent truncation/extension traps.
* **Advanced Types:** Why `real` is unsynthesizable and how fixed-point arithmetic solves it in hardware.
* **Vectors vs. Arrays:** Bus syntax vs. Memory depth and the standard Verilog array assignment limitation.
* **Sign Extension & Time:** Sign-extension hacks using replication, and the `$time` rounding/precision minefield.


## 🚀 Repository Goals

- **Conceptual Revision:** A reference for last-minute interview preparation.
- **Hardware Realities:** Focusing on synthesis and silicon behavior rather than just simulation.
- **Portfolio:** Showcasing clean, documented, and professional RTL code.

