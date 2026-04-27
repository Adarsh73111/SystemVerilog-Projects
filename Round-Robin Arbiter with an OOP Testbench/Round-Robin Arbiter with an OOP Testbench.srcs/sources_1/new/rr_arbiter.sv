module rr_arbiter (
  arbiter_if.dut vif
);

  logic [3:0] priority_mask;

  always_ff @(posedge vif.clk or negedge vif.rst_n) begin
    if (!vif.rst_n) begin
      priority_mask <= 4'b0001; // Start priority at device 0
      vif.gnt       <= 4'b0000;
    end else begin
      vif.gnt <= 4'b0000; // Default to no grant

      // Priority Logic: Check requests starting from the priority_mask
      if (vif.req[0] && priority_mask[0]) begin
        vif.gnt <= 4'b0001;
        priority_mask <= 4'b0010; // Shift priority to next device
      end 
      else if (vif.req[1] && (priority_mask[1] || priority_mask[0])) begin
        vif.gnt <= 4'b0010;
        priority_mask <= 4'b0100;
      end 
      else if (vif.req[2] && (priority_mask[2] || priority_mask[1] || priority_mask[0])) begin
        vif.gnt <= 4'b0100;
        priority_mask <= 4'b1000;
      end 
      else if (vif.req[3]) begin
        vif.gnt <= 4'b1000;
        priority_mask <= 4'b0001; // Wrap around to device 0
      end
      // Fallback: If higher priority devices didn't request, check the lower ones
      else if (vif.req[0]) begin
        vif.gnt <= 4'b0001;
        priority_mask <= 4'b0010;
      end
      else if (vif.req[1]) begin
        vif.gnt <= 4'b0010;
        priority_mask <= 4'b0100;
      end
      else if (vif.req[2]) begin
        vif.gnt <= 4'b0100;
        priority_mask <= 4'b1000;
      end
    end
  end

endmodule