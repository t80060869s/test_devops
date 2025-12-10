#!/bin/bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <process_name>"
    echo "Example: $0 test"
    exit 1
fi

PROCESS_NAME="$1"

# Check that if script and units are already installed
if [ ! -f /usr/local/bin/monitor_process.sh ]; then
    echo "Error: monitor_process.sh not found in /usr/local/bin/"
    echo "Please install the monitoring system first."
    exit 1
fi

if [ ! -f "/etc/systemd/system/monitor_process@.service" ] || [ ! -f "/etc/systemd/system/monitor_process@.timer" ]; then
    echo "Error: systemd units not found in /etc/systemd/system/"
    echo "Please install the monitoring system first."
    exit 1
fi

echo "Starting monitoring for process: $PROCESS_NAME"

# Activate and start the timer
systemctl enable --now "monitor_process@${PROCESS_NAME}.timer"

echo "Monitoring for '$PROCESS_NAME' has been started successfully."
echo "Status: $(systemctl is-active "monitor_process@${PROCESS_NAME}.timer")"
