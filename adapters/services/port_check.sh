#!/bin/bash
# Port Check Adapter - TCP connectivity test
# Unified output: {"service_name":"xxx","check_method":"port-check","status":"ok|failed|timeout","port":<number>,"latency_ms":<number>,"error_message":null,"timestamp":"2026-11-12T02:30:00Z"}

set -euo pipefail

HOST="${1:-localhost}"
PORT="${2:-5080}"
TIMEOUT="${3:-5}"
SERVICE_NAME="${4:-port-$PORT}"

main() {
    local start_time
    start_time=$(date +%s%N 2>/dev/null || date +%s000000000)
    local status="failed"
    local error_message=""
    local latency_ms=0
    
    # Check if nc (netcat) is available
    if ! command -v nc >/dev/null 2>&1; then
        # Try alternative: /dev/tcp (bash builtin)
        if timeout "$TIMEOUT" bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
            status="ok"
        else
            status="failed"
            error_message="Connection refused or timeout (no nc available)"
        fi
    else
        # Use netcat
        if timeout "$TIMEOUT" nc -z "$HOST" "$PORT" 2>/dev/null; then
            status="ok"
        else
            status="failed"
            error_message="Connection refused or timeout"
        fi
    fi
    
    local end_time
    end_time=$(date +%s%N 2>/dev/null || date +%s000000000)
    latency_ms=$(( (end_time - start_time) / 1000000 ))
    
    # Output unified JSON format
    printf '{"service_name":"%s","check_method":"port-check","status":"%s","port":%d,"latency_ms":%d,"error_message":%s,"timestamp":"%s"}\n' \
        "$SERVICE_NAME" \
        "$status" \
        "$PORT" \
        "$latency_ms" \
        "$( [ -n "$error_message" ] && printf '"%s"' "$error_message" || echo 'null' )" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

main "$@"