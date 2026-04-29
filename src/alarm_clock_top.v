`timescale 1ns / 1ps

module alarm_clock_top (
    input  wire clk,       // W5  - 100MHz clock (E3 for Nexys A7-50T)
    input  wire rst,       // CPU RESET button
    input  wire raw_set,   // BTNC - set field
    input  wire raw_inc,   // BTNL - increment value  
    input  wire raw_mode,  // BTNR - change mode
    input  wire sw_alarm,  // SW0  - enable alarm
    output wire [7:0] AN,  // 7-seg anodes
    output wire [6:0] SEG, // 7-seg segments
    output reg  [7:0] LED  // LEDs show alarm
);

    // ── clk_en inside top-level ──────────────────────────────
    wire ena;
    clk_en u_clk_en (
        .clk(clk),
        .rst(rst),
        .ena(ena)
    );

    // ── Debouncers inside top-level ──────────────────────────
    wire btn_set, btn_inc, btn_mode;
    debouncer u_deb_set  (.clk(clk), .btn_in(raw_set),  .btn_out(btn_set));
    debouncer u_deb_inc  (.clk(clk), .btn_in(raw_inc),  .btn_out(btn_inc));
    debouncer u_deb_mode (.clk(clk), .btn_in(raw_mode), .btn_out(btn_mode));

    // ── Time and alarm registers ─────────────────────────────
    reg [5:0] HH, MM, SS;
    reg [5:0] AHH, AMM;
    reg [1:0] FSM_state, set_field;
    reg       alarm_trig;

    // ── FSM mode switching ───────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            FSM_state <= 0;
            set_field <= 0;
        end else if (btn_mode) begin
            FSM_state <= (FSM_state == 2'd2) ? 2'd0 : FSM_state + 1;
            set_field <= 0;
        end
    end

    // ── Timekeeping (normal mode only) ───────────────────────
    always @(posedge clk) begin
        if (rst) begin
            HH <= 0; MM <= 0; SS <= 0;
        end else if (ena && FSM_state == 2'd0) begin
            if (SS == 59) begin
                SS <= 0;
                if (MM == 59) begin
                    MM <= 0;
                    HH <= (HH == 23) ? 0 : HH + 1;
                end else MM <= MM + 1;
            end else SS <= SS + 1;
        end
    end

    // ── Set time mode (FSM state 1) ──────────────────────────
    always @(posedge clk) begin
        if (FSM_state == 2'd1) begin
            if (btn_set)
                set_field <= (set_field == 2) ? 0 : set_field + 1;
            if (btn_inc) begin
                case (set_field)
                    0: HH <= (HH == 23) ? 0 : HH + 1;
                    1: MM <= (MM == 59) ? 0 : MM + 1;
                    2: SS <= (SS == 59) ? 0 : SS + 1;
                endcase
            end
        end
    end

    // ── Set alarm mode (FSM state 2) ─────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            AHH <= 0; AMM <= 0;
        end else if (FSM_state == 2'd2) begin
            if (btn_set)
                set_field <= (set_field == 1) ? 0 : set_field + 1;
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
        if (rst)
            alarm_trig <= 0;
        else if (sw_alarm && HH == AHH && MM == AMM && SS == 0)
            alarm_trig <= 1;
        else if (btn_set)
            alarm_trig <= 0;
    end

    // ── LEDs show alarm ──────────────────────────────────────
    always @(posedge clk) begin
        if (rst) LED <= 0;
        else LED <= alarm_trig ? 8'hFF : 8'h00;
    end

    // ── BCD digits for display ───────────────────────────────
    wire [31:0] digits;
    assign digits[31:28] = HH / 10;
    assign digits[27:24] = HH % 10;
    assign digits[23:20] = MM / 10;
    assign digits[19:16] = MM % 10;
    assign digits[15:12] = SS / 10;
    assign digits[11: 8] = SS % 10;
    assign digits[ 7: 0] = 8'h00;

    // ── Display driver inside top-level ──────────────────────
    display_driver u_display (
        .clk(clk),
        .digits(digits),
        .AN(AN),
        .SEG(SEG)
    );

endmodule
