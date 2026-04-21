# RTL Design — VLSI & Digital Design Interview Preparation

A structured, technically rigorous reference for VLSI and Digital Design interviews.
Every module focuses on **silicon behavior**, **synthesis realities**, and **interview traps** — not textbook theory.

---

## 📁 Repository Structure

```
RTL_Design/
├── 01_vlsi_fundamentals.md
├── 02_vlsi_ips_technology_nodes.md
├── 03_rtl_to_gdsii_flow.md
├── 04_lexical_elements_data_types.md
├── 05_verilog_module_anatomy.md
├── 06_gate_level_modeling.md
├── 07_dataflow_modeling.md
├── 08_verilog_operators.md
├── 09_structural_modeling.md
└── projects/
    ├── full_adder/
    ├── decodertree/
    ├── mux4x1/
    ├── muxytree/
    ├── operators/
    ├── project_2/
    └── project_3/
```

---

## 📚 Modules

| # | File | Topic |
|:---:|---|---|
| 01 | [01_vlsi_fundamentals.md](./01_vlsi_fundamentals.md) | The Silicon Paradigm & Verilog Fundamentals |
| 02 | [02_vlsi_ips_technology_nodes.md](./02_vlsi_ips_technology_nodes.md) | Silicon Real Estate — IPs & Technology Nodes |
| 03 | [03_rtl_to_gdsii_flow.md](./03_rtl_to_gdsii_flow.md) | The RTL-to-GDSII Toolchain & Full Adder Case Study |
| 04 | [04_lexical_elements_data_types.md](./04_lexical_elements_data_types.md) | Lexical Elements & Data Types |
| 05 | [05_verilog_module_anatomy.md](./05_verilog_module_anatomy.md) | Verilog Module Anatomy, Keywords & Synthesis |
| 06 | [06_gate_level_modeling.md](./06_gate_level_modeling.md) | Gate-Level Modeling & Primitives |
| 07 | [07_dataflow_modeling.md](./07_dataflow_modeling.md) | Dataflow Modeling — Continuous Assignments |
| 08 | [08_verilog_operators.md](./08_verilog_operators.md) | The 10 Verilog Operator Families |
| 09 | [09_structural_modeling.md](./09_structural_modeling.md) | Structural Modeling — The Silicon Schematic |

---

## 🔬 Vivado Lab Projects

| Project | Description |
|---|---|
| `projects/full_adder/` | 1-bit Full Adder — RTL, synthesis & simulation |
| `projects/decodertree/` | 2-to-4 and 3-to-8 Decoder tree |
| `projects/mux4x1/` | 4:1 MUX — behavioral, dataflow & structural variants |
| `projects/muxytree/` | 4:1 MUX using structural 2:1 MUX tree + testbench |
| `projects/operators/` | Ternary operator synthesis demonstration |
| `projects/project_2/` | 2:1 MUX with testbench |
| `projects/project_3/` | 4:1 MUX composed of 2:1 MUX modules |

---

## 🧠 Key Technical Standards

| Standard | Scope |
|---|---|
| IEEE 1364-2001 (Verilog-2001) | All RTL code in this repository |
| `u_` prefix | Module instances |
| `w_` prefix | Internal routing wires |
| `g_` prefix | Gate primitive instances |
| Named port mapping | Mandatory for all module instantiations |
