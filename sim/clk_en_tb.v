// clk_en_tb.v
`timescale 1ns/1ps
module clk_en_tb;
    reg clk, rst;
    wire ena;

    // Use fast MAX in clk_en (change localparam MAX to 9 for simulation)
    clk_en uut (.clk(clk), .rst(rst), .ena(ena));

    initial clk = 0;
    always #5 clk = ~clk;   // 100MHz

    initial begin
        rst = 1; #20;
        rst = 0;
        #200;               // the value was 200 but we made it 500 to extend the duration of the simulation
        $finish;
    end

    initial $monitor("t=%0t  ena=%b", $time, ena);
endmodule
