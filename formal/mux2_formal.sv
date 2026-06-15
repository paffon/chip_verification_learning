// Formal wrapper for mux2. It instantiates the real module and states its
// contract as immediate assertions. `sby` will check these for EVERY possible
// value of a, b, sel at once — not a sampled few like simulation.
module mux2_formal (
    input wire a,
    input wire b,
    input wire sel
);
    wire out;

    mux2 dut (
        .a(a),
        .b(b),
        .sel(sel),
        .out(out)
    );

    // The mux's contract, written independently of how mux2 implements it:
    //   when sel=1, out must equal a; when sel=0, out must equal b.
    // `always @*` re-checks whenever any input changes; in formal this means
    // "must hold for all input combinations".
    always @* begin
        if (sel) assert (out == a);
        else     assert (out == b);
    end
endmodule
