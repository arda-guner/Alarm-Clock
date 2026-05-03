// -----------------------------------------------------------
//! @brief Clock enable generator (single-cycle pulse)
//! @version 2.1
//! @copyright (c) 2019-2026 Tomas Fryza, MIT license
//!
//! This design generates a single-clock-cycle enable pulse
//! every MAX clock cycles.
//
// Notes:
// - Synchronous design (positive edge of clk)
// - High-active synchronous reset
// - Output pulse width = one clock period
// - MAX must be greater than 0
// -----------------------------------------------------------

`timescale 1ns/1ps

module clk_en #(
    // #() after a module name introduces a parameter list
    parameter MAX = 4  //! Number of clock cycles between pulses
)(
    input  wire clk,  //! Main clock
    input  wire rst,  //! High-active synchronous reset
    output reg  ce    //! One-clock-cycle enable pulse
);

    // Internal counter
    reg [$clog2(MAX)-1:0] cnt;
    // $clog2(MAX) -- Ceiling of log2(x) returns the minimum
    // number of bits required

    //! Clocked, sequential process, triggered when `clk`
    //! rises from 0 to 1 (positive edge of a signal)
    always @(posedge clk) begin
        if (rst) begin
            ce  <= 1'b0;  // Reset output
            cnt <= 0;     // Reset internal counter
        end
        else if (cnt == MAX-1) begin
            ce  <= 1'b1;  // Generate one-cycle pulse
            cnt <= 0;     // Reset internal counter
        end
        else begin
            ce   <= 1'b0;        // Clear output
            cnt  <= cnt + 1'b1;  // Increment internal counter
        end
    end

endmodule
