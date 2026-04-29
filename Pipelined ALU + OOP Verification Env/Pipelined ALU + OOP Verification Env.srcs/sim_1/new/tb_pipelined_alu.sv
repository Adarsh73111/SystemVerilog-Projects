virtual class Transaction;
  rand logic [7:0] id;
  pure virtual function void display(string name);
endclass

class AluTransaction extends Transaction;
  rand logic [7:0] a;
  rand logic [7:0] b;
  rand logic [2:0] op;
  logic [15:0] result;

  constraint c_op { op inside {[0:5]}; }

  function void display(string name);
    $display("[%s] ID:%h | OP:%0d | A:%h | B:%h | RES:%h", name, id, op, a, b, result);
  endfunction
endclass

class Generator;
  mailbox #(AluTransaction) gen2drv;
  event gen_done;
  int num_pkts;

  function new(mailbox #(AluTransaction) m, int n);
    gen2drv = m;
    num_pkts = n;
  endfunction

  task run();
    AluTransaction tx;
    for (int i = 0; i < num_pkts; i++) begin
      tx = new();
      if (!tx.randomize() with {id == i;}) $fatal("Rand failed");
      gen2drv.put(tx);
    end
    -> gen_done;
  endtask
endclass

class Driver;
  virtual alu_if vif;
  mailbox #(AluTransaction) gen2drv;
  semaphore print_sem;

  function new(virtual alu_if v, mailbox #(AluTransaction) m, semaphore s);
    vif = v;
    gen2drv = m;
    print_sem = s;
  endfunction

  task run();
    AluTransaction tx;
    forever begin
      gen2drv.get(tx);
      @(posedge vif.clk);
      vif.valid_in <= 1;
      vif.id_in    <= tx.id;
      vif.a        <= tx.a;
      vif.b        <= tx.b;
      vif.op       <= tx.op;
      
      print_sem.get(1);
      tx.display("Driver ");
      print_sem.put(1);
    end
  endtask
endclass

class Monitor;
  virtual alu_if vif;
  mailbox #(AluTransaction) mon2scb;
  semaphore print_sem;

  function new(virtual alu_if v, mailbox #(AluTransaction) m, semaphore s);
    vif = v;
    mon2scb = m;
    print_sem = s;
  endfunction

  task run();
    AluTransaction tx;
    forever begin
      @(posedge vif.clk);
      if (vif.valid_out) begin
        tx = new();
        tx.id     = vif.id_out;
        tx.result = vif.result;
        mon2scb.put(tx);
        
        print_sem.get(1);
        tx.display("Monitor");
        print_sem.put(1);
      end
    end
  endtask
endclass

class Scoreboard;
  mailbox #(AluTransaction) mon2scb;
  int pkts_rcvd = 0;
  int num_pkts;

  function new(mailbox #(AluTransaction) m, int n);
    mon2scb = m;
    num_pkts = n;
  endfunction

  task run();
    AluTransaction tx;
    forever begin
      mon2scb.get(tx);
      pkts_rcvd++;
      $display("[Scoreboard] Processed packet ID %h. Total: %0d/%0d", tx.id, pkts_rcvd, num_pkts);
    end
  endtask
endclass

class Environment;
  Generator  gen;
  Driver     drv;
  Monitor    mon;
  Scoreboard scb;

  mailbox #(AluTransaction) gen2drv;
  mailbox #(AluTransaction) mon2scb;
  semaphore print_sem;

  virtual alu_if vif;

  function new(virtual alu_if v, int num_pkts);
    vif = v;
    gen2drv   = new();
    mon2scb   = new();
    print_sem = new(1);

    gen = new(gen2drv, num_pkts);
    drv = new(vif, gen2drv, print_sem);
    mon = new(vif, mon2scb, print_sem);
    scb = new(mon2scb, num_pkts);
  endfunction

  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
    join_any

    wait(gen.gen_done.triggered);
    wait(scb.pkts_rcvd == scb.num_pkts);
    
    // The Teardown Phase Fix
    vif.valid_in <= 0; 
    
    #20;
    $display("--- TEST COMPLETE ---");
    $finish;
  endtask
endclass

module tb_pipelined_alu;
  logic clk;
  logic rst_n;

  alu_if vif(clk, rst_n);
  pipelined_alu dut(.vif(vif));
  Environment env;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    vif.valid_in = 0;
    #25 rst_n = 1;

    env = new(vif, 10);
    env.run();
  end
endmodule