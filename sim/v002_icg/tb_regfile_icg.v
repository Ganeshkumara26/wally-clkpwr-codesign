///////////////////////////////////////////
// tb_regfile_icg.v — Testbench for ICG-gated regfile (v002)
//
// Same test sequence as v001 baseline, but now monitors gated_clk
// to count how many cycles the register file clock actually toggles.
///////////////////////////////////////////
`timescale 1ns/1ps

module tb_regfile_icg;

  parameter XLEN = 32;
  parameter E_SUPPORTED = 0;

  reg              clk, reset;
  reg              we3;
  reg  [4:0]       a1, a2, a3;
  reg  [XLEN-1:0]  wd3;
  wire [XLEN-1:0]  rd1, rd2;

  // Clock generation: 100 MHz
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT — ICG-gated regfile
  regfile_icg #(.XLEN(XLEN), .E_SUPPORTED(E_SUPPORTED)) dut (
    .clk(clk),
    .reset(reset),
    .we3(we3),
    .a1(a1), .a2(a2), .a3(a3),
    .wd3(wd3),
    .rd1(rd1), .rd2(rd2)
  );

  integer write_cycles;
  integer idle_cycles;
  integer total_cycles;
  integer gated_clk_toggles;
  integer errors;
  integer i;

  // Count gated clock rising edges
  reg prev_gated_clk;
  always @(posedge clk) begin
    prev_gated_clk <= dut.gated_clk;
  end

  // Count falling edges of gated_clk (since regfile writes on negedge)
  always @(negedge dut.gated_clk) begin
    if (!reset)
      gated_clk_toggles = gated_clk_toggles + 1;
  end

  initial begin
    $dumpfile("v002_icg.vcd");
    $dumpvars(0, tb_regfile_icg);

    write_cycles = 0;
    idle_cycles = 0;
    total_cycles = 0;
    gated_clk_toggles = 0;
    errors = 0;
    reset = 1;
    we3 = 0;
    a1 = 0; a2 = 0; a3 = 0;
    wd3 = 0;
    prev_gated_clk = 0;

    repeat(4) @(posedge clk);
    reset = 0;
    @(posedge clk);

    $display("========================================");
    $display("v002 ICG-GATED REGFILE SIMULATION START");
    $display("XLEN=%0d  NUMREGS=%0d", XLEN, E_SUPPORTED ? 16 : 32);
    $display("========================================");

    // TEST 1: Write to all 31 registers
    $display("[TEST 1] Writing all registers x1-x31...");
    for (i = 1; i < 32; i = i + 1) begin
      @(negedge clk);
      we3 = 1;
      a3 = i[4:0];
      wd3 = 32'hA000_0000 + i;
      write_cycles = write_cycles + 1;
      total_cycles = total_cycles + 1;
      @(posedge clk);
    end
    we3 = 0;
    @(posedge clk);

    // TEST 2: Read back and verify
    $display("[TEST 2] Reading back and verifying...");
    for (i = 1; i < 32; i = i + 1) begin
      a1 = i[4:0];
      a2 = 5'd0;
      #1;
      if (rd1 !== (32'hA000_0000 + i)) begin
        $display("  ERROR: x%0d = 0x%08h, expected 0x%08h", i, rd1, 32'hA000_0000 + i);
        errors = errors + 1;
      end
      if (rd2 !== 32'h0) begin
        $display("  ERROR: x0 read as 0x%08h, expected 0x00000000", rd2);
        errors = errors + 1;
      end
      @(posedge clk);
      idle_cycles = idle_cycles + 1;
      total_cycles = total_cycles + 1;
    end

    // TEST 3: Stress
    $display("[TEST 3] Rapid write/read stress...");
    for (i = 1; i < 16; i = i + 1) begin
      @(negedge clk);
      we3 = 1;
      a3 = i[4:0];
      wd3 = 32'hDEAD_0000 + i;
      write_cycles = write_cycles + 1;
      total_cycles = total_cycles + 1;
      @(posedge clk);
      we3 = 0;
      a1 = i[4:0];
      #1;
      if (rd1 !== (32'hDEAD_0000 + i)) begin
        $display("  ERROR: x%0d = 0x%08h, expected 0x%08h", i, rd1, 32'hDEAD_0000 + i);
        errors = errors + 1;
      end
      @(posedge clk);
      idle_cycles = idle_cycles + 1;
      total_cycles = total_cycles + 1;
    end

    // TEST 4: 50 idle cycles
    $display("[TEST 4] 50 idle cycles (gated_clk should NOT toggle)...");
    we3 = 0;
    a1 = 5'd1; a2 = 5'd2;
    repeat(50) begin
      @(posedge clk);
      idle_cycles = idle_cycles + 1;
      total_cycles = total_cycles + 1;
    end

    // Summary
    $display("========================================");
    $display("v002 ICG-GATED SIMULATION RESULTS");
    $display("========================================");
    $display("Total main clk cycles:   %0d", total_cycles);
    $display("Write cycles (we3=1):    %0d", write_cycles);
    $display("Idle cycles  (we3=0):    %0d", idle_cycles);
    $display("Gated clk negedge count: %0d", gated_clk_toggles);
    $display("Write activity (%%):      %0d%%", (write_cycles * 100) / total_cycles);
    $display("Clock gating efficiency: %0d%%",
      ((total_cycles - gated_clk_toggles) * 100) / total_cycles);
    $display("Errors:                  %0d", errors);
    if (errors == 0)
      $display("STATUS: PASS");
    else
      $display("STATUS: FAIL");
    $display("========================================");
    $display("POWER IMPACT: In baseline, 992 FFs toggle every cycle.");
    $display("With ICG, 992 FFs only toggle %0d/%0d cycles = %0d%% of the time.",
      gated_clk_toggles, total_cycles,
      (gated_clk_toggles * 100) / total_cycles);
    $display("========================================");

    #20;
    $finish;
  end

endmodule
