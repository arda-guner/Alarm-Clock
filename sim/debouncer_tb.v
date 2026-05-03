`timescale 1ns/1ps

module debounce_tb;

    reg clk;
    reg rst;
    reg pin;

    wire state;
    wire press;

    debounce #(
        .DEBOUNCE_MAX(2)
    ) dut (
        .clk  (clk),
        .rst  (rst),
        .pin  (pin),
        .state(state),
        .press(press)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer press_count;

    initial begin
        $dumpfile("debounce_tb.vcd");
        $dumpvars(0, debounce_tb);

        rst = 1'b1;
        pin = 1'b0;
        press_count = 0;

        repeat (5) @(posedge clk);
        rst = 1'b0;

        //--------------------------------------------------------
        // Test 1: bouncing input
        //--------------------------------------------------------
        pin = 1'b1; repeat (2) @(posedge clk);
        pin = 1'b0; repeat (2) @(posedge clk);
        pin = 1'b1; repeat (2) @(posedge clk);
        pin = 1'b0; repeat (2) @(posedge clk);
        pin = 1'b1; repeat (20) @(posedge clk); // finally stable high

        //--------------------------------------------------------
        // Release
        //--------------------------------------------------------
        pin = 1'b0; repeat (20) @(posedge clk);

        //--------------------------------------------------------
        // Test 2: short glitch
        //--------------------------------------------------------
        pin = 1'b1; repeat (1) @(posedge clk);
        pin = 1'b0; repeat (20) @(posedge clk);

        if (press_count == 1) begin
            $display("PASS: debounce generated exactly one press pulse and ignored short glitch.");
        end
        else begin
            $display("FAIL: expected 1 press pulse, got %0d", press_count);
            $finish;
        end

        $finish;
    end

    always @(posedge clk) begin
        if (press) begin
            press_count = press_count + 1;
            $display("Press pulse detected at time %0t", $time);
        end
    end

endmodule
