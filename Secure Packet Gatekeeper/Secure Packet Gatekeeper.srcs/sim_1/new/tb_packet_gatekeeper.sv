class Packet;
  rand bit [7:0] dest;
  rand bit [7:0] src;
  rand bit [7:0] p1;
  rand bit [7:0] p2;
  bit expect_pass;

  function void post_randomize();
    expect_pass = (dest == 8'h5A) && (src != 8'h00) && (src != 8'hFF);
  endfunction
endclass

class Env_Data;
  bit [7:0] data_arr [100];
  bit       last_arr [100];
  int       num_beats;
endclass

class Generator;
  Packet pkt;
  Env_Data data;
  int num_pkts = 8;

  function new(Env_Data data);
    this.data = data;
  endfunction

  task run();
    int idx = 0;
    for (int i = 0; i < num_pkts; i++) begin
      pkt = new();
      
      if (i == 1) begin 
          if (!pkt.randomize() with { dest == 8'h5A; src == 8'h00; }) $error("Rand Fail"); 
      end
      else if (i == 3) begin 
          if (!pkt.randomize() with { dest == 8'hFF; src == 8'h11; }) $error("Rand Fail"); 
      end
      else if (i == 5) begin 
          if (!pkt.randomize() with { dest == 8'h5A; src == 8'hFF; }) $error("Rand Fail"); 
      end
      else begin 
          if (!pkt.randomize() with { dest == 8'h5A; src inside {[8'h01:8'hFE]}; }) $error("Rand Fail"); 
      end
      
      data.data_arr[idx] = pkt.dest; data.last_arr[idx] = 0; idx++;
      data.data_arr[idx] = pkt.src;  data.last_arr[idx] = 0; idx++;
      data.data_arr[idx] = pkt.p1;   data.last_arr[idx] = 0; idx++;
      data.data_arr[idx] = pkt.p2;   data.last_arr[idx] = 1; idx++;
      
      if (pkt.expect_pass) $display("[Generator] Built GOOD Packet : Dest=%h Src=%h", pkt.dest, pkt.src);
      else                 $display("[Generator] Built BAD Packet  : Dest=%h Src=%h", pkt.dest, pkt.src);
    end
    data.num_beats = idx;
  endtask
endclass

module tb_packet_gatekeeper;
  logic clk;
  logic rst_n;
  logic [7:0] s_axis_tdata;
  logic       s_axis_tvalid;
  logic       s_axis_tlast;
  logic       s_axis_tready;
  logic [7:0] m_axis_tdata;
  logic       m_axis_tvalid;
  logic       m_axis_tlast;
  logic       m_axis_tready;
  logic       dropped_flag;

  packet_gatekeeper dut (.*);

  Env_Data data;
  Generator gen;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    m_axis_tready = 1;
    forever begin
      @(posedge clk);
      if (m_axis_tvalid && m_axis_tready) begin
        $display("   [Monitor] -> Forwarded Byte: %h (Last: %b)", m_axis_tdata, m_axis_tlast);
      end
      if (dropped_flag) begin
        $display("   [Monitor] -> ALARM! Malicious Packet Dropped.");
      end
    end
  end

  initial begin
    rst_n = 0;
    s_axis_tvalid = 0;
    s_axis_tdata = 0;
    s_axis_tlast = 0;
    
    #25 rst_n = 1;
    
    @(posedge clk);
    
    data = new();
    gen = new(data);
    gen.run();

    $display("--- HARDWARE TX STARTING ---");
    for (int i = 0; i < data.num_beats; i++) begin
      s_axis_tvalid <= 1;
      s_axis_tdata  <= data.data_arr[i];
      s_axis_tlast  <= data.last_arr[i];
      
      @(posedge clk);
      while (s_axis_tready == 0) @(posedge clk);
      
      if (data.last_arr[i]) begin
        s_axis_tvalid <= 0;
        s_axis_tlast  <= 0;
        repeat(15) @(posedge clk); 
      end
    end

    #100 $finish;
  end
endmodule