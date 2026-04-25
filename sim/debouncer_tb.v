`timescale 1ns/1ps

module debouncer_tb;
    reg  clk, btn_in;
    wire btn_out;

    debouncer uut (.clk(clk), .btn_in(btn_in), .btn_out(btn_out));

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // Task: press button with bounce
    task press_with_bounce;
        integer i;
        begin
            // Simulate bouncing: rapid toggling
            for (i = 0; i < 5; i = i + 1) begin
                btn_in = 1; #30;
                btn_in = 0; #30;
            end
            // Settle HIGH (stable press)
            btn_in = 1;
            // Wait past STABLE cycles (use small STABLE=20 for sim)
            #500;
            btn_in = 0;
            #100;
        end
    endtask

    initial begin
        $dumpfile("debouncer_tb.vcd");
        $dumpvars(0, debouncer_tb);

        btn_in = 0;
        #100;

        $display("--- Test 1: Bouncy button press ---");
        press_with_bounce;

        $display("--- Test 2: Clean press (no bounce) ---");
        btn_in = 1; #500;
        btn_in = 0; #100;

        $display("--- Test 3: Very short glitch (should be ignored) ---");
        btn_in = 1; #20; // shorter than STABLE
        btn_in = 0; #200;

        $finish;
    end

    initial $monitor("t=%0t  btn_in=%b  btn_out=%b", $time, btn_in, btn_out);
endmodule
