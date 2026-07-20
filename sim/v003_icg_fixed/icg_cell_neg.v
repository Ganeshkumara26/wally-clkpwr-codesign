///////////////////////////////////////////
// icg_cell_neg.v — ICG cell for NEGEDGE-triggered flip-flops
//
// Standard ICG uses a neg-level latch for posedge FFs.
// Wally's regfile writes on negedge clk, so we need a
// POSITIVE-level latch: transparent when clk is HIGH,
// holds when clk is LOW. This lets we3 propagate through
// during the HIGH phase, so the gated falling edge arrives
// correctly.
///////////////////////////////////////////

module icg_cell_neg (
  input  wire clk_in,
  input  wire enable,
  input  wire test_en,
  output wire clk_out
);

  reg en_latch;

  // Positive level-sensitive latch
  // Transparent when clk_in is HIGH, holds when clk_in is LOW
  always @(*) begin
    if (clk_in)
      en_latch = enable | test_en;
  end

  // Gated clock: passes falling edge only when enabled
  assign clk_out = clk_in & en_latch;

endmodule
