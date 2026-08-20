# Adaptive Clock-Power Codesign for RISC-V

**Version 1.0 - Final Release (October 2026)**

This repository contains my final undergrad project: implementing Fine-Grained Clock Gating (FGCG) and Operand Isolation on a RISC-V core to reduce dynamic power. We used a modular subset of the Wally (CVW) RISC-V core and tested it with `iverilog` and `yosys`.

## 🛠️ The Architecture
The core focuses on two major dynamic power optimization techniques:
1. **Integrated Clock Gating (ICG)**: We injected SkyWater-style latch-based ICG cells into the 32x32 Register File. The clock is gated during Memory stalls, Branches, and NOPs (whenever `RegWrite` is false).
2. **Operand Isolation**: We added AND-clamp logic (`alu_active`) to the Execute stage to prevent operand switching noise from propagating into the ALU combinational cloud during inactive cycles.

*(See `docs/architecture.md` for a full Mermaid diagram of the implementation).*

## 📊 Final Benchmarking Results
We wrote a top-level integration (`core_integration.v`) to run a simulated 100-cycle Dhrystone workload (40% Compute, 20% Memory, 20% Branch, 20% Stalls) through both a baseline core and our optimized core simultaneously. 

The results were eye-opening:
* **Register File (ICG)**: We achieved a **40% reduction** in clock toggles. Clock gating works incredibly well for dense sequential logic that isn't written to every cycle.
* **ALU (Operand Isolation)**: We saw a **25% INCREASE** in combinational adder transitions. Why? Clamping stable datapath buses to `00000000` during stalls actually *creates* massive multi-bit toggles when the data wasn't going to change anyway. Isolation only saves power if the bus is highly noisy. 

*(See `docs/benchmark_results.log` for the exact simulation output).*

## 🐛 Engineering Log
This wasn't a straight line. We hit several major bugs along the way, fully documented in our `docs/issue_tracker.md`:
- **BUG-001**: We initially used negative-level ICG latches for a register file that writes on the negative edge, completely corrupting our timing.
- **BUG-002**: Our naive operand isolation logic forgot that `AUIPC` (U-type) instructions use the ALU, causing `AUIPC` to calculate `0 + 0 = 0`! 

## 📁 Repository Structure
- `sim/v001_baseline`: Pristine baseline RTL
- `sim/v003_icg_fixed`: Successful ICG implementation
- `sim/v006_auipc_fixed`: Successful operand isolation and bug fixes
- `sim/v007_final_core_integration`: The final testbench and benchmark integration
- `docs/`: Issue tracker, architecture diagrams, and simulation results

## 🚀 How to Run
All simulations run perfectly in `iverilog`. To run the final benchmark:
```bash
cd sim/v007_final_core_integration
iverilog -g2012 -o tb_benchmark.vvp *.v
vvp tb_benchmark.vvp
```
