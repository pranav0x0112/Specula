# Branch Prediction in BOOM

## Motivation

In an out-of-order (OoO) core, maintaining a steady supply of instructions is essential for keeping the backend busy. However, control-flow instructions (branches) break this flow by introducing uncertainty in the instruction stream. To avoid stalls, BOOM predicts the direction and target of branches _before_ they are resolved.

Accurate branch prediction minimizes pipeline flushes and maximizes ILP (Instruction-Level Parallelism).

---

## Branch Predictor Architecture

BOOM uses a combination of:

- **GShare Predictor**
    
- **Branch Target Buffer (BTB)**
    
- **Return Address Stack (RAS)**
    

These components are integrated into the **Frontend**, responsible for fetching instructions each cycle.

---

## GShare Predictor

GShare is a dynamic branch predictor that XORs the Global History Register (GHR) with the Program Counter (PC) to index into a Pattern History Table (PHT).

### Components:

- **GHR (Global History Register):** Captures outcomes of recent branches as a shift register of 1s (taken) and 0s (not taken).
    
- **PHT (Pattern History Table):** A table of 2-bit saturating counters, indicating branch tendency.
    

### Prediction Logic:

```text
index = PC ^ GHR
prediction = (PHT[index] >= 2) ? taken : not_taken
```

- 2-bit counters allow hysteresis (i.e., prediction needs two wrong outcomes to change direction).
    

---

## Branch Target Buffer (BTB)

BTB is used for **target prediction** of branches (especially indirect branches like function pointers or computed jumps).

- It caches the **target addresses** of previously seen branches.
    
- Accessed in parallel with GShare during fetch.
    
- If the BTB hits and GShare predicts **taken**, then BOOM will speculatively fetch from the predicted target.
    

---

## Return Address Stack (RAS)

Used for predicting **return addresses** from `jalr` instructions with `ra` as the destination (function returns).

- Pushes return address on function call.
    
- Pops address on function return.
    

This improves prediction accuracy for recursive functions and deep call stacks.

---

## Misprediction Handling

If a branch prediction was incorrect, BOOM flushes all subsequent instructions in the pipeline and redirects fetch to the correct target.

### Key stages:

- **Branch Resolution**: Occurs in the Execute stage.
    
- **Flush Logic**: Clears pipeline structures like ROB, RS, and fetch buffers.
    
- **Recovery**: PC is set to actual target, and GHR is restored.
    

---

## Summary

- BOOM uses a **hybrid predictor**: GShare + BTB + RAS.
    
- Early, speculative fetch is enabled by predictions, feeding multiple instructions per cycle into the decode stage.
    
- Prediction accuracy directly impacts pipeline utilization and IPC.