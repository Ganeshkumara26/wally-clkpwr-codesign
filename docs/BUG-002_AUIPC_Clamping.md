# BUG-002: ALU Operand Isolation Clamps AUIPC

## Date Found
Month 2 — During v005 Execute Stage Integration

## Description
While wiring the `alu_isolated` module into the execute stage and testing basic instructions, `ADD` and `ADDI` passed, but `AUIPC` (Add Upper Immediate to PC) failed dramatically. The ALU returned `00000000` instead of the expected `PC + Immediate`.

## Actual Error Output
```
[ADD]   rs1=10, rs2=20 -> ALU=30
[ADDI]  rs1=100, imm=15 -> ALU=115
[AUIPC] pc=00001000, imm=12345000 -> ALU=00000000
  => ERROR: Expected 12346000!
STATUS: FAIL (1 errors)
```

## Root Cause Analysis

The operand isolation logic in the execute stage uses a naive decoder to determine when the ALU is "active" (and therefore when it shouldn't clamp the inputs):

```verilog
wire alu_active = is_rtype | is_itype | is_load | is_store | is_branch;
```

I completely forgot that U-type instructions like `AUIPC` also use the ALU! Because `opcode == OP_AUIPC` is not in the `alu_active` equation, `alu_active` goes to 0 during an AUIPC instruction. 

The isolated ALU then perfectly executes its function: it AND-clamps the PC and Immediate to 0 to save power, and calculates `0 + 0 = 0`. Oops.

## Fix
Update the `alu_active` decode logic to include U-type instructions that require the ALU (`AUIPC`, and technically `LUI` if we implement LUI as `0 + Imm` through the ALU).

```verilog
wire is_auipc = (opcode == 7'b0010111);
wire alu_active = is_rtype | is_itype | is_load | is_store | is_branch | is_auipc;
```
