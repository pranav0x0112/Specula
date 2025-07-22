package SpeculaCore;

  import FetchUnit::*;
  import DecodeUnit::*;
  import Common::*;
  import Dispatch::*;

  module mkSpeculaCore(Empty);
    IfcFetchUnit fetch <- mkFetchUnit;
    IfcDecodeUnit decode <- mkDecodeUnit;
    IfcDispatch dispatch <- mkDispatch;
    
    let maxPC = 32'h00000100;

    Reg#(Bit#(32)) pc <- mkReg(0);
    Reg#(Bool) fetchStarted <- mkReg(False);
    Reg#(Bool) decodeStarted <- mkReg(False);
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

    rule doDispatch (decodeStarted && !halted);
      let d = decode.getDecoded();
      dispatch.start(d);
      pc <= pc + 4;
      fetchStarted <= False;
      decodeStarted <= False;
    endrule

    rule haltPC(pc >= maxPC && !halted);
      $display("[Specula] Halting at PC: %h", pc);
      halted <= True;
    endrule

  endmodule
endpackage