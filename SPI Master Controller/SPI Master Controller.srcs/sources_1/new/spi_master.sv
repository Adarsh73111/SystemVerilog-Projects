module spi_master (
  input  logic clk,
  input  logic rst_n,
  input  logic start,
  input  logic cpol,
  input  logic cpha,
  input  logic [7:0] tx_data,
  output logic mosi,
  input  logic miso,
  output logic sclk,
  output logic cs_n,
  output logic [7:0] rx_data,
  output logic done
);

  typedef enum logic [1:0] {IDLE, EDGE1, EDGE2, DONE_ST} state_t;
  state_t state;

  logic [7:0] tx_shift;
  logic [7:0] rx_shift;
  logic [2:0] bit_cnt;
  logic sclk_reg;

  assign sclk = (state == IDLE || state == DONE_ST) ? cpol : sclk_reg;
  assign cs_n = (state == IDLE);
  assign mosi = tx_shift[7];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state    <= IDLE;
      sclk_reg <= 0;
      tx_shift <= 0;
      rx_shift <= 0;
      bit_cnt  <= 0;
      done     <= 0;
      rx_data  <= 0;
    end else begin
      done <= 0;
      case (state)
        IDLE: begin
          sclk_reg <= cpol;
          if (start) begin
            tx_shift <= tx_data;
            bit_cnt  <= 0;
            state    <= EDGE1;
          end
        end

        EDGE1: begin
          sclk_reg <= ~sclk_reg;
          if (cpha == 0) rx_shift <= {rx_shift[6:0], miso};
          state <= EDGE2;
        end

        EDGE2: begin
          sclk_reg <= ~sclk_reg;
          if (cpha == 1) rx_shift <= {rx_shift[6:0], miso};

          if (bit_cnt == 7) begin
            state <= DONE_ST;
          end else begin
            tx_shift <= {tx_shift[6:0], 1'b0};
            bit_cnt  <= bit_cnt + 1;
            state    <= EDGE1;
          end
        end

        DONE_ST: begin
          rx_data <= rx_shift;
          done    <= 1;
          state   <= IDLE;
        end
      endcase
    end
  end
endmodule