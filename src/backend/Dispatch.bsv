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
        opcode: inst.opcode,
        src1: PhysRegTag'(zeroExtend(inst.rs1)),  
        src1Ready: True,
        src2: PhysRegTag'(zeroExtend(inst.rs2)),   
        src2Ready: True,
        immediate: inst.imm,                   
        useImmediate: (inst.opcode == ALU_ADD || inst.opcode == ALU_AND || inst.opcode == ALU_OR),
        dest: destTag,
        robTag: robTag
      };

      dispatchedEntry <= tagged Valid rsEntry;
      $display("[DISPATCH] RS entry opcode=%0d (should match decoded)", rsEntry.opcode);
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