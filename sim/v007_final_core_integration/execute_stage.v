///////////////////////////////////////////
// execute_stage.v — Simple Instruction Decode and Execute
//
// This module wraps the isolated ALU. It decodes the opcode
// to generate the `alu_active` isolation signal, and multiplexes
// the correct operands into the ALU.
///////////////////////////////////////////

module execute_stage #(
  parameter XLEN = 32
) (
  input  wire [31:0]     instr,
  input  wire [XLEN-1:0] pc,
  input  wire [XLEN-1:0] reg_rs1,
  input  wire [XLEN-1:0] reg_rs2,
  input  wire [XLEN-1:0] imm,
  
  output wire [XLEN-1:0] alu_result
);

  wire [6:0] opcode = instr[6:0];
  
  // Basic RISC-V Opcodes
  localparam OP_RTYPE  = 7'b0110011; // ADD, SUB, etc.
  localparam OP_ITYPE  = 7'b0010011; // ADDI, etc.
  localparam OP_LOAD   = 7'b0000011; // LW
  localparam OP_STORE  = 7'b0100011; // SW
  localparam OP_BRANCH = 7'b1100011; // BEQ
  localparam OP_AUIPC  = 7'b0010111; // AUIPC
  localparam OP_LUI    = 7'b0110111; // LUI

  // Undergrad logic: "ALU is used for arithmetic, loads/stores (address), and branches."
  wire is_rtype  = (opcode == OP_RTYPE);
  wire is_itype  = (opcode == OP_ITYPE);
  wire is_load   = (opcode == OP_LOAD);
  wire is_store  = (opcode == OP_STORE);
  wire is_branch = (opcode == OP_BRANCH);
  wire is_auipc  = (opcode == OP_AUIPC);
  wire is_lui    = (opcode == OP_LUI);
  
  wire alu_active = is_rtype | is_itype | is_load | is_store | is_branch | is_auipc | is_lui;

  // Operand Muxing
  wire [XLEN-1:0] operand_a;
  wire [XLEN-1:0] operand_b;
  
  // AUIPC uses PC as operand A. Everything else uses RS1.
  assign operand_a = (opcode == OP_AUIPC) ? pc : reg_rs1;
  
  // R-type uses RS2 as operand B. Everything else uses Immediate.
  assign operand_b = (opcode == OP_RTYPE || opcode == OP_BRANCH) ? reg_rs2 : imm;

  // ALU Control
  wire sub_arith = (is_rtype && instr[30]); // SUB if bit 30 is set
  
  // Use funct3 for R-type/I-type, otherwise default to ADD (3'b000) for address calculations
  wire [2:0] funct3 = instr[14:12];
  wire [2:0] alu_select = (is_rtype | is_itype) ? funct3 : 3'b000;

  // Instantiate Isolated ALU
  alu_isolated #(.XLEN(XLEN)) u_alu (
    .A(operand_a),
    .B(operand_b),
    .SubArith(sub_arith),
    .ALUSelect(alu_select),
    .alu_active(alu_active),
    .ALUResult(alu_result),
    .Sum() // Ignored
  );

endmodule
