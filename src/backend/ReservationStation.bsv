package ReservationStation;

  import FIFO::*;
  import FIFOF::*;
  import Common::*;
  import Vector::*;

  typedef 8 RS_SIZE;

  interface ReservationStationIfc;
    method Action enq(RSEntry entry);
    method ActionValue#(RSEntry) deq();
    method Bool notFull;
    method Bool notEmpty;
  endinterface

  module mkReservationStation(ReservationStationIfc);

    Reg#(Vector#(RS_SIZE, Maybe#(RSEntry))) slots <- mkReg(replicate(Invalid));

    function Maybe#(UInt#(TLog#(RS_SIZE))) findFree(Vector#(RS_SIZE, Maybe#(RSEntry)) s);
      Maybe#(UInt#(TLog#(RS_SIZE))) result = Invalid;
      for (Integer i = 0; i < valueOf(RS_SIZE); i = i + 1) begin
        if (!isValid(s[i]) && !isValid(result)) begin
          result = Valid(fromInteger(i)); 
        end
      end
      return result;
    endfunction

    function Maybe#(UInt#(TLog#(RS_SIZE))) findReady(Vector#(RS_SIZE, Maybe#(RSEntry)) s);
      Maybe#(UInt#(TLog#(RS_SIZE))) result = Invalid;
      for (Integer i = 0; i < valueOf(RS_SIZE); i = i + 1) begin
        if (isValid(s[i])) begin
          let e = fromMaybe(?, s[i]);
          if (e.src1Ready && e.src2Ready && !isValid(result))
            result = Valid(fromInteger(i));
        end
      end
      return result;
    endfunction

    rule show_rs;
      for (Integer i = 0; i < valueOf(RS_SIZE); i = i+1) begin
        if (isValid(slots[i])) begin
          let e = fromMaybe(?, slots[i]);
          $display("[RS] Slot %0d: op=%0d dest=%0d src1=%0d ready=%0d src2=%0d ready=%0d rob=%0d", i, e.opcode, e.dest, e.src1, e.src1Ready, e.src2, e.src2Ready, e.robTag.idx);
        end
      end
    endrule

    method Action enq(RSEntry entry);
      let freeIdx = findFree(slots);
      $display("[RS][ENQ] entry.opcode=%0d dest=%0d src1=%0d src2=%0d rob=%0d", entry.opcode, entry.dest, entry.src1, entry.src2, entry.robTag.idx);
      if (isValid(freeIdx)) begin
        slots[validValue(freeIdx)] <= Valid(entry);
      end
      else $display("[RS] Enqueue failed: RS full");
    endmethod

    method ActionValue#(RSEntry) deq();
      let readyIdx = findReady(slots);
      if (isValid(readyIdx)) begin
        let idx = validValue(readyIdx);
        let e = fromMaybe(?, slots[idx]);
        $display("[RS][DEQ] entry.opcode=%0d dest=%0d src1=%0d src2=%0d rob=%0d", e.opcode, e.dest, e.src1, e.src2, e.robTag.idx);
        slots[idx] <= Invalid;
        return e;
      end 
      else begin
        $display("[RS] Dequeue attempted but no ready entry");
        return ?;
      end
    endmethod
    
    method Bool notFull = isValid(findFree(slots));
    method Bool notEmpty = isValid(findReady(slots));

  endmodule
endpackage