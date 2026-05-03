`timescale 1ns/1ps

module display_driver_8digit #(
    parameter REFRESH_MAX = 100_000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] digits,
    output wire [6:0]  seg,
    output reg  [7:0]  an
);

    wire refresh_ce;

    clk_en #(
        .MAX(REFRESH_MAX)
    ) refresh_clk_en_inst (
        .clk(clk),
        .rst(rst),
        .ce (refresh_ce)
    );

    reg [2:0] digit_sel;

    always @(posedge clk) begin
        if (rst)
            digit_sel <= 3'd0;
        else if (refresh_ce)
            digit_sel <= digit_sel + 1'b1;
    end

    reg [3:0] digit_value;

    always @(*) begin
        case (digit_sel)
            3'd7: digit_value = digits[31:28];
            3'd6: digit_value = digits[27:24];
            3'd5: digit_value = digits[23:20];
            3'd4: digit_value = digits[19:16];
            3'd3: digit_value = digits[15:12];
            3'd2: digit_value = digits[11:8];
            3'd1: digit_value = digits[7:4];
            3'd0: digit_value = digits[3:0];
            default: digit_value = 4'd0;
        endcase
    end

    bin2seg decoder_inst (
        .bin(digit_value),
        .seg(seg)
    );

    always @(*) begin
        an = 8'b1111_1111;
        an[digit_sel] = 1'b0;
    end

endmodule
