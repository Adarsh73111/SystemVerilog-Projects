import codec_pkg::*;

module priority_decoder #(
  parameter N = 8
)(
  input  logic [$clog2(N)-1:0] encoded_in,
  input  req_status_e status_in,
  output logic [N-1:0] decoded_out
);

  always_comb begin
    decoded_out = '0; // Default zero-out

    // Only assert a bit if the encoder told us the input was valid
    if (status_in == VALID_REQ) begin
      decoded_out[encoded_in] = 1'b1; 
    end
  end

endmodule