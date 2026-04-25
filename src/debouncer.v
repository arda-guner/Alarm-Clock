
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
    localparam STABLE = 2_000_000; //we chamged it to 20ms second from 2_000_000
    reg [20:0] count; //we changed to 4 from 20
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
