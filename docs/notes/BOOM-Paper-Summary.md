## BOOM Paper Summary

### 1. Introduction

BOOM (Berkeley Out-of-Order Machine) is an open-source, parameterizable, out-of-order (OoO) RISC-V processor core designed at UC Berkeley. It aims to bring realistic, superscalar microarchitecture design to education and research, while being capable of real-world synthesis and tapeouts. BOOM is written in Chisel and integrates tightly with the Rocket Chip SoC generator ecosystem.

The motivation behind BOOM is to enable research and education in OoO designs by providing a reusable and extensible baseline core that can be targeted for both FPGAs and ASICs.

### 2. Key Design Choices

#### ISA: RISC-V

BOOM implements the RISC-V ISA, chosen for its simplicity, openness, and extensibility. It avoids legacy baggage, making it ideal for VLSI-driven research and new ISA extensions.

#### Language: Chisel

Chisel is a hardware construction language embedded in Scala. It supports features like parameterized generators, functional programming, and object-oriented design. Chisel allows BOOM to be easily configured for various microarchitectural parameters and to generate Verilog for FPGA and ASIC flows.

#### SoC Integration: Rocket Chip

BOOM is not a standalone processor. It uses Rocket Chip, another open-source SoC generator from Berkeley, to provide memory hierarchy, caches, interconnects, and uncore components. BOOM slots in as the backend core by replacing the in-order Rocket core with an OoO BOOM core.

### 3. BOOM Microarchitecture

BOOM is a dynamically scheduled, superscalar core that supports register renaming, speculation, and out-of-order execution. It features a frontend that fetches and decodes instructions, a backend with physical register file (PRF), reservation stations (RS), and a reorder buffer (ROB), and a commit stage that retires instructions in order.

Each component is designed to be modular and parameterizable, allowing the same source to generate cores of different widths, depths, and complexities.

BOOM's pipeline consists of:

- Fetch stage (instruction cache and branch prediction)
    
- Decode and rename
    
- Issue through reservation stations
    
- Execution via ALUs, LSU, FPU
    
- Commit via ROB
    

### 4. Design Philosophy

- **Reusability**: BOOM reuses Rocket Chip infrastructure heavily, avoiding duplication and enabling fast SoC generation.
    
- **Parameterization**: Almost every structural parameter (ROB size, fetch width, issue width, etc.) is configurable.
    
- **Tapeout Ready**: BOOM targets real-world ASIC flows and has been taped out multiple times as part of full SoCs.
    
- **Education Friendly**: The design exposes all key OoO concepts and is small enough to study but realistic enough for synthesis.
    

### 5. Implementation Highlights

- Implements full out-of-order pipeline with realistic complexity.
    
- Uses rename maps, free lists, and PRF for register renaming.
    
- Tracks instruction dependencies via reservation stations.
    
- Uses ROB to maintain precise exceptions and enforce in-order commit.
    
- Interacts with memory via Rocket’s data cache and memory hierarchy.
    

It supports key ISA features such as:

- Atomic memory operations (AMOs)
    
- FPU (floating-point support)
    
- Privileged modes and MMU
    

### 6. Performance and Simulation

For evaluation, the BOOM team ran SPEC CPU2006 benchmarks. Because each benchmark can take trillions of instructions, software simulation becomes impractical.

They used SimPoints to sample representative instruction windows (~10-100M instructions) instead of simulating entire benchmarks. Even then, full simulation on software takes too long — a single run could take 12+ hours at 50 MHz on an FPGA.

They propose FPGA-based simulation and even FPGA clusters to parallelize benchmark runs and speed up performance evaluations.

### 7. Takeaways

- BOOM itself is a single-core OoO core. To build multi-core systems, multiple BOOMs can be instantiated via the Rocket Chip generator.
    
- BOOM enables realistic out-of-order microarchitecture design, simulation, and tapeout with an open-source toolchain.
    
- It’s a great platform for education, research, and prototyping advanced processor ideas.