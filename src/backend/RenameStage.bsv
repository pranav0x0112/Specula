package RenameStage;

  import Common::*;
  import ROB::*;
  import RAT::*;
  import Vector::*;
  import FreeList::*;
  import PRF::*;

  interface RenameStage_IFC;
    method Action start(Decoded d);
    method RenamedInstr getRenamed();
    method Action testFreeListAlloc();
  endinterface

  module mkRenameStage(RenameStage_IFC);

    Decoded initInstr = Decoded {
      opcode: ALU_ADD,
      rd: 0,
      rs1: 0,
      rs2: 0,
      imm: 0
    };

    RenamedInstr initRenamed = RenamedInstr {
      instr: initInstr,
      src1Tag: 0,
      src1Ready: True,
      src2Tag: 0,
      src2Ready: True,
      destTag: 0,
      robTag: ROBTag{idx: 0}
    };

    Reg#(RenamedInstr) renamedInstr <- mkReg(initRenamed);

    method Action start(Decoded d);
      RenamedInstr renamed = RenamedInstr {
        instr: d,
        src1Tag: 0,
        src1Ready: True,
        src2Tag: 0,
        src2Ready: True,
        destTag: 0,
        robTag: ROBTag{idx: 0}
      };
      renamedInstr <= renamed;
      $display("[RENAME] Stored decoded instr: opcode=%0d rd=x%0d rs1=x%0d rs2=x%0d imm=%h",
               d.opcode, d.rd, d.rs1, d.rs2, d.imm);
    endmethod

    method RenamedInstr getRenamed();
      return renamedInstr;
    endmethod

    method Action testFreeListAlloc();
      $display("[FreeList Test] Method not implemented in simplified rename stage");
    endmethod

  endmodule

endpackage