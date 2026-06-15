// A 1-bit inverter (NOT gate): out is always the logical opposite of in.
// Purely combinational — no clock, no memory. out tracks in continuously.
module inverter (
    input  wire in,
    output wire out
);
    assign out = ~in;  // continuous assignment: a permanent wire connection
endmodule
