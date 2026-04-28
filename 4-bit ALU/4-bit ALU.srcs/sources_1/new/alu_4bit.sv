module alu_4bit (
  input  logic [3:0] a,
  input  logic [3:0] b,
  input  logic [2:0] opcode,
  output logic [3:0] result,
  output logic       zero,
  output logic       carry
);

  logic [4:0] temp_result;

  always_comb begin
    carry = 1'b0;
    
    case (opcode)
      3'b000: temp_result = a + b;
      3'b001: temp_result = a - b;
      3'b010: temp_result = {1'b0, a & b};
      3'b011: temp_result = {1'b0, a | b};
      3'b100: temp_result = {1'b0, a ^ b};
      3'b101: temp_result = {1'b0, ~a};
      3'b110: temp_result = {1'b0, a << 1};
      3'b111: temp_result = {1'b0, a >> 1};
      default: temp_result = 5'b00000;
    endcase
    
    result = temp_result[3:0];
    carry  = temp_result[4];
    zero   = (result == 4'b0000);
  end

endmodule