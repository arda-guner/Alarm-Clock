# Alarm Clock — Lab 1: Architecture

**Course:** Digital Electronics  
**Board:** Nexys A7-50T (Artix-7 XC7A50T)  
**Tool:** Vivado 2025.2  
**Language:** Verilog  

---

## Project Description

Implementation of a digital alarm clock on the Nexys A7-50T FPGA board.  
The clock displays the current time in **HH:MM:SS** format on the 8-digit 7-segment display.  
The user can set the current time and an alarm time using push buttons.  
When the alarm time is reached, the buzzer sounds and the LEDs light up.

---

## Team Members

 Arda Guner & Zay Yar Naung 

---

## Module Hierarchy (Block Diagram)

![Block_diagram](images/Block_diagram.png)

### Top-Level Inputs / Outputs

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `CLK100MHZ` | in | 1b | 100 MHz system clock (pin E3) |
| `BTNU` | in | 1b | Increment button |
| `BTND` | in | 1b | Confirm / alarm on-off button |
| `BTNC` | in | 1b | Mode select button |
| `SW[0]` | in | 1b | Alarm enable switch |
| `AN[7:0]` | out | 8b | 7-segment anodes (active LOW) |
| `SEG[6:0]` | out | 7b | 7-segment cathodes a–g (active LOW) |
| `AUD_PWM` | out | 1b | Buzzer PWM output |
| `LED[7:0]` | out | 8b | Alarm active indicator |

### Internal Signals

| Signal | Width | Description |
|--------|-------|-------------|
| `ena` | 1b | 1 Hz clock enable from `clk_en` |
| `btn_inc`, `btn_set`, `btn_mode` | 1b each | Debounced button outputs |
| `HH[5:0]`, `MM[5:0]`, `SS[5:0]` | 6b each | Current time registers |
| `AHH[4:0]`, `AMM[5:0]` | 5b, 6b | Alarm time registers |
| `digits[31:0]` | 32b | BCD digits fed to display driver |
| `alarm_trig` | 1b | High when current time == alarm time |
| `FSM_state[1:0]` | 2b | 0=normal, 1=set time, 2=set alarm |

---

## Pin Constraints (XDC)

Key pins used from `Nexys-A7-50T-Master.xdc`:

```tcl
# Clock
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
create_clock -add -name sys_clk_pin -period 10.00 [get_ports {CLK100MHZ}];

# Buttons
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 } [get_ports { BTNU }];
set_property -dict { PACKAGE_PIN P18 IOSTANDARD LVCMOS33 } [get_ports { BTND }];
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 } [get_ports { BTNC }];

# Switch
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { SW[0] }];

# 7-segment anodes
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports { AN[0] }];
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports { AN[1] }];
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { AN[2] }];
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports { AN[3] }];
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { AN[4] }];
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { AN[5] }];
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { AN[6] }];
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { AN[7] }];

# 7-segment cathodes
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { SEG[0] }]; # CA
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports { SEG[1] }]; # CB
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { SEG[2] }]; # CC
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports { SEG[3] }]; # CD
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { SEG[4] }]; # CE
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { SEG[5] }]; # CF
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { SEG[6] }]; # CG

# Buzzer
set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 } [get_ports { AUD_PWM }];
set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33 } [get_ports { AUD_SD  }];

# LEDs
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { LED[0] }];
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports { LED[1] }];
```

---



## Repository Structure

```
alarm_clock/
├── README.md
├── images/
│   └── Block_Diagram.png
│   └──alarm_clock_top_simulation.png
│   └──clk_en_tb.png
│   └──debouncer_simulation.png
│   └──display_driver.png
├── src/
│   └── alarm_clock_top.v
│   └── clk_en.v
│   └── debouncer.v
│   └── display_driver.v
│   └── Block_Diagram.png
├── sim/
│   └── alarm_clock_top.v
│   └── clk_en_tb.v
│   └── debouncer_tb.v
│   └──display_driver.v
```

---
## Design sources and testbenches
 1) clk_en.v
```verilog

// clk_en.v
// Generates a 1-cycle-wide enable pulse at 1Hz from 100MHz clock
module clk_en (
    input  wire clk,
    input  wire rst,
    output reg  ena
);
    // 100MHz / 100_000_000 = 1Hz
    localparam MAX = 100_000_000 - 1; //9 is simulation value, the one which must be is this -> 100_000_000 - 1
    reg [26:0] count;   //3 is simulation value, the one which must be is this -> 26

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            ena   <= 0;
        end else if (count == MAX) begin
            count <= 0;
            ena   <= 1;
        end else begin
            count <= count + 1;
            ena   <= 0;
        end
    end

endmodule
```
clk_en_tb.v
```verilog
// clk_en_tb.v
`timescale 1ns/1ps
module clk_en_tb;
    reg clk, rst;
    wire ena;

    // Use fast MAX in clk_en (change localparam MAX to 9 for simulation)
    clk_en uut (.clk(clk), .rst(rst), .ena(ena));

    initial clk = 0;
    always #5 clk = ~clk;   // 100MHz

    initial begin
        rst = 1; #20;
        rst = 0;
        #200;               // the value was 200 but we made it 500 to extend the duration of the simulation
        $finish;
    end

    initial $monitor("t=%0t  ena=%b", $time, ena);
endmodule
```
![Block_diagram](images/clk_en_tb.png)
 2) debouncer.v
```verilog
// debouncer.v
// Synchronizes and debounces a mechanical button
module debouncer (
    input  wire clk,
    input  wire btn_in,
    output reg  btn_out
);
    // Two-stage synchronizer to avoid metastability
    reg sync0, sync1;
    // Counter for stable detection (~20ms @ 100MHz = 2_000_000 cycles)
    localparam STABLE = 2_000_000;
    reg [20:0] count;
    reg btn_prev;

    always @(posedge clk) begin
        // Synchronize
        sync0 <= btn_in;
        sync1 <= sync0;

        btn_out <= 0;  // default: no pulse

        if (sync1 != btn_prev) begin
            count    <= 0;
            btn_prev <= sync1;
        end else if (count < STABLE) begin
            count <= count + 1;
        end else if (sync1 == 1'b1) begin
            btn_out <= 1;  // stable HIGH detected → emit single pulse
            count   <= 0;
        end
    end
endmodule
```

debouncer_tb.v
```verilog
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
```
![Block_diagram](images/debouncer_simulation.png)
3) alarm_clock_top.v
```verilog
// alarm_clock_top.v
module alarm_clock_top (
    input  wire clk,
    input  wire ena,         // 1Hz pulse from clk_en
    input  wire btn_set,     // BTND: confirm / alarm on-off
    input  wire btn_inc,     // BTNU: increment
    input  wire btn_mode,    // BTNC: mode select
    input  wire sw_alarm,    // SW[0]: alarm enable
    output reg  [31:0] digits,   // BCD to display driver
    output reg  alarm_trig
);
    // ── Time registers ──────────────────────────────────────
    reg [5:0] HH, MM, SS;   // Hours, Minutes, Seconds (0-23/59/59)

    // ── Alarm registers ─────────────────────────────────────
    reg [4:0] AHH;           // Alarm hours  (5b: 0-23)
    reg [5:0] AMM;           // Alarm minutes (6b: 0-59)

    // ── FSM ─────────────────────────────────────────────────
    // 0=normal, 1=set time, 2=set alarm
    reg [1:0] FSM_state;
    reg [1:0] set_field;     // which field is being edited (HH/MM/SS or AHH/AMM)

    // ── FSM: mode button cycles through states ───────────────
    always @(posedge clk) begin
        if (btn_mode)
            FSM_state <= (FSM_state == 2'd2) ? 2'd0 : FSM_state + 1;
    end

    // ── Clock counting (only in normal mode) ─────────────────
    always @(posedge clk) begin
        if (ena && FSM_state == 2'd0) begin
            if (SS == 6'd59) begin
                SS <= 0;
                if (MM == 6'd59) begin
                    MM <= 0;
                    HH <= (HH == 6'd23) ? 0 : HH + 1;
                end else MM <= MM + 1;
            end else SS <= SS + 1;
        end
    end

    // ── Set-time mode: btn_inc increments, btn_set changes field ─
    always @(posedge clk) begin
        if (FSM_state == 2'd1) begin
            if (btn_set) set_field <= (set_field == 2) ? 0 : set_field + 1;
            if (btn_inc) begin
                case (set_field)
                    0: HH <= (HH == 23) ? 0 : HH + 1;
                    1: MM <= (MM == 59) ? 0 : MM + 1;
                    2: SS <= (SS == 59) ? 0 : SS + 1;
                endcase
            end
        end
    end

    // ── Set-alarm mode ───────────────────────────────────────
    always @(posedge clk) begin
        if (FSM_state == 2'd2) begin
            if (btn_set) set_field <= (set_field == 1) ? 0 : set_field + 1;
            if (btn_inc) begin
                case (set_field)
                    0: AHH <= (AHH == 23) ? 0 : AHH + 1;
                    1: AMM <= (AMM == 59) ? 0 : AMM + 1;
                endcase
            end
        end
    end

    // ── Alarm trigger ────────────────────────────────────────
    always @(posedge clk) begin
        if (sw_alarm && HH == AHH && MM == AMM && SS == 0)
            alarm_trig <= 1;
        else if (btn_set)   // btn_set silences alarm
            alarm_trig <= 0;
    end

    // ── BCD packing for display driver ──────────────────────
    // digits[31:24]=HH, digits[23:16]=MM, digits[15:8]=SS, digits[7:0]=unused
    always @(*) begin
        digits[31:28] = HH / 10;
        digits[27:24] = HH % 10;
        digits[23:20] = MM / 10;
        digits[19:16] = MM % 10;
        digits[15:12] = SS / 10;
        digits[11:8]  = SS % 10;
        digits[7:0]   = 8'b0;
    end
Endmodule
```
alarm_clock_top_tb.v
```verilog
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
    always #5 clk = ~clk; // 100MHz

    // Task: send one clock-wide pulse
    task pulse(input reg sig);  // call as: pulse(btn_inc)
        // Since tasks can't take inout, use direct signal instead
    endtask

    // Task: press btn_inc N times
    task press_inc;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                btn_inc = 1; @(posedge clk); #1;
                btn_inc = 0; @(posedge clk); #1;
                #20;
            end
        end
    endtask

    // Task: press btn_set once
    task press_set;
        begin
            btn_set = 1; @(posedge clk); #1;
            btn_set = 0; @(posedge clk); #1;
            #20;
        end
    endtask

    // Task: press btn_mode once
    task press_mode;
        begin
            btn_mode = 1; @(posedge clk); #1;
            btn_mode = 0; @(posedge clk); #1;
            #20;
        end
    endtask

    // Task: tick ena N times (simulates N seconds)
    task tick;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                ena = 1; @(posedge clk); #1;
                ena = 0; @(posedge clk); #1;
                #10;
            end
        end
    endtask

    initial begin
        $dumpfile("alarm_clock_top_tb.vcd");
        $dumpvars(0, alarm_clock_top_tb);

        // Init
        btn_set=0; btn_inc=0; btn_mode=0; sw_alarm=0; ena=0;
        #50;

        // ── Test 1: Normal clock ticking ──────────────────────
        $display("--- Test 1: Clock ticks 5 seconds ---");
        tick(5);
        $display("digits=%h (expect SS=5)", digits);

        // ── Test 2: Set time to 01:30:00 ──────────────────────
        $display("--- Test 2: Set time HH=1, MM=30, SS=0 ---");
        press_mode; // go to set-time mode (FSM=1)

        // Increment HH to 1
        press_inc(1);
        $display("HH should be 1, digits=%h", digits);

        // Move to MM field
        press_set;
        press_inc(30);
        $display("MM should be 30, digits=%h", digits);

        // Move to SS field
        press_set;
        // leave SS=0

        // Back to normal mode
        press_mode; press_mode; // FSM: 1->2->0
        $display("Time set. digits=%h", digits);

        // ── Test 3: Set alarm to 01:30 ────────────────────────
        $display("--- Test 3: Set alarm HH=1, MM=30 ---");
        press_mode; press_mode; // FSM: 0->1->2 (set alarm)

        press_inc(1);           // AHH = 1
        press_set;              // move to AMM field
        press_inc(30);          // AMM = 30
        press_mode; press_mode; // back to normal

        // ── Test 4: Enable alarm and wait for trigger ─────────
        $display("--- Test 4: Enable alarm, wait for trigger ---");
        sw_alarm = 1;

        // Tick remaining seconds to reach alarm time (SS is at 0 already)
        // Time is 01:30:00, alarm is 01:30 → should trigger immediately on next ena
        tick(1);
        $display("alarm_trig=%b LED=%h (expect 1, FF)", alarm_trig, LED);

        // ── Test 5: Silence alarm with btn_set ────────────────
        $display("--- Test 5: Silence alarm ---");
        press_set;
        #20;
        $display("alarm_trig=%b LED=%h (expect 0, 00)", alarm_trig, LED);

        // ── Test 6: Clock rollover SS 59→0 ───────────────────
        $display("--- Test 6: SS rollover ---");
        // Set time to 00:00:58
        press_mode;             // FSM=1
        press_set; press_set;   // skip HH, MM → go to SS
        press_inc(58);
        press_mode; press_mode; // back to normal
        tick(3);                // tick 3s: 58→59→0→1
        $display("digits=%h (expect SS~1, MM incremented)", digits);

        $display("--- All tests done ---");
        $finish;
    end

    initial $monitor("t=%0t FSM=? ena=%b | HH=%h MM=%h SS=%h | alarm=%b LED=%h",
                     $time, ena,
                     digits[31:24], digits[23:16], digits[15:8],
                     alarm_trig, LED);
endmodule
```
![Block_diagram](images/alarm_clock_top_simulation.png)
4) display_driver.v
```verilog
// display_driver.v
// Multiplexes 8 7-segment digits (Nexys A7 active-LOW anodes/cathodes)
module display_driver (
    input  wire        clk,
    input  wire [31:0] digits,    // 8 x 4-bit BCD digits
    output reg  [7:0]  AN,        // active LOW anodes
    output reg  [6:0]  SEG        // active LOW segments (a-g)
);
    // Refresh ~1kHz per digit: 100MHz / 100000 = 1000Hz, /8 = 125Hz/digit
    reg [16:0] refresh_count;
    reg [2:0]  digit_sel;

    always @(posedge clk)
        refresh_count <= refresh_count + 1;

    always @(posedge clk)
        if (refresh_count == 0) digit_sel <= digit_sel + 1;

    // Anode select (active LOW, one-hot LOW)
    always @(*) begin
        AN = 8'b11111111;
        AN[digit_sel] = 1'b0;
    end

    // Pick BCD nibble for selected digit
    reg [3:0] bcd;
    always @(*) begin
        case (digit_sel)
            3'd7: bcd = digits[31:28];
            3'd6: bcd = digits[27:24];
            3'd5: bcd = digits[23:20];
            3'd4: bcd = digits[19:16];
            3'd3: bcd = digits[15:12];
            3'd2: bcd = digits[11:8];
            3'd1: bcd = digits[7:4];
            3'd0: bcd = digits[3:0];
        endcase
    end

    // 7-segment decoder (active LOW: SEG=gfedcba)
    always @(*) begin
        case (bcd)
            4'd0: SEG = 7'b1000000;
            4'd1: SEG = 7'b1111001;
            4'd2: SEG = 7'b0100100;
            4'd3: SEG = 7'b0110000;
            4'd4: SEG = 7'b0011001;
            4'd5: SEG = 7'b0010010;
            4'd6: SEG = 7'b0000010;
            4'd7: SEG = 7'b1111000;
            4'd8: SEG = 7'b0000000;
            4'd9: SEG = 7'b0010000;
            default: SEG = 7'b1111111; // blank
        endcase
    end
endmodule
   ```
display_driver_tb
   ```verilog
`timescale 1ns/1ps
module display_driver_tb;
    reg        clk;
    reg [31:0] digits;
    wire [7:0] AN;
    wire [6:0] SEG;

    display_driver uut (.clk(clk), .digits(digits), .AN(AN), .SEG(SEG));

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // Task: decode SEG back to digit for checking
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
            default:    seg_to_bcd = 4'hF; // blank/unknown
        endcase
    endfunction

    integer i;

    initial begin
        $dumpfile("display_driver_tb.vcd");
        $dumpvars(0, display_driver_tb);

        // ── Test 1: Display 12:34:56 → digits = 12_34_56_00 ──
        $display("--- Test 1: Show 12:34:56 ---");
        // BCD packed: HH=12→1,2  MM=34→3,4  SS=56→5,6  unused=0
        digits = {4'd1,4'd2, 4'd3,4'd4, 4'd5,4'd6, 8'h00};

        // Run enough clocks to cycle through all 8 digit positions
        // refresh_count overflows at 2^17=131072 cycles per digit step
        // For sim use small refresh_count (change to 4-bit in driver)
        // Here we just run many cycles and sample
        repeat(200) @(posedge clk);

        $display("AN=%b SEG=%b decoded=%0d", AN, SEG, seg_to_bcd(SEG));

        // ── Test 2: All zeros 00:00:00 ────────────────────────
        $display("--- Test 2: Show 00:00:00 ---");
        digits = 32'h00000000;
        repeat(200) @(posedge clk);
        $display("AN=%b SEG=%b decoded=%0d", AN, SEG, seg_to_bcd(SEG));

        // ── Test 3: All nines 99:99:99 (boundary) ─────────────
        $display("--- Test 3: Show 99:99:99 ---");
        digits = {4'd9,4'd9, 4'd9,4'd9, 4'd9,4'd9, 8'h00};
        repeat(200) @(posedge clk);
        $display("AN=%b SEG=%b decoded=%0d", AN, SEG, seg_to_bcd(SEG));

        // ── Test 4: Verify only one anode active at a time ────
        $display("--- Test 4: Only 1 anode LOW at a time ---");
        repeat(20) @(posedge clk);
        begin
            // AN should have exactly one 0 bit
            if ($countones(~AN) == 1)
                $display("PASS: AN=%b (one anode active)", AN);
            else
                $display("FAIL: AN=%b (multiple anodes!)", AN);
        end

        // ── Test 5: Cycle through all 8 digit positions ───────
        $display("--- Test 5: All 8 digit positions cycling ---");
        digits = {4'd1,4'd2,4'd3,4'd4,4'd5,4'd6,4'd7,4'd8};
        for (i = 0; i < 8; i = i + 1) begin
            repeat(50) @(posedge clk);
            $display("AN=%b  SEG=%b  decoded=%0d", AN, SEG, seg_to_bcd(SEG));
        end

        $display("--- All display tests done ---");
        $finish;
    end
endmodule
```
![Block_diagram](images/display_driver_simulation.png)

