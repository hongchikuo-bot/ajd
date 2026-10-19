#!/bin/bash
# test_heartbeat.sh - Simple heartbeat reporter for AJD demonstration
# Usage: ./test_heartbeat.sh <job_name> [status] [note]
#
# Examples:
#   ./test_heartbeat.sh "my-daily-report" ok "Generated at $(date)"
#   ./test_heartbeat.sh "stock-summary" failed "Connection timeout"

AJD_URL="${AJD_URL:-http://localhost:5080}"
HEARTBEAT_ENDPOINT="${AJD_URL}/api/heartbeat"

JOB_NAME="${1:-daily-report}"
STATUS="${2:-ok}"
NOTE="${3:-""}"

# Build payload
if [ -n "$NOTE" ]; then
    PAYLOAD="{\"job\":\"${JOB_NAME}\",\"status\":\"${STATUS}\",\"note\":\"${NOTE//\\/\\\\/}\"}"
else
    PAYLOAD="{\"job\":\"${JOB_NAME}\",\"status\":\"${STATUS}\"}"
fi

# Send heartbeat
echo "📤 Sending heartbeat for '${JOB_NAME}' (status: ${STATUS})..."
curl -sX POST "$HEARTBEAT_ENDPOINT" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" | python3 -m json.tool

RET=$?
if [ $RET -eq 0 ]; then
    echo "✅ Heartbeat received successfully!"
else
    echo "❌ Failed to send heartbeat (exit code: ${RET})"
    exit 1
fi
