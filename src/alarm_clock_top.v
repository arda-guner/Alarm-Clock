`timescale 1ns/1ps

module alarm_clock_top (
    input  wire        CLK100MHZ,
    input  wire        BTNU,       // Reset
    input  wire        BTNC,       // Set / silence / next field
    input  wire        BTNL,       // Increment selected value
    input  wire        BTNR,       // Change mode
    input  wire [15:0] SW,         // SW[0] = alarm enable

    output wire [7:0]  AN,
    output wire [6:0]  SEG,
    output reg  [7:0]  LED,
    output wire        AUD_PWM,
    output wire        AUD_SD
);

    //------------------------------------------------------------
    // Board signal aliases
    //------------------------------------------------------------
    wire clk       = CLK100MHZ;
    wire rst       = BTNU;
    wire raw_set   = BTNC;
    wire raw_inc   = BTNL;
    wire raw_mode  = BTNR;
    wire sw_alarm  = SW[0];

    //------------------------------------------------------------
    // Named FSM states
    //------------------------------------------------------------
    localparam STATE_NORMAL    = 2'd0;
    localparam STATE_SET_TIME  = 2'd1;
    localparam STATE_SET_ALARM = 2'd2;

    localparam FIELD_HOUR   = 2'd0;
    localparam FIELD_MINUTE = 2'd1;
    localparam FIELD_SECOND = 2'd2;

    //------------------------------------------------------------
    // 1 Hz clock enable
    //------------------------------------------------------------
    wire ena_1hz;

    clk_en #(
        .MAX(100_000_000)
    ) clk_en_1hz_inst (
        .clk(clk),
        .rst(rst),
        .ce (ena_1hz)
    );

    //------------------------------------------------------------
    // Debounced button pulses
    //------------------------------------------------------------
    wire btn_set_state;
    wire btn_inc_state;
    wire btn_mode_state;

    wire btn_set_press;
    wire btn_inc_press;
    wire btn_mode_press;

    debounce #(
        .DEBOUNCE_MAX(200_000)
    ) debounce_set_inst (
        .clk  (clk),
        .rst  (rst),
        .pin  (raw_set),
        .state(btn_set_state),
        .press(btn_set_press)
    );

    debounce #(
        .DEBOUNCE_MAX(200_000)
    ) debounce_inc_inst (
        .clk  (clk),
        .rst  (rst),
        .pin  (raw_inc),
        .state(btn_inc_state),
        .press(btn_inc_press)
    );

    debounce #(
        .DEBOUNCE_MAX(200_000)
    ) debounce_mode_inst (
        .clk  (clk),
        .rst  (rst),
        .pin  (raw_mode),
        .state(btn_mode_state),
        .press(btn_mode_press)
    );

    //------------------------------------------------------------
    // Time and alarm registers
    //------------------------------------------------------------
    reg [5:0] hour;
    reg [5:0] minute;
    reg [5:0] second;

    reg [5:0] alarm_hour;
    reg [5:0] alarm_minute;

    reg [1:0] state;
    reg [1:0] selected_field;

    reg alarm_active;
    reg alarm_ack;

    wire alarm_match;

    assign alarm_match =
        sw_alarm &&
        (hour == alarm_hour) &&
        (minute == alarm_minute) &&
        (second == 6'd0);

    //------------------------------------------------------------
    // Main synchronous alarm clock logic
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state          <= STATE_NORMAL;
            selected_field <= FIELD_HOUR;

            hour           <= 6'd0;
            minute         <= 6'd0;
            second         <= 6'd0;

            alarm_hour     <= 6'd0;
            alarm_minute   <= 6'd0;

            alarm_active   <= 1'b0;
            alarm_ack      <= 1'b0;
        end
        else begin

            //----------------------------------------------------
            // Clear alarm acknowledgement when time no longer matches
            //----------------------------------------------------
            if (!alarm_match)
                alarm_ack <= 1'b0;

            //----------------------------------------------------
            // Silence alarm
            //----------------------------------------------------
            if (alarm_active && btn_set_press) begin
                alarm_active <= 1'b0;
                alarm_ack    <= 1'b1;
            end

            //----------------------------------------------------
            // Mode switching
            //----------------------------------------------------
            else if (btn_mode_press) begin
                selected_field <= FIELD_HOUR;

                case (state)
                    STATE_NORMAL:
                        state <= STATE_SET_TIME;

                    STATE_SET_TIME:
                        state <= STATE_SET_ALARM;

                    STATE_SET_ALARM:
                        state <= STATE_NORMAL;

                    default:
                        state <= STATE_NORMAL;
                endcase
            end

            //----------------------------------------------------
            // State behavior
            //----------------------------------------------------
            else begin
                case (state)

                    //------------------------------------------------
                    // Normal clock operation
                    //------------------------------------------------
                    STATE_NORMAL: begin
                        if (ena_1hz) begin
                            if (second == 6'd59) begin
                                second <= 6'd0;

                                if (minute == 6'd59) begin
                                    minute <= 6'd0;

                                    if (hour == 6'd23)
                                        hour <= 6'd0;
                                    else
                                        hour <= hour + 1'b1;
                                end
                                else begin
                                    minute <= minute + 1'b1;
                                end
                            end
                            else begin
                                second <= second + 1'b1;
                            end
                        end

                        if (alarm_match && !alarm_ack)
                            alarm_active <= 1'b1;
                    end

                    //------------------------------------------------
                    // Set current time: HH, MM, SS
                    //------------------------------------------------
                    STATE_SET_TIME: begin
                        if (btn_set_press) begin
                            if (selected_field == FIELD_SECOND)
                                selected_field <= FIELD_HOUR;
                            else
                                selected_field <= selected_field + 1'b1;
                        end

                        else if (btn_inc_press) begin
                            case (selected_field)
                                FIELD_HOUR: begin
                                    if (hour == 6'd23)
                                        hour <= 6'd0;
                                    else
                                        hour <= hour + 1'b1;
                                end

                                FIELD_MINUTE: begin
                                    if (minute == 6'd59)
                                        minute <= 6'd0;
                                    else
                                        minute <= minute + 1'b1;
                                end

                                FIELD_SECOND: begin
                                    if (second == 6'd59)
                                        second <= 6'd0;
                                    else
                                        second <= second + 1'b1;
                                end

                                default: begin
                                    selected_field <= FIELD_HOUR;
                                end
                            endcase
                        end
                    end

                    //------------------------------------------------
                    // Set alarm: HH, MM
                    //------------------------------------------------
                    STATE_SET_ALARM: begin
                        if (btn_set_press) begin
                            if (selected_field == FIELD_MINUTE)
                                selected_field <= FIELD_HOUR;
                            else
                                selected_field <= FIELD_MINUTE;
                        end

                        else if (btn_inc_press) begin
                            case (selected_field)
                                FIELD_HOUR: begin
                                    if (alarm_hour == 6'd23)
                                        alarm_hour <= 6'd0;
                                    else
                                        alarm_hour <= alarm_hour + 1'b1;
                                end

                                FIELD_MINUTE: begin
                                    if (alarm_minute == 6'd59)
                                        alarm_minute <= 6'd0;
                                    else
                                        alarm_minute <= alarm_minute + 1'b1;
                                end

                                default: begin
                                    selected_field <= FIELD_HOUR;
                                end
                            endcase
                        end
                    end

                    default: begin
                        state <= STATE_NORMAL;
                    end

                endcase
            end
        end
    end

    //------------------------------------------------------------
    // Alarm LEDs
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (rst)
            LED <= 8'h00;
        else
            LED <= alarm_active ? 8'hFF : 8'h00;
    end

    //------------------------------------------------------------
    // Buzzer / audio PWM output
    //------------------------------------------------------------
    buzzer_pwm #(
        .CLK_FREQ(100_000_000),
        .BUZZ_FREQ(2000)
    ) buzzer_inst (
        .clk   (clk),
        .rst   (rst),
        .enable(alarm_active),
        .pwm   (AUD_PWM)
    );

    // Enable onboard audio circuit
    assign AUD_SD = 1'b1;

    //------------------------------------------------------------
    // BCD digits for HH:MM:SS
    // Display format: HH MM SS 00
    //------------------------------------------------------------
    wire [31:0] digits;

    assign digits[31:28] = hour / 10;
    assign digits[27:24] = hour % 10;

    assign digits[23:20] = minute / 10;
    assign digits[19:16] = minute % 10;

    assign digits[15:12] = second / 10;
    assign digits[11: 8] = second % 10;

    assign digits[ 7: 4] = 4'd0;
    assign digits[ 3: 0] = 4'd0;

    //------------------------------------------------------------
    // 8-digit display driver
    //------------------------------------------------------------
    display_driver_8digit #(
        .REFRESH_MAX(100_000)
    ) display_inst (
        .clk   (clk),
        .rst   (rst),
        .digits(digits),
        .seg   (SEG),
        .an    (AN)
    );

endmodule
