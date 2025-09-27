package Dispatch;

  import Common::*;
  import ReservationStation::*;

  interface IfcDispatch;
    method Action start(Decoded inst, PhysRegTag destTag, ROBTag robTag);
    method ActionValue#(RSEntry) getDispatchedEntry();
    method Bool hasDispatchedEntry();
  endinterface

  module mkDispatch(IfcDispatch);
    
    Reg#(Maybe#(RSEntry)) dispatchedEntry <- mkReg(tagged Invalid);

    method Action start(Decoded inst, PhysRegTag destTag, ROBTag robTag);
      
      RSEntry rsEntry = RSEntry {
        op: ALU_ADD,
        src1: PhysRegTag'(zeroExtend(inst.rs1)),  
        src1Ready: True,
        src2: PhysRegTag'(zeroExtend(inst.rs2)),   
        src2Ready: True,
        immediate: inst.imm,                   
        useImmediate: (inst.opcode == OP_IMM),
        dest: destTag,
        robTag: robTag
      };
      
      dispatchedEntry <= tagged Valid rsEntry;
    endmethod

    method ActionValue#(RSEntry) getDispatchedEntry() if (dispatchedEntry matches tagged Valid .entry);
      dispatchedEntry <= tagged Invalid;
      return entry;
    endmethod

    method Bool hasDispatchedEntry();
      return isValid(dispatchedEntry);
    endmethod
  endmodule

endpackage