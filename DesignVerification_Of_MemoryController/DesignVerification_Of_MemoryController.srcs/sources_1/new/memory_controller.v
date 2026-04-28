`timescale 1ns / 1ps

module memory_controller(
    input clk,
    input rst,
    input chip_en,
    input [7:0] addr,
    input [7:0] data_in,
    input rw,
    output reg [3:0] row,
    output reg [3:0] col,
    output reg [7:0] data_out,
    output reg req,
    output reg [7:0] qi,
    input [7:0] qa,
    input valid
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            row <= 0;
            col <= 0;
            req <= 0;
            data_out <= 0;
        end else if (chip_en) begin
            row <= addr[7:4];
            col <= addr[3:0];
            qi <= data_in;
            req <= 1;
            if (rw && valid) begin
                data_out <= qa;
            end
        end else begin
            req <= 0;
        end
    end
endmodule