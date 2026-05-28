#!/usr/bin/env bash
# =============================================================================
# run_flow.sh — Full OpenLane Docker flow for uart_top
#
# Prerequisites:
#   - Docker running
#   - OpenLane at $OPENLANE_ROOT  (default: ~/OpenLane)
#   - PDK at $PDK_ROOT            (default: ~/pdk)
#
# Usage:
#   chmod +x scripts/run_flow.sh && ./scripts/run_flow.sh
# =============================================================================

set -euo pipefail

OPENLANE_ROOT="${OPENLANE_ROOT:-$HOME/OpenLane}"
PDK_ROOT="${PDK_ROOT:-$HOME/pdk}"
DESIGN_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "================================================"
echo "  uart_top OpenLane Flow"
echo "  Design  : $DESIGN_DIR"
echo "  OpenLane: $OPENLANE_ROOT"
echo "  PDK     : $PDK_ROOT"
echo "================================================"

if ! docker info > /dev/null 2>&1; then
    echo "[ERROR] Docker not running."
    exit 1
fi

TAG="uart_run_$(date +%Y%m%d_%H%M%S)"

docker run --rm \
    -v "$OPENLANE_ROOT":/openlane \
    -v "$PDK_ROOT":/root/.volare \
    -v "$DESIGN_DIR":/design \
    -e PDK=sky130A \
    -e STD_CELL_LIBRARY=sky130_fd_sc_hd \
    -u "$(id -u):$(id -g)" \
    efabless/openlane:latest \
    bash -c "
        cd /openlane && \
        python3 flow.py \
            -design /design \
            -config_file /design/config.json \
            -tag $TAG \
            -overwrite \
            2>&1 | tee /design/flow_run.log
    "

echo ""
echo "Done. Results: $DESIGN_DIR/runs/$TAG"
echo "Log:           $DESIGN_DIR/flow_run.log"
