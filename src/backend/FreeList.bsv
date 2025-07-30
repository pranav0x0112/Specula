package FreeList;

  import Common::*;
  import Vector::*;

  interface FreeList_IFC;
    method ActionValue#(Maybe#(PhysRegTag)) tryAllocate();
  endinterface

  module mkFreeList(FreeList_IFC);
    Vector#(NUM_PHYS_REGS, Reg#(Bool)) freelist <- replicateM(mkReg(True));
    
    method ActionValue#(Maybe#(PhysRegTag)) tryAllocate();
      Maybe#(PhysRegTag) result = tagged Invalid;
      Bool allocated = False;

      action
        for (Integer i = 0; i < valueOf(NUM_PHYS_REGS); i = i + 1) begin
          if (!allocated && freelist[i]) begin
            freelist[i] <= False;
            result = tagged Valid fromInteger(i);
            allocated = True;
          end
        end
      endaction
      return result;
    endmethod

  endmodule
endpackage