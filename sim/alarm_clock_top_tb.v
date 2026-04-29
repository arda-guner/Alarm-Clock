`timescale 1ns/1ps
module alarm_clock_top_tb;

    reg  clk, rst;
    reg  raw_set, raw_inc, raw_mode, sw_alarm;
    wire [7:0] AN;
    wire [6:0] SEG;
    wire [7:0] LED;

    alarm_clock_top uut (
        .clk      (clk),
        .rst      (rst),
        .raw_set  (raw_set),
        .raw_inc  (raw_inc),
        .raw_mode (raw_mode),
        .sw_alarm (sw_alarm),
        .AN       (AN),
        .SEG      (SEG),
        .LED      (LED)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Task: press a button once (clean, no bounce)
    task press;
        input reg btn;
        begin
            btn = 1; @(posedge clk); #1;
            btn = 0; @(posedge clk); #1;
            #100;
        end
    endtask

    // Task: send N ena ticks directly to time counter
    // (bypass clk_en since it needs 100M cycles)
    task tick;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                // Force ena pulse by waiting -
                // in simulation we just wait clock cycles
                @(posedge clk); #1;
            end
        end
    endtask

    initial begin
        $dumpfile("alarm_clock_top_tb.vcd");
        $dumpvars(0, alarm_clock_top_tb);

        // Initialize
        rst=1; raw_set=0; raw_inc=0; raw_mode=0; sw_alarm=0;
        #50;
        rst=0;
        #100;

        // Test 1: check reset works
        $display("Test 1: After reset - HH=00 MM=00 SS=00");
        $display("AN=%b SEG=%b LED=%h", AN, SEG, LED);

        // Test 2: enter set-time mode and set HH=1
        $display("Test 2: Set HH to 1");
        raw_mode=1; @(posedge clk); #1; raw_mode=0; #200; // FSM -> state 1
        raw_inc=1;  @(posedge clk); #1; raw_inc=0;  #200; // HH = 1
        $display("AN=%b SEG=%b", AN, SEG);

        // Test 3: move to MM field, set MM=30
        $display("Test 3: Set MM to 5");
        raw_set=1; @(posedge clk); #1; raw_set=0; #200; // field -> MM
        repeat(5) begin
            raw_inc=1; @(posedge clk); #1; raw_inc=0; #200;
        end
        $display("AN=%b SEG=%b", AN, SEG);

        // Test 4: return to normal mode
        $display("Test 4: Return to normal mode");
        raw_mode=1; @(posedge clk); #1; raw_mode=0; #200; // FSM -> state 2
        raw_mode=1; @(posedge clk); #1; raw_mode=0; #200; // FSM -> state 0
        $display("AN=%b SEG=%b LED=%h", AN, SEG, LED);

        // Test 5: alarm enable
        $display("Test 5: Enable alarm switch");
        sw_alarm = 1;
        #500;
        $display("LED=%h (expect 00 - time does not match alarm)", LED);

        $display("--- All tests done ---");
        #200;
        $finish;
    end

endmodule

    
