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
    Bit#(3) funct3;
    Bit#(7) funct7;
    Bit#(32) imm;
    Instruction raw;
  } Decoded deriving (Bits, FShow);

  typedef struct {
    Decoded instr;
    PhysRegTag src1Tag;
    Bool src1Ready;
    PhysRegTag src2Tag;
    Bool src2Ready;
    PhysRegTag destTag;
    ROBTag robTag;
  } RenamedInstr deriving (Bits, FShow);

  typedef 6 LogNumPhysRegs;
  typedef 32 NUM_PHYS_REGS;
  typedef Bit#(LogNumPhysRegs) PhysRegTag;

  typedef PhysRegTag ZERO_TAG;
  function ZERO_TAG zeroTag();
    return 0;
  endfunction

  function Instruction getInstruction(Bit#(32) pc);
    case(pc)
      0: return 32'h00500093;   // addi x1, x0, 5   -> x1 = 5
      4: return 32'h00108113;   // addi x2, x1, 1   -> x2 = x1 + 1 = 6 (depends on x1) 
      8: return 32'h00200193;   // addi x3, x0, 2   -> x3 = 2 (independent)
      12: return 32'h003100B3;  // add  x1, x2, x3  -> x1 = x2 + x3 = 8 (depends on x2,x3)
      default: return 32'h00000013; // nop (addi x0, x0, 0)
    endcase
  endfunction

  function Decoded decode(Instruction instr, Bit#(32) pc);
    Decoded d;
    d.opcode = case (instr[6:0])
      7'b0010011: OP_IMM;    // I-type (addi, andi, ori, etc.)
      7'b0110011: OP;        // R-type (add, sub, and, or, etc.)
      7'b1100011: BRANCH;    // B-type (beq, bne, etc.)
      7'b1101111: JAL;       // J-type (jal)
      7'b1100111: JALR;      // I-type (jalr)
      7'b0000011: LOAD;      // I-type (lw, etc.)
      7'b0100011: STORE;     // S-type (sw, etc.)
      default: INVALID;
    endcase;
    
    d.rd = instr[11:7];
    d.funct3 = instr[14:12];
    d.rs1 = instr[19:15];
    d.rs2 = case (instr[6:0])
      7'b0110011: instr[24:20]; // R-type (add, sub, etc.)
      7'b1100011: instr[24:20]; // B-type (beq, bne, etc.)
      7'b0100011: instr[24:20]; // S-type (sw, etc.)
      default: 5'b00000;        // I-type and others: rs2 = x0
    endcase;
    d.funct7 = instr[31:25];
    d.raw = instr;
    
    case (instr[6:0])
      7'b1100011: begin // B-type
        d.imm = signExtend13({instr[31], instr[7], instr[30:25], instr[11:8], 1'b0});
      end
      7'b1101111: begin // JAL (J-type)  
        d.imm = signExtend21({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});
      end
      7'b1100111: begin // JALR (I-type)
        d.imm = signExtend(instr[31:20]);
      end
      7'b0100011: begin // S-type (store)
        d.imm = signExtend({instr[31:25], instr[11:7]});
      end
      default: begin
        d.imm = signExtend(instr[31:20]); // I-type default
      end
    endcase
    
    return d;
  endfunction

  function Bit#(32) signExtend(Bit#(12) imm12);
    Bit#(32) extended;
    if (imm12[11] == 1)
      extended = {20'hFFFFF, imm12};
    else
      extended = {20'h00000, imm12};
    return extended;
  endfunction
  
  // Sign extend 13-bit immediate (for B-type)
  function Bit#(32) signExtend13(Bit#(13) imm13);
    Bit#(32) extended;
    if (imm13[12] == 1)
      extended = {19'h7FFFF, imm13};
    else
      extended = {19'h00000, imm13};
    return extended;
  endfunction
  
  // Sign extend 21-bit immediate (for J-type)
  function Bit#(32) signExtend21(Bit#(21) imm21);
    Bit#(32) extended;
    if (imm21[20] == 1)
      extended = {11'h7FF, imm21};
    else
      extended = {11'h000, imm21};
    return extended;
  endfunction

  typedef struct {
    UInt#(6) idx;
  } ROBTag deriving (Bits, FShow);

  typedef enum {
    ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_SLL, ALU_SRL, ALU_SRA,
    ALU_ADDI, ALU_ANDI, ALU_ORI, ALU_XORI, ALU_SLLI
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
    Bit#(32) immediate;  
    Bool useImmediate;   
    PhysRegTag dest;
    ROBTag robTag;
  } RSEntry deriving (Bits, FShow);

endpackage