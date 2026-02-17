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
    method Action clearRAT(RegIndex r);  
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

        rat.rename(instr.rd, robTag);

        PhysRegTag src1PhysTag;
        Bool src1Ready;
        if (rs1_tag matches tagged Valid .rs1_rob) begin
          src1PhysTag = extend(pack(rs1_rob.idx)); 
          src1Ready = False; 
        end else begin
          src1PhysTag = extend(instr.rs1);  
          src1Ready = True;  
        end

        PhysRegTag src2PhysTag;
        Bool src2Ready;
        if (rs2_tag matches tagged Valid .rs2_rob) begin
          src2PhysTag = extend(pack(rs2_rob.idx));  
          src2Ready = False; 
        end else begin
          src2PhysTag = extend(instr.rs2);
          src2Ready = True;  
        end  

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

    method Action clearRAT(RegIndex r);
      rat.clear(r);
    endmethod

  endmodule

endpackage