#!/bin/bash
# AJD API Endpoints Validation Script
# 驗證所有 /api/* 端點是否正確回應

PORT="${AJD_PORT:-5080}"
BASE_URL="http://127.0.0.1:${PORT}"
RESULT_FILE="${REPORT_DIR:-$HOME/.ajd/data}/validation_results.json"
mkdir -p "$(dirname "$RESULT_FILE")"

echo "=== AJD API Endpoints Validation ==="
echo "Testing endpoints at ${BASE_URL}..."
echo "" > "$RESULT_FILE"

# 測試基本端點 /api/heartbeat (POST with data)
http_code_heartbeat=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${BASE_URL}/api/heartbeat" \
    -H 'Content-Type: application/json' \
    -d '{"job":"test","status":"ok"}')

if [ "$http_code_heartbeat" = "200" ] || [ "$http_code_heartbeat" = "401" ]; then
    echo "✅ POST /api/heartbeat (expected 200/401): got ${http_code_heartbeat}" >> "$RESULT_FILE"
else
    echo "❌ POST /api/heartbeat: got ${http_code_heartbeat} (expected 200)" >> "$RESULT_FILE"
fi

# 測試 /api/state
http_code_state=$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/api/state")

if [ "$http_code_state" = "200" ]; then
    echo "✅ GET /api/state (expected 200): got ${http_code_state}" >> "$RESULT_FILE"
else
    echo "❌ GET /api/state: got ${http_code_state} (expected 200)" >> "$RESULT_FILE"
fi

# 測試 /api/schedulers
http_code_schedulers=$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/api/schedulers")

if [ "$http_code_schedulers" = "200" ]; then
    echo "✅ GET /api/schedulers (expected 200): got ${http_code_schedulers}" >> "$RESULT_FILE"
else
    echo "! GET /api/schedulers: got ${http_code_schedulers} (may need adapter setup)" >> "$RESULT_FILE"
fi

# 測試 /api/services
http_code_services=$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/api/services")

if [ "$http_code_services" = "200" ]; then
    echo "✅ GET /api/services (expected 200): got ${http_code_services}" >> "$RESULT_FILE"
else
    echo "! GET /api/services: got ${http_code_services} (may need adapter setup)" >> "$RESULT_FILE"
fi

# 測試根端點
http_code_root=$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/")

if [ "$http_code_root" = "200" ]; then
    echo "✅ GET / (expected 200): got ${http_code_root}" >> "$RESULT_FILE"
else
    echo "❌ GET : got ${http_code_root} (service not running)" >> "$RESULT_FILE"
fi

# 輸出 JSON 摘要 - 使用正確的變數名稱
cat > "$RESULT_FILE" << EOF
{
  "validation_timestamp": "$(date -Iseconds)",
  "base_url": "${BASE_URL}",
  "endpoints": {
    "/api/heartbeat": {"method": "POST", "status": "$http_code_heartbeat"},
    "/api/state": {"method": "GET", "status": "$http_code_state"},
    "/api/schedulers": {"method": "GET", "status": "$http_code_schedulers"},
    "/api/services": {"method": "GET", "status": "$http_code_services"}
  }
}
EOF

echo "" >&2
cat "$RESULT_FILE" >&2
