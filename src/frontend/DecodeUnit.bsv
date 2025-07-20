package DecodeUnit;

  import InOrderCore::*;

  interface IfcDecodeUnit;
    method Action start(Instruction instr, Bit#(32) pc);
    method Decoded getDecoded();
  endinterface

  module mkDecodeUnit(IfcDecodeUnit);
    Reg#(Decoded) decoded <- mkReg(decode(32'h00000013, 0)); // nop

    method Action start(Instruction instr, Bit#(32) pc);
      decoded <= decode(instr, pc);
    endmethod

    method Decoded getDecoded();
      return decoded;
    endmethod
  endmodule

endpackage