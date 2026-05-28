# =============================================================================
# uart.sdc — OpenSTA / OpenLane timing constraints
#
# Strategy:
#   - Clock defined with uncertainty + transition to bound CTS slew
#   - rx_in declared as async input → false path (no async timing arc)
#   - All other I/O constrained relative to clock (20% for inputs, 20% for outputs)
#   - Multicycle path on baud counter (it only matters at baud_en edges)
# =============================================================================

# -----------------------------------------------------------------------------
# Primary clock
# -----------------------------------------------------------------------------
create_clock -name clk -period 10.000 [get_ports clk]

# Clock uncertainty: jitter + skew budget
set_clock_uncertainty -setup 0.200 [get_clocks clk]
set_clock_uncertainty -hold  0.100 [get_clocks clk]

# Clock transition — drives CTS buffer sizing
set_clock_transition 0.150 [get_clocks clk]

# -----------------------------------------------------------------------------
# Async input — rx_in goes through 2-FF synchroniser, no timing arc needed
# -----------------------------------------------------------------------------
set_false_path -from [get_ports rx_in]

# -----------------------------------------------------------------------------
# Input delays  (20% of clock period = 2 ns)
# -----------------------------------------------------------------------------
set_input_delay -clock clk -max 2.000 [get_ports {rst tx_data tx_valid rx_ready}]
set_input_delay -clock clk -min 0.100 [get_ports {rst tx_data tx_valid rx_ready}]

# -----------------------------------------------------------------------------
# Output delays (20% of clock period = 2 ns)
# -----------------------------------------------------------------------------
set_output_delay -clock clk -max 2.000 \
    [get_ports {tx_out tx_ready rx_data rx_valid \
                tx_fifo_full tx_fifo_empty \
                rx_fifo_full rx_fifo_empty \
                rx_frame_err rx_overrun_err}]
set_output_delay -clock clk -min 0.100 \
    [get_ports {tx_out tx_ready rx_data rx_valid \
                tx_fifo_full tx_fifo_empty \
                rx_fifo_full rx_fifo_empty \
                rx_frame_err rx_overrun_err}]

# -----------------------------------------------------------------------------
# Baud counter multicycle path
# The baud_cnt comparator result (baud_en) only changes once per CLKS_PER_BIT
# cycles. Relax setup by N-1 cycles so the router doesn't over-buffer this path.
# Adjust multiplier if CLKS_PER_BIT changes.
# -----------------------------------------------------------------------------
set_multicycle_path -setup 2 -from [get_pins */baud_cnt*] -to [get_pins */baud_en*]
set_multicycle_path -hold  1 -from [get_pins */baud_cnt*] -to [get_pins */baud_en*]

# -----------------------------------------------------------------------------
# Load / drive models  (Sky130 HD typical parasitics)
# -----------------------------------------------------------------------------
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 -pin X \
    [get_ports {rst tx_data tx_valid rx_ready rx_in}]
set_load 0.05 [all_outputs]

# -----------------------------------------------------------------------------
# Operating conditions
# -----------------------------------------------------------------------------
set_max_fanout 6 [current_design]
set_max_transition 0.500 [current_design]
set_max_capacitance 0.500 [current_design]
