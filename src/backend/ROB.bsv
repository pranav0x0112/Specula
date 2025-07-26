package ROB;

import Vector::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Common::*;

typedef 32 NumEntries;

typedef struct {
  ROBTag tag;
  Maybe#(RegIndex) dst;
  Bool completed;
  Data data;
} ROBEntry deriving (Bits, FShow);

interface ROB_IFC;
  method Bool canAllocate();
  method ActionValue#(ROBTag) allocate(Maybe#(RegIndex) dst);
  method Action writeResult(ROBTag tag, Data data);
  method Action markCompleted(ROBTag tag);
  method Maybe#(Tuple2#(ROBTag, ROBEntry)) peekHead();
  method Action commitHead();
endinterface

module mkROB(ROB_IFC);

  Vector#(NumEntries, Reg#(ROBEntry)) robEntries <- replicateM(mkRegU);
  Reg#(UInt#(6)) head <- mkReg(0);
  Reg#(UInt#(6)) tail <- mkReg(0);
  Reg#(UInt#(6)) count <- mkReg(0); // 6 bits to count up to 32

  function ROBTag mkTag(UInt#(6) idx);
    return ROBTag { idx: idx };
  endfunction

  method Bool canAllocate();
    return (count < fromInteger(valueOf(NumEntries)));
  endmethod

  method ActionValue#(ROBTag) allocate(Maybe#(RegIndex) dst);
    if (!(count < fromInteger(valueOf(NumEntries))))
      $fatal(1, "ROB full!");

    let tag = mkTag(tail);
    robEntries[tail] <= ROBEntry {
      tag: tag,
      dst: dst,
      completed: False,
      data: unpack(0)
    };
    tail <= (tail + 1 == fromInteger(valueOf(NumEntries))) ? 0 : tail + 1;
    count <= count + 1;
    return tag;
  endmethod

  method Action writeResult(ROBTag tag, Data data);
    robEntries[tag.idx].data <= data;
  endmethod

  method Action markCompleted(ROBTag tag);
    robEntries[tag.idx].completed <= True;
  endmethod

  method Maybe#(Tuple2#(ROBTag, ROBEntry)) peekHead();
    Maybe#(Tuple2#(ROBTag, ROBEntry)) result = tagged Invalid;
    if (count > 0)
      result = tagged Valid tuple2(robEntries[head].tag, robEntries[head]);
    return result;
  endmethod

  method Action commitHead();
    if (count > 0 && robEntries[head].completed) begin
      head <= (head + 1 == fromInteger(valueOf(NumEntries))) ? 0 : head + 1;
      count <= count - 1;
    end
  endmethod

endmodule

endpackage