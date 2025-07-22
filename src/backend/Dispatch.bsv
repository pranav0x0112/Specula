package Dispatch;

  import Common::*;

  interface IfcDispatch;
    method Action start(Decoded inst);
  endinterface

  module mkDispatch(IfcDispatch);
    method Action start(Decoded dinst);
      $display("[Dispatch] opcode: %b | rd: %0d | rs1: %0d | rs2: %0d", dinst.opcode, dinst.rd, dinst.rs1, dinst.rs2);
    endmethod
  endmodule

endpackage