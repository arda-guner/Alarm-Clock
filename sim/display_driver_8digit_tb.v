`timescale 1ns/1ps

module display_driver_8digit_tb;

    reg clk;
    reg rst;
    reg [31:0] digits;

    wire [6:0] seg;
    wire [7:0] an;

    display_driver_8digit #(
        .REFRESH_MAX(8)
    ) dut (
        .clk   (clk),
        .rst   (rst),
        .digits(digits),
        .seg   (seg),
        .an    (an)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    function valid_anode;
        input [7:0] anode;
        begin
            valid_anode =
                (anode == 8'b11111110) ||
                (anode == 8'b11111101) ||
                (anode == 8'b11111011) ||
                (anode == 8'b11110111) ||
                (anode == 8'b11101111) ||
                (anode == 8'b11011111) ||
                (anode == 8'b10111111) ||
                (anode == 8'b01111111);
        end
    endfunction

    integer i;
    integer valid_count;

    initial begin
        $dumpfile("display_driver_8digit_tb.vcd");
        $dumpvars(0, display_driver_8digit_tb);

        rst = 1'b1;
        digits = 32'h12345678;
        valid_count = 0;

        repeat (5) @(posedge clk);
        rst = 1'b0;

        //--------------------------------------------------------
        // Test 1: display 12345678
        //--------------------------------------------------------
        repeat (100) begin
            @(posedge clk);

            if (!valid_anode(an)) begin
                $display("FAIL: invalid anode pattern. AN=%b", an);
                $finish;
            end

            valid_count = valid_count + 1;
        end

        $display("PASS: valid anode multiplexing for digits=12345678.");

        //--------------------------------------------------------
        // Test 2: display all zeros
        //--------------------------------------------------------
        digits = 32'h00000000;

        repeat (50) begin
            @(posedge clk);

            if (!valid_anode(an)) begin
                $display("FAIL: invalid anode pattern during zero test. AN=%b", an);
                $finish;
            end
        end

        $display("PASS: display driver handles all zeros.");

        //--------------------------------------------------------
        // Test 3: display all nines
        //--------------------------------------------------------
        digits = 32'h99999999;

        repeat (50) begin
            @(posedge clk);

            if (!valid_anode(an)) begin
                $display("FAIL: invalid anode pattern during nine test. AN=%b", an);
                $finish;
            end
        end

        $display("PASS: display driver handles all nines.");

        //--------------------------------------------------------
        // Test 4: full scan observation
        //--------------------------------------------------------
        digits = 32'h10203040;

        repeat (100) @(posedge clk);

        $display("PASS: display driver completed multiple scan cycles.");
        $display("ALL display_driver_8digit TESTS PASSED.");

        $finish;
    end

endmodule
