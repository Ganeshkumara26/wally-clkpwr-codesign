///////////////////////////////////////////
// regfile.v — Verilog-2005 port of Wally's regfile.sv
//
// Original: David_Harris@hmc.edu, Sarah.Harris@unlv.edu
// Ported for iverilog compatibility. Functionally identical
// to the upstream CVW regfile.sv.
//
// This is the v001 UNMODIFIED baseline.
///////////////////////////////////////////

module regfile #(
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

  // Three ported register file
  // Read two ports combinationally (a1/rd1, a2/rd2)
  // Write on falling edge of clock (a3/wd3/we3)
  // Register 0 hardwired to 0

  always @(negedge clk) begin
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
