`timescale 1ns / 1ps

module top(
    input clk,
    input rst,
    input chip_en,
    input rw,
    input [7:0] addr,
    input [7:0] data_in,
    output [7:0] data_out
);

    wire [3:0] ar, ac;
    wire req;
    wire [7:0] qi, qa;
    wire valid;

    memory_controller mc (
        .clk(clk),
        .rst(rst),
        .chip_en(chip_en),
        .addr(addr),
        .data_in(data_in),
        .rw(rw),
        .row(ar),
        .col(ac),
        .data_out(data_out),
        .req(req),
        .qi(qi),
        .qa(qa),
        .valid(valid)
    );

    ram r (
        .clk(clk),
        .rst(rst),
        .req(req),
        .rw(rw),
        .ar(ar),
        .ac(ac),
        .qi(qi),
        .qa(qa),
        .valid(valid)
    );
endmodule