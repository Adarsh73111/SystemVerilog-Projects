import flit_pkg::*;

module tb_noc_3x3;

  logic clk;
  logic rst_n;

  logic [2:0][2:0][FLIT_WIDTH-1:0] pe_in_flit;
  logic [2:0][2:0]                 pe_in_write_en;
  logic [2:0][2:0][2:0]            pe_out_credits;

  logic [2:0][2:0][FLIT_WIDTH-1:0] pe_out_flit;
  logic [2:0][2:0]                 pe_out_write_en;
  logic [2:0][2:0][2:0]            pe_in_credits;

  noc_3x3 dut (.*);

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Task to inject a wormhole packet into a specific Processing Element
  task inject_packet(input int src_x, input int src_y, input int dst_x, input int dst_y, input logic [7:0] pkt_id);
    header_data_t hdr;
    hdr.reserved = '0;
    hdr.pkt_id   = pkt_id;
    hdr.src_y    = src_y;
    hdr.src_x    = src_x;
    hdr.dst_y    = dst_y;
    hdr.dst_x    = dst_x;

    // Wait for credits, then inject HEADER
    wait(pe_out_credits[src_x][src_y] > 0);
    @(posedge clk);
    pe_in_write_en[src_x][src_y] <= 1;
    pe_in_flit[src_x][src_y]     <= {HEADER, 30'(hdr)};

    // Inject Body Flit 1
    @(posedge clk);
    wait(pe_out_credits[src_x][src_y] > 0);
    pe_in_flit[src_x][src_y]     <= {BODY, 30'h1111111};

    // Inject Body Flit 2
    @(posedge clk);
    wait(pe_out_credits[src_x][src_y] > 0);
    pe_in_flit[src_x][src_y]     <= {BODY, 30'h2222222};

    // Inject Tail Flit
    @(posedge clk);
    wait(pe_out_credits[src_x][src_y] > 0);
    pe_in_flit[src_x][src_y]     <= {TAIL, 30'h3333333};

    // Stop writing
    @(posedge clk);
    pe_in_write_en[src_x][src_y] <= 0;
  endtask

  initial begin
    // Initialize
    rst_n = 0;
    pe_in_write_en = '0;
    pe_in_flit = '0;
    pe_in_credits = '{default: 4}; // Assume all receiving endpoints have 4 buffer slots

    #25 rst_n = 1;
    #10;

    $display("--- INJECTING PACKET: Src(0,0) -> Dst(2,2) ---");
    // Send a packet from Top-Left to Bottom-Right, Packet ID = 0xA5
    inject_packet(0, 0, 2, 2, 8'hA5);

  end

  // Monitor for arriving packets at (2,2)
  initial begin
    forever begin
      @(posedge clk);
      if (pe_out_write_en[2][2]) begin
        if (pe_out_flit[2][2][31:30] == HEADER)
          $display("[%0t] PE(2,2) Ejected HEADER: ID=%h", $time, pe_out_flit[2][2][15:8]);
        else if (pe_out_flit[2][2][31:30] == TAIL)
          $display("[%0t] PE(2,2) Ejected TAIL. Packet Transfer Complete!", $time);
        else
          $display("[%0t] PE(2,2) Ejected BODY: Data=%h", $time, pe_out_flit[2][2][29:0]);
      end
    end
  end

  initial begin
    #500 $display("--- TEST FINISHED ---");
    $finish;
  end

endmodule