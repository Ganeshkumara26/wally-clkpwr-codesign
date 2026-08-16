///////////////////////////////////////////
// core_integration.v — Final Core Top Level for Power Benchmarking
//
// Wraps both a Baseline Core and an Optimized Core.
// Allows us to run identical instruction streams into both
// and count the toggle differences in real-time.
///////////////////////////////////////////

module core_baseline #(
  parameter XLEN = 32
) (
  input  wire             clk,
  input  wire             reset,
  input  wire [31:0]      instr,
  input  wire [XLEN-1:0]  pc,
  input  wire [XLEN-1:0]  imm,
  input  wire             we3,
  input  wire [4:0]       rd_addr
);

  wire [XLEN-1:0] rs1_data, rs2_data;
  wire [XLEN-1:0] alu_result;
  
  // Baseline Regfile (Always toggles 992 FFs)
  regfile #(.XLEN(XLEN)) u_regfile (
    .clk(clk), .reset(reset), .we3(we3),
    .a1(instr[19:15]), .a2(instr[24:20]), .a3(rd_addr),
    .wd3(alu_result),
    .rd1(rs1_data), .rd2(rs2_data)
  );
  
  // Baseline Execute Stage (Naive ALU, always computes)
  wire sub_arith = (instr[6:0] == 7'b0110011 && instr[30]);
  wire [XLEN-1:0] op_a = (instr[6:0] == 7'b0010111) ? pc : rs1_data;
  wire [XLEN-1:0] op_b = (instr[6:0] == 7'b0110011 || instr[6:0] == 7'b1100011) ? rs2_data : imm;
  
  alu_wally #(.XLEN(XLEN)) u_alu (
    .A(op_a), .B(op_b), .SubArith(sub_arith), .ALUSelect(3'b000),
    .ALUResult(alu_result), .Sum()
  );

endmodule


module core_optimized #(
  parameter XLEN = 32
) (
  input  wire             clk,
  input  wire             reset,
  input  wire [31:0]      instr,
  input  wire [XLEN-1:0]  pc,
  input  wire [XLEN-1:0]  imm,
  input  wire             we3,
  input  wire [4:0]       rd_addr
);

  wire [XLEN-1:0] rs1_data, rs2_data;
  wire [XLEN-1:0] alu_result;
  
  // Optimized Regfile (ICG clock gating)
  regfile_icg #(.XLEN(XLEN)) u_regfile (
    .clk(clk), .reset(reset), .we3(we3),
    .a1(instr[19:15]), .a2(instr[24:20]), .a3(rd_addr),
    .wd3(alu_result),
    .rd1(rs1_data), .rd2(rs2_data)
  );
  
  // Optimized Execute Stage (AND-clamped operand isolation)
  execute_stage #(.XLEN(XLEN)) u_execute (
    .instr(instr), .pc(pc),
    .reg_rs1(rs1_data), .reg_rs2(rs2_data), .imm(imm),
    .alu_result(alu_result)
  );

endmodule
