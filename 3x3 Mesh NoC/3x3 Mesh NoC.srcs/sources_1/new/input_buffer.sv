import flit_pkg::*;

module input_buffer #(
  parameter DEPTH = 4
)(
  input  logic                  clk,
  input  logic                  rst_n,
  input  logic                  write_en,
  input  logic                  read_en,
  input  logic [FLIT_WIDTH-1:0] data_in,
  
  output logic [FLIT_WIDTH-1:0] data_out,
  output logic                  empty,
  output logic                  full,
  output logic [2:0]            credits_out
);

  logic [FLIT_WIDTH-1:0]    mem [DEPTH-1:0];
  logic [$clog2(DEPTH)-1:0] wr_ptr;
  logic [$clog2(DEPTH)-1:0] rd_ptr;
  logic [$clog2(DEPTH):0]   count;

  assign empty       = (count == 0);
  assign full        = (count == DEPTH);
  assign credits_out = DEPTH - count;
  assign data_out    = mem[rd_ptr];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      count  <= 0;
    end else begin
      case ({write_en && !full, read_en && !empty})
        2'b10: begin // Write only
          mem[wr_ptr] <= data_in;
          wr_ptr      <= wr_ptr + 1;
          count       <= count + 1;
        end
        2'b01: begin // Read only
          rd_ptr <= rd_ptr + 1;
          count  <= count - 1;
        end
        2'b11: begin // Write and Read simultaneously
          mem[wr_ptr] <= data_in;
          wr_ptr      <= wr_ptr + 1;
          rd_ptr      <= rd_ptr + 1;
        end
      endcase
    end
  end

endmodule