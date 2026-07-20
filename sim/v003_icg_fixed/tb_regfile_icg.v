///////////////////////////////////////////
// tb_regfile_icg.v — v003: Fixed testbench timing for ICG regfile
//
// KEY INSIGHT FROM BUG-001 DEBUG:
// The ICG cell needs we3 to be stable during the HIGH phase of clk
// so the latch can capture it. In a real pipeline, RegWriteW is
// computed by combinational logic and stable well before the edge.
// The testbench must mimic this: drive we3 at posedge, not negedge.
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

  initial clk = 0;
  always #5 clk = ~clk;

  regfile_icg #(.XLEN(XLEN), .E_SUPPORTED(E_SUPPORTED)) dut (
    .clk(clk), .reset(reset), .we3(we3),
    .a1(a1), .a2(a2), .a3(a3),
    .wd3(wd3), .rd1(rd1), .rd2(rd2)
  );

  integer write_cycles, idle_cycles, total_cycles, gated_toggles, errors;
  integer i;

  // Count gated clock negedges (actual FF toggle events)
  always @(negedge dut.gated_clk) begin
    if (!reset)
      gated_toggles = gated_toggles + 1;
  end

  initial begin
    $dumpfile("v003_icg_fixed.vcd");
    $dumpvars(0, tb_regfile_icg);

    write_cycles = 0; idle_cycles = 0;
    total_cycles = 0; gated_toggles = 0; errors = 0;
    reset = 1; we3 = 0;
    a1 = 0; a2 = 0; a3 = 0; wd3 = 0;

    repeat(4) @(posedge clk);
    reset = 0;

    $display("========================================");
    $display("v003 ICG-FIXED REGFILE SIMULATION");
    $display("========================================");

    // TEST 1: Write all 31 registers
    // Drive we3 at posedge so ICG latch captures it during HIGH phase.
    // The write happens on the negedge of gated_clk within the same cycle.
    $display("[TEST 1] Writing x1-x31...");
    for (i = 1; i < 32; i = i + 1) begin
      @(posedge clk);
      we3 = 1;
      a3 = i[4:0];
      wd3 = 32'hA000_0000 + i;
      write_cycles = write_cycles + 1;
      total_cycles = total_cycles + 1;
    end
    @(posedge clk);
    we3 = 0;
    total_cycles = total_cycles + 1;
    idle_cycles = idle_cycles + 1;

    // TEST 2: Read back all registers
    $display("[TEST 2] Read-back verification...");
    for (i = 1; i < 32; i = i + 1) begin
      a1 = i[4:0];
      a2 = 5'd0;
      #1;
      if (rd1 !== (32'hA000_0000 + i)) begin
        $display("  FAIL: x%0d = 0x%08h, want 0x%08h", i, rd1, 32'hA000_0000 + i);
        errors = errors + 1;
      end
      if (rd2 !== 32'h0) begin
        $display("  FAIL: x0 = 0x%08h, want 0", rd2);
        errors = errors + 1;
      end
      @(posedge clk);
      idle_cycles = idle_cycles + 1;
      total_cycles = total_cycles + 1;
    end

    // TEST 3: Interleaved write/read stress
    $display("[TEST 3] Write/read stress x1-x15...");
    for (i = 1; i < 16; i = i + 1) begin
      // Write cycle
      @(posedge clk);
      we3 = 1;
      a3 = i[4:0];
      wd3 = 32'hDEAD_0000 + i;
      write_cycles = write_cycles + 1;
      total_cycles = total_cycles + 1;

      // Read-back cycle (next posedge)
      @(posedge clk);
      we3 = 0;
      a1 = i[4:0];
      #1;
      if (rd1 !== (32'hDEAD_0000 + i)) begin
        $display("  FAIL: x%0d = 0x%08h, want 0x%08h", i, rd1, 32'hDEAD_0000 + i);
        errors = errors + 1;
      end
      idle_cycles = idle_cycles + 1;
      total_cycles = total_cycles + 1;
    end

    // TEST 4: 50 idle cycles — gated_clk should NOT toggle
    $display("[TEST 4] 50 idle cycles...");
    we3 = 0; a1 = 5'd1; a2 = 5'd2;
    repeat(50) begin
      @(posedge clk);
      idle_cycles = idle_cycles + 1;
      total_cycles = total_cycles + 1;
    end

    // Results
    $display("========================================");
    $display("v003 RESULTS");
    $display("========================================");
    $display("Total cycles:            %0d", total_cycles);
    $display("Write cycles (we3=1):    %0d", write_cycles);
    $display("Idle cycles (we3=0):     %0d", idle_cycles);
    $display("Gated clk toggles:       %0d", gated_toggles);
    $display("Write activity:          %0d%%", (write_cycles * 100) / total_cycles);
    $display("Clock gating efficiency: %0d%%",
      ((total_cycles - gated_toggles) * 100) / total_cycles);
    $display("Errors:                  %0d", errors);
    $display("STATUS: %s", errors == 0 ? "PASS" : "FAIL");
    $display("========================================");

    #20; $finish;
  end
endmodule
