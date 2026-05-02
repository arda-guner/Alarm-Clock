// -----------------------------------------------------------
//! @brief Button debouncer
//! @version 2.1
//! @copyright (c) 2023-2026 Tomas Fryza, MIT license
//!
//! This module implements a debouncer for mechanical push-buttons
//! using a sampling technique with a shift register. The circuit
//! provides a stable debounced output and generates a one-clock-cycle
//! pulse when a button press is detected.
//
// Notes:
// - Synchronous design (rising edge of clk)
// - High-active synchronous reset
// - Input synchronization using two flip-flops
// - Debouncing via shift register and sampling
// - Configurable debounce time via clock enable
// - One-clock pulse output for button press
// -----------------------------------------------------------

`timescale 1ns/1ps

module debouncer (
    input  wire clk,    // Main clock
    input  wire rst,    // High-active synchronous reset
    input  wire pin,    // Raw push-button input (may contain bounce)
    output wire state,  // Debounced button level
    output wire press   // One-clock pulse generated when the button is pressed
    // output wire release
);

    //------------------------------------------------------------
    // Constants (internal)
    //------------------------------------------------------------
    localparam SHIFT_LEN = 4;  // Debounce history
    localparam MAX       = 2;  // Sampling period
                               // 2 for simulation
                               // 200_000 (2 ms) for implementation !!!

    //------------------------------------------------------------
    // Internal signals
    //------------------------------------------------------------
    wire ce_sample;
    reg sync0, sync1;
    reg [SHIFT_LEN-1:0] shift_reg;
    reg debounced, delayed;

    //------------------------------------------------------------
    // Clock enable instance
    //------------------------------------------------------------
    clk_en #(
        .MAX(MAX)
    ) clock_inst (
        .clk(clk),
        .rst(rst),
        .ce (ce_sample)
    );

    //------------------------------------------------------------
    // Debounce logic
    //------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            sync0     <= 0;
            sync1     <= 0;
            shift_reg <= 0;
            debounced <= 0;
            delayed   <= 0;
        end else begin
            // Input synchronizer
            sync1 <= sync0;
            sync0 <= pin;

            // Sample only when enable pulse occurs
            if (ce_sample) begin

                // Shift values to the left and load a new sample as LSB
                shift_reg <= {shift_reg[SHIFT_LEN-2:0], sync1};

                // Check if all bits are '1'
                if (&shift_reg)
                    debounced <= 1;
                // Check if all bits are '0'
                else if (~|shift_reg)
                    debounced <= 0;
            end

            // One clock delayed output for edge detector
            delayed <= debounced;
        end
    end

    //------------------------------------------------------------
    // Outputs
    //------------------------------------------------------------
    assign state = debounced;
    // One-clock pulse when button pressed
    assign press = debounced & ~delayed;

    // assign btn_release = ~debounced & delayed;

endmodule
