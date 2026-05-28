# =============================================================================
# pdn.tcl — Power Delivery Network for uart_top on Sky130HD
#
# Strategy:
#   - Core ring on met4/met5 for low-resistance VDD/VSS loop
#   - met4 horizontal straps, met5 vertical straps at 80um pitch
#   - met1 standard cell rails connected via met2/met3/met4 via stacks
#   - Stripe widths sized for <1% IR drop at 50mW estimated peak
# =============================================================================

set ::power_nets  "VPWR"
set ::ground_nets "VGND"

# Core ring
add_pdn_ring \
    -grid       stdcell_grid \
    -layers     {met4 met5} \
    -widths     {1.60 1.60} \
    -spacings   {1.70 1.70} \
    -core_offset {2.00 2.00}

# Horizontal straps on met4
add_pdn_stripe \
    -grid    stdcell_grid \
    -layer   met4 \
    -width   1.60 \
    -pitch   80.0 \
    -offset  16.32 \
    -nets    {VPWR VGND}

# Vertical straps on met5
add_pdn_stripe \
    -grid    stdcell_grid \
    -layer   met5 \
    -width   1.60 \
    -pitch   80.0 \
    -offset  16.65 \
    -nets    {VPWR VGND}

# Standard cell rails on met1 (followpins)
add_pdn_stripe \
    -grid       stdcell_grid \
    -layer      met1 \
    -width      0.48 \
    -followpins \
    -nets       {VPWR VGND}

# Via stacks connecting rails to straps
add_pdn_connect -grid stdcell_grid -layers {met1 met4}
add_pdn_connect -grid stdcell_grid -layers {met4 met5}
