`timescale 1ns/1ps

module clk_en_tb;

    reg clk;
    reg rst;
    wire ce;

    // For simulation: MAX = 10
    clk_en #(
        .MAX(10)
    ) dut (
        .clk(clk),
        .rst(rst),
        .ce (ce)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;   // 100 MHz clock, 10 ns period

    integer pulse_count;
    integer cycle_count;

    initial begin
        $dumpfile("clk_en_tb.vcd");
        $dumpvars(0, clk_en_tb);

        rst = 1'b1;
        pulse_count = 0;
        cycle_count = 0;

        repeat (3) @(posedge clk);
        rst = 1'b0;

        repeat (50) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (ce)
                pulse_count = pulse_count + 1;
        end

        if (pulse_count >= 4) begin
            $display("PASS: clk_en generated periodic one-clock enable pulses.");
            $display("Pulse count = %0d", pulse_count);
        end
        else begin
            $display("FAIL: clk_en did not generate enough pulses. Pulse count = %0d", pulse_count);
            $finish;
        end

        $finish;
    end

endmodule
