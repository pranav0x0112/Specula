package FetchUnit;

  import InOrderCore::*;

  interface IfcFetchUnit;
    method Action start(Bit#(32) pc);
    method Instruction getFetched();
  endinterface

  module mkFetchUnit(IfcFetchUnit);
    Reg#(Instruction) instr <- mkReg(0);

    method Action start(Bit#(32) pc);
      instr <= getInstruction(pc);
    endmethod

    method Instruction getFetched();
      return instr;
    endmethod
  endmodule

endpackage