module uart (
    input        clk,
    input        rst,
    // TX interface
    input  [7:0] tx_data,
    input        tx_valid,
    output reg   tx_ready,
    output reg   tx_out,
    // RX interface
    output reg [7:0] rx_data,
    output reg       rx_valid,
    input            rx_in
);

parameter CLKS_PER_BIT = 868; // 100MHz / 115200 baud

// TX Logic
reg [9:0]  tx_shift;
reg [9:0]  tx_clk_count;
reg [3:0]  tx_bit_count;
reg        tx_active;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        tx_out       <= 1;
        tx_ready     <= 1;
        tx_active    <= 0;
        tx_clk_count <= 0;
        tx_bit_count <= 0;
    end else begin
        if (tx_valid && tx_ready) begin
            tx_shift     <= {1'b1, tx_data, 1'b0};
            tx_active    <= 1;
            tx_ready     <= 0;
            tx_clk_count <= 0;
            tx_bit_count <= 0;
        end else if (tx_active) begin
            if (tx_clk_count < CLKS_PER_BIT - 1) begin
                tx_clk_count <= tx_clk_count + 1;
            end else begin
                tx_clk_count <= 0;
                tx_out       <= tx_shift[0];
                tx_shift     <= {1'b0, tx_shift[9:1]};
                tx_bit_count <= tx_bit_count + 1;
                if (tx_bit_count == 9) begin
                    tx_active <= 0;
                    tx_ready  <= 1;
                end
            end
        end
    end
end

// RX Logic
reg [9:0]  rx_clk_count;
reg [3:0]  rx_bit_count;
reg [7:0]  rx_shift;
reg        rx_active;
reg        rx_in_sync;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        rx_valid     <= 0;
        rx_active    <= 0;
        rx_clk_count <= 0;
        rx_bit_count <= 0;
        rx_in_sync   <= 1;
    end else begin
        rx_in_sync <= rx_in;
        rx_valid   <= 0;
        if (!rx_active && !rx_in_sync) begin
            rx_active    <= 1;
            rx_clk_count <= CLKS_PER_BIT / 2;
            rx_bit_count <= 0;
        end else if (rx_active) begin
            if (rx_clk_count < CLKS_PER_BIT - 1) begin
                rx_clk_count <= rx_clk_count + 1;
            end else begin
                rx_clk_count <= 0;
                if (rx_bit_count < 8) begin
                    rx_shift     <= {rx_in_sync, rx_shift[7:1]};
                    rx_bit_count <= rx_bit_count + 1;
                end else begin
                    rx_data   <= rx_shift;
                    rx_valid  <= 1;
                    rx_active <= 0;
                end
            end
        end
    end
end

endmodule
