# Out-of-Order Execution: Overview

Out-of-order (OoO) execution allows a CPU to execute instructions as soon as their operands are available, rather than waiting for all previous instructions to complete. This increases parallelism and improves performance, especially in workloads with instruction-level parallelism (ILP).

---

## Motivation for OoO

- In-order execution can result in pipeline stalls when an instruction with a long latency (like a load from memory) blocks following instructions.
    
- OoO allows subsequent independent instructions to execute as soon as their data dependencies are resolved, improving utilization of functional units and boosting throughput.
    

### Simple Example:
```asm
1:   LW  x1, 0(x2)     ; Load, might take several cycles
2:   ADD x3, x4, x5    ; Independent, can be executed immediately
```

- With **in-order**: `ADD` is stalled until `LW` completes.
- With **OoO**: `ADD` executes immediately after decode, provided its operands are ready.

---

## Core Components of an OoO Core

|Component|Role|
|---|---|
|**Register Renaming**|Eliminates WAR/WAW hazards by mapping logical to physical registers|
|**Reservation Stations (RS)**|Hold instructions waiting for operands; issue when ready|
|**Reorder Buffer (ROB)**|Maintains program order for in-order commit; handles exceptions|
|**Physical Register File (PRF)**|Stores values of all physical registers|
|**Issue Logic**|Detects ready instructions (wakeup) and selects among them (select)|
|**Commit Unit**|Commits completed instructions in order, ensuring architectural state|

These components decouple the execution phase from the program order, allowing multiple instructions to be in-flight and executed in parallel.

---

## High-Level Instruction Lifecycle

1. **Fetch** – Fetch instructions using the PC
    
2. **Decode** – Decode opcode and operand fields
    
3. **Register Rename** – Assign new physical registers, update rename table
    
4. **Dispatch** – Allocate ROB entry, send to RS, track operands
    
5. **Issue (Wakeup + Select)** – Issue instruction when all operands are ready
    
6. **Execute** – Perform the operation in ALU/mult/div/FU
    
7. **Writeback** – Write result to PRF, broadcast tag to RS
    
8. **Commit** – Commit result in order using ROB; free resources
    

---

## Hazards and OoO Mitigation Techniques

|   |   |   |
|---|---|---|
|Hazard Type|Description|Mitigation|
|RAW|Read After Write (true dependency)|Wait via RS and wakeup logic|
|WAR|Write After Read (false dependency)|Eliminated via register renaming|
|WAW|Write After Write (false dependency)|Eliminated via register renaming|
|Control|Branches/mispredictions|Speculative execution + flush logic|

---

## Additional Notes

- All instructions must **commit in program order** to maintain precise exceptions.
    
- ROB is the key to ensuring precise state even with out-of-order execution.
    
- Branch misprediction recovery requires flushing ROB and clearing invalid instructions.
    
- The number of in-flight instructions is limited by sizes of ROB, RS, and PRF.