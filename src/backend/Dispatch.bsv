package Dispatch;

  import Common::*;
  import ReservationStation::*;

  function ALUOp getALUOp(Decoded inst);
    ALUOp op = ALU_ADD; // default
    
    case (inst.opcode)
      OP_IMM: begin
        case (inst.funct3)
          3'b000: op = ALU_ADDI;  // addi
          3'b111: op = ALU_ANDI;  // andi
          3'b110: op = ALU_ORI;   // ori
          3'b100: op = ALU_XORI;  // xori
          3'b001: op = ALU_SLLI;  // slli
          default: op = ALU_ADDI;
        endcase
      end
      
      OP: begin
        case ({inst.funct7, inst.funct3})
          {7'b0000000, 3'b000}: op = ALU_ADD;  // add
          {7'b0100000, 3'b000}: op = ALU_SUB;  // sub
          {7'b0000000, 3'b111}: op = ALU_AND;  // and
          {7'b0000000, 3'b110}: op = ALU_OR;   // or
          {7'b0000000, 3'b100}: op = ALU_XOR;  // xor
          {7'b0000000, 3'b001}: op = ALU_SLL;  // sll
          {7'b0000000, 3'b101}: op = ALU_SRL;  // srl
          {7'b0100000, 3'b101}: op = ALU_SRA;  // sra
          default: op = ALU_ADD;
        endcase
      end
      
      default: op = ALU_ADD;
    endcase
    
    return op;
  endfunction

  interface IfcDispatch;
    method Action start(Decoded inst, PhysRegTag destTag, ROBTag robTag);
    method ActionValue#(RSEntry) getDispatchedEntry();
    method Bool hasDispatchedEntry();
  endinterface

  module mkDispatch(IfcDispatch);
    
    Reg#(Maybe#(RSEntry)) dispatchedEntry <- mkReg(tagged Invalid);

    method Action start(Decoded inst, PhysRegTag destTag, ROBTag robTag);
      
      ALUOp operation = getALUOp(inst);
      
      RSEntry rsEntry = RSEntry {
        opcode: inst.opcode,
        src1: PhysRegTag'(zeroExtend(inst.rs1)),  
        src1Ready: True,
        src2: PhysRegTag'(zeroExtend(inst.rs2)),   
        src2Ready: True,
        immediate: inst.imm,                   
        useImmediate: (inst.opcode == ALU_ADD || inst.opcode == ALU_AND || inst.opcode == ALU_OR),
        dest: destTag,
        robTag: robTag
      };

      dispatchedEntry <= tagged Valid rsEntry;
      $display("[DISPATCH] RS entry opcode=%0d (should match decoded)", rsEntry.opcode);
    endmethod

    method ActionValue#(RSEntry) getDispatchedEntry() if (dispatchedEntry matches tagged Valid .entry);
      dispatchedEntry <= tagged Invalid;
      return entry;
    endmethod

    method Bool hasDispatchedEntry();
      return isValid(dispatchedEntry);
    endmethod
  endmodule

endpackage