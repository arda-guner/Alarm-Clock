


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
