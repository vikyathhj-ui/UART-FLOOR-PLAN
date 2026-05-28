# uart_top — Improved UART for Sky130HD / OpenLane

## Directory layout
```
uart-improved/
├── src/
│   ├── uart_top.v      Top-level: FIFOs, sync, error flags
│   ├── uart_tx.v       TX engine FSM with clock-gated shift register
│   ├── uart_rx.v       RX engine FSM with start-verify + stop check
│   └── sync_fifo.v     Gray-coded synchronous FIFO
├── tb/
│   └── uart_tb.v       Self-checking iverilog testbench (5 tests)
├── constraints/
│   └── uart.sdc        Clock, I/O, multicycle, false-path constraints
├── pdn/
│   └── pdn.tcl         Core ring + met4/met5 strap PDN
├── scripts/
│   ├── run_flow.sh     Full OpenLane Docker flow (one command)
│   └── run_sim.sh      iverilog RTL simulation
└── config.json         OpenLane configuration
```

## Quick start

### 1. Run RTL simulation
```bash
# Requires: iverilog (apt install iverilog / brew install icarus-verilog)
chmod +x scripts/run_sim.sh
./scripts/run_sim.sh
# View waveforms:
gtkwave sim/uart_tb.vcd
```

### 2. Run OpenLane physical flow
```bash
# Set paths if not default
export OPENLANE_ROOT=~/OpenLane
export PDK_ROOT=~/pdk

chmod +x scripts/run_flow.sh
./scripts/run_flow.sh
```

## Key parameters (uart_top.v)
| Parameter      | Default         | Description               |
|----------------|-----------------|---------------------------|
| CLK_FREQ_HZ    | 100_000_000     | Input clock frequency     |
| BAUD_RATE      | 115_200         | UART baud rate            |
| TX_FIFO_DEPTH  | 16              | TX FIFO depth (power of 2)|
| RX_FIFO_DEPTH  | 16              | RX FIFO depth (power of 2)|
| DATA_BITS      | 8               | Frame data bits (5–8)     |
| STOP_BITS      | 1               | Stop bits (1 or 2)        |
| PARITY_MODE    | 0               | 0=none 1=odd 2=even       |

## Improvements over baseline

### RTL / Architecture
- 2-FF metastability synchroniser on `rx_in`
- Start-bit glitch rejection (mid-bit verify)
- Stop-bit framing error detection
- TX pipeline stage: FIFO→LOAD→SHIFT breaks combo path
- Gray-coded FIFO pointers (min switching activity)
- `$clog2`-derived counter widths (no silent overflow)
- Synchronous reset everywhere (no async reset arcs)

### Power
- Baud counters clock-gated: only toggle when active
- Shift registers gated by FSM state enables
- Gray FIFO pointers: 1-bit toggle per push/pop
- FIFO prevents TX/RX stalling the data path

### Timing
- SDC: false path on async `rx_in`
- SDC: multicycle path relaxation on baud counter
- SDC: I/O delays, drive strength, max fanout, max transition
- All outputs registered — no combinational output paths
- CTS: clkbuf_4/8 buffer list + clkbuf_16 root

### Physical (OpenLane config)
- Absolute die/core sizing (250µm × 250µm)
- Core ring on met4/met5
- 80µm pitch met4/met5 straps
- Diode insertion strategy 4 (antenna)
- DRC fill insertion enabled
- LVS power pin insertion
- 64-iteration detailed route optimisation
