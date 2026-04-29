module arbiter (
  input  logic       clk,
  input  logic       rst_n,
  input  logic [4:0] req,   // 5 input requests
  output logic [4:0] grant  // 1-hot grant output
);

  logic [4:0] priority_ptr;
  logic [4:0] grant_comb;

  // Double-width trick for easy round-robin wrap-around math
  logic [9:0] double_req;
  logic [9:0] double_grant;

  assign double_req = {req, req};
  
  // Find the first request starting from the priority pointer
  assign double_grant = double_req & ~(double_req - priority_ptr);
  
  // Collapse back to 5 bits
  assign grant_comb = double_grant[4:0] | double_grant[9:5];

  always_comb begin
    if (req == 5'b0) begin
      grant = 5'b0;
    end else begin
      grant = grant_comb;
    end
  end

  // Advance the priority pointer
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      priority_ptr <= 5'b00001;
    end else if (grant != 5'b0) begin
      // Rotate left by 1 based on the current grant
      priority_ptr <= {grant[3:0], grant[4]};
    end
  end

endmodule