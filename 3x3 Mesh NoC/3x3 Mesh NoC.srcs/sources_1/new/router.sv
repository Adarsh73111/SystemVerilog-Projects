import flit_pkg::*;

module router #(
  parameter logic [1:0] MY_X_COORD = 0,
  parameter logic [1:0] MY_Y_COORD = 0
)(
  input  logic clk,
  input  logic rst_n,

  // 5 Input Ports (Data + Write Enable)
  input  logic [4:0][FLIT_WIDTH-1:0] in_flit,
  input  logic [4:0]                 in_write_en,
  output logic [4:0][2:0]            out_credits, // Credits sent BACK upstream

  // 5 Output Ports (Data + Write Enable)
  output logic [4:0][FLIT_WIDTH-1:0] out_flit,
  output logic [4:0]                 out_write_en,
  input  logic [4:0][2:0]            in_credits   // Credits received from downstream
);

  // --- Internal Signals ---
  logic [4:0][FLIT_WIDTH-1:0] buf_data_out;
  logic [4:0]                 buf_empty;
  logic [4:0]                 buf_read_en;
  
  // Routing & State
  typedef enum logic {S_IDLE = 1'b0, S_ACTIVE = 1'b1} port_state_t;
  port_state_t [4:0] port_state;
  port_t       [4:0] locked_out_port;
  
  // Packed 2D arrays for easy mapping to sub-modules
  logic [4:0][4:0] arb_req;   // arb_req[output_port][input_port]
  logic [4:0][4:0] arb_grant; // arb_grant[output_port][input_port]
  
  port_t [4:0] rcu_out_port; // Computed routes
  
  // --- 1. Input Buffers & Route Compute Units ---
  genvar i;
  generate
    for (i = 0; i < 5; i++) begin : IN_PORTS
      input_buffer #(.DEPTH(4)) ibuf (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(in_write_en[i]),
        .read_en(buf_read_en[i]),
        .data_in(in_flit[i]),
        .data_out(buf_data_out[i]),
        .empty(buf_empty[i]),
        .full(), // Flow control prevents full
        .credits_out(out_credits[i])
      );
      
      // Cast the top of the buffer to the header struct to read XY coords
      header_data_t hdr;
      assign hdr = buf_data_out[i];
      
      route_compute rcu (
        .cur_x(MY_X_COORD),
        .cur_y(MY_Y_COORD),
        .dst_x(hdr.dst_x),
        .dst_y(hdr.dst_y),
        .out_port(rcu_out_port[i])
      );
    end
  endgenerate

  // --- 2. Input Port State Machines (Wormhole Locking) ---
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int p = 0; p < 5; p++) begin
        port_state[p]      <= S_IDLE;
        locked_out_port[p] <= LOCAL;
      end
    end else begin
      for (int p = 0; p < 5; p++) begin
        if (port_state[p] == S_IDLE) begin
          if (!buf_empty[p]) begin
            // Top 2 bits [31:30] of flit hold the flit type (00=HEADER)
            if (buf_data_out[p][31:30] == HEADER) begin
              port_state[p]      <= S_ACTIVE;
              locked_out_port[p] <= rcu_out_port[p];
            end
          end
        end else if (port_state[p] == S_ACTIVE) begin
          // Only release the lock if the TAIL flit was successfully read this cycle
          if (buf_read_en[p] && buf_data_out[p][31:30] == TAIL) begin
            port_state[p] <= S_IDLE;
          end
        end
      end
    end
  end

  // --- 3. Arbiter Request Matrix ---
  always_comb begin
    arb_req = '0; // Initialize all requests to 0
    
    for (int in_p = 0; in_p < 5; in_p++) begin
      if (!buf_empty[in_p]) begin
        if (port_state[in_p] == S_ACTIVE) begin
          // Already locked, keep requesting the same output port
          arb_req[ locked_out_port[in_p] ][in_p] = 1'b1;
        end else if (port_state[in_p] == S_IDLE && buf_data_out[in_p][31:30] == HEADER) begin
          // New packet arriving, request the newly computed route
          arb_req[ rcu_out_port[in_p] ][in_p] = 1'b1;
        end
      end
    end
  end

  // --- 4. Arbiters (One for each of the 5 output ports) ---
  generate
    for (i = 0; i < 5; i++) begin : OUT_PORTS
      arbiter out_arb (
        .clk(clk),
        .rst_n(rst_n),
        .req(arb_req[i]),
        .grant(arb_grant[i])
      );
    end
  endgenerate

  // --- 5. Crossbar and Flow Control (Credits) ---
  always_comb begin
    buf_read_en  = '0;
    out_write_en = '0;
    
    for (int in_p = 0; in_p < 5; in_p++) begin
      for (int out_p = 0; out_p < 5; out_p++) begin
        if (arb_grant[out_p][in_p]) begin
          // We won the arbiter! Do we have downstream credits to send?
          if (in_credits[out_p] > 0) begin
            buf_read_en[in_p]   = 1'b1;
            out_write_en[out_p] = 1'b1;
          end
        end
      end
    end
  end
  
  // Instantiate the Crossbar
  crossbar xbar (
    .in_flits(buf_data_out),
    .grant_matrix(arb_grant),
    .out_flits(out_flit)
  );

endmodule