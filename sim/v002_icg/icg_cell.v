///////////////////////////////////////////
// icg_cell.v — Behavioral Latch-Based Integrated Clock Gating Cell
//
// This is the physically correct ICG implementation.
// The negative-level-sensitive latch holds the enable signal stable
// while the clock is HIGH, preventing glitches.
// The AND gate produces the gated clock.
//
// In a real ASIC flow, this would be mapped to sky130_fd_sc_hd__dlclkp.
///////////////////////////////////////////

module icg_cell (
  input  wire clk_in,
  input  wire enable,
  input  wire test_en,
  output wire clk_out
);

  reg en_latch;

  // Negative level-sensitive latch
  // Transparent when clk_in is LOW, holds when clk_in is HIGH
  always @(*) begin
    if (!clk_in)
      en_latch = enable | test_en;
  end

  // Gated clock output
  assign clk_out = clk_in & en_latch;

endmodule
