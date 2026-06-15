// A 2-to-1 multiplexer: out follows a when sel=1, else follows b.
// Purely combinational — no clock. out tracks its inputs continuously.
module mux2 (
    input  wire a,
    input  wire b,
    input  wire sel,
    output wire out
);
    assign out = sel ? a : b;  // ternary: condition ? if_true : if_false
endmodule
