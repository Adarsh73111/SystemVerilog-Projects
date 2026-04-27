interface fifo_if #(parameter DATA_WIDTH = 8, parameter DEPTH = 16) (
  input logic clk, 
  input logic rst_n
);
  
  logic [DATA_WIDTH-1:0] data_in;
  logic wr_en;
  logic rd_en;
  logic [DATA_WIDTH-1:0] data_out;
  logic full;
  logic empty;

  modport dut (
    input  clk, rst_n, data_in, wr_en, rd_en,
    output data_out, full, empty
  );

  modport tb (
    output data_in, wr_en, rd_en,
    input  clk, rst_n, data_out, full, empty
  );

endinterface