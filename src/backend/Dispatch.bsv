package Dispatch;

  interface IfcDispatch;
    method Action dummy();
  endinterface

  module mkDispatch(IfcDispatch);
    method Action dummy();
    endmethod
  endmodule

endpackage