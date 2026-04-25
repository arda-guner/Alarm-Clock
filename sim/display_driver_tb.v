`timescale 1ns/1ps
module display_driver_tb;
    reg        clk;
    reg [31:0] digits;
    wire [7:0] AN;
    wire [6:0] SEG;

    display_driver uut (.clk(clk), .digits(digits), .AN(AN), .SEG(SEG));

    initial clk = 0;
    always #5 clk = ~clk;

    function [3:0] seg_to_bcd;
        input [6:0] seg;
        case (seg)
            7'b1000000: seg_to_bcd = 4'd0;
            7'b1111001: seg_to_bcd = 4'd1;
            7'b0100100: seg_to_bcd = 4'd2;
            7'b0110000: seg_to_bcd = 4'd3;
            7'b0011001: seg_to_bcd = 4'd4;
            7'b0010010: seg_to_bcd = 4'd5;
            7'b0000010: seg_to_bcd = 4'd6;
            7'b1111000: seg_to_bcd = 4'd7;
            7'b0000000: seg_to_bcd = 4'd8;
            7'b0010000: seg_to_bcd = 4'd9;
            default:    seg_to_bcd = 4'hF;
        endcase
    endfunction

    integer i;
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, display_driver_tb);

        // Test 1: Show 12:34:56
        $display("--- Test 1: Show 12:34:56 ---");
        digits = {4'd1,4'd2, 4'd3,4'd4, 4'd5,4'd6, 8'h00};
        repeat(200) @(posedge clk);
        $display("AN=%b SEG=%b decoded=%0d", AN, SEG, seg_to_bcd(SEG));

        // Test 2: All zeros
        $display("--- Test 2: Show 00:00:00 ---");
        digits = 32'h00000000;
        repeat(200) @(posedge clk);
        $display("AN=%b SEG=%b decoded=%0d", AN, SEG, seg_to_bcd(SEG));

        // Test 3: All nines
        $display("--- Test 3: Show 99:99:99 ---");
        digits = {4'd9,4'd9, 4'd9,4'd9, 4'd9,4'd9, 8'h00};
        repeat(200) @(posedge clk);
        $display("AN=%b SEG=%b decoded=%0d", AN, SEG, seg_to_bcd(SEG));

        // Test 4: One anode active check
        $display("--- Test 4: Only 1 anode LOW at a time ---");
        repeat(20) @(posedge clk);
        if ((~AN & (~AN - 1)) == 8'b0 && ~AN != 8'b0)
            $display("PASS: AN=%b (one anode active)", AN);
        else
            $display("FAIL: AN=%b (multiple anodes!)", AN);

        // Test 5: Cycle through all 8 digit positions
        $display("--- Test 5: All 8 digit positions ---");
        digits = {4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8};
        for (i = 0; i < 8; i = i + 1) begin
            repeat(50) @(posedge clk);
            $display("AN=%b  SEG=%b  decoded=%0d", AN, SEG, seg_to_bcd(SEG));
        end

        $display("--- All tests done ---");
        $finish;
    end
endmodule
