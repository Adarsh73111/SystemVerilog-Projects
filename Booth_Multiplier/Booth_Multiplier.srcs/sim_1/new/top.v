`timescale 1ns / 1ps

module top (
    input clk,
    input rst,
    input start,
    input [7:0] m,
    input [7:0] q,
    output [6:0] disp_seg_o,
    output [7:0] disp_an_o,  // Now 8-bit anode for Nexys 4 DDR
    output dp
);

    wire [15:0] product;
    wire done_flag;

    booth_multiplier uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .m(m),
        .q(q),
        .product(product),
        .done_flag(done_flag)
    );

    reg [19:0] clkdiv = 0;
    always @(posedge clk) clkdiv <= clkdiv + 1;

    wire [1:0] digit_sel = clkdiv[17:16];  // 4-digit refresh selector

    reg [3:0] hex_digit;
    reg [6:0] seg;

    // Activate only lower 4 digits (anodes are active-low)
    // disp_an_o[7:4] = 1 (off), disp_an_o[3:0] = rotating active-low
    reg [7:0] anode_mask;
    always @(*) begin
        case (digit_sel)
            2'b00: anode_mask = 8'b11111110;
            2'b01: anode_mask = 8'b11111101;
            2'b10: anode_mask = 8'b11111011;
            2'b11: anode_mask = 8'b11110111;
            default: anode_mask = 8'b11111111;
        endcase
    end

    // Select the 4-bit nibble from the 16-bit product to display
    always @(*) begin
        case (digit_sel)
            2'b00: hex_digit = product[3:0];
            2'b01: hex_digit = product[7:4];
            2'b10: hex_digit = product[11:8];
            2'b11: hex_digit = product[15:12];
            default: hex_digit = 4'h0;
        endcase
    end

    // Hex to 7-segment decoder
    always @(*) begin
        case (hex_digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end

    assign disp_seg_o = seg;
    assign disp_an_o = anode_mask;  // Final anode output (active-low)
    assign dp = done_flag;          // Optional use of DP for done_flag

endmodule


// TEST-BENCH //

`timescale 1ns / 1ps

module tb_top;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] m;
    reg [7:0] q;

    wire [6:0] disp_seg_o;
    wire [3:0] disp_an_o;
    wire dp; // Done flag output connected to decimal point

    // Instantiate the top module
    top uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .m(m),
        .q(q),
        .disp_seg_o(disp_seg_o),
        .disp_an_o(disp_an_o),
        .dp(dp)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period = 100MHz
    end

    initial begin
        rst = 1;
        start = 0;
        m = 0;
        q = 0;
        #20;
        rst = 0;

        // --- Test Case 1: 5 * 3 = 15 ---
        wait (dp == 0);
        m = 8'd5;
        q = 8'd3;
        start = 1;
        #10; start = 0;
        wait (dp == 1);
        #100;

        // --- Test Case 2: -5 * 3 = -15 ---
        wait (dp == 0);
        m = -8'sd5;
        q = 8'd3;
        start = 1;
        #10; start = 0;
        wait (dp == 1);
        #100;

        // --- Test Case 3: -5 * -3 = 15 ---
        wait (dp == 0);
        m = -8'sd5;
        q = -8'sd3;
        start = 1;
        #10; start = 0;
        wait (dp == 1);
        #100;

        // --- Test Case 4: 7 * -2 = -14 ---
        wait (dp == 0);
        m = 8'd7;
        q = -8'sd2;
        start = 1;
        #10; start = 0;
        wait (dp == 1);
        #100;

        // --- Test Case 5: 4 * -3 = -12 ---
        wait (dp == 0);
        m = 8'd4;
        q = -8'sd3;
        start = 1;
        #10; start = 0;
        wait (dp == 1);
        #100;

        // --- Test Case 6: 3 * -3 = -9 ---
        wait (dp == 0);
        m = 8'd3;
        q = -8'sd3;
        start = 1;
        #10; start = 0;
        wait (dp == 1);
        #100;

        // --- Test Case 7: -3 * -3 = 9 ---
        wait (dp == 0);
        m = -8'sd3;
        q = -8'sd3;
        start = 1;
        #10; start = 0;
        wait (dp == 1);
        #100;

        // --- Test Case 8: 4 * 3 = 12 ---
        wait (dp == 0);
        m = 8'd4;
        q = 8'd3;
        start = 1;
        #10; start = 0;
        wait (dp == 1);
        #100;

        $finish;
    end

endmodule