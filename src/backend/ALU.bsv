package ALU;

  import Common::*;
  import FIFOF::*;

  function Bit#(32) signedShiftRight(Bit#(32) val, Bit#(5) shamt);
    Int#(32) signedVal = unpack(val);
    Int#(32) shifted = signedVal >> shamt;
    return pack(shifted);
  endfunction

  typedef struct {
    ALUOp opcode;
    Data a;
    Data b;
    PhysRegTag dest;
    ROBTag robTag;
    Bit#(32) pc;
    Bit#(32) branchOffset;
  } ALUReq deriving (Bits, FShow);

  typedef struct {
    Data result;
    PhysRegTag dest;
    ROBTag robTag;
    Bool isBranch;
    Bool actualTaken;
    Data actualTarget;
  } ALUResp deriving (Bits, FShow);

  interface ALU_IFC;
    method Bool notFull();
    method Bool notEmpty();
    method Action enq(ALUReq r);
    method ActionValue#(ALUResp) deq();
  endinterface

  module mkALU(ALU_IFC);

    FIFOF#(ALUReq) reqQ <- mkFIFOF();
    FIFOF#(ALUReq) stage1Q <- mkFIFOF();
    FIFOF#(ALUReq) stage2Q <- mkFIFOF();
    FIFOF#(ALUReq) stage3Q <- mkFIFOF();
    FIFOF#(ALUReq) stage4Q <- mkFIFOF();
    FIFOF#(ALUReq) stage5Q <- mkFIFOF();
    FIFOF#(ALUReq) stage6Q <- mkFIFOF();
    FIFOF#(ALUReq) stage7Q <- mkFIFOF();
    FIFOF#(ALUReq) stage8Q <- mkFIFOF();
    FIFOF#(ALUResp) stage9Q <- mkFIFOF();
    FIFOF#(ALUResp) respQ <- mkFIFOF();

    rule s1; let r = reqQ.first; reqQ.deq; stage1Q.enq(r); endrule
    rule s2; let r = stage1Q.first; stage1Q.deq; stage2Q.enq(r); endrule
    rule s3; let r = stage2Q.first; stage2Q.deq; stage3Q.enq(r); endrule
    rule s4; let r = stage3Q.first; stage3Q.deq; stage4Q.enq(r); endrule
    rule s5; let r = stage4Q.first; stage4Q.deq; stage5Q.enq(r); endrule
    rule s6; let r = stage5Q.first; stage5Q.deq; stage6Q.enq(r); endrule  
    rule s7; let r = stage6Q.first; stage6Q.deq; stage7Q.enq(r); endrule
    rule s8; let r = stage7Q.first; stage7Q.deq; stage8Q.enq(r); endrule

    // Stage 9: Execute
    rule stage_execute;
      let r = stage8Q.first; stage8Q.deq;

      Data res = 32'd0;
      Bool isBranch = False;
      Bool actualTaken = False;
      Data actualTarget = 32'd0;
      
      case (r.opcode) 
        ALU_ADD: res = r.a + r.b;
        ALU_SUB: res = r.a - r.b;
        ALU_AND: res = r.a & r.b;
        ALU_OR: res = r.a | r.b;
        ALU_BEQ: begin
          isBranch = True;
          actualTaken = (r.a == r.b);
          actualTarget = r.pc + r.branchOffset;
          res = 0;
        end
        ALU_BNE: begin
          isBranch = True;
          actualTaken = (r.a != r.b);
          actualTarget = r.pc + r.branchOffset;
          res = 0;
        end
        ALU_BLT: begin
          isBranch = True;
          actualTaken = (signedLT(r.a, r.b));
          actualTarget = r.pc + r.branchOffset;
          res = 0;
        end
        ALU_BGE: begin
          isBranch = True;
          actualTaken = (signedGE(r.a, r.b));
          actualTarget = r.pc + r.branchOffset;
          res = 0;
        end
        default: res = 32'd0;
      endcase

      ALUResp out = ALUResp {
        result: res, 
        dest: r.dest,
        robTag: r.robTag,
        isBranch: isBranch,
        actualTaken: actualTaken,
        actualTarget: actualTarget
      };
      stage9Q.enq(out);
    endrule

    // Stage 10: Writeback
    rule stage_writeback;
      let out = stage9Q.first; stage9Q.deq;
      respQ.enq(out);
    endrule

    method Bool notFull() = reqQ.notFull;
    method Bool notEmpty() = respQ.notEmpty;

    method Action enq(ALUReq r);
      reqQ.enq(r);
    endmethod

    method ActionValue#(ALUResp) deq();
      let v = respQ.first; respQ.deq;
      return v;
    endmethod

  endmodule
endpackage