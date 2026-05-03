`timescale 1ns/1ps

module buzzer_pwm_tb;

    reg clk;
    reg rst;
    reg enable;
    wire pwm;

    //------------------------------------------------------------
    // DUT
    // For simulation:
    // CLK_FREQ  = 100
    // BUZZ_FREQ = 10
    // HALF_PERIOD = 100 / (2*10) = 5 clock cycles
    //------------------------------------------------------------
    buzzer_pwm #(
        .CLK_FREQ(100),
        .BUZZ_FREQ(10)
    ) dut (
        .clk   (clk),
        .rst   (rst),
        .enable(enable),
        .pwm   (pwm)
    );

    //------------------------------------------------------------
    // Clock generation
    //------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer toggle_count;
    reg prev_pwm;

    //------------------------------------------------------------
    // Count PWM toggles
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            prev_pwm     <= 1'b0;
            toggle_count <= 0;
        end
        else begin
            if (pwm !== prev_pwm) begin
                toggle_count <= toggle_count + 1;
                $display("PWM toggle at time %0t, pwm=%b", $time, pwm);
            end

            prev_pwm <= pwm;
        end
    end

    initial begin
        $dumpfile("buzzer_pwm_tb.vcd");
        $dumpvars(0, buzzer_pwm_tb);

        rst = 1'b1;
        enable = 1'b0;
        toggle_count = 0;
        prev_pwm = 1'b0;

        //--------------------------------------------------------
        // Reset
        //--------------------------------------------------------
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);

        if (pwm !== 1'b0) begin
            $display("FAIL: pwm should be 0 when disabled.");
            $finish;
        end

        //--------------------------------------------------------
        // Enable buzzer
        //--------------------------------------------------------
        enable = 1'b1;

        repeat (40) @(posedge clk);

        if (toggle_count < 6) begin
            $display("FAIL: pwm did not toggle enough. toggle_count=%0d", toggle_count);
            $finish;
        end

        $display("PASS: pwm toggles when enable is high.");

        //--------------------------------------------------------
        // Disable buzzer
        //--------------------------------------------------------
        enable = 1'b0;
        repeat (5) @(posedge clk);

        if (pwm !== 1'b0) begin
            $display("FAIL: pwm should return to 0 when disabled.");
            $finish;
        end

        $display("PASS: pwm returns to 0 when disabled.");

        //--------------------------------------------------------
        // Re-enable buzzer
        //--------------------------------------------------------
        toggle_count = 0;
        enable = 1'b1;

        repeat (25) @(posedge clk);

        if (toggle_count < 3) begin
            $display("FAIL: pwm did not restart after re-enable.");
            $finish;
        end

        $display("PASS: pwm restarts correctly after re-enable.");

        $display("========================================");
        $display("ALL buzzer_pwm TESTS PASSED.");
        $display("========================================");

        $finish;
    end

endmodule 
