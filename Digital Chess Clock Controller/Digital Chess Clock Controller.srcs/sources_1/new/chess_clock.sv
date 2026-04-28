module chess_clock #(
  parameter CLK_FREQ = 50_000_000 
)(
  input  logic clk,
  input  logic rst_n,
  input  logic start_btn,
  input  logic p1_btn,
  input  logic p2_btn,
  input  logic [1:0] time_ctrl, 
  
  output logic [11:0] p1_time,
  output logic [11:0] p2_time,
  output logic p1_flag,
  output logic p2_flag
);

  typedef enum logic [1:0] {IDLE, P1_ACTIVE, P2_ACTIVE, GAME_OVER} state_t;
  state_t state;

  logic [$clog2(CLK_FREQ)-1:0] tick_counter;
  logic one_sec_pulse;

  logic p1_btn_d, p2_btn_d;
  logic p1_btn_pulse, p2_btn_pulse;
  logic [11:0] init_time;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      p1_btn_d <= 0;
      p2_btn_d <= 0;
    end else begin
      p1_btn_d <= p1_btn;
      p2_btn_d <= p2_btn;
    end
  end

  assign p1_btn_pulse = p1_btn & ~p1_btn_d;
  assign p2_btn_pulse = p2_btn & ~p2_btn_d;

  always_comb begin
    case (time_ctrl)
      2'b00: init_time = 12'd60;
      2'b01: init_time = 12'd180;
      2'b10: init_time = 12'd300;
      2'b11: init_time = 12'd600;
    endcase
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tick_counter <= 0;
      one_sec_pulse <= 0;
    end else if (state == P1_ACTIVE || state == P2_ACTIVE) begin
      if (tick_counter == CLK_FREQ - 1) begin
        tick_counter <= 0;
        one_sec_pulse <= 1;
      end else begin
        tick_counter <= tick_counter + 1;
        one_sec_pulse <= 0;
      end
    end else begin
      tick_counter <= 0;
      one_sec_pulse <= 0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      p1_time <= 12'd60;
      p2_time <= 12'd60;
      p1_flag <= 0;
      p2_flag <= 0;
    end else begin
      case (state)
        IDLE: begin
          p1_time <= init_time;
          p2_time <= init_time;
          p1_flag <= 0;
          p2_flag <= 0;
          if (start_btn) state <= P1_ACTIVE;
        end
        
        P1_ACTIVE: begin
          if (one_sec_pulse) begin
            if (p1_time == 1) begin
              p1_time <= 0;
              p1_flag <= 1;
              state <= GAME_OVER;
            end else begin
              p1_time <= p1_time - 1;
            end
          end
          if (p1_btn_pulse && p1_time > 0) state <= P2_ACTIVE;
        end
        
        P2_ACTIVE: begin
          if (one_sec_pulse) begin
            if (p2_time == 1) begin
              p2_time <= 0;
              p2_flag <= 1;
              state <= GAME_OVER;
            end else begin
              p2_time <= p2_time - 1;
            end
          end
          if (p2_btn_pulse && p2_time > 0) state <= P1_ACTIVE;
        end
        
        GAME_OVER: begin
          if (start_btn) state <= IDLE;
        end
      endcase
    end
  end
endmodule