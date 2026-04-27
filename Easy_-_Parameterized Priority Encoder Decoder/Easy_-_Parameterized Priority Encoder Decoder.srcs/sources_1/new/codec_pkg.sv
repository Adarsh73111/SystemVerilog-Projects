package codec_pkg;

  // Enum to define the validity/priority state of the input
  typedef enum logic [1:0] {
    NO_REQ    = 2'b00, // Zero-in edge case
    VALID_REQ = 2'b01  // Valid request present
  } req_status_e;

  // Typedef for a generic data word just to demonstrate package usage
  typedef logic [31:0] dword_t;

endpackage