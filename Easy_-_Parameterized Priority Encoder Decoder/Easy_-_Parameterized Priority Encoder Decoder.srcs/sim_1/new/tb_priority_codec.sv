import codec_pkg::*;

module tb_priority_codec;

  parameter N = 8;
  localparam OUT_W = $clog2(N);

  logic [N-1:0] req_in;
  logic [OUT_W-1:0] code_out;
  req_status_e status;
  logic [N-1:0] decoded_out;

  // 1. Instantiate Encoder
  priority_encoder #(N) dut_enc (
    .unencoded_in(req_in),
    .encoded_out(code_out),
    .status_out(status)
  );

  // 2. Instantiate Decoder
  priority_decoder #(N) dut_dec (
    .encoded_in(code_out),
    .status_in(status),
    .decoded_out(decoded_out)
  );

  // Verification Data Structures
  logic [OUT_W-1:0] golden_model [*]; // Associative array for expected results
  logic [N-1:0]     dyn_stimulus [];  // Dynamic array for directed tests

  initial begin
    // --- STEP 1: Build the Golden Model ---
    // Pre-calculate the expected priority output for all 256 possible inputs
    for (int i = 0; i < (1<<N); i++) begin
      logic [OUT_W-1:0] expected = 0;
      for (int j = N-1; j >= 0; j--) begin
         if (i[j]) begin
           expected = j;
           break;
         end
      end
      golden_model[i] = expected;
    end

    // --- STEP 2: Directed Testing ---
    // Allocate memory for 5 specific edge cases
    dyn_stimulus = new[5];
    dyn_stimulus[0] = 8'b0000_0000; // Zero-in (Expect NO_REQ)
    dyn_stimulus[1] = 8'b0000_0001; // LSB Priority
    dyn_stimulus[2] = 8'b1000_0000; // MSB Priority
    dyn_stimulus[3] = 8'b1010_1010; // Multiple requests (MSB should win)
    dyn_stimulus[4] = 8'b0001_1000; // Middle requests

    $display("\n--- STARTING DIRECTED TESTS ---");
    foreach(dyn_stimulus[i]) begin
      req_in = dyn_stimulus[i];
      #10;
      $display("Input: %b | Status: %s | Encoded Binary: %0d | Decoded One-Hot: %b", 
               req_in, status.name(), code_out, decoded_out);
    end

    // --- STEP 3: Exhaustive Testing ---
    $display("\n--- STARTING EXHAUSTIVE TESTS ---");
    for (int i = 0; i < (1<<N); i++) begin
      req_in = i;
      #5;
      
      // Check 1: Did the encoder output match the golden model?
      if (status == VALID_REQ && code_out !== golden_model[i]) begin
        $error("ENCODER FAIL at %b! Expected %0d, Got %0d", req_in, golden_model[i], code_out);
      end
      
      // Check 2: Zero-in edge case verification
      if (req_in == 0 && status !== NO_REQ) begin
        $error("ZERO-IN FAIL! Status should be NO_REQ");
      end
      
      // Check 3: Did the decoder correctly recreate the highest priority bit?
      if (status == VALID_REQ && decoded_out[code_out] !== 1'b1) begin
         $error("DECODER FAIL at %b! One-hot mismatch.", req_in);
      end
    end

    $display("All exhaustive tests completed successfully. Check waveforms!");
    #20 $finish;
  end

endmodule