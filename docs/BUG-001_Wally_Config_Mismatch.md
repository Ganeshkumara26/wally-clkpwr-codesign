# BUG-001: ICG Latch Polarity Mismatch with Negedge-Triggered Register File

## Date Found
Month 1 — During v002 ICG simulation

## Description
After integrating the latch-based ICG cell into the Wally register file (`regfile_icg.v`), the simulation passed TEST 1 (writes) but FAILED during TEST 2 (read-back) and TEST 3 (stress). Data was arriving one cycle late or not at all.

## Actual Error Output
```
[TEST 2] Reading back and verifying...
  ERROR: x1 = 0x00000000, expected 0xa0000001
[TEST 3] Rapid write/read stress...
  ERROR: x1 = 0x00000000, expected 0xdead0001
  ERROR: x2 = 0xa0000002, expected 0xdead0002
  ...
STATUS: FAIL (16 errors)
```

## Root Cause Analysis

### The Problem
The original Wally `regfile.sv` writes on `negedge clk` (falling edge). Our ICG cell uses a **negative-level-sensitive latch** — it's transparent when `clk_in` is LOW and holds when `clk_in` is HIGH. This is the standard ICG design for **posedge-triggered** flip-flops.

But Wally's register file is **negedge-triggered!**

### What Happens
1. `we3` asserts during the HIGH phase of `clk`.
2. The ICG latch is in **hold** mode (clk is HIGH), so it doesn't see the new `we3`.
3. The ICG latch only becomes transparent on the NEXT LOW phase — AFTER the negedge has already passed.
4. The gated clock pulse arrives too late.

### Options Considered
| Option | Description | Risk |
|--------|-------------|------|
| A | Invert the latch polarity: use a **positive-level-sensitive latch** (transparent when clk is HIGH, holds when LOW). This allows `we3` to pass through before the falling edge. | Low — correct approach for negedge FFs |
| B | Change the regfile to use `posedge clk` instead of `negedge clk`. | High — modifies Wally's pipeline timing contract |
| C | Register `we3` with a half-cycle pre-buffer. | Medium — adds logic, may break tight loops |

## Decision
**Option A: Invert the ICG latch polarity.**

For a negedge-triggered register file, the ICG latch must be **positive-level-sensitive** (transparent when clk is HIGH). This way:
1. During the HIGH phase, `we3` propagates through the latch.
2. The AND gate passes the clock through.
3. The falling edge of the gated clock arrives exactly when the FFs expect it.

## Status
Open — implementing fix in v003.
