package RenameStage;

import Common::*;
import ROB::*;
import RAT::*;
import Vector::*;

interface RenameStage_IFC;
  method Action start(Decoded d);
  method Decoded getRenamed();
endinterface

module mkRenameStage(RenameStage_IFC);

  ROB_IFC rob <- mkROB();
  RAT_IFC rat <- mkRAT();

  Decoded testInstr = Decoded {
    opcode: OP_IMM,
    rd: 3,
    rs1: 1,
    rs2: 0,
    imm: 5
  };

  Reg#(Decoded) renamedInstr <- mkReg(testInstr);
  Reg#(Bool) did <- mkReg(False);

  rule do_rename (!did);
    let instr = renamedInstr;

    let rs1_tag = rat.lookup(instr.rs1);
    let rs2_tag = rat.lookup(instr.rs2);

    let robTag <- rob.allocate(tagged Valid instr.rd);
    rat.rename(instr.rd, robTag);

    $display("[RENAME]");
    $display("  instr: rd = x%0d, rs1 = x%0d, rs2 = x%0d, imm = %0d", instr.rd, instr.rs1, instr.rs2, instr.imm);
    $display("  rs1 tag: %s", fshow(rs1_tag));
    $display("  rs2 tag: %s", fshow(rs2_tag));
    $display("  allocated ROB tag: %d", robTag.idx);

    did <= True;
  endrule

    method Action start(Decoded d);
    renamedInstr <= d;
    did <= False;
  endmethod

  method Decoded getRenamed();
    return renamedInstr;
  endmethod

endmodule

endpackage