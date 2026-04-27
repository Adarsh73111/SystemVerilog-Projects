module tb_sync_fifo;

  // Parameters matching the DUT
  parameter DATA_WIDTH = 8;
  parameter DEPTH = 16;

  // Clock and Reset generation variables
  logic clk;
  logic rst_n;

  // 1. Instantiate the Interface
  fifo_if #(DATA_WIDTH, DEPTH) vif (
    .clk(clk), 
    .rst_n(rst_n)
  );

  // 2. Instantiate the DUT (Device Under Test)
  // Connect the DUT modport of the interface to the module
  sync_fifo #(DATA_WIDTH, DEPTH) dut (
    .vif(vif.dut)
  );

  // 3. Clock Generation (10ns period / 100MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk; 
  end

  // 4. Stimulus Generation
  initial begin
    // Initialize signals
    vif.wr_en = 0;
    vif.rd_en = 0;
    vif.data_in = 0;
    rst_n = 0;

    // Apply Reset
    #15 rst_n = 1;

    // --- TEST 1: Basic Write ---
    @(posedge clk);
    vif.wr_en <= 1; vif.data_in <= 8'hA1;
    @(posedge clk);
    vif.wr_en <= 1; vif.data_in <= 8'hB2;
    @(posedge clk);
    vif.wr_en <= 1; vif.data_in <= 8'hC3;
    @(posedge clk);
    vif.wr_en <= 0; // Stop writing

    #20; // Wait a few cycles

    // --- TEST 2: Basic Read ---
    @(posedge clk);
    vif.rd_en <= 1;
    @(posedge clk); 
    @(posedge clk); 
    @(posedge clk); 
    vif.rd_en <= 0; // Stop reading

    #20;

    // --- TEST 3: Fill the FIFO to trigger 'full' flag ---
    vif.wr_en <= 1;
    for (int i = 0; i < DEPTH; i++) begin
      vif.data_in <= i;
      @(posedge clk);
    end
    vif.wr_en <= 0;

    #20;

    // --- TEST 4: Empty the FIFO to trigger 'empty' flag ---
    vif.rd_en <= 1;
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge clk);
    end
    vif.rd_en <= 0;

    // End simulation
    #50 $finish;
  end

endmodule