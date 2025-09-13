package Common;

  typedef Bit#(5) RegIndex;
  typedef Bit#(32) Instruction;
  typedef Bit#(32) Data;
  typedef Maybe#(ROBTag) RATEntry;

  typedef enum {
    OP_IMM, OP, LUI, AUIPC, JAL, JALR, BRANCH, LOAD, STORE, MISC_MEM, SYSTEM, INVALID
  } Opcode deriving (Bits, Eq, FShow);

  typedef struct {
    Opcode opcode;
    RegIndex rd;
    RegIndex rs1;
    RegIndex rs2;
    Bit#(32) imm;
  } Decoded deriving (Bits, FShow);

  typedef 6 LogNumPhysRegs;
  typedef 32 NUM_PHYS_REGS;
  typedef Bit#(LogNumPhysRegs) PhysRegTag;

  typedef PhysRegTag ZERO_TAG;
  function ZERO_TAG zeroTag();
    return 0;
  endfunction

  function Instruction getInstruction(Bit#(32) pc);
    case(pc)
      32'h00008398: return 32'h00108093; // addi x1, x1, 1
      32'h0000839c: return 32'h00208113; // addi x2, x1, 2
      32'h000083a0: return 32'h00310193; // addi x3, x2, 3
      default: return 32'h00000013; // nop (addi x0, x0, 0)
    endcase
  endfunction

  function Decoded decode(Instruction instr, Bit#(32) pc);
    return Decoded {
      opcode: OP_IMM,
      rd: instr[11:7],
      rs1: instr[19:15],
      rs2: instr[24:20],
      imm: signExtend(instr[31:20])
    };
  endfunction

  function Bit#(32) signExtend(Bit#(12) imm12);
    Bit#(32) extended;
    if (imm12[11] == 1)
      extended = {20'hFFFFF, imm12};
    else
      extended = {20'h00000, imm12};
    return extended;
  endfunction

  typedef struct {
    UInt#(6) idx;
  } ROBTag deriving (Bits, FShow);

  typedef enum {
    ALU_ADD, ALU_SUB, ALU_AND, ALU_OR
  } ALUOp deriving (Bits, Eq, FShow);

  typedef struct {
    ALUOp op;
    PhysRegTag src1;
    PhysRegTag src2;
    PhysRegTag dest;
  } ALUInstr deriving (Bits, FShow);

  typedef struct {
    ALUOp op;
    PhysRegTag src1;
    Bool src1Ready;
    PhysRegTag src2;
    Bool src2Ready;
    PhysRegTag dest;
    ROBTag robTag;
  } RSEntry deriving (Bits, FShow);

endpackage