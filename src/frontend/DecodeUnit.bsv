package DecodeUnit;

  import Common::*;

  interface IfcDecodeUnit;
    method Action start(Instruction instr, Bit#(32) pc);
    method Decoded getDecoded();
  endinterface

  module mkDecodeUnit(IfcDecodeUnit);
    Reg#(Decoded) decoded <- mkReg(Decoded {
      opcode: OP_IMM,
      rd: 0,
      rs1: 0,
      rs2: 0,
      funct3: 0,
      funct7: 0,
      imm: 0,
      raw: 32'h00000013
    });

    method Action start(Instruction instr, Bit#(32) pc);
      decoded <= decode(instr, pc);
    endmethod

    method Decoded getDecoded();
      return decoded;
    endmethod
  endmodule

endpackage