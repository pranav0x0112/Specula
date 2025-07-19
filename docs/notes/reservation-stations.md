# Reservation Stations (RS) in Out-of-Order Cores

Reservation Stations (RS) serve as holding buffers for instructions waiting for their source operands to become ready. They decouple instruction issue from execution, enabling dynamic scheduling.

## Goals of Reservation Stations

1. **Decouple issue and execution** – Allow instruction to wait for operands asynchronously.
    
2. **Enable data-driven execution** – Wake up when operands are available.
    
3. **Support multiple functional units** – Feed units independently.
    

---

## Structure

Each reservation station entry includes:

- Opcode and function type (e.g., ALU, MUL)
    
- Source operand values or physical register tags (if not ready)
    
- Ready bits for each source
    
- Destination physical register tag (where result goes)
    
- ROB ID or instruction ID
    

RS entries are typically grouped per functional unit (e.g., ALU RS, branch RS, load/store queue).

---

## RS Lifecycle

### 1. Issue (from rename stage)

- An instruction is allocated an RS entry.
    
- Source operands are checked:
    
    - If ready: values are written.
        
    - If not: tags are recorded, ready bits = 0.
        
- Entry is marked as valid.
    

### 2. Wakeup (on result broadcast)

- When a result is written to the Common Data Bus (CDB), matching RS tags are updated.
    
- The corresponding source becomes ready.
    

### 3. Select

- RS scans for ready instructions.
    
- Based on arbitration (e.g., oldest-first, priority), selects ready instructions.
    
- Dispatches to corresponding functional unit.
    

---

## Operand Tracking

Reservation stations track operand readiness via tags and ready bits:

|Operand|Tag|Ready|Value|
|---|---|---|---|
|rs1|P5|0|—|
|rs2|P3|1|12|

On broadcast of P5, this RS entry is updated:

- Ready ← 1
    
- Value ← Broadcasted result
    

---

## Example

```
Cycle 1: ADD x5, x2, x3 → RS0 ← rs1=P2, rs2=P3 (both ready)
Cycle 2: MUL x6, x1, x5 → RS1 ← rs1=P1, rs2=P7 (P7 not ready)
Cycle 6: ADD result broadcast (P7 ready) → RS1 wakes up
Cycle 7: RS1 issues MUL to FUnit
```

---

## RS vs Issue Queue

- RS is more general, can filter by FU type.
    
- Centralized issue queue is simpler but harder to scale.
    
- Modern OoO cores may use distributed RS (per FU type).
    

---

## Challenges

- RS size limits parallelism.
    
- Complex wakeup/select logic can be a critical path.
    
- Broadcast bandwidth limits (CDB fanout).
    

---

## Summary

- Enables dynamic scheduling and operand-driven execution.
    
- Tracks readiness of inputs.
    
- Wakes up on data broadcast.
    
- Selects ready instructions for execution units.