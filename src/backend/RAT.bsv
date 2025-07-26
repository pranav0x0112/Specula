package RAT;

  import Vector::*;
  import Common::*;

  typedef ROBTag ROBTagT;

  interface RAT_IFC;
    method Maybe#(ROBTagT) lookup(RegIndex r);
    method Action rename(RegIndex r, ROBTagT tag);
    method Action clear(RegIndex r);
  endinterface

  module mkRAT(RAT_IFC);

    Vector#(32, Reg#(Maybe#(ROBTagT))) ratTable <- replicateM(mkReg(tagged Invalid));
    
    method Maybe#(ROBTagT) lookup(RegIndex r);
      return ratTable[r];
    endmethod

    method Action rename(RegIndex r, ROBTagT tag);
      if (r != 0)
        ratTable[r] <= tagged Valid tag;
    endmethod

    method Action clear(RegIndex r);
      if (r != 0)
        ratTable[r] <= tagged Invalid;
    endmethod

  endmodule

endpackage