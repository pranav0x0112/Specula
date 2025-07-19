# Specula: Design Notes

This document contains evolving design notes for Specula, a custom out-of-order (OoO) RISC-V processor core. As development progresses, this file will serve as a central log for architectural decisions, implementation strategies, and design tradeoffs.

---

## 1. Project Goals

- Build a simple, simulation-ready OoO core (RISC-V RV32I)
    
- Focus on understanding and implementing core OoO concepts:
    
    - Register renaming
        
    - Reorder buffer (ROB)
        
    - Reservation stations (RS)
        
    - Physical register file (PRF)
        
    - Issue logic and out-of-order execution
        
    - Speculative branch prediction and recovery
        
- Modular, clean, and extensible RTL (initially in Bluespec)
    

---

## 2. Initial Scope

- Single issue (w/ option to go dual-issue later)
    
- Integer instructions only (RV32I)
    
- No MMU, virtual memory, or exceptions in early stages
    
- Basic branch predictor (2-bit bimodal or gshare)
    
- In-order commit using ROB
    
- Static PRF allocation
    
- Simulation support with test payloads
    

---

## 3. Design Decisions

- **Language**: Bluespec SystemVerilog for now 
    
- **Simulation first**: focus on correctness and traceability over FPGA deployability
    
- **Instruction fetch**: fixed-length fetch unit, possibly simple instruction queue
    
- **Decode**: static decoding into internal µops format
    
- **Rename**: physical register allocation table (RAT), freelist, busy table
    
- **Issue/Execute**:
    
    - RS holds ready instructions
        
    - Broadcast result via CDB-like model
        
    - Functional units operate in parallel
        
- **Writeback**: back to PRF only (architectural reg updates occur on commit)
    
- **Commit**:
    
    - In-order commit through ROB
        
    - Handles mispredictions, flushes, exception recovery (future)
        

---

## 5. Next Steps

- Finalize block diagram
    
- Define interface contracts between blocks (e.g. Fetch → Decode, Rename → RS)
    
- Start with basic Fetch–Decode–Rename pipeline
    
- Simulate flow of a few sample instructions through the pipeline manually
    

---

## 6. Inspirations

- BOOM microarchitecture
    
- FireSim methodology
    
- Chisel designs (for long-term reference)
    
- RISC-V Out-of-Order Core Tutorial by Princeton