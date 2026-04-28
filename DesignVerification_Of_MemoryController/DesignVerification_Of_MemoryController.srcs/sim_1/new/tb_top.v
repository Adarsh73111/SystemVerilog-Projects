`timescale 1ns / 1ps

module tb_top();

    reg clk;
    reg rst;
    reg chip_en;
    reg rw;
    reg [7:0] addr;
    reg [7:0] data_in;
    wire [7:0] data_out;

    top dut (
        .clk(clk),
        .rst(rst),
        .chip_en(chip_en),
        .rw(rw),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    always #5 clk = ~clk; // 100MHz clock

    initial begin
        clk = 0;
        rst = 1;
        chip_en = 0;
        rw = 0;
        addr = 8'b0;
        data_in = 8'b0;

        #10 rst = 0;

        // Write 0x55 to address 0x0A
        #10 chip_en = 1; rw = 0;
        addr = 8'h0A;
        data_in = 8'h55;
        #10 chip_en = 0;

        // Read from address 0x0A
        #10 chip_en = 1; rw = 1;
        addr = 8'h0A;
        #10 chip_en = 0;

        #20 $finish;
    end
endmodule