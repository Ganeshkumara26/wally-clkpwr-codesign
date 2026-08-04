///////////////////////////////////////////
// alu_wally.v — Simplified Wally ALU for operand isolation testing
//
// Faithfully reproduces the core operations from cvw/src/ieu/alu.sv:
//   - ADD/SUB (ALUSelect=000)
//   - SLL/SRL/SRA (ALUSelect=001)
//   - SLT (ALUSelect=010)
//   - SLTU (ALUSelect=011)
//   - XOR (ALUSelect=100)
//   - OR (ALUSelect=110)
//   - AND (ALUSelect=111)
//
// Omits BMU extensions (ZBA/ZBB/ZBC/ZBS) since they're irrelevant
// to demonstrating operand isolation.
///////////////////////////////////////////

module alu_wally #(
  parameter XLEN = 32
) (
  input  wire [XLEN-1:0] A, B,
  input  wire             SubArith,   // 1 = subtract / arithmetic shift
  input  wire [2:0]       ALUSelect,  // Operation select
  output reg  [XLEN-1:0]  ALUResult,
  output wire [XLEN-1:0]  Sum
);

  wire [XLEN-1:0] CondInvB = SubArith ? ~B : B;
  wire             Carry;

  // Adder
  assign {Carry, Sum} = A + CondInvB + {{(XLEN-1){1'b0}}, SubArith};

  // Shift
  wire [XLEN-1:0] ShiftLeft  = A << B[4:0];
  wire [XLEN-1:0] ShiftRight = SubArith ?
    ($signed(A) >>> B[4:0]) : (A >> B[4:0]);

  // Comparisons
  wire Neg  = Sum[XLEN-1];
  wire Asign = A[XLEN-1];
  wire Bsign = B[XLEN-1];
  wire LT  = (Asign & ~Bsign) | (Asign & Neg) | (~Bsign & Neg);
  wire LTU = ~Carry;

  // Result mux
  always @(*) begin
    case (ALUSelect)
      3'b000: ALUResult = Sum;
      3'b001: ALUResult = ALUSelect[2] ? ShiftRight : ShiftLeft;  // simplified
      3'b010: ALUResult = {{(XLEN-1){1'b0}}, LT};
      3'b011: ALUResult = {{(XLEN-1){1'b0}}, LTU};
      3'b100: ALUResult = A ^ CondInvB;
      3'b101: ALUResult = ShiftRight;
      3'b110: ALUResult = A | CondInvB;
      3'b111: ALUResult = A & CondInvB;
    endcase
  end

endmodule
