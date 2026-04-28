module tb_chess_clock;

  logic clk;
  logic rst_n;
  logic start_btn;
  logic p1_btn;
  logic p2_btn;
  logic [1:0] time_ctrl;
  
  logic [11:0] p1_time;
  logic [11:0] p2_time;
  logic p1_flag;
  logic p2_flag;

  chess_clock #(
    .CLK_FREQ(10) 
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start_btn(start_btn),
    .p1_btn(p1_btn),
    .p2_btn(p2_btn),
    .time_ctrl(time_ctrl),
    .p1_time(p1_time),
    .p2_time(p2_time),
    .p1_flag(p1_flag),
    .p2_flag(p2_flag)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    start_btn = 0;
    p1_btn = 0;
    p2_btn = 0;
    time_ctrl = 2'b00; 
    
    #15 rst_n = 1;
    #10;
    
    start_btn = 1; #10; start_btn = 0;
    
    #300;
    
    p1_btn = 1; #10; p1_btn = 0;
    
    #200;
    
    p2_btn = 1; #10; p2_btn = 0;
    
    #6000;
    
    start_btn = 1; #10; start_btn = 0;
    time_ctrl = 2'b01;
    #50;
    
    $finish;
  end

endmodule