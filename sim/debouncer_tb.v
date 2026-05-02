`timescale 1ns/1ps

module debounce_tb ();

    // Testbench signals
    reg  clk;
    reg  rst;
    reg  pin;
    wire state;
    wire press;

    // Instantiate Device Under Test (DUT)
    debounce dut (
        .clk  (clk),
        .rst  (rst),
        .pin  (pin),
        .state(state),
        .press(press)
    );

    // Clock generation: 10 ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Testbench stimulus
    initial begin
        // Initialize
        rst = 1;
        pin = 0;

        $display("\nStarting simulation...\n");
        $display("Reset phase");
        #50;
        rst = 0;

        #20;
        $display("Simulate bouncing (fast toggling)");
        pin = 1; #30;
        pin = 0; #20;
        pin = 1; #40;
        pin = 0; #30;
        pin = 1;  // Finally stable HIGH
        #300;

        $display("Simulate button on release");
        pin = 0; #30;
        pin = 1; #20;
        pin = 0; #40;
        pin = 1; #30;
        pin = 0;  // Finally stable LOW
        #300;

        // Finish simulation
        $display("\nSimulation finished\n");
        $finish;
 end

    // VCD waveform dump for GTKWave
    initial begin
        $dumpfile("debounce.vcd");
        $dumpvars(0, debounce_tb);
    end

endmodule
