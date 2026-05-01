interface dff_if(input logic clk, rst_n);
  logic d;
  logic q;
endinterface

class transaction;
  rand bit d; // Input to be randomized
  bit q;      // Output to be monitored
  
  function void display(string name);
    $display("[%0t] %s: d = %0b, q = %0b", $time, name, d, q);
  endfunction
endclass

class generator;
  mailbox #(transaction) gen2drv;
  int repeat_count;
  event ended;

  function new(mailbox #(transaction) gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task run();
    transaction tx;
    for (int i = 0; i < repeat_count; i++) begin
      tx = new();
      if (!tx.randomize()) $fatal("Randomization failed");
      gen2drv.put(tx);
    end
    -> ended; // Signal that generation is complete
  endtask
endclass

class driver;
  virtual dff_if vif;
  mailbox #(transaction) gen2drv;

  function new(virtual dff_if vif, mailbox #(transaction) gen2drv);
    this.vif = vif;
    this.gen2drv = gen2drv;
  endfunction

  task run();
    transaction tx;
    forever begin
      gen2drv.get(tx);
      @(posedge vif.clk);
      vif.d <= tx.d;
      tx.display("Driver ");
    end
  endtask
endclass

// ---------------------------------------------------
// 5. Monitor Class
// ---------------------------------------------------
class monitor;
  virtual dff_if vif;
  mailbox #(transaction) mon2scb;

  function new(virtual dff_if vif, mailbox #(transaction) mon2scb);
    this.vif = vif;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction tx;
    forever begin
      tx = new();
      @(posedge vif.clk);
      // Wait a tiny delay to sample the stabilized output
      #1; 
      tx.d = vif.d;
      tx.q = vif.q;
      tx.display("Monitor");
      mon2scb.put(tx);
    end
  endtask
endclass

// ---------------------------------------------------
// 6. Scoreboard Class
// ---------------------------------------------------
class scoreboard;
  mailbox #(transaction) mon2scb;
  bit expected_q; // Remembers the previous 'd' value

  function new(mailbox #(transaction) mon2scb);
    this.mon2scb = mon2scb;
    expected_q = 0;
  endfunction

  task run();
    transaction tx;
    forever begin
      mon2scb.get(tx);
      
      // Compare actual Q with the expected Q (which is the previous D)
      if (tx.q == expected_q) begin
        $display("[%0t] Scoreboard: PASS. Expected = %0b, Actual = %0b", $time, expected_q, tx.q);
      end else begin
        $error("[%0t] Scoreboard: FAIL! Expected = %0b, Actual = %0b", $time, expected_q, tx.q);
      end
      
      // The current 'd' becomes the expected 'q' for the next clock cycle
      expected_q = tx.d; 
    end
  endtask
endclass

// ---------------------------------------------------
// 7. Environment Class
// ---------------------------------------------------
class environment;
  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard scb;
  
  mailbox #(transaction) gen2drv;
  mailbox #(transaction) mon2scb;
  
  virtual dff_if vif;

  function new(virtual dff_if vif);
    this.vif = vif;
    gen2drv = new();
    mon2scb = new();
    
    gen = new(gen2drv);
    drv = new(vif, gen2drv);
    mon = new(vif, mon2scb);
    scb = new(mon2scb);
  endfunction

  task run();
    gen.repeat_count = 10; // Run 10 randomized tests
    
    // Fork runs tasks in parallel
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
    join_any
    
    // Wait for the generator to finish creating packets
    wait(gen.ended.triggered);
    
    // Allow time for the final packets to drain through the pipeline
    #20; 
  endtask
endclass

// ---------------------------------------------------
// 8. Top Level Testbench Module
// ---------------------------------------------------
module tb_top;
  logic clk;
  logic rst_n;

  // Instantiate Interface and RTL
  dff_if vif(clk, rst_n);
  dff dut (
    .clk(vif.clk),
    .rst_n(vif.rst_n),
    .d(vif.d),
    .q(vif.q)
  );

  // Instantiate Environment
  environment env;

  // Clock Generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns time period
  end

  // Test Flow
  initial begin
    // 1. Assert Reset
    rst_n = 0;
    vif.d = 0;
    #15; 
    
    // 2. De-assert Reset
    rst_n = 1;
    
    // 3. Initialize and run environment
    env = new(vif);
    env.run();
    
    // 4. End Simulation
    $display("--- TEST COMPLETE ---");
    $finish;
  end
  
  // Optional: Dump waveforms (for EDA Playground or Vivado)
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule