package ALU;

  import Common::*;
  import FIFOF::*;

  typedef struct {
    ALUOp op;
    Data a;
    Data b;
    PhysRegTag dest;
    ROBTag robTag;
  } ALUReq deriving (Bits, FShow);

  typedef struct {
    Data result;
    PhysRegTag dest;
    ROBTag robTag;
  } ALUResp deriving (Bits, FShow);

  interface ALU_IFC;
    method Bool notFull();
    method Bool notEmpty();
    method Action enq(ALUReq r);
    method ActionValue#(ALUResp) deq();
  endinterface

  module mkALU(ALU_IFC);

    FIFOF#(ALUReq) reqQ <- mkFIFOF();
    FIFOF#(ALUResp) respQ <- mkFIFOF();

    rule do_execute(respQ.notFull && reqQ.notEmpty);
      let r = reqQ.first; reqQ.deq;

      Data res = 32'd0;
      case (r.op) 
        ALU_ADD: res = r.a + r.b;
        ALU_SUB: res = r.a - r.b;
        ALU_AND: res = r.a & r.b;
        ALU_OR: res = r.a | r.b;
        default: res = 32'd0;
      endcase

      ALUResp out = ALUResp {
        result: res, 
        dest: r.dest,
        robTag: r.robTag
      };
      respQ.enq(out);

      $display("[ALU] op=%0d a=%0d b=%0d -> res=%0d dest=%0d rob=%0d", r.op, r.a, r.b, res, r.dest, r.robTag.idx);

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