// --- 1. Transaction Class ---
class Transaction;
  rand bit [3:0] req; 
  constraint c_req { req > 0; } 
endclass

// --- 2. Shared Data Wrapper (STATIC ARRAY) ---
class Env_Data;
  bit [3:0] req_array [15]; 
endclass

// --- 3. Generator Class ---
// Handles the randomized OOP logic (which we know works!)
class Generator;
  Transaction trans;
  Env_Data data; 
  int num_transactions = 15; 

  function new(Env_Data data);
    this.data = data;
  endfunction

  task run();
    $display("--- GENERATOR STARTING ---");
    for (int i = 0; i < num_transactions; i++) begin
      trans = new(); 
      if (!trans.randomize()) $error("Randomization failed!");
      
      data.req_array[i] = trans.req; 
      $display("[Generator] Generated Request [%0d]: %b", i, trans.req);
    end
    $display("--- GENERATOR FINISHED ---");
  endtask
endclass

// --- 4. Top-Level Testbench Module ---
module tb_rr_arbiter;
  logic clk;
  logic rst_n;

  arbiter_if vif(.clk(clk), .rst_n(rst_n));
  rr_arbiter dut(.vif(vif.dut));

  Env_Data data; 
  Generator gen;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    #15 rst_n = 1;

    // Manual override test
    @(posedge clk);
    vif.req <= 4'b1111;
    #40; 
    
    @(negedge clk); 

    // 1. Launch OOP Generator (Software Side)
    data = new(); 
    gen = new(data);
    gen.run(); // This fills the array instantly

    // 2. Hardware Driver Loop (Safe Module Side)
    $display("--- HARDWARE DRIVER STARTING ---");
    vif.req <= 0; 
    wait(rst_n == 1); 

    for (int i = 0; i < 15; i++) begin
      @(posedge clk);
      vif.req <= data.req_array[i]; // Pull from OOP array and drive pins safely
      $display("[Module Driver] Driving Request [%0d]: %b at time %0t", i, data.req_array[i], $time);
    end

    $display("All transactions completed.");
    #50 $finish; 
  end
endmodule