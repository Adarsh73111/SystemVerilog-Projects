module sync_fifo #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH = 16
)(
  fifo_if.dut vif
);

  localparam PTR_WIDTH = $clog2(DEPTH);

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
  logic [PTR_WIDTH:0] wr_ptr;
  logic [PTR_WIDTH:0] rd_ptr;

  assign vif.full  = (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]) && 
                     (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]);
  
  assign vif.empty = (wr_ptr == rd_ptr);

  always_ff @(posedge vif.clk or negedge vif.rst_n) begin
    if (!vif.rst_n) begin
      wr_ptr <= 0;
    end else if (vif.wr_en && !vif.full) begin
      mem[wr_ptr[PTR_WIDTH-1:0]] <= vif.data_in;
      wr_ptr <= wr_ptr + 1;
    end
  end

  always_ff @(posedge vif.clk or negedge vif.rst_n) begin
    if (!vif.rst_n) begin
      rd_ptr <= 0;
      vif.data_out <= 0;
    end else if (vif.rd_en && !vif.empty) begin
      vif.data_out <= mem[rd_ptr[PTR_WIDTH-1:0]];
      rd_ptr <= rd_ptr + 1;
    end
  end

endmodule