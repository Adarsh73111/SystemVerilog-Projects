module tb_i2c_master;

    // Testbench signals
    logic       clk;
    logic       rst_n;
    logic       start;
    logic [6:0] slave_addr;
    logic [7:0] tx_data;
    
    // I2C physical wires (must be wire, not logic, for inout)
    wire        sda;
    wire        scl;
    
    logic       busy;
    logic       ack_error;

    // Provide the pull-up resistors required for I2C protocol
    pullup(sda);
    pullup(scl);

    // Instantiate the DUT 
    // Trick for simulation: We lower the SYS_CLK_FREQ so the simulation 
    // doesn't take hours to show a 32 bps waveform.
    i2c_master_32bps #(
        .SYS_CLK_FREQ(1000), // Scaled down for simulation speed
        .I2C_BAUD_RATE(32)
    ) dut (
        .*
    );

    // System Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Mock I2C Slave to generate ACKs
    // Whenever the Master releases SDA (z) during the 9th clock cycle, 
    // the slave will pull it down to 0 to say "I received the data".
    assign sda = (dut.state == dut.GET_ACK1 || dut.state == dut.GET_ACK2) ? 1'b0 : 1'bz;

    // Stimulus
    initial begin
        $display("Starting 32 bps I2C Master Simulation...");
        
        // Initialize inputs
        rst_n      = 0;
        start      = 0;
        slave_addr = 7'b1010101; // Example Device Address
        tx_data    = 8'b11001100; // Example Payload
        
        #50 rst_n = 1;
        #50;
        
        // --- THE FIX: Proper Handshake ---
        // Trigger the I2C transaction and hold it until the FSM catches it
        @(posedge clk);
        start = 1;
        
        wait(busy == 1); // Don't drop start until busy goes high!
        
        @(posedge clk);
        start = 0;
        // ---------------------------------
        
        // Wait for the FSM to finish the entire protocol
        wait(busy == 0);
        
        $display("I2C Transaction Complete! Check Waveforms.");
        
        #100 $finish;
    end

endmodule