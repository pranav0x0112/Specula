# Reorder Buffer (ROB) in Out-of-Order Cores

The Reorder Buffer (ROB) is essential for maintaining precise exceptions and correct instruction retirement in an OoO processor. It holds all in-flight instructions from dispatch to commit.

## Goals of ROB

1. **Precise exceptions** – Instructions are retired in-order.
    
2. **State recovery** – On mispredictions or traps.
    
3. **Tracking instruction state** – For each in-flight instruction.
    
---

## Structure

The ROB is usually implemented as a circular buffer or FIFO with head and tail pointers. Each entry contains:

- PC (program counter) of the instruction
    
- Destination architectural register (if any)
    
- Destination physical register (new mapping)
    
- Old physical register (to free on commit)
    
- Exception status or trap info
    
- Completion status
    
- Store value (for memory operations)
    
---

## ROB Lifecycle

### 1. Dispatch (entry allocation)

- Instruction is decoded and renamed.
    
- A new ROB entry is created.
    
- Assigned an index (ROB ID).
    
- Destination PRF mapping and old mapping are stored.
    

### 2. Execute

- Instruction waits in RS until operands are ready.
    
- On execution complete, result is written to PRF.
    
- ROB entry is marked complete.
    

### 3. Commit

- Head of ROB is checked.
    
- If complete and no exceptions:
    
    - Commit the result.
        
    - Free old physical register.
        
    - Advance head.
        
- If exception:
    
    - Flush ROB and pipeline.
        
    - Restore RAT to snapshot.
        

---

## Examples

```text
Cycle 1: ADD x1, x2, x3 -> ROB[0] <- alloc PRF[P5], old=P1
Cycle 2: SUB x4, x1, x6 -> waits for P5 to be ready
Cycle 5: ADD finishes, P5 written -> ROB[0] marked complete
Cycle 6: ROB[0] commits -> x1 <- P5
```

---
## Interaction with RAT and PRF

- RAT updated at rename stage with new PRF mapping.
    
- ROB stores old mapping (for freeing PRF).
    
- On commit: free old PRF, ratify new mapping.
    
- On rollback: restore RAT to old state and free newer PRFs.
    

---

## Commit Conditions

- Instruction at head is done.
    
- No exceptions.
    
- Memory instructions: store buffer must be ready.
    

---

## Exception Handling

- On trap or mispredict:
    
    - Flush ROB entries younger than the faulting instruction.
        
    - Restore RAT.
        
    - Restore PC.
        

---

## Summary

- Maintains program order commit.
    
- Ensures precise exceptions.
    
- Coordinates with rename logic and PRF.
    
- Central to OoO execution correctness.