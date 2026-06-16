// Synchronous FIFO controller, depth 4. Tracks occupancy only (no data payload) —
// every interesting property lives in this control logic. TRUSTING version:
// it blindly applies wr/rd and trusts the environment not to over/underflow.
module fifo_ctrl (
    input  wire       clk,
    input  wire       rst,    // synchronous reset -> empty
    input  wire       wr,     // push request this cycle
    input  wire       rd,     // pop request this cycle
    output reg  [2:0] count,  // occupancy, 0..4 (3 bits)
    output wire       full,
    output wire       empty
);
    // SECTION 1 — clocked update of count.
    // On a tick: if rst, go to 0; else apply your +wr / -rd rule.
    // Hint: Use <= (non-blocking — it's a flip-flop). count + wr - rd is legal Verilog: the 1-bit wr/rd are treated as 0/1 in the arithmetic.
    always @(posedge clk) begin
        if (rst) count <= 1'b0;
        else count <= count + wr - rd;
    end

    // SECTION 2 — the status flags (combinational, continuous assign).
    // full when count == 4, empty when count == 0.
    // Hint: `assign full = (count == 3'd4);` is the pattern — 3'd4 means "3-bit decimal 4." Do empty the same way.
    assign full  = (count == 3'd4);
    assign empty = (count == 3'd0);
endmodule