interface alu_if(input logic clk, rst_n);
  logic       valid_in;
  logic [7:0] id_in;
  logic [7:0] a;
  logic [7:0] b;
  logic [2:0] op;
  
  logic       valid_out;
  logic [7:0] id_out;
  logic [15:0] result;
endinterface

module pipelined_alu (
  alu_if vif
);

  logic       s1_v;
  logic [7:0] s1_id;
  logic [7:0] s1_a;
  logic [7:0] s1_b;
  logic [2:0] s1_op;

  logic        s2_v;
  logic [7:0]  s2_id;
  logic [15:0] s2_res;

  always_ff @(posedge vif.clk or negedge vif.rst_n) begin
    if (!vif.rst_n) begin
      s1_v <= 0;
      s1_id <= 0;
      s1_a <= 0;
      s1_b <= 0;
      s1_op <= 0;
    end else begin
      s1_v  <= vif.valid_in;
      s1_id <= vif.id_in;
      s1_a  <= vif.a;
      s1_b  <= vif.b;
      s1_op <= vif.op;
    end
  end

  always_ff @(posedge vif.clk or negedge vif.rst_n) begin
    if (!vif.rst_n) begin
      s2_v   <= 0;
      s2_id  <= 0;
      s2_res <= 0;
    end else begin
      s2_v  <= s1_v;
      s2_id <= s1_id;
      if (s1_v) begin
        case (s1_op)
          3'b000: s2_res <= s1_a + s1_b;
          3'b001: s2_res <= s1_a - s1_b;
          3'b010: s2_res <= s1_a * s1_b;
          3'b011: s2_res <= {8'b0, s1_a & s1_b};
          3'b100: s2_res <= {8'b0, s1_a | s1_b};
          3'b101: s2_res <= {8'b0, s1_a ^ s1_b};
          default: s2_res <= 0;
        endcase
      end
    end
  end

  always_ff @(posedge vif.clk or negedge vif.rst_n) begin
    if (!vif.rst_n) begin
      vif.valid_out <= 0;
      vif.id_out    <= 0;
      vif.result    <= 0;
    end else begin
      vif.valid_out <= s2_v;
      vif.id_out    <= s2_id;
      vif.result    <= s2_res;
    end
  end

endmodule