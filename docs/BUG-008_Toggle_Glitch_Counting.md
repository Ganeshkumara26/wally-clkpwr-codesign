# BUG-008: Toggle Counter Counts Combinational Glitches

**Date:** 2026-08-16 (Month 5)
**Component:** `tb_benchmark.v`
**Author:** Ganesh Kumar A

## The Problem
My previous benchmark showed that operand isolation actually INCREASED dynamic power by 25%. While it is true that isolation can cause toggles by clamping stable data to `0`, the 25% penalty seemed suspiciously high.

I looked closely at how I was measuring ALU toggles in `tb_benchmark.v`:
```verilog
  always @(u_base.u_alu.Sum) begin
    if (!reset && (u_base.u_alu.Sum !== prev_base_sum)) begin
      base_alu_toggles = base_alu_toggles + 1;
      // ...
```

By triggering on `always @(Sum)`, I was incrementing the toggle counter *every time the signal glitched* during the combinational settling phase! When inputs arrive at an adder at slightly different times, the output ripples through multiple intermediate values before settling. I was counting all these temporary glitches as full clock-cycle transitions, severely skewing the power estimate.

## The Fix
I changed the trigger to `always @(negedge clk)` so that the counter only samples the *final, settled* value of the ALU at the end of the clock cycle, before the next posedge changes the inputs.

```verilog
  always @(negedge clk) begin
    if (!reset && (u_base.u_alu.Sum !== prev_base_sum)) begin
      base_alu_toggles = base_alu_toggles + 1;
      // ...
```

After re-running the benchmark with this fix (and the fully expanded ALU from BUG-007), the penalty dropped from +25% to **0%**. Operand isolation still doesn't save any power on this workload (because the pipeline registers naturally hold their values anyway), but it doesn't cause a massive penalty either.
