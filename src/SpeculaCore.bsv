package SpeculaCore;

  import FetchUnit::*;
  import DecodeUnit::*;
  import InOrderCore::*;

  module mkSpeculaCore(Empty);
    IfcFetchUnit fetch <- mkFetchUnit;
    IfcDecodeUnit decode <- mkDecodeUnit;

    Reg#(Bit#(32)) pc <- mkReg(0);
    Reg#(Bool) started <- mkReg(False);

    rule doFetch (!started);
      fetch.start(pc);
      started <= True;
    endrule

    rule doDecode (started);
      let instr = fetch.getFetched();
      decode.start(instr, pc);
      let d = decode.getDecoded();
      $display("[Specula] instr: %h | rs1: %0d rs2: %0d rd: %0d", instr, d.rs1, d.rs2, d.rd);
    endrule

  endmodule
endpackage
