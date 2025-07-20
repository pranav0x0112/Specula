package ROB;

  interface IfcROB;
    method Action dummy();
  endinterface

  module mkROB(IfcROB);
    method Action dummy();
    endmethod
  endmodule

endpackage