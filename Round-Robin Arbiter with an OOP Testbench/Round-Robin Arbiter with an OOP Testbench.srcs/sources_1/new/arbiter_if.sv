interface arbiter_if (
  input logic clk,
  input logic rst_n
);
  logic [3:0] req;
  logic [3:0] gnt;

  // Driver modport
  modport drv (
    input  clk, rst_n, gnt,
    output req
  );

  // DUT modport
  modport dut (
    input  clk, rst_n, req,
    output gnt
  );
endinterface