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

    ROB_IFC       rob      <- mkROB();
    RAT_IFC       rat      <- mkRAT();
    FreeList_IFC  freelist <- mkFreeList();
    PRF           prf      <- mkPRF();

    Decoded testInstr = Decoded {
      opcode: OP_IMM,
      rd: 3,
      rs1: 1,
      rs2: 0,
      imm: 5
    };

    Reg#(Decoded) renamedInstr <- mkReg(testInstr);
    Reg#(RenamedInstr) finalRenamed <- mkReg(?);
    Reg#(Bool)    did          <- mkReg(False);

    rule do_rename (!did);
      let instr = renamedInstr;

      let rs1_tag = rat.lookup(instr.rs1);
      let rs2_tag = rat.lookup(instr.rs2);
      let maybeDest <- freelist.tryAllocate();
      let robTag <- rob.allocate(tagged Valid instr.rd, maybeDest);

      if (maybeDest matches tagged Valid .pDst) begin

        rat.rename(instr.rd, robTag);

        PhysRegTag src1PhysTag = extend(instr.rs1);  // Convert 5-bit RegIndex to 6-bit PhysRegTag
        PhysRegTag src2PhysTag = extend(instr.rs2);  // Convert 5-bit RegIndex to 6-bit PhysRegTag
        Bool src1Ready = True;  
        Bool src2Ready = True;  

        RenamedInstr renamed = RenamedInstr {
          instr: instr,
          src1Tag: src1PhysTag,
          src1Ready: src1Ready,
          src2Tag: src2PhysTag,
          src2Ready: src2Ready,
          destTag: pDst,
          robTag: robTag
        };

        finalRenamed <= renamed;

        $display("[RENAME]");
        $display("  instr: rd=x%0d, rs1=x%0d, rs2=x%0d, imm=%0d",
                 instr.rd, instr.rs1, instr.rs2, instr.imm);
        $display("  RAT rs1 -> %s", fshow(rs1_tag));
        $display("  RAT rs2 -> %s", fshow(rs2_tag));
        $display("  allocated ROB tag: %0d", robTag.idx);
        $display("  allocated PHYS tag (dest): p%0d", pDst);

        did <= True;
      end
      else begin
        $display("[RENAME] Stall: FreeList empty, cannot allocate dest phys-reg");
      end
    endrule

    method Action start(Decoded d);
      renamedInstr <= d;
      did          <= False;
    endmethod

    method RenamedInstr getRenamed();
      return finalRenamed;
    endmethod

    method Action testFreeListAlloc();
      let maybeTag <- freelist.tryAllocate();
      $display("[FreeList Test] Allocated tag: %s", fshow(maybeTag));
    endmethod

  endmodule

endpackage