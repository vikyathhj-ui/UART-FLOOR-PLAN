// =============================================================================
// uart_tx.v — UART transmitter engine
//
// [ARCH]  Reads from external TX FIFO via rd/empty handshake
// [ARCH]  Builds complete frame: start + data + parity? + stop(s)
// [ARCH]  3-state FSM: IDLE → LOAD → SHIFT
// [POWER] Shift register and bit counter only toggle when tx_active
//         (ICG-friendly: synthesiser will infer clock enable on DFFs)
// [TIMING] Synchronous reset, fully registered outputs, no combo paths
// =============================================================================

`default_nettype none

module uart_tx #(
    parameter integer DATA_BITS   = 8,
    parameter integer STOP_BITS   = 1,
    parameter integer PARITY_MODE = 0,   // 0=none 1=odd 2=even
    parameter integer FRAME_BITS  = 10,
    parameter integer BIT_CNT_W   = 4
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  baud_en,       // 1-cycle pulse per baud period
    // FIFO interface
    input  wire [DATA_BITS-1:0]  fifo_data,
    input  wire                  fifo_empty,
    output reg                   fifo_rd,       // pop FIFO
    // Serial output
    output reg                   tx_out
);

    // -------------------------------------------------------------------------
    // FSM states
    // -------------------------------------------------------------------------
    localparam [1:0] IDLE  = 2'd0,
                     LOAD  = 2'd1,
                     SHIFT = 2'd2;

    reg [1:0]              state;
    reg [FRAME_BITS-1:0]   shift_reg;
    reg [BIT_CNT_W-1:0]    bit_cnt;
    reg                    tx_active;

    // -------------------------------------------------------------------------
    // Parity calculation (combinational — purely on fifo_data)
    // -------------------------------------------------------------------------
    function automatic [0:0] calc_parity;
        input [DATA_BITS-1:0] d;
        input integer mode;      // 1=odd, 2=even
        integer i;
        reg p;
        begin
            p = 1'b0;
            for (i = 0; i < DATA_BITS; i = i + 1)
                p = p ^ d[i];
            // even parity: XOR of all bits; odd parity: invert
            calc_parity = (mode == 1) ? ~p : p;
        end
    endfunction

    // -------------------------------------------------------------------------
    // Frame assembly helper
    // -------------------------------------------------------------------------
    function automatic [FRAME_BITS-1:0] build_frame;
        input [DATA_BITS-1:0] d;
        reg [FRAME_BITS-1:0] f;
        integer idx;
        begin
            f   = {FRAME_BITS{1'b1}};   // prefill with 1s (stop / idle level)
            f[0] = 1'b0;                // start bit
            for (idx = 0; idx < DATA_BITS; idx = idx + 1)
                f[1 + idx] = d[idx];
            if (PARITY_MODE != 0)
                f[1 + DATA_BITS] = calc_parity(d, PARITY_MODE);
            // Stop bit(s) already 1 from prefill
            build_frame = f;
        end
    endfunction

    // -------------------------------------------------------------------------
    // TX FSM
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            tx_out    <= 1'b1;
            tx_active <= 1'b0;
            bit_cnt   <= {BIT_CNT_W{1'b0}};
            shift_reg <= {FRAME_BITS{1'b1}};
            fifo_rd   <= 1'b0;
        end else begin
            fifo_rd <= 1'b0;    // default: deassert

            case (state)
                // -----------------------------------------------------------
                IDLE: begin
                    tx_out <= 1'b1;
                    if (!fifo_empty) begin
                        fifo_rd <= 1'b1;    // pop one byte from FIFO
                        state   <= LOAD;
                    end
                end

                // -----------------------------------------------------------
                // One-cycle pipeline stage: FIFO data is now registered.
                // This breaks the combinational path FIFO→shift_reg→tx_out.
                // [TIMING] Improves setup slack on the tx_out path.
                // -----------------------------------------------------------
                LOAD: begin
                    shift_reg <= build_frame(fifo_data);
                    bit_cnt   <= {BIT_CNT_W{1'b0}};
                    tx_active <= 1'b1;
                    state     <= SHIFT;
                end

                // -----------------------------------------------------------
                SHIFT: begin
                    if (baud_en) begin
                        // [POWER] shift_reg only toggles when baud_en=1
                        tx_out    <= shift_reg[0];
                        shift_reg <= {{1'b1}, shift_reg[FRAME_BITS-1:1]};
                        if (bit_cnt == BIT_CNT_W'(FRAME_BITS - 1)) begin
                            tx_active <= 1'b0;
                            state     <= IDLE;
                            bit_cnt   <= {BIT_CNT_W{1'b0}};
                        end else begin
                            bit_cnt   <= bit_cnt + 1'b1;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
`default_nettype wire
