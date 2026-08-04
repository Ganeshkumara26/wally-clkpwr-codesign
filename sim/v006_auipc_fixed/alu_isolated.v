///////////////////////////////////////////
// alu_isolated.v — ALU with AND-clamping operand isolation
//
// When alu_active=0, inputs A and B are clamped to zero.
// This prevents random toggle propagation through the combinational
// cloud (adder, shifter, comparators) when the ALU result is unused
// (e.g., during LOAD, STORE, NOP, BRANCH instructions).
///////////////////////////////////////////

module alu_isolated #(
  parameter XLEN = 32
) (
  input  wire [XLEN-1:0] A, B,
  input  wire             SubArith,
  input  wire [2:0]       ALUSelect,
  input  wire             alu_active,  // NEW: 1 when ALU result is needed
  output wire [XLEN-1:0]  ALUResult,
  output wire [XLEN-1:0]  Sum
);

  // Operand isolation: AND-clamp inputs when not active
  wire [XLEN-1:0] A_clamped = A & {XLEN{alu_active}};
  wire [XLEN-1:0] B_clamped = B & {XLEN{alu_active}};

  // Instantiate the actual ALU with clamped inputs
  alu_wally #(.XLEN(XLEN)) core_alu (
    .A(A_clamped),
    .B(B_clamped),
    .SubArith(SubArith & alu_active),
    .ALUSelect(ALUSelect),
    .ALUResult(ALUResult),
    .Sum(Sum)
  );

endmodule
