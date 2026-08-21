# BUG-007: Execute Stage Hardcodes ALU to ADD/SUB

**Date:** 2026-08-08 (Month 4)
**Component:** `execute_stage.v`
**Author:** Ganesh Kumar A

## The Problem
While reviewing the benchmark results for the operand isolation implementation, I realized a massive shortcut I took earlier. In `execute_stage.v`, I hardcoded `alu_select = 3'b000` (which forces the ALU to only do ADD or SUB)!

```verilog
  // ALU Control (simplified for ADD only for this test)
  wire sub_arith = (is_rtype && instr[30]); // SUB if bit 30 is set
  wire [2:0] alu_select = 3'b000; // Force ADD/SUB
```

This means my benchmark is completely fake! If the incoming instruction is an XOR (`funct3 = 3'b100`) or a Shift (`funct3 = 3'b001`), my core just performs an ADD anyway. Since different operations activate different parts of the combinational cloud inside the ALU, locking it to `ADD` means my toggle counts (and thus my power numbers) for the isolated ALU are inaccurate.

## The Fix
The `alu_wally.v` module already supports all the basic RISC-V operations. I just need to hook up `alu_select` to `instr[14:12]` (the `funct3` field) for R-type and I-type instructions, and ensure it defaults to ADD (`3'b000`) for Loads, Stores, Branches, and AUIPC (since they use the adder to calculate addresses/targets).

I will implement this full decoder in `execute_stage.v` and re-run the benchmarks to get authentic toggle counts.
