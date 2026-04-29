module lfsr_4bit (
    input logic clk,
    input logic rst_n,
    output logic [3:0] q
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 4'b1000;
        end else begin
            q <= {q[2:0], q[3] ^ q[2]};
        end
    end

endmodule