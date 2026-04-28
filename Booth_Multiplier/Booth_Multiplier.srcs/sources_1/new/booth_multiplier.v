`timescale 1ns / 1ps

module booth_multiplier (
    input clk,
    input rst,
    input start,
    input [7:0] m,
    input [7:0] q,
    output reg [15:0] product,
    output reg done_flag
);
    reg [16:0] shift_reg;  // [16:9] = A, [8:1] = Q, [0] = Q-1
    reg [7:0] m_reg;
    reg [3:0] count;
    reg [1:0] state;
    reg step; // 0: add/sub, 1: shift

    parameter IDLE = 2'b00, CALC = 2'b01, DONE = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 0;
            m_reg <= 0;
            product <= 0;
            done_flag <= 0;
            count <= 0;
            state <= IDLE;
            step <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done_flag <= 0;
                    if (start) begin
                        shift_reg <= {9'b0, q, 1'b0};
                        m_reg <= m;
                        count <= 8;
                        step <= 0;
                        state <= CALC;
                    end
                end
                CALC: begin
                    if (step == 0) begin
                        // Step 1: ADD/SUB
                        case (shift_reg[1:0])
                            2'b01: shift_reg[16:9] <= shift_reg[16:9] + m_reg;
                            2'b10: shift_reg[16:9] <= shift_reg[16:9] - m_reg;
                        endcase
                        step <= 1;
                    end else begin
                        // Step 2: ARS
                        shift_reg <= {shift_reg[16], shift_reg[16:1]};
                        count <= count - 1;
                        step <= 0;
                        if (count == 1)
                            state <= DONE;
                    end
                end
                DONE: begin
                    product <= shift_reg[16:1];
                    done_flag <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule