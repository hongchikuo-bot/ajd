#!/bin/bash
# Docker Health Check Adapter
# Unified output: {"service_name":"xxx","check_method":"docker-inspect","status":"ok|failed","port":null,"latency_ms":42,"error_message":null,"timestamp":"2026-11-12T02:30:00Z"}

set -euo pipefail

SERVICE_NAME="${1:-unknown_container}"
TIMEOUT="${2:-10}"

main() {
    local start_time
    start_time=$(date +%s%N 2>/dev/null || date +%s000000000)
    local status="failed"
    local error_message=""
    local port=null
    local latency_ms=0
    
    # Check if docker is available
    if ! command -v docker >/dev/null 2>&1; then
        status="failed"
        error_message="docker command not found"
    else
        # Try to inspect the container
        local inspect_output
        inspect_output=$(docker inspect "$SERVICE_NAME" 2>/dev/null || echo "")
        
        if [ -z "$inspect_output" ]; then
            status="failed"
            error_message="Container not found or docker inspect failed"
        else
            # Parse container state
            local state_running
            state_running=$(echo "$inspect_output" | grep -o '"Running":\s*true' | head -1 || echo "")
            
            local state_status
            state_status=$(echo "$inspect_output" | grep -o '"Status":\s*"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
            
            local state_health
            state_health=$(echo "$inspect_output" | grep -o '"Health":\s*{[^}]*}' | head -1 || echo "")
            
            local health_status=""
            if [ -n "$state_health" ]; then
                health_status=$(echo "$state_health" | grep -o '"Status":\s*"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
            fi
            
            # Determine status
            if [ -n "$state_running" ]; then
                if [ -n "$health_status" ]; then
                    case "$health_status" in
                        "healthy")
                            status="ok"
                            ;;
                        "unhealthy")
                            status="failed"
                            error_message="Container health check: unhealthy"
                            ;;
                        "starting")
                            status="warning"
                            error_message="Container health check: starting"
                            ;;
                        *)
                            status="ok"  # Running but no health check defined
                            ;;
                    esac
                else
                    status="ok"  # Running, no health check defined
                fi
            elif [ "$state_status" = "exited" ]; then
                status="failed"
                local exit_code
                exit_code=$(echo "$inspect_output" | grep -o '"ExitCode":\s*[0-9]*' | head -1 | cut -d':' -f2 | tr -d ' ' || echo "?")
                error_message="Container exited with code $exit_code"
            elif [ "$state_status" = "created" ]; then
                status="warning"
                error_message="Container created but not started"
            elif [ "$state_status" = "restarting" ]; then
                status="warning"
                error_message="Container restarting"
            elif [ "$state_status" = "paused" ]; then
                status="warning"
                error_message="Container paused"
            elif [ "$state_status" = "dead" ]; then
                status="failed"
                error_message="Container dead"
            else
                status="failed"
                error_message="Container state: $state_status"
            fi
            
            # Try to extract port mappings
            local ports
            ports=$(echo "$inspect_output" | grep -o '"Ports":\s*{[^}]*}' | head -1 || echo "")
            if [ -n "$ports" ] && [ "$ports" != '{}' ]; then
                # Extract first host port
                local host_port
                host_port=$(echo "$ports" | grep -o '"HostPort":\s*"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
                if [ -n "$host_port" ] && [ "$host_port" != "0" ]; then
                    port="$host_port"
                fi
            fi
        fi
    fi
    
    local end_time
    end_time=$(date +%s%N 2>/dev/null || date +%s000000000)
    latency_ms=$(( (end_time - start_time) / 1000000 ))
    
    # Output unified JSON format
    printf '{"service_name":"%s","check_method":"docker-inspect","status":"%s","port":%s,"latency_ms":%d,"error_message":%s,"timestamp":"%s"}\n' \
        "$SERVICE_NAME" \
        "$status" \
        "$port" \
        "$latency_ms" \
        "$( [ -n "$error_message" ] && printf '"%s"' "$error_message" || echo 'null' )" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}

main "$@"