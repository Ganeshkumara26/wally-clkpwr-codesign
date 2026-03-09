# Adaptive Clock-Power Codesign for RISC-V

**Version 0.1 - Initial Draft**

This is my honors thesis project repository. The goal is to implement Fine-Grained Clock Gating (FGCG) and Operand Isolation on the Wally (CVW) RISC-V core to reduce dynamic power. 

We are targeting the SkyWater 130nm node using the OpenLane ASIC flow. 

## Structure
- `src/cvw`: Upstream clone of Wally
- `src/rtl`: My modified versions
- `openlane`: Synthesis scripts and configs
- `logs`: Power and area reports

More instructions to follow as I figure out how to actually use OpenLane...
