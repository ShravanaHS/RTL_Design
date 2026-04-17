

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

### [Module 5: The Anatomy of a Verilog Module & Instantiation](./module_5_module_anatomy.md)
* **Comments:** Single-line (`//`) vs. Block (`/* */`) and the non-nesting catastrophe trap.
* **ANSI-Style Module Declaration:** Parameterized, inline port direction — the modern standard.
* **Positional vs. Named Port Mapping:** Why `.port(signal)` named mapping is the only industrial standard.
* **Module Hierarchy:** How the instantiation tree maps directly to the physical floorplan.

### [Module 6: Keywords & Verification Fundamentals](./module_6_keywords_verification.md)
* **Keywords:** All reserved — strictly lowercase. Verilog is fully case-sensitive.
* **Event-Driven Simulation Engine:** How the simulator's event queue and NBC scheduling regions work.
* **Abstract Time (`#delay`):** A simulation-only construct — completely ignored by the synthesizer.
* **The Testbench:** A closed universe (no ports), DUT inputs are `reg`, outputs are `wire`.
* **`initial` Block:** One-shot simulation stimulus — not synthesizable in ASIC flows.

### [Module 7: Design Methodologies & Advanced Synthesis](./module_7_methodologies_synthesis.md)
* **Synthesis Phases:** Translation → Optimization (ruthless dead-code elimination) → Technology Mapping.
* **Top-Down:** SoC spec → RTL → Gates. Architecture-driven with late physical feedback.
* **Bottom-Up:** PDK cells → Functional blocks → System. Implementation-driven.
* **Meet-in-the-Middle:** The real-world standard — Top-Down RTL converges with Bottom-Up constraints via iterative ECOs.
* **Mermaid Diagram:** Full Top-Down / Bottom-Up / Meet-in-the-Middle methodology flowchart.

---

## 📖 Reference Guides

### [Lexical Elements & Data Types — The Grammar of Silicon](./lexical_elements.md)
A standalone masterclass reference covering the fundamental grammar, syntax, and data types of Verilog. Designed for rapid pre-interview review.
* **Comments:** Intent over description. Block comment non-nesting trap. `` `ifdef `` safe disable pattern.
* **Identifiers:** Naming rules, case-sensitivity trap, escaped identifiers in synthesis netlists.
* **Keywords:** Reserved lexicon categories. `reg` misconception — it is NOT a flip-flop keyword.
* **Ports:** Direction-to-type mapping. Driving an input trap. `inout` tri-state buffer syntax.
* **Number Literals:** 4-logic states (`0`,`1`,`X`,`Z`). Unsized bloat (32-bit default). Silent truncation/extension.
* **Data Types:** Nets (`wire`, `wand`, `wor`) vs. Variables (`reg`). Multiple-driver contention. Signed/Unsigned mixing.
* **`integer` & `real`:** Loop counter vs. datapath use. Why `real` is unsynthesizable — Fixed-Point alternative.
* **Vectors vs. Arrays:** Bus (`[N:0] name`) vs. Memory (`name [depth]`). Illegal whole-array assignment.
* **Strings:** ASCII storage in `reg` vectors. Silent truncation and null-padding traps.
* **Special Characters:** `#`, `@`, `$`, `` ` ``, `?:`. Concatenation/Replication operators. Sign extension hack. `$time` rounding error.


## 🚀 Repository Goals

- **Conceptual Revision:** A reference for last-minute interview preparation.
- **Hardware Realities:** Focusing on synthesis and silicon behavior rather than just simulation.
- **Portfolio:** Showcasing clean, documented, and professional RTL code.

