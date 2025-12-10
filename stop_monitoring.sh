#!/bin/bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <process_name>"
    echo "Example: $0 test"
    exit 1
fi

PROCESS_NAME="$1"

echo "Stopping monitoring for process: $PROCESS_NAME"

# Stop and disable timer
systemctl disable --now "monitor_process@${PROCESS_NAME}.timer" 2>/dev/null || true

# Delete PID file
PID_FILE="/var/run/monitor_${PROCESS_NAME}.pid"
if [ -f "$PID_FILE" ]; then
    rm -f "$PID_FILE"
    echo "Removed stale PID file: $PID_FILE"
fi

echo "Monitoring for '$PROCESS_NAME' has been stopped."
