package RenameStage;

  interface IfcRenameStage;
    method Action dummy();
  endinterface

  module mkRenameStage(IfcRenameStage);
    method Action dummy();
    endmethod
  endmodule

endpackage