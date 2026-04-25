
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
