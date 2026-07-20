///////////////////////////////////////////
// tb_debug.v — Minimal debug testbench to trace ICG timing
///////////////////////////////////////////
`timescale 1ns/1ps

module tb_debug;
  reg clk, reset, we3;
  reg [4:0] a1, a3;
  reg [31:0] wd3;
  wire [31:0] rd1, rd2;

  initial clk = 0;
  always #5 clk = ~clk;

  regfile_icg #(.XLEN(32), .E_SUPPORTED(0)) dut (
    .clk(clk), .reset(reset), .we3(we3),
    .a1(a1), .a2(5'd0), .a3(a3),
    .wd3(wd3), .rd1(rd1), .rd2(rd2)
  );

  initial begin
    $dumpfile("debug.vcd");
    $dumpvars(0, tb_debug);

    reset = 1; we3 = 0; a1 = 0; a3 = 0; wd3 = 0;

    // Reset
    repeat(4) @(posedge clk);
    reset = 0;

    // Write x1 = 0xCAFEBABE
    // Setup data BEFORE posedge, so it's stable for the negedge write
    @(posedge clk);
    we3 = 1;
    a3 = 5'd1;
    wd3 = 32'hCAFEBABE;
    $display("t=%0t: Set we3=1, a3=1, wd3=0xCAFEBABE", $time);
    $display("t=%0t: clk=%b gated_clk=%b en_latch=%b", $time, clk, dut.gated_clk, dut.u_icg.en_latch);

    @(negedge clk);
    $display("t=%0t: NEGEDGE clk. clk=%b gated_clk=%b en_latch=%b", $time, clk, dut.gated_clk, dut.u_icg.en_latch);

    @(posedge clk);
    $display("t=%0t: POSEDGE clk. clk=%b gated_clk=%b en_latch=%b rf[1]=%h", $time, clk, dut.gated_clk, dut.u_icg.en_latch, dut.rf[1]);

    // Now read back
    we3 = 0;
    a1 = 5'd1;
    #1;
    $display("t=%0t: READ rd1=%h (expect CAFEBABE)", $time, rd1);

    // Try again: set we3 one full cycle earlier
    @(posedge clk);
    @(posedge clk);
    we3 = 1;
    a3 = 5'd2;
    wd3 = 32'hDEAD_BEEF;
    $display("t=%0t: Set we3=1 for x2", $time);

    // Wait for the negedge to actually write
    @(negedge clk);
    $display("t=%0t: NEGEDGE. gated_clk=%b en_latch=%b", $time, dut.gated_clk, dut.u_icg.en_latch);
    #1;
    $display("t=%0t: After negedge settle. gated_clk=%b rf[2]=%h", $time, dut.gated_clk, dut.rf[2]);

    @(posedge clk);
    we3 = 0;
    a1 = 5'd2;
    #1;
    $display("t=%0t: READ rd1=%h (expect DEADBEEF)", $time, rd1);

    #50;
    $finish;
  end
endmodule
