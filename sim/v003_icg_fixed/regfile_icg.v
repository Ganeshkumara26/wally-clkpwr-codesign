///////////////////////////////////////////
// regfile_icg.v — v003: ICG-gated regfile with fixed latch polarity
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

  wire rf_clk_en = we3 | reset;
  wire gated_clk;

  icg_cell_neg u_icg (
    .clk_in  (clk),
    .enable  (rf_clk_en),
    .test_en (1'b0),
    .clk_out (gated_clk)
  );

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
