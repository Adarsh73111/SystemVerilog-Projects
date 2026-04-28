`timescale 1ns / 1ps

module ram(
    input clk,
    input rst,
    input req,
    input rw,
    input [3:0] ar,  // row address
    input [3:0] ac,  // column address
    input [7:0] qi,  // data to write
    output reg [7:0] qa, // data read
    output reg valid
);

    reg [7:0] mem [0:15][0:15]; // 16x16 RAM, 8-bit wide

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            qa <= 8'b0;
            valid <= 0;
        end else if (req) begin
            if (rw) begin
                qa <= mem[ar][ac];
                valid <= 1;
            end else begin
                mem[ar][ac] <= qi;
                valid <= 0;
            end
        end else begin
            valid <= 0;
        end
    end
endmodule