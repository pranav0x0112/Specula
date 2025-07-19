# Register Renaming in Out-of-Order Cores

Register renaming is a key technique in OoO processors to eliminate false dependencies (WAR and WAW). It maps logical (architectural) registers to a larger pool of physical registers.

## Why Register Renaming?

### Dependencies in pipelines:

- **RAW (Read After Write)** – true dependency (must preserve order)
- **WAR (Write After Read)** – false dependency
- **WAW (Write After Write)** – false dependency


In in-order or simple pipelines, WAR and WAW hazards cause stalls. OoO cores eliminate these with register renaming.

---

## Core Idea

Use a rename table to assign a new physical register (PRF index) every time a destination architectural register is written. This breaks WAR and WAW hazards.

### Example:
```asm
1:  ADD x1, x2, x3     ; dest = x1 → assign P5
2:  SUB x1, x4, x6     ; dest = x1 → assign P7 (not P5)
```

- x1 is renamed to P5 and then to P7.
- Second instruction doesn't wait for first to write to x1.

---
## Components Involved

### 1. Rename Map Table (RAT)

- Maps architectural registers to most recent physical registers.
    
- Updated during rename stage.
    

### 2. Free List / Free Register Pool

- Tracks available physical registers.
    
- Allocates one per destination register during rename.
    

### 3. Physical Register File (PRF)

- Holds actual values.
    
- Larger than architectural register file (e.g., 32 ARF → 64 PRF).
    

### 4. Mapping Snapshots

- For precise exception rollback or branch mispredict recovery.
    
- Snapshot current RAT, or track older mappings in ROB.
    

---

## Rename Flow

1. Instruction decoded.
    
2. Source architectural registers are looked up in the RAT → get PRF indices.
    
3. For destination reg:
    
    - Allocate a new PRF entry from freelist.
        
    - Update RAT with new mapping.
        
    - Store old mapping in ROB (for commit/rollback).
        

### Example Table:

|Arch Reg|RAT Mapping|
|---|---|
|x1|P7|
|x2|P8|

---

## Handling Rollback

- On branch mispredict or exception, discard younger instructions.
    
- Restore RAT to earlier state (from snapshot or ROB entries).
    
- Freed physical registers are returned to freelist.
    

---

## Summary

- Eliminates WAR and WAW by assigning new destinations each time.
    
- Requires larger register file and bookkeeping (RAT, freelist, snapshots).
    
- Enables independent instructions to proceed in parallel.