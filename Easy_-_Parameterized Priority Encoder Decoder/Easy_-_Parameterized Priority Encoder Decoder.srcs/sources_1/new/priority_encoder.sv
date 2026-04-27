import codec_pkg::*; // Import the package

module priority_encoder #(
  parameter N = 8
)(
  input  logic [N-1:0] unencoded_in,
  output logic [$clog2(N)-1:0] encoded_out,
  output req_status_e status_out
);

  // Parameterized struct defined locally to utilize 'N'
  typedef struct packed {
    req_status_e          status;
    logic [$clog2(N)-1:0] code;
  } encoder_result_s;

  encoder_result_s result;

  always_comb begin
    // Default assignments (Handles the zero-in-zero-out edge case)
    result.status = NO_REQ;
    result.code   = '0;

    // Procedural unrolling: Start from MSB down to LSB. 
    // Highest index gets highest priority.
    for (int i = N-1; i >= 0; i--) begin
      if (unencoded_in[i]) begin
        result.status = VALID_REQ;
        result.code   = i;
        break; // Stop looking once the highest priority bit is found
      end
    end

    // Assign struct fields to output ports
    encoded_out = result.code;
    status_out  = result.status;
  end

endmodule