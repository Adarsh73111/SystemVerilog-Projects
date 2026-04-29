package flit_pkg;

  // Network Dimensions (3x3)
  localparam MESH_X = 3;
  localparam MESH_Y = 3;
  localparam FLIT_WIDTH = 32;

  // Flit Types for Wormhole Routing
  typedef enum logic [1:0] {
    HEADER = 2'b00,
    BODY   = 2'b01,
    TAIL   = 2'b10
  } flit_type_t;

  // Header Flit Payload Structure
  // Packed into 32 bits: [31:16 Reserved] [15:8 Pkt ID] [7:6 Src Y] [5:4 Src X] [3:2 Dst Y] [1:0 Dst X]
  typedef struct packed {
    logic [15:0] reserved;
    logic [7:0]  pkt_id;
    logic [1:0]  src_y;
    logic [1:0]  src_x;
    logic [1:0]  dst_y;
    logic [1:0]  dst_x;
  } header_data_t;

  // Router Port Mapping
  typedef enum logic [2:0] {
    LOCAL = 3'd0,
    NORTH = 3'd1,
    SOUTH = 3'd2,
    EAST  = 3'd3,
    WEST  = 3'd4
  } port_t;

endpackage