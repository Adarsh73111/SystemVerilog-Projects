module tb_alu_4bit;

  logic [3:0] a;
  logic [3:0] b;
  logic [2:0] opcode;
  logic [3:0] result;
  logic       zero;
  logic       carry;

  alu_4bit dut (
    .a(a),
    .b(b),
    .opcode(opcode),
    .result(result),
    .zero(zero),
    .carry(carry)
  );

  initial begin
    a = 4'b0101; b = 4'b0011; opcode = 3'b000; #10;
    
    a = 4'b1000; b = 4'b0010; opcode = 3'b001; #10;
    
    a = 4'b1100; b = 4'b1010; opcode = 3'b010; #10;
    
    a = 4'b1100; b = 4'b1010; opcode = 3'b011; #10;
    
    a = 4'b1111; b = 4'b0101; opcode = 3'b100; #10;
    
    a = 4'b1010; b = 4'b0000; opcode = 3'b101; #10;
    
    a = 4'b0111; b = 4'b0000; opcode = 3'b110; #10;
    
    a = 4'b1110; b = 4'b0000; opcode = 3'b111; #10;
    
    a = 4'b1111; b = 4'b0001; opcode = 3'b000; #10;
    
    $finish;
  end

endmodule