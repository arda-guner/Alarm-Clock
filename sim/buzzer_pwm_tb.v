`timescale 1ns/1ps

module buzzer_pwm_tb;

    reg clk;
    reg rst;
    reg enable;
    wire buzzer;

    //------------------------------------------------------------
    // DUT
    // Simulation parameters are reduced for fast waveform view.
    //
    // CLK_FREQ  = 100
    // BUZZ_FREQ = 10
    // HALF_PERIOD = 100 / (2 * 10) = 5 clock cycles
    //------------------------------------------------------------
    buzzer_pwm #(
        .CLK_FREQ(100),
        .BUZZ_FREQ(10)
    ) dut (
        .clk   (clk),
        .rst   (rst),
        .enable(enable),
        .buzzer(buzzer)
    );

    //------------------------------------------------------------
    // Clock generation: 10 ns period
    //------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer toggle_count;
    reg prev_buzzer;

    //------------------------------------------------------------
    // Count buzzer toggles
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            toggle_count <= 0;
            prev_buzzer  <= 1'b0;
        end
        else begin
            if (buzzer !== prev_buzzer) begin
                toggle_count <= toggle_count + 1;
                $display("Buzzer toggle at time %0t, buzzer=%b", $time, buzzer);
            end

            prev_buzzer <= buzzer;
        end
    end

    //------------------------------------------------------------
    // Stimulus
    //------------------------------------------------------------
    initial begin
        $dumpfile("buzzer_pwm_tb.vcd");
        $dumpvars(0, buzzer_pwm_tb);

        rst = 1'b1;
        enable = 1'b0;
        toggle_count = 0;
        prev_buzzer = 1'b0;

        //--------------------------------------------------------
        // Reset
        //--------------------------------------------------------
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);

        if (buzzer !== 1'b0) begin
            $display("FAIL: buzzer should be 0 after reset while disabled.");
            $finish;
        end

        //--------------------------------------------------------
        // Enable buzzer
        //--------------------------------------------------------
        enable = 1'b1;
        repeat (40) @(posedge clk);

        if (toggle_count < 6) begin
            $display("FAIL: buzzer did not toggle enough. toggle_count=%0d", toggle_count);
            $finish;
        end

        $display("PASS: buzzer toggles correctly when enable is high.");

        //--------------------------------------------------------
        // Disable buzzer
        //--------------------------------------------------------
        enable = 1'b0;
        repeat (10) @(posedge clk);

        if (buzzer !== 1'b0) begin
            $display("FAIL: buzzer should return to 0 when disabled.");
            $finish;
        end

        $display("PASS: buzzer returns to 0 when disabled.");

        //--------------------------------------------------------
        // Re-enable buzzer
        //--------------------------------------------------------
        toggle_count = 0;
        enable = 1'b1;
        repeat (30) @(posedge clk);

        if (toggle_count < 4) begin
            $display("FAIL: buzzer did not restart after re-enable. toggle_count=%0d", toggle_count);
            $finish;
        end

        $display("PASS: buzzer restarts correctly after re-enable.");

        $display("========================================");
        $display("ALL buzzer_pwm TESTS PASSED.");
        $display("========================================");

        $finish;
    end

endmodule
