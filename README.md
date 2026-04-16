# RTL Design & VLSI Interview Preparation

Welcome to my comprehensive repository for RTL design concepts, Verilog fundamentals, and VLSI interview preparation. This repository is structured into modules covering everything from basic digital design to advanced verification and synthesis.

## 📚 Modules

### [Module 1: The Silicon Paradigm & Verilog Fundamentals](./module_1_fundamentals.md)
* **The Hardware vs. Software Paradigm Shift**
* **Verilog Basics:** `wire` vs. `reg` and physical synthesis reality.
* **Levels of Abstraction:** Behavioral, Dataflow, Structural, and Switch level.
* **Sequential Logic:** Synchronous vs. Asynchronous resets, and D-Flip Flop implementation.
* **The VLSI Design Flow & Front-End Tools**

### [Module 2: The Silicon Real Estate — VLSI IPs](./module_2_vlsi_ips.md)
* **Soft IP:** Synthesizable RTL source — maximally flexible, zero guaranteed timing.
* **Firm IP:** Gate-level netlist — technology-specific, area/power bounded.
* **Hard IP:** Pre-placed GDSII macro — silicon-proven, zero flexibility.
* **VIP (Verification IP):** UVM/SystemVerilog testbench component — *never* synthesized.
* **System Architecture IP Flow** with Mermaid diagram.

### [Module 3: The Physics of Scaling & Technology Nodes](./module_3_technology_nodes.md)
* **Technology Node** — What it historically meant vs. the modern marketing label ("The 3nm Lie").
* **Moore's Law vs. Dennard Scaling** — and the exact moment Dennard scaling died (~2005).
* **PPA Trade-off Table** — leakage power explosion and RC delay bottleneck at advanced nodes.
* **Transistor Evolution:** Planar MOSFET → FinFET → GAAFET/Nanosheet with Mermaid diagram.

### [Module 4: The RTL-to-GDSII Toolchain & Full Adder Case Study](./module_4_rtl_to_gdsii.md)
* **Automated Digital Flow vs. Custom Analog Flow** — tool mapping and philosophy.
* **Open-Source EDA Stack:** `iverilog`, `gtkwave`, `yosys`, `OpenROAD`, `xschem`, `ngspice`, `Magic`, `netgen`.
* **Physical Signoff:** DRC (Design Rule Check) & LVS (Layout vs. Schematic) — with interview trap.
* **Case Study 4.1:** 1-bit Full Adder traced from RTL → Yosys/SKY130 netlist → Floorplan → Placement → Routing → GDSII.

---

## 🚀 Repository Goals
- **Conceptual Revision:** A reference for last-minute interview preparation.
- **Hardware Realities:** Focusing on synthesis and silicon behavior rather than just simulation.
- **Portfolio:** Showcasing clean, documented, and professional RTL code.

## 🛠️ Tools & Technologies

### Verification
- **Languages:** Verilog (IEEE 1364), SystemVerilog (IEEE 1800)
- **Simulation:** `iverilog` (Icarus Verilog), `gtkwave` (Waveform Viewer)
- **Industry Simulators:** ModelSim/Questasim, Synopsys VCS, Cadence Xcelium

### Digital Synthesis & Physical Design (Open-Source)
- **Synthesis:** `yosys` (with ABC back-end, SkyWater SKY130 PDK)
- **Place & Route:** `OpenROAD` (Floorplan, CTS, Routing, STA)
- **Layout & DRC:** `Magic`
- **LVS:** `netgen`

### Analog & Custom Design (Open-Source)
- **Schematic:** `xschem`
- **SPICE Simulation:** `ngspice`
- **Layout:** `Magic` (open-source), Cadence `Virtuoso` (industry)

### Industry EDA
- **Synthesis:** Synopsys Design Compiler, Cadence Genus
- **P&R:** Cadence Innovus, Synopsys IC Compiler 2
- **Signoff:** Mentor/Siemens Calibre (DRC/LVS), Synopsys PrimeTime (STA)
- **Visualization:** GTKWave, Cadence Verdi, Mermaid.js

---
Created and maintained by [Shravana HS](https://github.com/ShravanaHS).
