import flit_pkg::*;

module noc_3x3 (
  input  logic clk,
  input  logic rst_n,

  // Local Ports exposed to Processing Elements (PEs)
  input  logic [2:0][2:0][FLIT_WIDTH-1:0] pe_in_flit,
  input  logic [2:0][2:0]                 pe_in_write_en,
  output logic [2:0][2:0][2:0]            pe_out_credits,

  output logic [2:0][2:0][FLIT_WIDTH-1:0] pe_out_flit,
  output logic [2:0][2:0]                 pe_out_write_en,
  input  logic [2:0][2:0][2:0]            pe_in_credits
);

  // Internal wires between routers
  // Horizontal links (East-West)
  logic [1:0][2:0][FLIT_WIDTH-1:0] ew_flit, we_flit;
  logic [1:0][2:0]                 ew_write, we_write;
  logic [1:0][2:0][2:0]            ew_credits, we_credits;

  // Vertical links (North-South)
  logic [2:0][1:0][FLIT_WIDTH-1:0] ns_flit, sn_flit;
  logic [2:0][1:0]                 ns_write, sn_write;
  logic [2:0][1:0][2:0]            ns_credits, sn_credits;

  genvar x, y;
  generate
    for (x = 0; x < 3; x++) begin : COL
      for (y = 0; y < 3; y++) begin : ROW

        // Port arrays for this specific router
        logic [4:0][FLIT_WIDTH-1:0] r_in_flit;
        logic [4:0]                 r_in_write;
        logic [4:0][2:0]            r_out_credits;

        logic [4:0][FLIT_WIDTH-1:0] r_out_flit;
        logic [4:0]                 r_out_write;
        logic [4:0][2:0]            r_in_credits;

        // --- LOCAL PORT WIRING ---
        assign r_in_flit[LOCAL]    = pe_in_flit[x][y];
        assign r_in_write[LOCAL]   = pe_in_write_en[x][y];
        assign pe_out_credits[x][y]= r_out_credits[LOCAL];

        assign pe_out_flit[x][y]   = r_out_flit[LOCAL];
        assign pe_out_write_en[x][y] = r_out_write[LOCAL];
        assign r_in_credits[LOCAL] = pe_in_credits[x][y];

        // --- EAST PORT WIRING ---
        if (x < 2) begin
          assign r_in_flit[EAST]    = we_flit[x][y];
          assign r_in_write[EAST]   = we_write[x][y];
          assign ew_credits[x][y]   = r_out_credits[EAST];

          assign ew_flit[x][y]      = r_out_flit[EAST];
          assign ew_write[x][y]     = r_out_write[EAST];
          assign r_in_credits[EAST] = we_credits[x][y];
        end else begin
          assign r_in_flit[EAST]    = '0;
          assign r_in_write[EAST]   = 1'b0;
          assign r_in_credits[EAST] = '0;
        end

        // --- WEST PORT WIRING ---
        if (x > 0) begin
          assign r_in_flit[WEST]    = ew_flit[x-1][y];
          assign r_in_write[WEST]   = ew_write[x-1][y];
          assign we_credits[x-1][y] = r_out_credits[WEST];

          assign we_flit[x-1][y]      = r_out_flit[WEST];
          assign we_write[x-1][y]     = r_out_write[WEST];
          assign r_in_credits[WEST] = ew_credits[x-1][y];
        end else begin
          assign r_in_flit[WEST]    = '0;
          assign r_in_write[WEST]   = 1'b0;
          assign r_in_credits[WEST] = '0;
        end

        // --- SOUTH PORT WIRING ---
        if (y < 2) begin
          assign r_in_flit[SOUTH]    = ns_flit[x][y];
          assign r_in_write[SOUTH]   = ns_write[x][y];
          assign sn_credits[x][y]    = r_out_credits[SOUTH];

          assign sn_flit[x][y]       = r_out_flit[SOUTH];
          assign sn_write[x][y]      = r_out_write[SOUTH];
          assign r_in_credits[SOUTH] = ns_credits[x][y];
        end else begin
          assign r_in_flit[SOUTH]    = '0;
          assign r_in_write[SOUTH]   = 1'b0;
          assign r_in_credits[SOUTH] = '0;
        end

        // --- NORTH PORT WIRING ---
        if (y > 0) begin
          assign r_in_flit[NORTH]    = sn_flit[x][y-1];
          assign r_in_write[NORTH]   = sn_write[x][y-1];
          assign ns_credits[x][y-1]  = r_out_credits[NORTH];

          assign ns_flit[x][y-1]      = r_out_flit[NORTH];
          assign ns_write[x][y-1]     = r_out_write[NORTH];
          assign r_in_credits[NORTH] = sn_credits[x][y-1];
        end else begin
          assign r_in_flit[NORTH]    = '0;
          assign r_in_write[NORTH]   = 1'b0;
          assign r_in_credits[NORTH] = '0;
        end

        // Instantiate Router
        router #(
          .MY_X_COORD(x),
          .MY_Y_COORD(y)
        ) node (
          .clk(clk),
          .rst_n(rst_n),
          .in_flit(r_in_flit),
          .in_write_en(r_in_write),
          .out_credits(r_out_credits),
          .out_flit(r_out_flit),
          .out_write_en(r_out_write),
          .in_credits(r_in_credits)
        );

      end
    end
  endgenerate

endmodule