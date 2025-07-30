package PRF;

  import Vector::*;
  import RegFile::*;
  import Common::*;

  interface PRF;
    method Maybe#(Data) read(PhysRegTag tag);
    method Action write(PhysRegTag tag, Data val);
    method Bool isReady(PhysRegTag tag);
    method Action markReady(PhysRegTag tag);
  endinterface

  module mkPRF (PRF);
    Vector#(NUM_PHYS_REGS, Reg#(Data)) regs <- replicateM(mkRegU);
    Vector#(NUM_PHYS_REGS, Reg#(Bool)) readyBits <- replicateM(mkReg(False));

    method Maybe#(Data) read(PhysRegTag tag);
      if (readyBits[tag]) return Valid(regs[tag]);
      else return Invalid;
    endmethod

    method Action write(PhysRegTag tag, Data val);
      regs[tag] <= val;
    endmethod

    method Bool isReady(PhysRegTag tag);
      return readyBits[tag];
    endmethod

    method Action markReady(PhysRegTag tag);
      readyBits[tag] <= True;
    endmethod

  endmodule
endpackage