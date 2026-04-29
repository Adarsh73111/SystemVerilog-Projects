import flit_pkg::*;

module route_compute (
  input  logic [1:0] cur_x,
  input  logic [1:0] cur_y,
  input  logic [1:0] dst_x,
  input  logic [1:0] dst_y,
  output port_t      out_port
);

  always_comb begin
    // X-Axis Routing First
    if (dst_x > cur_x) begin
      out_port = EAST;
    end else if (dst_x < cur_x) begin
      out_port = WEST;
    // Y-Axis Routing Second (FIXED DIRECTIONS)
    end else if (dst_y > cur_y) begin
      out_port = SOUTH; // Increasing Y means going Down/South!
    end else if (dst_y < cur_y) begin
      out_port = NORTH; // Decreasing Y means going Up/North!
    // Arrived at destination router
    end else begin
      out_port = LOCAL; 
    end
  end

endmodule