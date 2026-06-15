`timescale 1ns/1ps  // time unit = 1ns, precision = 1ps (for #delays and prints)

// Testbench for mux2. No ports: this module IS the outside world.
module mux2_tb;
    // Signals the TB *drives* must be 'reg' (they hold a value we set).
    reg  a, b, sel;
    // Signal the TB *observes* (driven by the DUT) stays a 'wire'.
    wire out;

    // Instantiate the Device Under Test. ".port(signal)" connects by name:
    // the DUT's port 'a' connects to our reg 'a', etc.
    mux2 dut (
        .a(a),
        .b(b),
        .sel(sel),
        .out(out)
    );

    // 'initial' runs once at time 0, top-to-bottom — the ONE place Verilog
    // behaves sequentially. Used only for sim/testbenches, not real hardware.
    initial begin
        a = 1; b = 0; sel = 0; #1;  // set inputs, then #1 = wait 1 time unit
        $display("t=%0t  a=%b b=%b sel=%b -> out=%b", $time, a, b, sel, out);

        sel = 1; #1;                // flip select; a and b unchanged
        $display("t=%0t  a=%b b=%b sel=%b -> out=%b", $time, a, b, sel, out);

        a = 0; b = 1; sel = 0; #1;  // swap values, select b again
        $display("t=%0t  a=%b b=%b sel=%b -> out=%b", $time, a, b, sel, out);

        $finish;                    // end the simulation
    end
endmodule
