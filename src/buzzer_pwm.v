`timescale 1ns/1ps

module buzzer_pwm #(
    parameter CLK_FREQ = 100_000_000,
    parameter BUZZ_FREQ = 2000
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  pwm
);

    localparam integer HALF_PERIOD = CLK_FREQ / (2 * BUZZ_FREQ);

    reg [$clog2(HALF_PERIOD)-1:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            cnt <= 0;
            pwm <= 1'b0;
        end
        else if (!enable) begin
            cnt <= 0;
            pwm <= 1'b0;
        end
        else begin
            if (cnt == HALF_PERIOD - 1) begin
                cnt <= 0;
                pwm <= ~pwm;
            end
            else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

endmodule 
