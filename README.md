# Specula
Specula is an Out-of-Order RV32I Core in Bluespec SV

![Specula](./docs/specula.png)

```
                         +-------------------------+
                         |     Branch Predictor    |
                         +-----------+-------------+
                                     |
+----------------+        +---------v---------+        +------------------+
| Instruction    | -----> |    Fetch Unit     | -----> |   Decode Unit    |
| Memory         |        +-------------------+        +------------------+
+----------------+                                       |         |
                                                         |         v
                                                         |   Register Rename
                                                         |   + Free List
                                                         v
                                              +---------------------------+
                                              |  Dispatch Queue / RS      |
                                              +-----------+---------------+
                                                          |
        +----------------------------+--------------------+-----------------------------+
        |                            |                    |                             |
        v                            v                    v                             v
+-------------------+     +--------------------+  +---------------------+     +---------------------+
|   Integer ALU(s)  |     |  Load/Store Unit   |  |   Branch Unit       |     |  [Other FU, e.g. FP]|
+-------------------+     +--------------------+  +---------------------+     +---------------------+
                                 |                         |
                      +----------v-----------+             |
                      |  Load/Store Queue    | <-----------+
                      +----------------------+ 
                                 |
                          +------v------+
                          |  Data Mem   |
                          +-------------+

        +-----------------------------------------------------------------------+
        |                                  ROB                                  |
        +-----------+----------------+--------------------+---------------------+
                    |                |                    |
                    v                v                    v
              Commit Logic     Register File      Exceptions / CSR

```

_Specula_'s out-of-order execution pipeline. This design supports register renaming, out-of-order execution using reservation stations, a central ROB to maintain in-order commit, and functional units including ALU, LSU, and Branch units. Data and instruction memories are assumed to be ideal in early simulations