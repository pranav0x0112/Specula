package FetchUnit;

  import Common::*;
  import RegFile::*;

  interface IfcFetchUnit;
    method Action start(Bit#(32) pc);
    method Instruction getFetched();
  endinterface

  module mkFetchUnit(IfcFetchUnit);
    Reg#(Bit#(32)) pcReg <- mkReg(0);
    Reg#(Instruction) fetchedInstr <- mkReg(0);
    Reg#(Bool) started <- mkReg(False);

    let maxPC = 32'h00000100;

    RegFile#(Bit#(32), Instruction) imem <- mkRegFileFull();

    rule preload;
      imem.upd(0, 32'h00508193);
      noAction;
    endrule

    method Action start(Bit#(32) pc);
      pcReg <= pc;
      let instr = getInstruction(pc);
      fetchedInstr <= instr;
      $display("[Fetch] PC: %08x | instr: %08x", pc, instr);
      started <= True;
    endmethod
    
    method Instruction getFetched();
      return fetchedInstr;
    endmethod
  endmodule

endpackage