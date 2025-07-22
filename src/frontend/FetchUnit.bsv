package FetchUnit;

  import Common::*;

  interface IfcFetchUnit;
    method Action start(Bit#(32) pc);
    method Instruction getFetched();
  endinterface

  module mkFetchUnit(IfcFetchUnit);
    Reg#(Bit#(32)) pcReg <- mkReg(0);
    Reg#(Instruction) instr <- mkReg(0);
    Reg#(Bool) started <- mkReg(False);

    let maxPC = 32'h00000100;

    rule doFetch(started && pcReg < maxPC);
      instr <= getInstruction(pcReg);
      $display("[Fetch] PC: %08x | instr: %08x", pcReg, getInstruction(pcReg));
      pcReg <= pcReg + 4;
    endrule

    rule stopFetching(started && pcReg >= maxPC);
      $display("[FetchUnit] Stopping fetch: reached PC limit = %h", pcReg);
      started <= False;
    endrule

    method Action start(Bit#(32) pc);
      pcReg <= pc;
      started <= True;
    endmethod
    
    method Instruction getFetched();
      return instr;
    endmethod
  endmodule

endpackage