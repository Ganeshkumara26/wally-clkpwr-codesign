///////////////////////////////////////////
// regfile_icg.v — Wally regfile with Latch-Based ICG
//
// v002: Modified register file that uses an ICG cell to gate the
// clock to the register array. The clock only reaches the FFs
// when we3 (write enable) is asserted.
//
// This is the key power optimization: during idle cycles (no write),
// the gated clock does not toggle, so 992 flip-flops consume
// near-zero dynamic power.
///////////////////////////////////////////

module regfile_icg #(
  parameter XLEN = 32,
  parameter E_SUPPORTED = 0
) (
  input  wire             clk,
  input  wire             reset,
  input  wire             we3,
  input  wire [4:0]       a1, a2, a3,
  input  wire [XLEN-1:0]  wd3,
  output wire [XLEN-1:0]  rd1, rd2
);

  localparam NUMREGS = E_SUPPORTED ? 16 : 32;

  reg [XLEN-1:0] rf [1:NUMREGS-1];
  integer i;

  // ICG: Gate the clock to the register file
  // The enable signal is (we3 || reset) because we need the clock
  // during reset to clear all registers.
  wire rf_clk_en = we3 | reset;
  wire gated_clk;

  icg_cell u_icg (
    .clk_in  (clk),
    .enable  (rf_clk_en),
    .test_en (1'b0),
    .clk_out (gated_clk)
  );

  // Register file now uses the GATED clock
  always @(negedge gated_clk) begin
    if (reset) begin
      for (i = 1; i < NUMREGS; i = i + 1)
        rf[i] <= {XLEN{1'b0}};
    end else begin
      if (we3 && a3 != 0)
        rf[a3] <= wd3;
    end
  end

  assign rd1 = (a1 != 0) ? rf[a1] : {XLEN{1'b0}};
  assign rd2 = (a2 != 0) ? rf[a2] : {XLEN{1'b0}};

endmodule
