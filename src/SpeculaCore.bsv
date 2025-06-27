package SpeculaCore;

  import Vector::*;
  import RegFile::*;
  import FIFO::*;
  import ClientServer::*;
  import GetPut::*;

  typedef Bit#(32) Instruction;
  typedef Bit#(32) Word;
  typedef Bit#(5) RegIndex;

  typedef struct {
    Bit #(7) opcode;
    RegIndex rd;
    RegIndex rs1;
    RegIndex rs2;
    Bit#(3) funct3;
    Bit#(7) funct7;
    Bit#(32) imm;
    Instruction raw;
  } Decoded deriving (Bits, FShow);

  function Bit#(32) getInstruction(Bit#(32) pc);
    case (pc)
      0: return 32'h00500113; // addi x2, x0, 5
      4: return 32'h002081B3; // add  x3, x1, x2
      8: return 32'h00000000; // nop
      12: return 32'h4062A3B3; // sub x7, x5, x6
      16: return 32'h00c2b433; // or x8, x5, x6
      20: return 32'h00c2c4b3; // xor x9, x5, x6
      24: return 32'h00c2d533; // sll x10, x5, x6
      28: return 32'h40c2e5b3; // sra x11, x5, x6

      default: return 32'h00000013; // default: addi x0, x0, 0
    endcase
  endfunction

  function Decoded decode(Instruction i);
    Decoded d;
    d.opcode = i[6:0];
    d.rd = unpack(i[11:7]);
    d.funct3 = i[14:12];
    d.rs1 = unpack(i[19:15]);
    d.rs2 = unpack(i[24:20]);
    d.funct7 = i[31:25];
    d.imm = signExtend(i[31:20]);
    d.raw = i;
    return d;
  endfunction

  module mkSimpleRAM(RegFile#(Bit#(32), Bit#(32)));
    RegFile#(Bit#(32), Bit#(32)) mem <- mkRegFileFull;
    return mem;
  endmodule

  module mkSpeculaCore(Empty);
    Reg#(Bit#(32)) pc <- mkReg(0);
    Reg#(Bit#(3)) initState <- mkReg(0);
    RegFile#(RegIndex, Word) rf <- mkRegFileFull;
    RegFile#(Bit#(32), Bit#(32)) ram <- mkSimpleRAM;

    Reg#(Instruction) if_id_instr <- mkReg(0);
    Reg#(Decoded) id_ex_decoded <- mkReg(?);
    Reg#(Tuple2#(Word, RegIndex)) ex_wb_result <- mkReg(?);
    Reg#(Tuple3#(Bit#(32), RegIndex, Bool)) mem_wb <- mkReg(?);
    Reg#(Tuple4#(Bit#(32), RegIndex, Bool, Bit#(32))) ex_mem <- mkReg(?);

    rule init1(initState == 0);
      rf.upd(1, 10); // x1 = 10 
      initState <= 1;
    endrule

    rule init2(initState == 1);
      rf.upd(2, 20); // x2 = 20
      initState <= 2;
    endrule

    rule init3(initState == 2);
      rf.upd(5, 100); // x5 = 100
      initState <= 3;
    endrule

    rule init4(initState == 3);
      rf.upd(6, 60); // x6 = 60
      initState <= 4;
    endrule

    // === Instruction Fetch ===
    rule stage_IF(initState == 4);
      Instruction instr = getInstruction(pc);
      if_id_instr <= instr;
      $display("[IF] pc = %0d", pc);

      if(pc >= 32)
        $finish;
      pc <= pc + 4;
      
    endrule

    // === Instruction Decode ===
    rule stage_ID;
      Decoded d = decode(if_id_instr);
      id_ex_decoded <= d;
    endrule

    // === Execute ===
    rule stage_EX;
      let d = id_ex_decoded;
      let val1 = rf.sub(d.rs1);
      let val2 = rf.sub(d.rs2);
      Word result = 0;
      Bool isLoad = False;
      Bit#(32) storeVal = 0;

      if (d.opcode == 7'b0010011) begin
        case(d.funct3)
          3'b000: result = val1 + d.imm; // addi
          3'b111: result = val1 & d.imm; // andi
          3'b110: result = val1 | d.imm; // ori
          3'b100: result = val1 ^ d.imm; // xori
          3'b001: result = val1 << d.imm[4:0]; // slli
          default: result = 0;
        endcase
      end
      else if (d.opcode == 7'b0110011) begin
        case ({d.funct7, d.funct3})
          {7'b0000000, 3'b000}: result = val1 + val2;  // add
          {7'b0100000, 3'b000}: result = val1 - val2;  // sub
          {7'b0000000, 3'b111}: result = val1 & val2;  // and
          {7'b0000000, 3'b110}: result = val1 | val2;  // or
          {7'b0000000, 3'b100}: result = val1 ^ val2;  // xor
          {7'b0000000, 3'b001}: result = val1 << val2[4:0]; // sll
          {7'b0000000, 3'b101}: result = val1 >> val2[4:0]; // srl
          default: result = 0;
        endcase
      end

      else if (d.opcode == 7'b0000011) begin // Load
        isLoad = True;
        result = d.imm + val1; // address calculation
      end
      else if (d.opcode == 7'b0100011) begin // Store
        isLoad = False;
        storeVal = val2;
        result = d.imm + val1; // address calculation
      end

      ex_mem <= tuple4(result, d.rd, isLoad, storeVal);
      
      $display("[EX] Instr: %h", d.raw);
      $display("     opcode: %b rd: %0d rs1: %0d val1: %0d rs2: %0d val2: %0d -> result: %0d", d.opcode, d.rd, d.rs1, val1, d.rs2, val2, result);
    endrule

    // === Memory Access ===
    rule stage_MEM;
      let { addr, rd, isLoad, storeVal } = ex_mem;

      if(isLoad) begin
        let loadVal = ram.sub(addr);
        mem_wb <= tuple3(loadVal, rd, True);
      end else begin
        ram.upd(addr, storeVal);
        mem_wb <= tuple3(0, rd, False);
      end
    endrule

    // === Write Back ===
    rule stage_WB;
      let { val, rd, isLoad } = mem_wb;
      if (rd != 0 && isLoad)
        rf.upd(rd, val);
    endrule

  endmodule
endpackage