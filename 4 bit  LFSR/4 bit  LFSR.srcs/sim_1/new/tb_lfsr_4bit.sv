module tb_lfsr_4bit;

    logic clk;
    logic rst_n;
    logic [3:0] q;

    lfsr_4bit uut (
        .clk(clk),
        .rst_n(rst_n),
        .q(q)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        
        #10;
        rst_n = 1;

        #200;
        
        $finish;
    end

    initial begin
        $monitor("Time = %0t | rst_n = %b | q = %b", $time, rst_n, q);
    end

endmodule