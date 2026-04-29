module packet_gatekeeper (
  input  logic clk,
  input  logic rst_n,

  input  logic [7:0] s_axis_tdata,
  input  logic       s_axis_tvalid,
  input  logic       s_axis_tlast,
  output logic       s_axis_tready,

  output logic [7:0] m_axis_tdata,
  output logic       m_axis_tvalid,
  output logic       m_axis_tlast,
  input  logic       m_axis_tready,

  output logic       dropped_flag
);

  logic [7:0] buffer [63:0];
  logic [5:0] wr_ptr;
  logic [5:0] rd_ptr;
  logic [5:0] pkt_len;

  typedef enum logic [1:0] {IDLE, RECV, FORWARD} state_t;
  state_t state;

  logic rule_pass;

  assign s_axis_tready = (state == IDLE) || (state == RECV);
  assign m_axis_tvalid = (state == FORWARD);
  assign m_axis_tdata  = buffer[rd_ptr];
  assign m_axis_tlast  = (state == FORWARD) && (rd_ptr == pkt_len - 1);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state        <= IDLE;
      wr_ptr       <= 0;
      rd_ptr       <= 0;
      pkt_len      <= 0;
      dropped_flag <= 0;
    end else begin
      dropped_flag <= 0;

      case (state)
        IDLE: begin
          wr_ptr <= 0;
          rd_ptr <= 0;
          if (s_axis_tvalid && s_axis_tready) begin
            buffer[wr_ptr] <= s_axis_tdata;
            wr_ptr <= wr_ptr + 1;
            if (s_axis_tlast) begin
              pkt_len   <= wr_ptr + 1;
              rule_pass <= (s_axis_tdata == 8'h5A); 
              if (rule_pass) state <= FORWARD;
              else begin
                dropped_flag <= 1;
                state <= IDLE;
              end
            end else begin
              state <= RECV;
            end
          end
        end

        RECV: begin
          if (s_axis_tvalid && s_axis_tready) begin
            buffer[wr_ptr] <= s_axis_tdata;
            wr_ptr <= wr_ptr + 1;

            if (s_axis_tlast) begin
              pkt_len   <= wr_ptr + 1;
              rule_pass = (buffer[0] == 8'h5A) && (buffer[1] != 8'h00) && (buffer[1] != 8'hFF);
              
              if (rule_pass) begin
                state <= FORWARD;
              end else begin
                dropped_flag <= 1;
                state <= IDLE;
              end
            end
          end
        end

        FORWARD: begin
          if (m_axis_tready && m_axis_tvalid) begin
            if (m_axis_tlast) begin
              state <= IDLE;
            end else begin
              rd_ptr <= rd_ptr + 1;
            end
          end
        end
      endcase
    end
  end
endmodule