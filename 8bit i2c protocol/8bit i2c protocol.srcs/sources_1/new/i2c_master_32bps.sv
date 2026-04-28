module i2c_master_32bps #(
    parameter SYS_CLK_FREQ = 50_000_000, // Assuming a 50 MHz FPGA base clock
    parameter I2C_BAUD_RATE = 32         // 32 bps target speed
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,
    input  logic [6:0] slave_addr,
    input  logic [7:0] tx_data,
    
    // I2C Physical Lines (Open-Drain)
    inout  wire        sda,
    inout  wire        scl,
    
    // Status Flags
    output logic       busy,
    output logic       ack_error
);

    // We need 4 ticks per I2C clock cycle to safely change data when SCL is low 
    // and sample when SCL is high.
    localparam TICK_FREQ = I2C_BAUD_RATE * 4;
    localparam MAX_COUNT = SYS_CLK_FREQ / TICK_FREQ;

    logic [$clog2(MAX_COUNT)-1:0] clk_div;
    logic tick;

    // I2C Open-Drain Control Signals
    logic sda_out;
    logic scl_out;
    logic sda_dir; // 1 = Master drives SDA, 0 = Slave drives (or Idle)

    // Open-drain assignments: If we want to send '1', we release the line (high-Z)
    // and let the pull-up resistor pull it high. If '0', we drive it to ground.
    assign sda = (sda_dir && (sda_out == 1'b0)) ? 1'b0 : 1'bz;
    assign scl = (scl_out == 1'b0) ? 1'b0 : 1'bz;

    // FSM States
    typedef enum logic [3:0] {
        IDLE, START_COND, 
        SEND_ADDR, GET_ACK1, 
        SEND_DATA, GET_ACK2, 
        STOP_COND
    } state_t;
    
    state_t state;
    
    logic [7:0] shift_reg;
    logic [2:0] bit_cnt;
    logic [1:0] phase; // Tracks the 4 phases of a single I2C bit period

    // --------------------------------------------------------
    // Clock Divider: Generates a tick at 4x the Baud Rate
    // --------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 0;
            tick <= 0;
        end else begin
            if (clk_div == MAX_COUNT - 1) begin
                clk_div <= 0;
                tick <= 1;
            end else begin
                clk_div <= clk_div + 1;
                tick <= 0;
            end
        end
    end

    // --------------------------------------------------------
    // Main I2C FSM
    // --------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            sda_out   <= 1'b1;
            scl_out   <= 1'b1;
            sda_dir   <= 1'b1;
            busy      <= 1'b0;
            ack_error <= 1'b0;
            phase     <= 2'b00;
        end else if (tick) begin
            case (state)
                IDLE: begin
                    sda_out <= 1'b1;
                    scl_out <= 1'b1;
                    sda_dir <= 1'b1;
                    if (start) begin
                        busy      <= 1'b1;
                        ack_error <= 1'b0;
                        shift_reg <= {slave_addr, 1'b0}; // Write mode (0)
                        state     <= START_COND;
                        phase     <= 2'b00;
                    end else begin
                        busy <= 1'b0;
                    end
                end

                // Start Condition: SDA goes low while SCL is high
                START_COND: begin
                    case (phase)
                        0: begin sda_out <= 1; scl_out <= 1; phase <= 1; end
                        1: begin sda_out <= 0; scl_out <= 1; phase <= 2; end // SDA falls
                        2: begin sda_out <= 0; scl_out <= 0; phase <= 3; end // SCL falls
                        3: begin bit_cnt <= 7; state <= SEND_ADDR; phase <= 0; end
                    endcase
                end

                // Shift out Address + RW bit
                SEND_ADDR: begin
                    case (phase)
                        0: begin sda_out <= shift_reg[7]; scl_out <= 0; phase <= 1; end // Change data on low clock
                        1: begin scl_out <= 1; phase <= 2; end // Clock high
                        2: begin scl_out <= 1; phase <= 3; end // Hold data
                        3: begin
                            scl_out <= 0; // Clock low
                            phase <= 0;
                            if (bit_cnt == 0) begin
                                sda_dir <= 0; // Hand over SDA to slave for ACK
                                state <= GET_ACK1;
                            end else begin
                                shift_reg <= {shift_reg[6:0], 1'b0};
                                bit_cnt <= bit_cnt - 1;
                            end
                        end
                    endcase
                end

                // Wait for Slave to pull SDA low (ACK)
                GET_ACK1: begin
                    case (phase)
                        0: begin scl_out <= 0; phase <= 1; end
                        1: begin scl_out <= 1; phase <= 2; end
                        2: begin 
                            ack_error <= sda; // If SDA is high, slave did not ACK
                            scl_out <= 1; 
                            phase <= 3; 
                        end
                        3: begin
                            scl_out <= 0;
                            sda_dir <= 1; // Take SDA back
                            if (ack_error) state <= STOP_COND; // Abort on NACK
                            else begin
                                shift_reg <= tx_data; // Load payload
                                bit_cnt <= 7;
                                state <= SEND_DATA;
                                phase <= 0;
                            end
                        end
                    endcase
                end

                // Shift out 8-bit Data payload
                SEND_DATA: begin
                    case (phase)
                        0: begin sda_out <= shift_reg[7]; scl_out <= 0; phase <= 1; end
                        1: begin scl_out <= 1; phase <= 2; end
                        2: begin scl_out <= 1; phase <= 3; end
                        3: begin
                            scl_out <= 0;
                            phase <= 0;
                            if (bit_cnt == 0) begin
                                sda_dir <= 0; 
                                state <= GET_ACK2;
                            end else begin
                                shift_reg <= {shift_reg[6:0], 1'b0};
                                bit_cnt <= bit_cnt - 1;
                            end
                        end
                    endcase
                end

                // Get final ACK from slave
                GET_ACK2: begin
                    case (phase)
                        0: begin scl_out <= 0; phase <= 1; end
                        1: begin scl_out <= 1; phase <= 2; end
                        2: begin ack_error <= sda; scl_out <= 1; phase <= 3; end
                        3: begin
                            scl_out <= 0;
                            sda_dir <= 1; 
                            state <= STOP_COND;
                            phase <= 0;
                        end
                    endcase
                end

                // Stop Condition: SDA goes high while SCL is high
                STOP_COND: begin
                    case (phase)
                        0: begin sda_out <= 0; scl_out <= 0; phase <= 1; end
                        1: begin sda_out <= 0; scl_out <= 1; phase <= 2; end // SCL rises
                        2: begin sda_out <= 1; scl_out <= 1; phase <= 3; end // SDA rises
                        3: begin state <= IDLE; busy <= 0; phase <= 0; end
                    endcase
                end
            endcase
        end
    end
endmodule