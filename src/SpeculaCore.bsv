package SpeculaCore;

  import FetchUnit::*;
  import DecodeUnit::*;
  import Common::*;
  import Dispatch::*;
  import RenameStage::*;
  import PRF::*;
  import FreeList::*;
  import ReservationStation::*;
  import ROB::*;
  import ALU::*;

  module mkSpeculaCore(Empty);
    IfcFetchUnit fetch <- mkFetchUnit;
    IfcDecodeUnit decode <- mkDecodeUnit;
    IfcDispatch dispatch <- mkDispatch;
    RenameStage_IFC rename <- mkRenameStage;
    PRF prf <- mkPRF;
    FreeList_IFC freelist <- mkFreeList; 
    ReservationStationIfc rs <- mkReservationStation;
    ROB_IFC rob <- mkROB;
    ALU_IFC alu <- mkALU;
    
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

    rule doDispatch (renameDone);
      $display("[DEBUG] doDispatch rule firing! renameDone=%b", renameDone);
      
      if (rs.notFull) begin
        let r = rename.getRenamed();

        let maybeDestTag <- freelist.tryAllocate();
        
        if (maybeDestTag matches tagged Valid .destTag) begin
          let robTag <- rob.allocate(tagged Valid r.instr.rd, tagged Valid destTag);

          let rsEntry = RSEntry {
            op: ALU_ADD,
            src1: PhysRegTag'(zeroExtend(r.instr.rs1)),
            src1Ready: True,
            src2: PhysRegTag'(zeroExtend(r.instr.rs2)),
            src2Ready: True,
            dest: destTag,
            robTag: robTag,
            immediate: r.instr.imm,
            useImmediate: (r.instr.opcode == OP_IMM)
          };
          
          rs.enq(rsEntry);
          $display("[DISPATCH] Sent to RS: dest=p%0d rob=%0d", destTag, robTag.idx);

          renameDone <= False;
        end else begin
          $display("[DISPATCH] No free physical registers - stalling");
        end
      end else begin
        $display("[DISPATCH] RS is full - stalling");
      end
    endrule

    rule doRename (decodeStarted && !halted);
      let d = decode.getDecoded();
      rename.start(d);
      decodeStarted <= False;
      renameDone <= True;
    endrule

    rule haltPC(pc >= maxPC && !halted);
      $display("[Specula] Halting at PC: %h", pc);
      halted <= True;
    endrule

    rule doCommit;
      let maybeHead = rob.peekHead();
      if (maybeHead matches tagged Valid .headInfo) begin
        match {.tag, .entry} = headInfo;
        if (entry.completed) begin
          rob.commitHead(freelist);
        end
      end
    endrule

    rule doExecute (rs.notEmpty && alu.notFull);
      $display("[DEBUG] doExecute rule firing: rs.notEmpty=%b alu.notFull=%b", rs.notEmpty, alu.notFull);
      let rsEntry <- rs.deq();
      $display("[Execute] Dequeued RS entry: op=%0d dest=p%0d rob=%0d", rsEntry.op, rsEntry.dest, rsEntry.robTag.idx);

      let src1Val = prf.read(rsEntry.src1);
      let src2Val = prf.read(rsEntry.src2);
      
      let aVal = (src1Val matches tagged Valid .v ? v : 32'h0);
      let bVal = rsEntry.useImmediate ? rsEntry.immediate : (src2Val matches tagged Valid .v ? v : 32'h0);

      ALUReq aluReq = ALUReq {
        op: rsEntry.op,
        a: aVal,
        b: bVal,  
        dest: rsEntry.dest,
        robTag: rsEntry.robTag
      };
      
      alu.enq(aluReq);
      $display("[Execute] Sent to ALU: op=%0d a=%0d b=%0d dest=p%0d rob=%0d (useImm=%0d)", rsEntry.op, aVal, bVal, rsEntry.dest, rsEntry.robTag.idx, rsEntry.useImmediate);
    endrule

    rule doWriteback (alu.notEmpty);
      let aluResp <- alu.deq();
      $display("[Writeback] ALU result: res=%0d dest=p%0d rob=%0d", aluResp.result, aluResp.dest, aluResp.robTag.idx);

      rob.writeResultAndComplete(aluResp.robTag, aluResp.result);

      prf.write(aluResp.dest, aluResp.result);
      prf.markReady(aluResp.dest);
      
      $display("[Writeback] ROB[%0d] completed with result=%0d, PRF[p%0d] = %0d", 
               aluResp.robTag.idx, aluResp.result, aluResp.dest, aluResp.result);
    endrule

  endmodule
endpackage