#!/bin/bash
# HTTP Health Check Adapter - HTTP GET to health endpoint
# Unified output: {"service_name":"xxx","check_method":"http-health","status":"ok|failed|timeout","port":<number>,"latency_ms":<number>,"error_message":null,"timestamp":"2026-11-12T02:30:00Z"}

set -euo pipefail

URL="${1:-http://localhost:5080/health}"
SERVICE_NAME="${2:-http-service}"
TIMEOUT="${3:-10}"

main() {
    local start_time
    start_time=$(date +%s%N 2>/dev/null || date +%s000000000)
    local status="failed"
    local error_message=""
    local port=null
    local latency_ms=0
    local http_code=""
    
    # Extract port from URL for reporting
    if [[ "$URL" =~ :([0-9]+) ]]; then
        port="${BASH_REMATCH[1]}"
    fi
    
    # Check if curl is available
    if ! command -v curl >/dev/null 2>&1; then
        status="failed"
        error_message="curl command not found"
    else
        # Perform HTTP health check
        http_code=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" "$URL" 2>/dev/null || echo "000")
        # Ensure http_code is exactly 3 digits
        http_code="${http_code: -3}"
        
        case "$http_code" in
            200|204)
                status="ok"
                ;;
            000)
                status="failed"
                error_message="Connection failed or timeout"
                ;;
            4*)
                status="failed"
                error_message="HTTP $http_code (client error)"
                ;;
            5*)
                status="failed"
                error_message="HTTP $http_code (server error)"
                ;;
            *)
                status="warning"
                error_message="HTTP $http_code"
                ;;
        esac
    fi
    
    local end_time
    end_time=$(date +%s%N 2>/dev/null || date +%s000000000)
    latency_ms=$(( (end_time - start_time) / 1000000 ))
    
    # Output unified JSON format
    printf '{"service_name":"%s","check_method":"http-health","status":"%s","port":%s,"latency_ms":%d,"error_message":%s,"timestamp":"%s"}\n' \
        "$SERVICE_NAME" \
        "$status" \
        "$port" \
        "$latency_ms" \
        "$( [ -n "$error_message" ] && printf '"%s"' "$error_message" || echo 'null' )" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

main "$@"