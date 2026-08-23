# OpenLane Configuration for Wally (CVW) v003

set ::env(DESIGN_NAME) "core_integration"
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/../../sim/v007_final_core_integration/*.v]

set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) "clk"
set ::env(CLOCK_PERIOD) "10.0"

# Fix for BUG-001
set ::env(PDK) "sky130A"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 2000 2000"
set ::env(PL_TARGET_DENSITY) 0.45

# Fix for BUG-002
set ::env(RUN_POWER_ANALYSIS) 1

# CTS defaults
set ::env(CTS_TARGET_SKEW) 150
