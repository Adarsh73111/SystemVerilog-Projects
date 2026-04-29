import flit_pkg::*;

module crossbar (
  input  logic [4:0][FLIT_WIDTH-1:0] in_flits,
  
  // grant_matrix[OUTPUT_PORT][INPUT_PORT]
  input  logic [4:0][4:0]            grant_matrix, 
  
  output logic [4:0][FLIT_WIDTH-1:0] out_flits
);

  always_comb begin
    for (int out_p = 0; out_p < 5; out_p++) begin
      out_flits[out_p] = '0; // Default to zero if no one is routing here
      
      for (int in_p = 0; in_p < 5; in_p++) begin
        if (grant_matrix[out_p][in_p]) begin
          out_flits[out_p] = in_flits[in_p];
        end
      end
    end
  end

endmodule