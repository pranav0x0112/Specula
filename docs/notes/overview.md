# Out-of-Order Execution: Overview

Out-of-order (OoO) execution allows a CPU to execute instructions as soon as their operands are available, rather than waiting for all previous instructions to complete. This increases parallelism and improves performance, especially in workloads with instruction-level parallelism (ILP).

## Motivation for OoO

- In-order pipelines stall frequently due to data dependencies and long-latency operations (e.g., memory loads).
    
- OoO execution decouples instruction _fetch/decode_ from _execute/commit_, allowing the backend to exploit available execution units more efficiently.
    
- Key idea: **Don't wait unnecessarily** — execute when inputs are ready.
    

### Simple Example:

```
1:   LW  x1, 0(x2)     ; Load, might take several cycles
2:   ADD x3, x4, x5    ; Independent, can be executed immediately
```

- **In-order pipeline**: `ADD` stalls behind `LW`.
    
- **OoO core**: `ADD` proceeds if x4 and x5 are ready, while `LW` still loads.
    

---

## Core Components of an OoO Core

|Component|Role|
|---|---|
|**Register Renaming**|Maps logical to physical registers; avoids WAR/WAW hazards|
|**Reservation Stations**|Buffers instructions until operands are ready|
|**Reorder Buffer (ROB)**|Tracks instructions in program order; enables in-order commit|
|**Physical Register File**|Stores actual register values, decoupled from architectural names|
|**Issue Logic**|Detects ready ops (wakeup) and chooses among them (select)|
|**Commit Unit**|Commits instructions in program order, updates architectural state|

These components let the backend operate out-of-order while presenting a precise, in-order frontend to the programmer.

---

## High-Level Instruction Lifecycle (8 Stages)

1. **Fetch** – Get instruction from memory into the fetch queue
    
2. **Decode** – Extract opcode and source/dest registers
    
3. **Rename** – Allocate new physical registers for dests, update rename table
    
4. **Dispatch** – Allocate ROB entry; send instruction and operand tags to RS
    
5. **Issue (Wakeup + Select)** – When all operands are ready, issue to FU
    
6. **Execute** – Functional unit performs operation
    
7. **Writeback** – FU broadcasts result tag; update PRF + wakeup dependent RS
    
8. **Commit** – ROB commits instructions in-order, freeing resources
    

---

## Hazards in Pipelined Execution

|   |   |   |
|---|---|---|
|Hazard Type|Description|OoO Mitigation|
|RAW|Read After Write (true dependency)|Stall until data is ready (RS wait)|
|WAR|Write After Read (false dependency)|Eliminated via register renaming|
|WAW|Write After Write (false dependency)|Eliminated via register renaming|
|Control|Uncertainty due to branches|Speculative execution + branch predictor + flush logic|

---

## Precise Exceptions & State Recovery

- To maintain **precise exceptions**, instructions must **commit in-order**.
    
- ROB ensures correct state: instructions are only committed after completion and validity.
    
- On branch misprediction or exception, all younger instructions in the ROB are flushed.
    
- Physical registers are reference-counted or freelisted to support rollback.
    

---

## Scalability and Limits

- Number of in-flight instructions limited by ROB entries, RS capacity, and physical register count.
    
- Aggressive OoO cores (e.g., BOOM, Cortex-A76) use large ROBs (128+ entries), wide issue (2–6), and deep RS banks.
    
- Power and complexity grow with window size — hence "lightweight" OoO cores compromise.