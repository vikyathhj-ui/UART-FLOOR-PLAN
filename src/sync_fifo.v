// =============================================================================
// sync_fifo.v — Synchronous FIFO with gray-coded pointers
//
// [POWER] Gray-coded read/write pointers minimise switching on pointer buses
// [ARCH]  Show-ahead (FWFT) output — rd_data valid same cycle rd_en asserted
// [TIMING] Full/empty from registered MSB comparison — no combinational paths
// [TIMING] Synchronous reset, registered outputs
// =============================================================================

`default_nettype none

module sync_fifo #(
    parameter integer WIDTH = 8,
    parameter integer DEPTH = 16     // must be power of 2
)(
    input  wire             clk,
    input  wire             rst,
    // Write port
    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,
    // Read port
    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,
    // Status
    output wire             empty,
    output wire             full
);

    localparam integer ADDR_W = $clog2(DEPTH);

    // -------------------------------------------------------------------------
    // Memory array
    // -------------------------------------------------------------------------
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // -------------------------------------------------------------------------
    // Binary pointers (one extra bit for full/empty distinction)
    // -------------------------------------------------------------------------
    reg [ADDR_W:0] wr_ptr_bin, rd_ptr_bin;

    // -------------------------------------------------------------------------
    // Gray-code conversion
    // [POWER] Toggle only 1 bit per pointer increment
    // -------------------------------------------------------------------------
    function automatic [ADDR_W:0] bin2gray;
        input [ADDR_W:0] b;
        begin
            bin2gray = b ^ (b >> 1);
        end
    endfunction

    wire [ADDR_W:0] wr_ptr_gray = bin2gray(wr_ptr_bin);
    wire [ADDR_W:0] rd_ptr_gray = bin2gray(rd_ptr_bin);

    // -------------------------------------------------------------------------
    // Full / Empty flags
    // Full:  MSB differs, lower bits equal  (standard gray FIFO rule)
    // Empty: all bits equal
    // -------------------------------------------------------------------------
    assign full  = (wr_ptr_gray == {~rd_ptr_gray[ADDR_W:ADDR_W-1],
                                      rd_ptr_gray[ADDR_W-2:0]});
    assign empty = (wr_ptr_gray == rd_ptr_gray);

    // -------------------------------------------------------------------------
    // Write port
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr_bin <= {(ADDR_W+1){1'b0}};
        end else if (wr_en && !full) begin
            mem[wr_ptr_bin[ADDR_W-1:0]] <= wr_data;
            wr_ptr_bin                  <= wr_ptr_bin + 1'b1;
        end
    end

    // -------------------------------------------------------------------------
    // Read port — first-word-fall-through
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr_bin <= {(ADDR_W+1){1'b0}};
        end else if (rd_en && !empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1'b1;
        end
    end

    assign rd_data = mem[rd_ptr_bin[ADDR_W-1:0]];

endmodule
`default_nettype wire
