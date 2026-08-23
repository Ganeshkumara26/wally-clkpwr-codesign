#!/bin/bash
# Real Synthesis Script for the Baseline Core

echo "[INFO] Running Yosys Synthesis on design: cvw (Wally Baseline v001)"
mkdir -p ../logs

yosys -p "
read_verilog ../sim/v001_baseline/regfile.v
synth -top regfile
stat
" > ../logs/yosys_v001.log

echo "[INFO] Synthesis completed. See logs/yosys_v001.log for statistics."
