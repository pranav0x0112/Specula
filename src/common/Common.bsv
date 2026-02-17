package Common;

  typedef Bit#(5) RegIndex;
  typedef Bit#(32) Instruction;
  typedef Bit#(32) Data;
  typedef Maybe#(ROBTag) RATEntry;

  typedef enum {
    OP_IMM, OP, LUI, AUIPC, JAL, JALR, BRANCH, LOAD, STORE, MISC_MEM, SYSTEM, INVALID
  } Opcode deriving (Bits, Eq, FShow);

  typedef enum {
    ALU_ADD, ALU_SUB, ALU_AND, ALU_OR,
    ALU_BEQ, ALU_BNE, ALU_BLT, ALU_BGE
  } ALUOp deriving (Bits, Eq, FShow);

  typedef struct {
    ALUOp opcode;
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
<<<<<<< HEAD
      32'h00000000: return 32'h00500093; // addi x1, x0, 5           (x1 = 5)
      32'h00000004: return 32'h00500113; // addi x2, x0, 5           (x2 = 5)
      32'h00000008: return 32'h00208263; // beq x1, x2, +4 → 0x0C    (branch to skip addi x3)
      32'h0000000C: return 32'h00A00293; // addi x5, x0, 10          (branch target, x5=10)
      32'h00000010: return 32'h00000013; // nop
      32'h00000014: return 32'h00000013; // nop
      32'h00000018: return 32'h00000013; // nop
      32'h0000001C: return 32'h00000013; // nop
      32'h00000020: return 32'h00000013; // nop
      default: return 32'h00000013; // nop (addi x0, x0, 0)
    endcase
  endfunction

  function Decoded decode(Instruction instr, Bit#(32) pc);
    Bit#(7) actualOpcode = instr[6:0];
    Bit#(3) funct3 = instr[14:12];
    
    // Determine instruction class and ALUOp
    ALUOp aluOp;
    if (actualOpcode == 7'b0110011) begin  // R-type
      if (funct3 == 3'b000) aluOp = ALU_ADD;      // ADD/SUB
      else if (funct3 == 3'b111) aluOp = ALU_AND;  // AND
      else if (funct3 == 3'b110) aluOp = ALU_OR;   // OR
      else aluOp = ALU_ADD;
    end else if (actualOpcode == 7'b0010011) begin  // I-type (ADDI, etc.)
      aluOp = ALU_ADD;
    end else if (actualOpcode == 7'b1100011) begin  // Branch (B-type)
      if (funct3 == 3'b000) aluOp = ALU_BEQ;
      else if (funct3 == 3'b001) aluOp = ALU_BNE;
      else if (funct3 == 3'b100) aluOp = ALU_BLT;
      else if (funct3 == 3'b101) aluOp = ALU_BGE;
      else aluOp = ALU_BEQ;
    end else begin
      aluOp = ALU_ADD;  // Default
    end
    
    // Extract immediates based on instruction type
    Bit#(32) imm = 0;
    RegIndex rs2Field = 0;
    
    if (actualOpcode == 7'b0010011) begin  // I-type immediate
      imm = signExtend(instr[31:20]);
      rs2Field = 0;  // I-type doesn't use rs2
    end else if (actualOpcode == 7'b1100011) begin  // B-type immediate
      // Branch immediate layout: imm[12|10:5|4:1|11]
      // instr layout: [31|30:25|11:8|7]
      Bit#(1) bit12 = instr[31];
      Bit#(6) bits10_5 = instr[30:25];
      Bit#(4) bits4_1 = instr[11:8];
      Bit#(1) bit11 = instr[7];
      Bit#(12) branchImmTmp = {bit12, bits10_5, bits4_1, bit11};
      imm = signExtend(branchImmTmp);
      rs2Field = instr[24:20];  // B-type uses rs2
    end else begin
      rs2Field = instr[24:20];  // R-type and other types use rs2
    end
    
    return Decoded {
      opcode: aluOp,
      rd: instr[11:7],
      rs1: instr[19:15],
      rs2: rs2Field,
      imm: imm
    };
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
>>>>>>> main
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

  function Bool signedLT(Bit#(32) a, Bit#(32) b);
    Int#(32) sa = unpack(a);
    Int#(32) sb = unpack(b);
    return sa < sb;
  endfunction

  function Bool signedGE(Bit#(32) a, Bit#(32) b);
    Int#(32) sa = unpack(a);
    Int#(32) sb = unpack(b);
    return sa >= sb;
  endfunction

  typedef struct {
    UInt#(6) idx;
  } ROBTag deriving (Bits, FShow);

  typedef struct {
    ALUOp opcode;
    PhysRegTag src1;
    PhysRegTag src2;
    PhysRegTag dest;
  } ALUInstr deriving (Bits, FShow);

  typedef struct {
  } BranchMetadata deriving (Bits, FShow);

endpackage