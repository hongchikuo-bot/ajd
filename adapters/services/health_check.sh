#!/bin/bash
# Service Health Check Adapter
# Unified output: {"status":"ok","job":"xxx","service":"http://localhost:5080/api/health"}

set -e

SERVICE_URL="${1:-http://localhost:5080}"
JOB_NAME="${2:-unknown_service}"
TIMEOUT=${3:-5}

check_port() {
    local port=$(echo "$1" | grep -oE '[0-9]+$' || echo "")
    if [ -n "$port" ]; then
        nc -z localhost "$port" 2>/dev/null && echo "ok" || echo "failed"
    else
        echo "unknown"
    fi
}

check_http() {
    curl -s -o /dev/null -w '%{http_code}' --connect-timeout "$TIMEOUT" "$1" 2>/dev/null || echo "000"
}

main() {
    local url=$(echo "$SERVICE_URL" | grep -oE '^[a-z]+://[^/]*' || echo "")
    local port=$(echo "$SERVICE_URL" | grep -oE '[0-9]+$' || echo "")
    
    # Determine status
    local http_code=""
    local port_status="unknown"
    
    if [ -n "$url" ]; then
        http_code=$(check_http "$SERVICE_URL")
        # Ensure http_code is exactly 3 digits
        http_code="${http_code: -3}"
        if [ "$http_code" = "200" ] || [ "$http_code" = "204" ]; then
            status="ok"
        elif [ "$http_code" != "000" ]; then
            status="warning: HTTP $http_code"
        else
            status="failed"
        fi
    else
        port_status=$(check_port "$port")
        if [ "$port_status" = "ok" ]; then
            status="ok"
        else
            status="failed"
        fi
    fi
    
    # Output unified JSON format
    echo "{\"status\":\"$status\",\"job\":\"$JOB_NAME\",\"service\":\"${SERVICE_URL%:*}\"}"
}

main "$@"
