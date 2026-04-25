`timescale 1ns / 1ps


// alarm_clock_top.v
module alarm_clock_top (
    input  wire clk,
    input  wire ena,
    input  wire btn_set,
    input  wire btn_inc,
    input  wire btn_mode,
    input  wire sw_alarm,
    output reg  [31:0] digits,
    output reg  alarm_trig,
    output reg  [7:0] LED
);
    // ── Time registers ──────────────────────────────────────
    reg [5:0] HH, MM, SS;

    // ── Alarm registers ─────────────────────────────────────
    reg [5:0] AHH;
    reg [5:0] AMM;

    // ── FSM ─────────────────────────────────────────────────
    reg [1:0] FSM_state;
    reg [1:0] set_field;

    // ── Initial values ───────────────────────────────────────
    initial begin
        HH         = 0;
        MM         = 0;
        SS         = 0;
        AHH        = 0;
        AMM        = 0;
        FSM_state  = 0;
        set_field  = 0;
        alarm_trig = 0;
        LED        = 0;
        digits     = 0;
    end

    // ── FSM: mode button cycles through states ───────────────
    always @(posedge clk) begin
        if (btn_mode) begin
            FSM_state <= (FSM_state == 2'd2) ? 2'd0 : FSM_state + 1;
            set_field <= 0;
        end
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

    // ── Set-time mode ────────────────────────────────────────
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
        else if (btn_set)
            alarm_trig <= 0;
    end

    // ── LED driven by alarm_trig ─────────────────────────────
    always @(posedge clk) begin
        LED <= alarm_trig ? 8'hFF : 8'h00;
    end

    // ── BCD packing ──────────────────────────────────────────
    always @(*) begin
        digits[31:28] = HH / 10;
        digits[27:24] = HH % 10;
        digits[23:20] = MM / 10;
        digits[19:16] = MM % 10;
        digits[15:12] = SS / 10;
        digits[11:8]  = SS % 10;
        digits[7:0]   = 8'b0;
    end

endmodule
