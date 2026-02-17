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
  import BranchPredictor::*;
  import FIFOF::*;
  import Vector::*;

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
    BranchPredictor_IFC bp <- mkBranchPredictor;
    
    let maxPC = 32'h00000100;

    Reg#(Bit#(32)) pc <- mkReg(0);
    Reg#(Bool) fetchStarted <- mkReg(False);
    Reg#(Bool) decodeStarted <- mkReg(False);
    Reg#(Bool) renameDone <- mkReg(False);
    Reg#(Bool) halted <- mkReg(False);
    Reg#(Bit#(32)) lastFetchedInstr <- mkReg(32'h00000013); // Initialize to NOP
    Reg#(Bit#(32)) lastFetchedPC <- mkReg(0);
    
    // Branch metadata storage indexed by ROB tag
    Vector#(32, Reg#(BranchMetadata)) branchMeta <- replicateM(mkReg(BranchMetadata {
      isBranch: False,
      pc: 0,
      predictedTarget: 0
    }));
    
    // FIFO to flow branch metadata alongside instructions through the pipeline
    FIFOF#(BranchMetadata) branchMetaQ <- mkFIFOF();
    
    // Architectural register mapping: arch reg -> current physical reg
    Vector#(32, Reg#(PhysRegTag)) archRegMap <- replicateM(mkReg(0));
    // Track which arch regs have been written (to avoid freeing on first write)
    Vector#(32, Reg#(Bool)) archRegWritten <- replicateM(mkReg(False));

    rule doFetch (!fetchStarted && !decodeStarted && !halted);
      fetch.start(pc);
      fetchStarted <= True;
    endrule

    rule doDecode (fetchStarted && !decodeStarted && !halted);
      let instr = fetch.getFetched();
      lastFetchedInstr <= instr;
      lastFetchedPC <= pc;
      decode.start(instr, pc);
      decodeStarted <= True;
      fetchStarted <= False;
    endrule

    rule doDecodeComplete (decodeStarted && !renameDone && !halted);
      let d = decode.getDecoded();
      let pred <- bp.predict(lastFetchedPC);  // Predict based on the instruction's PC
      
      $display("[Specula] Decoded instr: %h at PC %h | opcode=%0d rd=%0d rs1=%0d rs2=%0d imm=%h", 
               lastFetchedInstr, lastFetchedPC, d.opcode, d.rd, d.rs1, d.rs2, d.imm);
      $display("[BP] PC=%h prediction=%b target=%h valid=%b", lastFetchedPC, pred.prediction, pred.targetAddr, pred.isValid);
      
      // Pass decoded instruction to rename stage
      rename.start(d);
      
      // Store branch prediction metadata for later resolution
      Bool isBranchInstr = (d.opcode == ALU_BEQ || d.opcode == ALU_BNE || d.opcode == ALU_BLT || d.opcode == ALU_BGE);
      branchMetaQ.enq(BranchMetadata {
        isBranch: isBranchInstr,
        pc: lastFetchedPC,
        predictedTarget: pred.targetAddr
      });
      
      // Only use predictor result if this instruction is a branch
      if (isBranchInstr) begin
        pc <= pred.targetAddr;
        $display("[Specula] BRANCH detected! Using predicted PC: %h", pred.targetAddr);
      end else begin
        pc <= lastFetchedPC + 4;
        $display("[Specula] Non-branch, incrementing PC from %h to %h", lastFetchedPC, lastFetchedPC + 4);
      end
      
      decodeStarted <= False;
      renameDone <= True;
    endrule

    rule doDispatch (renameDone);
      $display("[DEBUG] doDispatch rule firing! renameDone=%b", renameDone);
      
      if (rs.notFull) begin
        let r = rename.getRenamed();

<<<<<<< HEAD
        // Don't allocate physical register for writes to x0
        Maybe#(PhysRegTag) maybeDestTag = tagged Invalid;
        PhysRegTag destTag = 0;  // Default to p0 for x0
        Maybe#(PhysRegTag) oldPhysDst = tagged Invalid;
        
        if (r.instr.rd != 0) begin
          let allocResult <- freelist.tryAllocate();
          if (allocResult matches tagged Valid .tag) begin
            destTag = tag;
            maybeDestTag = tagged Valid tag;
            // Save old physical register only if this arch reg was previously written
            if (archRegWritten[r.instr.rd]) begin
              PhysRegTag oldDestPhysReg = archRegMap[r.instr.rd];
              oldPhysDst = tagged Valid oldDestPhysReg;
            end
          end else begin
            $display("[DISPATCH] No free physical registers - stalling");
            renameDone <= False;
          end
        end
        
        if (r.instr.rd == 0 || isValid(maybeDestTag)) begin
          let robTag <- rob.allocate(tagged Valid r.instr.rd, (r.instr.rd == 0 ? tagged Invalid : tagged Valid destTag), oldPhysDst);

          Bool isBranchOp = (r.instr.opcode == ALU_BEQ || r.instr.opcode == ALU_BNE || 
                             r.instr.opcode == ALU_BLT || r.instr.opcode == ALU_BGE);
          
          // Look up current physical registers for source operands
          PhysRegTag src1PhysReg = archRegMap[r.instr.rs1];
          PhysRegTag src2PhysReg = archRegMap[r.instr.rs2];
          
          // Update mapping: this instruction's dest arch reg now maps to new phys reg
          if (r.instr.rd != 0) begin
            archRegMap[r.instr.rd] <= destTag;
            archRegWritten[r.instr.rd] <= True;
          end
          
          let rsEntry = RSEntry {
            opcode: r.instr.opcode,
            src1: src1PhysReg,
            src1Ready: True,
            src2: src2PhysReg,
            src2Ready: True,
            immediate: r.instr.imm,
            useImmediate: (r.instr.opcode == ALU_ADD || r.instr.opcode == ALU_AND || r.instr.opcode == ALU_OR),
            dest: destTag,
            robTag: robTag,
            pc: lastFetchedPC
          };
          
          rs.enq(rsEntry);
          $display("[DISPATCH] Sent to RS: dest=p%0d rob=%0d", destTag, robTag.idx);

          renameDone <= False;
        end
        $display("[DISPATCH] Sent to RS: dest=p%0d rob=%0d", r.destTag, r.robTag.idx);
        renameDone <= False;
>>>>>>> main
      end else begin
        $display("[DISPATCH] RS is full - stalling");
      end
    endrule

    // Removed doRename rule - functionality moved to doDecodeComplete

    rule haltPC(pc >= maxPC && !halted);
      $display("[Specula] Halting at PC: %h", pc);
      halted <= True;
    endrule

    rule doTerminate (halted && !rs.notEmpty && !alu.notEmpty && rob.isEmpty());
      $display("[Specula] Simulation complete - all instructions retired");
      $finish();
    endrule

    rule doCommit;
      let maybeHead = rob.peekHead();
      if (maybeHead matches tagged Valid .headInfo) begin
        match {.tag, .entry} = headInfo;
        if (entry.completed) begin
          if (entry.dst matches tagged Valid .dstReg) begin
            rename.clearRAT(dstReg);
            $display("[COMMIT] Clearing RAT entry for x%0d", dstReg);
          end
          rob.commitHead(freelist);
        end
      end
    endrule

    rule doExecute (rs.notEmpty && alu.notFull);
      $display("[DEBUG] doExecute rule firing: rs.notEmpty=%b alu.notFull=%b", rs.notEmpty, alu.notFull);
      let rsEntry <- rs.deq();
      $display("[Execute] Dequeued RS entry: op=%0d dest=p%0d rob=%0d", rsEntry.opcode, rsEntry.dest, rsEntry.robTag.idx);

      let src1Val = prf.read(rsEntry.src1);
      let src2Val = prf.read(rsEntry.src2);
      
      let aVal = (src1Val matches tagged Valid .v ? v : 32'h0);
      let bVal = rsEntry.useImmediate ? rsEntry.immediate : (src2Val matches tagged Valid .v ? v : 32'h0);

      ALUReq aluReq = ALUReq {
        opcode: rsEntry.opcode,
        a: aVal,
        b: bVal,  
        dest: rsEntry.dest,
        robTag: rsEntry.robTag,
        pc: rsEntry.pc,
        branchOffset: rsEntry.immediate
      };
      
      alu.enq(aluReq);
      $display("[Execute] Sent to ALU: op=%0d a=%0d b=%0d dest=p%0d rob=%0d (useImm=%0d)", rsEntry.opcode, aVal, bVal, rsEntry.dest, rsEntry.robTag.idx, rsEntry.useImmediate);
    endrule

    rule doWriteback (alu.notEmpty && branchMetaQ.notEmpty);
      let aluResp <- alu.deq();
      let branchMd = branchMetaQ.first; branchMetaQ.deq;
      
      $display("[Writeback] ALU result: res=%0d dest=p%0d rob=%0d", aluResp.result, aluResp.dest, aluResp.robTag.idx);

      rob.writeResultAndComplete(aluResp.robTag, aluResp.result);

      prf.write(aluResp.dest, aluResp.result);
      prf.markReady(aluResp.dest);

      rs.wakeup(aluResp.dest);
      $display("[Writeback] Waking up instructions waiting for p%0d", aluResp.dest);
      
      $display("[Writeback] ROB[%0d] completed with result=%0d, PRF[p%0d] = %0d", 
               aluResp.robTag.idx, aluResp.result, aluResp.dest, aluResp.result);
      
      // Branch resolution: compare prediction vs actual outcome
      if (aluResp.isBranch && branchMd.isBranch) begin
        let mispredicted = (branchMd.predictedTarget != aluResp.actualTarget);
        $display("[Branch Resolution] PC=%h predicted=%h actual=%h | %s", 
                 branchMd.pc, branchMd.predictedTarget, aluResp.actualTarget,
                 mispredicted ? "MISPREDICTED!" : "correct");
        
        // Update predictor with actual outcome
        BranchUpdate upd = BranchUpdate {
          pc: branchMd.pc,
          targetAddr: aluResp.actualTarget,
          taken: aluResp.actualTaken,
          newHistory: 0  // The predictor will compute this internally
        };
        bp.update(upd);
        
        if (mispredicted) begin
          $display("[Misprediction] Flushing pipeline and recovering PC to %h", aluResp.actualTarget);
          pc <= aluResp.actualTarget;
          // TODO: flush pipeline stages
        end
      end
    endrule

  endmodule
endpackage