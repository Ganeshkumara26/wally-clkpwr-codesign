///////////////////////////////////////////
// tb_regfile.sv — Standalone testbench for Wally's regfile.sv
//
// v001 Baseline: Unmodified register file from CVW.
// This testbench exercises write and read-back operations, dumps VCD,
// and prints toggle statistics for power analysis.
///////////////////////////////////////////
`timescale 1ns/1ps

module tb_regfile;

  parameter XLEN = 32;
  parameter E_SUPPORTED = 0;

  logic             clk, reset;
  logic             we3;
  logic [4:0]       a1, a2, a3;
  logic [XLEN-1:0]  wd3;
  logic [XLEN-1:0]  rd1, rd2;

  // Clock generation: 100 MHz (10 ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT instantiation — original unmodified Wally regfile
  regfile #(.XLEN(XLEN), .E_SUPPORTED(E_SUPPORTED)) dut (
    .clk(clk),
    .reset(reset),
    .we3(we3),
    .a1(a1),
    .a2(a2),
    .a3(a3),
    .wd3(wd3),
    .rd1(rd1),
    .rd2(rd2)
  );

  // Toggle counter for power estimation
  integer write_cycles;
  integer idle_cycles;
  integer total_cycles;
  integer errors;

  initial begin
    $dumpfile("v001_baseline.vcd");
    $dumpvars(0, tb_regfile);

    // Initialize
    write_cycles = 0;
    idle_cycles = 0;
    total_cycles = 0;
    errors = 0;
    reset = 1;
    we3 = 0;
    a1 = 0; a2 = 0; a3 = 0;
    wd3 = 0;

    // Hold reset for 4 cycles
    repeat(4) @(posedge clk);
    reset = 0;
    @(posedge clk);

    $display("========================================");
    $display("v001 BASELINE REGFILE SIMULATION START");
    $display("========================================");

    // TEST 1: Write to all 31 registers (x1-x31)
    $display("[TEST 1] Writing all registers x1-x31...");
    begin : write_all
      integer i;
      for (i = 1; i < 32; i = i + 1) begin
        @(negedge clk);  // Wally regfile writes on negedge
        we3 = 1;
        a3 = i[4:0];
        wd3 = 32'hA000_0000 + i;
        write_cycles = write_cycles + 1;
        total_cycles = total_cycles + 1;
        @(posedge clk);
      end
    end
    we3 = 0;
    @(posedge clk);

    // TEST 2: Read back and verify all registers
    $display("[TEST 2] Reading back and verifying...");
    begin : read_all
      integer i;
      for (i = 1; i < 32; i = i + 1) begin
        a1 = i[4:0];
        a2 = 5'd0;  // x0 should always read 0
        @(posedge clk);
        #1; // small delay for combinational read to settle
        idle_cycles = idle_cycles + 1;
        total_cycles = total_cycles + 1;
        if (rd1 !== (32'hA000_0000 + i)) begin
          $display("  ERROR: x%0d = 0x%08h, expected 0x%08h", i, rd1, 32'hA000_0000 + i);
          errors = errors + 1;
        end
        if (rd2 !== 32'h0) begin
          $display("  ERROR: x0 read as 0x%08h, expected 0x00000000", rd2);
          errors = errors + 1;
        end
      end
    end

    // TEST 3: Stress — rapid writes interleaved with reads
    $display("[TEST 3] Rapid write/read stress...");
    begin : stress
      integer i;
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
        @(posedge clk);
        #1;
        idle_cycles = idle_cycles + 1;
        total_cycles = total_cycles + 1;
        if (rd1 !== (32'hDEAD_0000 + i)) begin
          $display("  ERROR: x%0d = 0x%08h, expected 0x%08h", i, rd1, 32'hDEAD_0000 + i);
          errors = errors + 1;
        end
      end
    end

    // TEST 4: Idle cycles (no writes — clock still toggles all FFs)
    $display("[TEST 4] 50 idle cycles (no writes)...");
    we3 = 0;
    a1 = 5'd1; a2 = 5'd2;
    repeat(50) begin
      @(posedge clk);
      idle_cycles = idle_cycles + 1;
      total_cycles = total_cycles + 1;
    end

    // Summary
    $display("========================================");
    $display("v001 BASELINE SIMULATION RESULTS");
    $display("========================================");
    $display("Total cycles:       %0d", total_cycles);
    $display("Write cycles:       %0d", write_cycles);
    $display("Idle cycles:        %0d", idle_cycles);
    $display("Write activity (%%): %0d%%", (write_cycles * 100) / total_cycles);
    $display("Errors:             %0d", errors);
    if (errors == 0)
      $display("STATUS: PASS");
    else
      $display("STATUS: FAIL");
    $display("========================================");

    #20;
    $finish;
  end

endmodule
