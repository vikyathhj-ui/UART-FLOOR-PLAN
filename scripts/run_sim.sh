#!/usr/bin/env bash
# =============================================================================
# run_sim.sh — Compile and run RTL simulation with iverilog
#
# Requirements: iverilog + vvp (sudo apt install iverilog  or  brew install icarus-verilog)
# =============================================================================

set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== Compiling UART RTL + testbench ==="
iverilog -g2012 -Wall -o sim/uart_tb \
    tb/uart_tb.v \
    src/uart_top.v \
    src/uart_tx.v \
    src/uart_rx.v \
    src/sync_fifo.v

echo "=== Running simulation ==="
mkdir -p sim
cd sim && vvp uart_tb

echo ""
echo "VCD written to sim/uart_tb.vcd"
echo "Open with: gtkwave sim/uart_tb.vcd"
