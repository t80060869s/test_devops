#!/bin/bash

# Script to monitor a process by name


# Name of the monitoring process (passed from service)
PROCESS_NAME=$@

# Path to log file
LOG_FILE="/var/log/monitoring.log"
# Path to store previous PID
PID_FILE="/var/run/monitor_${PROCESS_NAME}.pid"
# API endpoint
API_URL="https://test.com/monitoring/test/api"


# Creating dirs for logs and PID files
mkdir -p /var/log
mkdir -p /var/run

# Checking access rights
if [ ! -w "$(dirname "$LOG_FILE")" ]; then
    echo "Error: No permission to write to dir $(dirname "$LOG_FILE")"
    exit 1
fi

if [ ! -w "$(dirname "$PID_FILE")" ]; then
    echo "Error: No permission to write to dir $(dirname "$PID_FILE")"
    exit 1
fi


# Function to log messages with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}


# Check if process is running
if pgrep -x $PROCESS_NAME > /dev/null; then
    CURRENT_PID=$(pgrep -x $PROCESS_NAME | head -n 1)
    
    # Check for restart
    if [ -f "$PID_FILE" ]; then
        PREV_PID=$(cat "$PID_FILE")
        if [ "$CURRENT_PID" != "$PREV_PID" ]; then
            log_message "Process '$PROCESS_NAME' has been restarted. New PID: $CURRENT_PID"
        fi
    fi
    
    # Update PID file
    echo "$CURRENT_PID" > "$PID_FILE"
    
    # Send request to API and get result
    RESPONSE=$(curl -sS -o /dev/null -w "\n%{http_code}" "$API_URL" --connect-timeout 10 --max-time 15 2>&1)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')

    # Check if request return error
    if [ "$HTTP_CODE" != "200" ]; then

        # Access denied
        if [ "$HTTP_CODE" -eq "403" ]; then
            log_message "Monitoring server is unavailable: '403 Access denied' for process '$PROCESS_NAME' (PID: $CURRENT_PID)"
        # Not found
        elif [ "$HTTP_CODE" -eq "404" ]; then
            log_message "Monitoring server is unavailable: '404 Not found' for process '$PROCESS_NAME' (PID: $CURRENT_PID)"
        # Service Temporarily Unavailable
        elif [ "$HTTP_CODE" -eq "503" ]; then
            log_message "Monitoring server is unavailable: '503 Service Temporarily Unavailable' for process '$PROCESS_NAME' (PID: $CURRENT_PID)"
        # Connection error
        elif [ "$HTTP_CODE" -eq "000" ]; then
            if echo "$BODY" | grep -q "Could not resolve host"; then
                log_message "Monitoring server is unavailable: 'Could not resolve host' for process '$PROCESS_NAME' (PID: $CURRENT_PID)"
            elif echo "$BODY" | grep -q "Connection refused"; then
                log_message "Monitoring server is unavailable: 'Connection refused' for process '$PROCESS_NAME' (PID: $CURRENT_PID)"
            elif echo "$BODY" | grep -q "Connection timed out"; then
                log_message "Monitoring server is unavailable: 'Connection timed out' for process '$PROCESS_NAME' (PID: $CURRENT_PID)"
            else
                log_message "Monitoring server is unavailable: Unknown network error for process '$PROCESS_NAME' (PID: $CURRENT_PID). HTTP response: $BODY"
            fi
        else
            # Other HTTP error
            log_message "Monitoring server is unavailable: Unknown network error for process '$PROCESS_NAME' (PID: $CURRENT_PID). HTTP code: $HTTP_CODE. HTTP response: $BODY"
        fi
    fi
fi

exit 0
