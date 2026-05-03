`timescale 1ns/1ps

module bin2seg_tb;

    reg  [3:0] bin;
    wire [6:0] seg;

    bin2seg dut (
        .bin(bin),
        .seg(seg)
    );

    task check_seg;
        input [3:0] value;
        input [6:0] expected;
        begin
            bin = value;
            #10;

            if (seg !== expected) begin
                $display("FAIL: bin=%0d, seg=%b, expected=%b", value, seg, expected);
                $finish;
            end
            else begin
                $display("PASS: bin=%0d decoded correctly as seg=%b", value, seg);
            end
        end
    endtask

    initial begin
        $dumpfile("bin2seg_tb.vcd");
        $dumpvars(0, bin2seg_tb);

        check_seg(4'd0, 7'b1000000);
        check_seg(4'd1, 7'b1111001);
        check_seg(4'd2, 7'b0100100);
        check_seg(4'd3, 7'b0110000);
        check_seg(4'd4, 7'b0011001);
        check_seg(4'd5, 7'b0010010);
        check_seg(4'd6, 7'b0000010);
        check_seg(4'd7, 7'b1111000);
        check_seg(4'd8, 7'b0000000);
        check_seg(4'd9, 7'b0010000);

        // Invalid BCD input should blank the display
        check_seg(4'd10, 7'b1111111);
        check_seg(4'd15, 7'b1111111);

        $display("ALL bin2seg TESTS PASSED.");
        $finish;
    end

endmodule
