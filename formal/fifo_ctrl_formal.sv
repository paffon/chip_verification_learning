// Formal wrapper for fifo_ctrl. clk/rst/wr/rd are the free formal inputs the
// solver may drive any way it likes; count/full/empty come from the DUT.
module fifo_ctrl_formal (
    input wire clk,
    input wire rst,
    input wire wr,
    input wire rd
);
    wire [2:0] count;
    wire       full;
    wire       empty;

    fifo_ctrl dut (
        .clk(clk), .rst(rst), .wr(wr), .rd(rd),
        .count(count), .full(full), .empty(empty)
    );

    // Start from a known, reset state (kills bogus cycle-0 failures).
    initial assume (rst);

    // SAFETY: occupancy never leaves the legal range 0..4.
    // Open Yosys supports IMMEDIATE assertions in procedural blocks, not full
    // concurrent SVA (`assert property (@...)`). So we sample on the clock with
    // an always block; `if (!rst)` is our hand-written `disable iff (rst)`.
    always @(posedge clk)
        if (!rst) assert (count <= 3'd4);

    // ENVIRONMENT CONTRACT: the producer/consumer never issue an illegal request.
    // We do NOT prove this here — we DEMAND it. It must be guaranteed elsewhere.
    always @(posedge clk) begin
        if (full)  assume (wr==0);  // no push into a full FIFO
        if (empty) assume (rd==0);  // no pop from an empty FIFO
    end

    // REACHABILITY / anti-vacuity: prove the FIFO can actually FILL.
    // If this is unreachable under our assumptions, the PASS above is hollow.
    always @(posedge clk)
        if (!rst) cover (full);
endmodule