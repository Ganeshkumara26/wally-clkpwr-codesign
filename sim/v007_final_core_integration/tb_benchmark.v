///////////////////////////////////////////
// tb_benchmark.v — Final Benchmark for EPI calculation
//
// Simulates a 100-cycle mixed instruction workload (simulating Dhrystone).
// Tracks toggle events across both cores to measure total
// dynamic switching reduction.
///////////////////////////////////////////
`timescale 1ns/1ps

module tb_benchmark;

  reg clk, reset;
  reg [31:0] instr, pc, imm;
  reg we3;
  reg [4:0] rd_addr;

  initial clk = 0;
  always #5 clk = ~clk;

  // Baseline Core
  core_baseline #(.XLEN(32)) u_base (
    .clk(clk), .reset(reset), .instr(instr), .pc(pc), .imm(imm),
    .we3(we3), .rd_addr(rd_addr)
  );

  // Optimized Core
  core_optimized #(.XLEN(32)) u_opt (
    .clk(clk), .reset(reset), .instr(instr), .pc(pc), .imm(imm),
    .we3(we3), .rd_addr(rd_addr)
  );

  // Toggle Counters
  integer base_rf_toggles, base_alu_toggles;
  integer opt_rf_toggles, opt_alu_toggles;
  
  reg [31:0] prev_base_sum, prev_opt_sum;

  // Baseline Tracking
  always @(negedge clk) begin
    if (!reset) base_rf_toggles = base_rf_toggles + 1;
  end
  always @(u_base.u_alu.Sum) begin
    if (!reset && (u_base.u_alu.Sum !== prev_base_sum)) begin
      base_alu_toggles = base_alu_toggles + 1;
      prev_base_sum = u_base.u_alu.Sum;
    end
  end

  // Optimized Tracking
  always @(negedge u_opt.u_regfile.gated_clk) begin
    if (!reset) opt_rf_toggles = opt_rf_toggles + 1;
  end
  always @(u_opt.u_execute.u_alu.Sum) begin
    if (!reset && (u_opt.u_execute.u_alu.Sum !== prev_opt_sum)) begin
      opt_alu_toggles = opt_alu_toggles + 1;
      prev_opt_sum = u_opt.u_execute.u_alu.Sum;
    end
  end

  integer i, cycle_count;
  integer instr_type;

  initial begin
    $dumpfile("v007_benchmark.vcd");
    $dumpvars(0, tb_benchmark);

    base_rf_toggles = 0; base_alu_toggles = 0;
    opt_rf_toggles = 0; opt_alu_toggles = 0;
    prev_base_sum = 0; prev_opt_sum = 0;
    cycle_count = 0;

    instr = 0; pc = 0; imm = 0; we3 = 0; rd_addr = 0;
    reset = 1;
    repeat(4) @(posedge clk);
    reset = 0;

    // Simulate 100 instructions (realistic Dhrystone mix)
    for (i = 0; i < 100; i = i + 1) begin
      @(posedge clk);
      #2; // Simulate combinational logic delay. we3 must be stable during the HIGH phase!
      
      pc = pc + 4;
      instr_type = {$random} % 100;
      
      if (instr_type < 40) begin
        // 40% Compute: R-Type ADD (ALU Active, RegWrite Active)
        instr = {7'b0000000, 5'd10, 5'd11, 3'b000, 5'd12, 7'b0110011};
        imm = 0;
        we3 = 1;
        rd_addr = 12;
      end else if (instr_type < 60) begin
        // 20% Memory: LOAD/STORE (ALU Inactive, NOISE on bus)
        instr = {7'b0000000, 5'd0, 5'd0, 3'b000, 5'd0, 7'b0000011}; // LW
        imm = $random; // High noise
        we3 = 0;       // Stalling writeback
        rd_addr = 0;
      end else if (instr_type < 80) begin
        // 20% Branch (ALU Active, RegWrite Inactive)
        instr = {7'b0000000, 5'd10, 5'd11, 3'b000, 5'd0, 7'b1100011}; // BEQ
        imm = 0;
        we3 = 0;
        rd_addr = 0;
      end else begin
        // 20% NOP/Stall (ALU Inactive, RegWrite Inactive, NOISE)
        instr = 32'h00000013; // NOP
        imm = $random;
        we3 = 0;
        rd_addr = 0;
      end
      
      cycle_count = cycle_count + 1;
    end

    @(posedge clk);
    
    $display("========================================");
    $display("FINAL BENCHMARK ACTIVITY REPORT");
    $display("========================================");
    $display("1. REGISTER FILE CLOCK TREE");
    $display("   Baseline FF clock negedges: %0d", base_rf_toggles);
    $display("   Optimized FF clock negedges: %0d", opt_rf_toggles);
    $display("   -> Dynamic Power Reduction: %0d%%", 
      ((base_rf_toggles - opt_rf_toggles) * 100) / base_rf_toggles);
    $display("----------------------------------------");
    $display("2. ALU COMBINATIONAL CLOUD");
    $display("   Baseline adder transitions: %0d", base_alu_toggles);
    $display("   Isolated adder transitions: %0d", opt_alu_toggles);
    $display("   -> Dynamic Power Reduction: %0d%%",
      ((base_alu_toggles - opt_alu_toggles) * 100) / base_alu_toggles);
    $display("========================================");
    
    $finish;
  end

endmodule
