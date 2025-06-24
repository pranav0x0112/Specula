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
    d.rd = unpack(i[11:7]);
    d.rs1 = unpack(i[19:15]);
    d.rs2 = unpack(i[24:20]);
    return d;
  endfunction

  module mkSpeculaCore(Empty);
    Reg#(Bit#(2)) initState <- mkReg(0);
    Reg#(Bit#(32)) pc <- mkReg(0);
    RegFile#(RegIndex, Word) rf <- mkRegFileFull;

    rule init1(initState == 0);
      rf.upd(1, 10); // x1 = 10 
      initState <= 1;
    endrule

    rule init2(initState == 0);
      rf.upd(2, 20); // x2 = 20
      initState <= 2;
    endrule


    rule fetch_and_decode;
      Instruction inst = getInstruction(pc);
      Decoded d = decode(inst);

      let val1 = rf.sub(d.rs1);
      let val2 = rf.sub(d.rs2);

      Word result = 0;

      if(d.opcode == 7'b0010011)
        begin
          result = val1 + signExtend(inst[31:20]);
        end
      else if(d.opcode == 7'b0110011)
        begin
          result = val1 + val2;
        end
         
      if(d.rd != 0)
        rf.upd(d.rd, result);

      $display("[Specula] PC: %0d Instr: %h", pc, inst);
      $display("  opcode: %b rd: %0d rs1: %0d val1: %0d rs2: %0d val2: %0d -> result: %0d", d.opcode, d.rd, d.rs1, val1, d.rs2, val2, result);
      $fflush(stdout);

      pc <= pc + 4; 
      if (pc >= 12) 
        $finish;
    endrule
  
  endmodule

endpackage