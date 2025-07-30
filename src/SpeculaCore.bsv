package SpeculaCore;

  import FetchUnit::*;
  import DecodeUnit::*;
  import Common::*;
  import Dispatch::*;
  import RenameStage::*;
  import PRF::*;
  import FreeList::*;

  module mkSpeculaCore(Empty);
    IfcFetchUnit fetch <- mkFetchUnit;
    IfcDecodeUnit decode <- mkDecodeUnit;
    IfcDispatch dispatch <- mkDispatch;
    RenameStage_IFC rename <- mkRenameStage;
    PRF prf <- mkPRF;
    FreeList_IFC freelist <- mkFreeList; 
    
    let maxPC = 32'h00000100;

    Reg#(Bit#(32)) pc <- mkReg(0);
    Reg#(Bool) fetchStarted <- mkReg(False);
    Reg#(Bool) decodeStarted <- mkReg(False);
    Reg#(Bool) renameDone <- mkReg(False);
    Reg#(Bool) halted <- mkReg(False);

    rule doFetch (!fetchStarted && !halted);
      fetch.start(pc);
      fetchStarted <= True;
    endrule

    rule doDecode (fetchStarted && !decodeStarted && !halted);
      let instr = fetch.getFetched();
      decode.start(instr, pc);
      decodeStarted <= True;
      let d = decode.getDecoded();
      $display("[Specula] instr: %h | rs1: %0d rs2: %0d rd: %0d", instr, d.rs1, d.rs2, d.rd);
    endrule

    rule doDispatch (!decodeStarted && !halted && renameDone);
      let r = rename.getRenamed();
      dispatch.start(r);
      pc <= pc + 4;
      fetchStarted <= False;
      renameDone <= False;
    endrule

    rule doRename (decodeStarted && !halted);
      let d = decode.getDecoded();
      rename.start(d);
      decodeStarted <= False;
      renameDone <= True;
    endrule

    rule testPRF (pc == 0);
      prf.write(PhysRegTag'(5), 32'hDEADBEEF);
      prf.markReady(PhysRegTag'(5));
      let val = prf.read(PhysRegTag'(5));

      if (val matches tagged Valid .v) begin
        $display("[PRF Test] PRF[5] = %x", v);
      end else begin
        $display("[PRF Test] PRF[5] = BAD");
      end
    endrule

    rule testFreeList (pc == 0);
      let maybeTag <- freelist.tryAllocate();
      $display("[FreeList Test] Allocated tag: %s", fshow(maybeTag));
    endrule

    rule haltPC(pc >= maxPC && !halted);
      $display("[Specula] Halting at PC: %h", pc);
      halted <= True;
    endrule

  endmodule
endpackage