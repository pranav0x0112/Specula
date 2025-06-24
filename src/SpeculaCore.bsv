package SpeculaCore;

  import Vector::*;
  import RegFile::*;
  import FIFO::*;
  import ClientServer::*;
  import GetPut::*;

  typedef Bit#(32) Instruction;
  typedef Bit#(32) Word;
  typedef Bit#(5) RegIndex;

  typedef struct {
    Bit #(7) opcode;
    RegIndex rd;
    RegIndex rs1;
    RegIndex rs2;
  } Decoded deriving (Bits, FShow);

  function Bit#(32) getInstruction(Bit#(32) pc);
    case (pc)
      0: return 32'h00500113; // addi x2, x0, 5
      4: return 32'h002081B3; // add  x3, x1, x2
      8: return 32'h00000000; // nop

      default: return 32'h00000013; // default: addi x0, x0, 0
    endcase
  endfunction

  function Decoded decode(Instruction i);
    Decoded d;
    d.opcode = i[6:0];
    d.rd = i[11:7];
    d.rs1 = i[19:15];
    d.rs2 = i[24:20];
    return d;
  endfunction

  module mkSpeculaCore(Empty);
    Reg#(Bit#(32)) pc <- mkReg(0);
    
    rule fetch_and_decode;
      Instruction inst = getInstruction(pc);
      Decoded d = decode(inst);
      $display("[Specula] PC: %0d Instr: %h | opcode: %b rd: %0d rs1: %0d rs2: %0d", pc, inst, d.opcode, d.rd, d.rs1, d.rs2);
      pc <= pc + 4; 
    endrule
  endmodule

endpackage

