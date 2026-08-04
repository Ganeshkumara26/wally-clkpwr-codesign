///////////////////////////////////////////
// tb_execute.v — Testbench for Execute Stage Integration
//
// Simulates a few RISC-V instructions passing through the execute
// stage. Checks if the ALU computes the correct result.
///////////////////////////////////////////
`timescale 1ns/1ps

module tb_execute;

  reg [31:0] instr;
  reg [31:0] pc;
  reg [31:0] reg_rs1;
  reg [31:0] reg_rs2;
  reg [31:0] imm;
  
  wire [31:0] alu_result;
  
  execute_stage #(.XLEN(32)) dut (
    .instr(instr),
    .pc(pc),
    .reg_rs1(reg_rs1),
    .reg_rs2(reg_rs2),
    .imm(imm),
    .alu_result(alu_result)
  );

  integer errors = 0;

  initial begin
    $dumpfile("v006_execute.vcd");
    $dumpvars(0, tb_execute);

    $display("========================================");
    $display("v006 EXECUTE STAGE SIMULATION");
    $display("========================================");

    // 1. ADD x3, x1, x2 (R-type)
    // opcode=0110011, funct3=000, funct7=0000000
    instr = 32'b0000000_00010_00001_000_00011_0110011;
    reg_rs1 = 32'd10;
    reg_rs2 = 32'd20;
    #10;
    $display("[ADD]   rs1=%0d, rs2=%0d -> ALU=%0d", reg_rs1, reg_rs2, alu_result);
    if (alu_result !== 32'd30) begin
      $display("  => ERROR: Expected 30!");
      errors = errors + 1;
    end

    // 2. ADDI x3, x1, 15 (I-type)
    // opcode=0010011
    instr = 32'b000000001111_00001_000_00011_0010011;
    reg_rs1 = 32'd100;
    imm = 32'd15;
    #10;
    $display("[ADDI]  rs1=%0d, imm=%0d -> ALU=%0d", reg_rs1, imm, alu_result);
    if (alu_result !== 32'd115) begin
      $display("  => ERROR: Expected 115!");
      errors = errors + 1;
    end

    // 3. AUIPC x4, 0x12345 (U-type)
    // opcode=0010111
    // pc + (imm20 << 12)
    instr = 32'b00010010001101000101_00100_0010111;
    pc = 32'h0000_1000;
    imm = 32'h1234_5000; // Immediate already shifted by decode stage
    #10;
    $display("[AUIPC] pc=%h, imm=%h -> ALU=%h", pc, imm, alu_result);
    if (alu_result !== (32'h0000_1000 + 32'h1234_5000)) begin
      $display("  => ERROR: Expected %h!", 32'h0000_1000 + 32'h1234_5000);
      errors = errors + 1;
    end

    $display("========================================");
    if (errors > 0) $display("STATUS: FAIL (%0d errors)", errors);
    else $display("STATUS: PASS");
    $display("========================================");

    $finish;
  end

endmodule
