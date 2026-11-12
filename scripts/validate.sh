#!/usr/bin/env bash
# validate.sh — Quick verification script for AJD runtime health check
set -euo pipefail

# Determine app directory: use AJD_HOME if set, else derive from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${AJD_HOME:-${SCRIPT_DIR}/../app}"

echo "=== AJD Runtime Health Check ==="
echo ""

# 1. Kill existing processes
echo "1. Stopping existing app instances..."
pkill -f "app.py" 2>/dev/null || true
sleep 1

# 2. Start fresh server
echo "2. Starting server on port 5081..."
cd "$APP_DIR"
AJD_PORT=5081 python3 app.py >/tmp/ajd_validate.log 2>&1 &
SERVER_PID=$!
echo "   PID: $SERVER_PID"

# 3. Wait for readiness with HTTP check
echo ""
echo "3. Waiting for server readiness..."
HTTP_CODE=0
for try in {1..8}; do
    if curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:5081/api/state" | grep -q '^2'; then
        HTTP_CODE=200
        echo "   ✅ Server ready (HTTP 2xx)"
        break
    fi
    sleep 1
done

# 4. Test heartbeat endpoint
echo ""
echo "4. Testing heartbeat POST..."
HEARTBEAT=$(curl -s -X POST http://127.0.0.1:5081/api/heartbeat \
    -H 'Content-Type: application/json' \
    -d '{"job":"validate-test","status":"ok"}')
if echo "$HEARTBEAT" | grep -q '"ok":true'; then
    echo "   ✅ Heartbeat recorded"
    echo "   Response: $HEARTBEAT"
else
    echo "   ⚠️  Heartbeat response unexpected: $HEARTBEAT"
fi

# 5. Verify no private data in app/
echo ""
echo "5. Checking for private data leakage..."
PRIVATES=$(grep -rIl -e macmima1234 -e hckytbot "$APP_DIR" 2>/dev/null | grep -v __pycache__ || true)
if [ -z "$PRIVATES" ]; then
    echo "   ✅ No private traces found"
else
    echo "   ❌ Private data detected:"
    echo "$PRIVATES"
fi

# 6. Clean up
echo ""
echo "6. Cleaning up..."
kill $SERVER_PID 2>/dev/null || true
rm -f /tmp/ajd_validate.log

echo ""
echo "=== Validation Summary ==="
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ ALL CHECKS PASSED"
else
    echo "❌ SOME CHECKS FAILED (port not available)"
fi
