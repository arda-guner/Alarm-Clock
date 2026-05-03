`timescale 1ns/1ps

module alarm_clock_top_tb;

    reg clk;
    reg rst;
    reg raw_set;
    reg raw_inc;
    reg raw_mode;
    reg sw_alarm;

    wire [7:0] AN;
    wire [6:0] SEG;
    wire [7:0] LED;
    wire AUD_PWM;
    wire AUD_SD;

    //------------------------------------------------------------
    // DUT
    //------------------------------------------------------------
    alarm_clock_top dut (
        .CLK100MHZ(clk),
        .BTNU(rst),
        .BTNC(raw_set),
        .BTNL(raw_inc),
        .BTNR(raw_mode),
        .SW({15'd0, sw_alarm}),
        .AN(AN),
        .SEG(SEG),
        .LED(LED),
        .AUD_PWM(AUD_PWM),
        .AUD_SD(AUD_SD)
    );

    //------------------------------------------------------------
    // Clock generation: 100 MHz, 10 ns period
    //------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    //------------------------------------------------------------
    // Internal forced clean pulses
    // Debounce is tested separately, so top-level TB drives clean
    // button pulses directly.
    //------------------------------------------------------------
    task pulse_tick;
        begin
            force dut.ena_1hz = 1'b1;
            @(posedge clk);
            #1;
            force dut.ena_1hz = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task press_mode;
        begin
            force dut.btn_mode_press = 1'b1;
            @(posedge clk);
            #1;
            force dut.btn_mode_press = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task press_set;
        begin
            force dut.btn_set_press = 1'b1;
            @(posedge clk);
            #1;
            force dut.btn_set_press = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    task press_inc;
        begin
            force dut.btn_inc_press = 1'b1;
            @(posedge clk);
            #1;
            force dut.btn_inc_press = 1'b0;
            @(posedge clk);
            #1;
        end
    endtask

    //------------------------------------------------------------
    // Check helpers
    //------------------------------------------------------------
    task check_time;
        input [5:0] exp_h;
        input [5:0] exp_m;
        input [5:0] exp_s;
        begin
            if (dut.hour !== exp_h || dut.minute !== exp_m || dut.second !== exp_s) begin
                $display("FAIL: time mismatch. Got %0d:%0d:%0d, expected %0d:%0d:%0d",
                         dut.hour, dut.minute, dut.second,
                         exp_h, exp_m, exp_s);
                $finish;
            end
        end
    endtask

    task check_alarm_time;
        input [5:0] exp_h;
        input [5:0] exp_m;
        begin
            if (dut.alarm_hour !== exp_h || dut.alarm_minute !== exp_m) begin
                $display("FAIL: alarm time mismatch. Got %0d:%0d, expected %0d:%0d",
                         dut.alarm_hour, dut.alarm_minute,
                         exp_h, exp_m);
                $finish;
            end
        end
    endtask

    task check_state;
        input [1:0] exp_state;
        begin
            if (dut.state !== exp_state) begin
                $display("FAIL: state mismatch. Got %0d, expected %0d",
                         dut.state, exp_state);
                $finish;
            end
        end
    endtask

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

    //------------------------------------------------------------
    // Buzzer PWM check helper
    //------------------------------------------------------------
    task check_buzzer_toggles_when_alarm_active;
        integer i;
        integer toggle_count;
        reg prev_pwm;
        begin
            toggle_count = 0;
            prev_pwm = AUD_PWM;

            // HALF_PERIOD = 100_000_000 / (2*2000) = 25_000 clock cycles.
            // One full period is 50_000 cycles. We observe long enough to see toggles.
            for (i = 0; i < 80000; i = i + 1) begin
                @(posedge clk);
                if (AUD_PWM !== prev_pwm) begin
                    toggle_count = toggle_count + 1;
                    prev_pwm = AUD_PWM;
                end
            end

            if (toggle_count < 2) begin
                $display("FAIL: AUD_PWM did not toggle enough while alarm was active. toggle_count=%0d",
                         toggle_count);
                $finish;
            end
            else begin
                $display("PASS: buzzer PWM toggles while alarm is active. toggle_count=%0d",
                         toggle_count);
            end
        end
    endtask

    integer i;

    initial begin
        $dumpfile("alarm_clock_top_tb.vcd");
        $dumpvars(0, alarm_clock_top_tb);

        raw_set  = 1'b0;
        raw_inc  = 1'b0;
        raw_mode = 1'b0;
        sw_alarm = 1'b0;

        force dut.ena_1hz        = 1'b0;
        force dut.btn_set_press  = 1'b0;
        force dut.btn_inc_press  = 1'b0;
        force dut.btn_mode_press = 1'b0;

        //--------------------------------------------------------
        // Reset
        //--------------------------------------------------------
        rst = 1'b1;
        repeat (5) @(posedge clk);
        #1;
        rst = 1'b0;
        repeat (3) @(posedge clk);
        #1;

        check_state(2'd0);
        check_time(6'd0, 6'd0, 6'd0);
        check_alarm_time(6'd0, 6'd0);

        if (AUD_SD !== 1'b1) begin
            $display("FAIL: AUD_SD should be 1 to enable onboard audio.");
            $finish;
        end

        if (AUD_PWM !== 1'b0) begin
            $display("FAIL: AUD_PWM should be 0 after reset.");
            $finish;
        end

        $display("PASS: reset works.");

        //--------------------------------------------------------
        // Test 1: normal ticking
        //--------------------------------------------------------
        pulse_tick();
        pulse_tick();
        pulse_tick();

        check_time(6'd0, 6'd0, 6'd3);
        $display("PASS: normal ticking works.");

        //--------------------------------------------------------
        // Test 2: set current time to 01:30:00
        //--------------------------------------------------------
        press_mode(); // NORMAL -> SET_TIME
        check_state(2'd1);

        press_inc();  // hour: 0 -> 1
        press_set();  // select minute

        for (i = 0; i < 30; i = i + 1) begin
            press_inc();
        end

        press_set();  // select second

        // second is currently 3, add 57 to wrap to 0
        for (i = 0; i < 57; i = i + 1) begin
            press_inc();
        end

        check_time(6'd1, 6'd30, 6'd0);
        $display("PASS: set time works.");

        //--------------------------------------------------------
        // Test 3: set alarm to 01:30
        //--------------------------------------------------------
        press_mode(); // SET_TIME -> SET_ALARM
        check_state(2'd2);

        press_inc();  // alarm hour: 0 -> 1
        press_set();  // select alarm minute

        for (i = 0; i < 30; i = i + 1) begin
            press_inc();
        end

        check_alarm_time(6'd1, 6'd30);
        $display("PASS: set alarm works.");

        //--------------------------------------------------------
        // Test 4: return to normal and trigger alarm
        //--------------------------------------------------------
        press_mode(); // SET_ALARM -> NORMAL
        check_state(2'd0);

        sw_alarm = 1'b1;

        // At this moment time is 01:30:00 and alarm is 01:30.
        pulse_tick();

        // LED is registered separately, wait one extra clock for LED update.
        @(posedge clk);
        #1;

        if (dut.alarm_active !== 1'b1) begin
            $display("FAIL: alarm_active did not become 1.");
            $finish;
        end

        if (LED !== 8'hFF) begin
            $display("FAIL: LED did not become FF. LED=%h", LED);
            $finish;
        end

        $display("PASS: alarm trigger works.");

        //--------------------------------------------------------
        // Test 5: buzzer PWM output
        //--------------------------------------------------------
        check_buzzer_toggles_when_alarm_active;

        //--------------------------------------------------------
        // Test 6: silence alarm
        //--------------------------------------------------------
        press_set();

        @(posedge clk);
        #1;

        if (dut.alarm_active !== 1'b0) begin
            $display("FAIL: alarm_active did not clear.");
            $finish;
        end

        if (LED !== 8'h00) begin
            $display("FAIL: LED did not clear. LED=%h", LED);
            $finish;
        end

        // Give buzzer one clock to settle low after disable
        @(posedge clk);
        #1;

        if (AUD_PWM !== 1'b0) begin
            $display("FAIL: AUD_PWM should return to 0 after alarm is silenced.");
            $finish;
        end

        $display("PASS: alarm silence works.");

        //--------------------------------------------------------
        // Test 7: seconds rollover 01:30:58 -> 01:31:01
        //--------------------------------------------------------
        press_mode(); // NORMAL -> SET_TIME
        check_state(2'd1);

        force dut.hour   = 6'd1;
        force dut.minute = 6'd30;
        force dut.second = 6'd58;
        @(posedge clk);
        #1;
        release dut.hour;
        release dut.minute;
        release dut.second;
        @(posedge clk);
        #1;

        press_mode(); // SET_TIME -> SET_ALARM
        press_mode(); // SET_ALARM -> NORMAL
        check_state(2'd0);

        sw_alarm = 1'b0;

        pulse_tick(); // 01:30:58 -> 01:30:59
        check_time(6'd1, 6'd30, 6'd59);

        pulse_tick(); // 01:30:59 -> 01:31:00
        check_time(6'd1, 6'd31, 6'd0);

        pulse_tick(); // 01:31:00 -> 01:31:01
        check_time(6'd1, 6'd31, 6'd1);

        $display("PASS: seconds/minutes rollover works.");

        //--------------------------------------------------------
        // Test 8: display anode sanity
        //--------------------------------------------------------
        repeat (20) @(posedge clk);
        #1;

        if (!valid_anode(AN)) begin
            $display("FAIL: invalid AN pattern. AN=%b", AN);
            $finish;
        end

        $display("PASS: display anode sanity check works.");

        //--------------------------------------------------------
        // Done
        //--------------------------------------------------------
        $display("========================================");
        $display("ALL TOP-LEVEL TESTS PASSED.");
        $display("========================================");

        $finish;
    end

endmodule
