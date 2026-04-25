`timescale 1ns/1ps
module alarm_clock_top_tb;
    reg  clk, ena;
    reg  btn_set, btn_inc, btn_mode, sw_alarm;
    wire [31:0] digits;
    wire alarm_trig;
    wire [7:0] LED;

    alarm_clock_top uut (
        .clk(clk), .ena(ena),
        .btn_set(btn_set), .btn_inc(btn_inc),
        .btn_mode(btn_mode), .sw_alarm(sw_alarm),
        .digits(digits), .alarm_trig(alarm_trig),
        .LED(LED)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Task: press btn_inc N times
    task press_inc;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                btn_inc = 1; @(posedge clk); #1;
                btn_inc = 0; @(posedge clk); #1;
                #100;
            end
        end
    endtask

    // Task: press btn_set once
    task press_set;
        begin
            btn_set = 1; @(posedge clk); #1;
            btn_set = 0; @(posedge clk); #1;
            #100;
        end
    endtask

    // Task: press btn_mode once
    task press_mode;
        begin
            btn_mode = 1; @(posedge clk); #1;
            btn_mode = 0; @(posedge clk); #1;
            #100;
        end
    endtask

    // Task: tick ena N times
    task tick;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                ena = 1; @(posedge clk); #1;
                ena = 0; @(posedge clk); #1;
                #100;
            end
        end
    endtask

    initial begin
        $dumpfile("alarm_clock_top_tb.vcd");
        $dumpvars(0, alarm_clock_top_tb);

        btn_set=0; btn_inc=0; btn_mode=0; sw_alarm=0; ena=0;
        #200;

        // ── Test 1: Normal clock ticking ──────────────────────
        $display("--- Test 1: Clock ticks 3 seconds ---");
        tick(3);
        $display("digits=%h (expect SS=03)", digits);

        // ── Test 2: Set time to 01:30:00 ──────────────────────
        $display("--- Test 2: Set time HH=1 MM=30 SS=0 ---");
        press_mode;         // FSM: 0→1 (set time)

        // Set HH to 1
        press_inc(1);
        $display("HH should be 1, digits=%h", digits);

        // Move to MM, set to 30
        press_set;
        press_inc(30);
        $display("MM should be 30, digits=%h", digits);

        // Move to SS, wrap to 0
        // SS is currently 3 (from Test 1), add 57 to wrap to 0
        press_set;
        press_inc(57);      // 3 + 57 = 60 → wraps to 0
        $display("SS should be 0, digits=%h", digits);

        // Back to normal mode
        press_mode; press_mode; // FSM: 1→2→0
        $display("Time set. digits=%h (expect 01300000)", digits);

        // ── Test 3: Set alarm to 01:30 ────────────────────────
        $display("--- Test 3: Set alarm HH=1 MM=30 ---");
        press_mode; press_mode; // FSM: 0→1→2 (set alarm)

        press_inc(1);           // AHH = 1
        press_set;              // move to AMM
        press_inc(30);          // AMM = 30
        press_mode; press_mode; // FSM: 2→0 back to normal
        $display("Alarm set. digits=%h", digits);

        // ── Test 4: Enable alarm and wait for trigger ─────────
        $display("--- Test 4: Enable alarm wait for trigger ---");
        sw_alarm = 1;
        #200;

        // Time is 01:30:00, alarm is 01:30, SS==0 → trigger now
        tick(1);
        #200;
        $display("alarm_trig=%b LED=%h (expect 1 FF)", alarm_trig, LED);

        // ── Test 5: Silence alarm ─────────────────────────────
        $display("--- Test 5: Silence alarm ---");
        press_set;
        #200;
        $display("alarm_trig=%b LED=%h (expect 0 00)", alarm_trig, LED);

        // ── Test 6: SS rollover 59→0 ──────────────────────────
        $display("--- Test 6: SS rollover ---");
        press_mode;             // FSM: 0→1 (set time)
        press_set;              // skip HH
        press_set;              // skip MM → now on SS
        press_inc(58);          // SS = 58
        press_mode; press_mode; // FSM: 1→2→0
        tick(3);                // 58→59→0→1
        $display("digits=%h (expect SS=01 MM incremented)", digits);

        $display("--- All tests done ---");
        #200;
        $finish;
    end

endmodule


    
