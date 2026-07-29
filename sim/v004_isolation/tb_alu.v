///////////////////////////////////////////
// tb_alu.v — Testbench for ALU Operand Isolation
//
// Tests functional equivalence of baseline vs isolated ALU.
// Counts toggle events inside the ALU combinational logic to prove
// dynamic power reduction during inactive cycles.
///////////////////////////////////////////
`timescale 1ns/1ps

module tb_alu;

  parameter XLEN = 32;

  reg [XLEN-1:0] A, B;
  reg            SubArith;
  reg [2:0]      ALUSelect;
  reg            alu_active;

  wire [XLEN-1:0] ALUResult_base, Sum_base;
  wire [XLEN-1:0] ALUResult_iso, Sum_iso;

  // Baseline ALU (always sees toggling inputs)
  alu_wally #(.XLEN(XLEN)) dut_base (
    .A(A), .B(B), .SubArith(SubArith), .ALUSelect(ALUSelect),
    .ALUResult(ALUResult_base), .Sum(Sum_base)
  );

  // Isolated ALU (inputs clamped to 0 when inactive)
  alu_isolated #(.XLEN(XLEN)) dut_iso (
    .A(A), .B(B), .SubArith(SubArith), .ALUSelect(ALUSelect),
    .alu_active(alu_active),
    .ALUResult(ALUResult_iso), .Sum(Sum_iso)
  );

  integer i, errors;
  integer active_cycles, inactive_cycles;

  // We want to count toggles in the internal Sum output (representing adder logic)
  integer base_adder_toggles, iso_adder_toggles;
  reg [XLEN-1:0] prev_sum_base, prev_sum_iso;

  always @(Sum_base) begin
    if ($time > 0) base_adder_toggles = base_adder_toggles + 1;
  end

  always @(Sum_iso) begin
    if ($time > 0) iso_adder_toggles = iso_adder_toggles + 1;
  end

  initial begin
    $dumpfile("v004_isolation.vcd");
    $dumpvars(0, tb_alu);

    errors = 0;
    active_cycles = 0; inactive_cycles = 0;
    base_adder_toggles = 0; iso_adder_toggles = 0;
    prev_sum_base = 0; prev_sum_iso = 0;

    A = 0; B = 0; SubArith = 0; ALUSelect = 0; alu_active = 0;
    #10;

    $display("========================================");
    $display("v004 ALU OPERAND ISOLATION SIMULATION");
    $display("========================================");

    // TEST 1: Active compute cycles (ALU is used)
    $display("[TEST 1] Active Cycles: ADD, SUB, XOR, AND...");
    alu_active = 1;
    
    // Cycle 1: ADD (A + B)
    A = 32'h0000_1111; B = 32'h0000_2222; SubArith = 0; ALUSelect = 3'b000;
    #10;
    if (ALUResult_base !== ALUResult_iso || ALUResult_iso !== 32'h0000_3333) begin
      $display("  ERROR in ADD: base=%h iso=%h (want 00003333)", ALUResult_base, ALUResult_iso);
      errors = errors + 1;
    end
    active_cycles = active_cycles + 1;

    // Cycle 2: SUB (A - B)
    A = 32'h0000_5555; B = 32'h0000_1111; SubArith = 1; ALUSelect = 3'b000;
    #10;
    if (ALUResult_base !== ALUResult_iso || ALUResult_iso !== 32'h0000_4444) begin
      $display("  ERROR in SUB: base=%h iso=%h (want 00004444)", ALUResult_base, ALUResult_iso);
      errors = errors + 1;
    end
    active_cycles = active_cycles + 1;

    // Cycle 3: XOR
    A = 32'hFFFF_0000; B = 32'h0000_FFFF; SubArith = 0; ALUSelect = 3'b100;
    #10;
    if (ALUResult_base !== ALUResult_iso || ALUResult_iso !== 32'hFFFF_FFFF) begin
      $display("  ERROR in XOR: base=%h iso=%h (want FFFFFFFF)", ALUResult_base, ALUResult_iso);
      errors = errors + 1;
    end
    active_cycles = active_cycles + 1;

    // TEST 2: Inactive cycles (e.g. LOAD, STORE, BRANCH - ALU not needed)
    $display("[TEST 2] Inactive Cycles (Toggle suppression test)...");
    alu_active = 0;
    
    // We will spam random inputs simulating datapath noise while ALU is inactive
    for (i = 0; i < 50; i = i + 1) begin
      A = $random;
      B = $random;
      SubArith = $random % 2;
      ALUSelect = $random % 8;
      #10;
      // In isolated ALU, ALUResult_iso should be computed as if A=0, B=0.
      // E.g. 0 + 0 = 0.
      inactive_cycles = inactive_cycles + 1;
    end

    // TEST 3: Back to active compute
    $display("[TEST 3] Back to Active Compute...");
    alu_active = 1;
    A = 32'h1234_5678; B = 32'h8765_4321; SubArith = 0; ALUSelect = 3'b000;
    #10;
    if (ALUResult_base !== ALUResult_iso) begin
      $display("  ERROR in Wakeup ADD: base=%h iso=%h", ALUResult_base, ALUResult_iso);
      errors = errors + 1;
    end
    active_cycles = active_cycles + 1;

    $display("========================================");
    $display("v004 ISOLATION RESULTS");
    $display("========================================");
    $display("Active cycles:           %0d", active_cycles);
    $display("Inactive cycles:         %0d", inactive_cycles);
    $display("Errors (Equivalence):    %0d", errors);
    $display("----------------------------------------");
    $display("Combinational Toggle Count (Adder cloud):");
    $display("  Baseline ALU toggles: %0d", base_adder_toggles);
    $display("  Isolated ALU toggles: %0d", iso_adder_toggles);
    $display("  Toggle Reduction:     %0d%%", 
      ((base_adder_toggles - iso_adder_toggles) * 100) / base_adder_toggles);
    $display("========================================");
    
    if (errors == 0) $display("STATUS: PASS");
    else $display("STATUS: FAIL");

    $finish;
  end

endmodule
