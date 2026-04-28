class SpiTransaction;
  randc bit [1:0] mode; 
  rand  bit [7:0] data;

  constraint c_data {
    data inside {[0:255]};
  }
endclass

module tb_spi_master;
  logic clk;
  logic rst_n;
  logic start;
  logic cpol;
  logic cpha;
  logic [7:0] tx_data;
  logic mosi;
  logic miso;
  logic sclk;
  logic cs_n;
  logic [7:0] rx_data;
  logic done;

  spi_master dut (.*);

  assign miso = mosi;

  bit [7:0] scoreboard [int];

  SpiTransaction tr;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    start = 0;
    cpol = 0;
    cpha = 0;
    tx_data = 0;
    #15 rst_n = 1;

    tr = new();

    $display("--- STARTING CONSTRAINED RANDOM SPI TEST ---");

    for (int i = 0; i < 50; i++) begin
      if (i == 10) begin
        if (!tr.randomize() with { mode == 2'b11; data == 8'hFF; }) $error("Rand failed");
      end else if (i == 20) begin
        if (!tr.randomize() with { mode == 2'b00; data == 8'h00; }) $error("Rand failed");
      end else begin
        if (!tr.randomize()) $error("Rand failed");
      end
      
      scoreboard[i] = tr.data;

      @(negedge clk);
      cpol    = tr.mode[1];
      cpha    = tr.mode[0];
      tx_data = tr.data;
      start   = 1;
      
      @(negedge clk);
      start = 0;

      wait(done == 1);
      @(posedge clk);

      if (rx_data === scoreboard[i]) begin
         $display("[Pass] Tx %0d: Mode=%b, Sent=%h, Rcvd=%h", i, tr.mode, tr.data, rx_data);
      end else begin
         $display("[FAIL] Tx %0d: Mode=%b, Sent=%h, Rcvd=%h", i, tr.mode, tr.data, rx_data);
      end
      
      #20; 
    end

    $display("--- TEST COMPLETE ---");
    #50 $finish;
  end
endmodule