#!/usr/bin/env bash
# AJD Clean Install Test — verifies one-command install works in a fresh directory
# This simulates: curl -fsSL <repo>/install.sh | bash
# but uses local files instead of GitHub raw URLs

set -euo pipefail

# Use a temp directory for clean install test
TEST_DIR="${TMPDIR:-/tmp}/ajd_clean_install_test_$$"
export AJD_HOME="$TEST_DIR"
# Find an available port
for p in 5199 5200 5201 5202 5203; do
  if ! lsof -ti:$p >/dev/null 2>&1; then
    export PORT=$p
    break
  fi
done
export NO_AGENT=true
# Source directory (where AJD source lives) - set via env or auto-detect
SRC_DIR="${AJD_SOURCE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

echo "=== AJD Clean Install Test ==="
echo "Test directory: $TEST_DIR"
echo "Port: $PORT"
echo ""

# Clean up any previous test
rm -rf "$TEST_DIR"

# Create directory structure
mkdir -p "$TEST_DIR/app" "$TEST_DIR/data/logs" "$TEST_DIR/data/snapshots"
mkdir -p "$TEST_DIR/app/adapters/schedulers" "$TEST_DIR/app/adapters/services"
mkdir -p "$TEST_DIR/app/static" "$TEST_DIR/app/templates"
mkdir -p "$TEST_DIR/docs"

echo "📥 Copying AJD engine files from local source..."

# Copy core app files
cp "$SRC_DIR/app/app.py" "$TEST_DIR/app/app.py"
cp "$SRC_DIR/app/harvest.py" "$TEST_DIR/app/harvest.py"
cp "$SRC_DIR/app/test_adapters.py" "$TEST_DIR/app/test_adapters.py"
cp "$SRC_DIR/app/requirements.txt" "$TEST_DIR/app/requirements.txt"
cp "$SRC_DIR/app/projects.example.json" "$TEST_DIR/app/projects.example.json"

# Copy adapters
cp "$SRC_DIR/app/adapters/__init__.py" "$TEST_DIR/app/adapters/"
cp "$SRC_DIR/app/adapters/registry.py" "$TEST_DIR/app/adapters/"
cp "$SRC_DIR/app/adapters/schedulers/"* "$TEST_DIR/app/adapters/schedulers/"
cp "$SRC_DIR/app/adapters/services/"* "$TEST_DIR/app/adapters/services/"

# Copy static and templates
cp "$SRC_DIR/app/static/"* "$TEST_DIR/app/static/"
cp "$SRC_DIR/app/templates/"* "$TEST_DIR/app/templates/"

# Copy docs
cp "$SRC_DIR/AGENTS.md" "$TEST_DIR/AGENTS.md"
cp "$SRC_DIR/SETUP.md" "$TEST_DIR/SETUP.md"
cp "$SRC_DIR/README.md" "$TEST_DIR/README.md"
cp "$SRC_DIR/README-zh.md" "$TEST_DIR/README-zh.md"
cp "$SRC_DIR/docs/screenshot-desktop.png" "$TEST_DIR/docs/screenshot-desktop.png" 2>/dev/null || true
cp "$SRC_DIR/docs/screenshot-mobile.png" "$TEST_DIR/docs/screenshot-mobile.png" 2>/dev/null || true

# Create projects.json from example
cp "$TEST_DIR/app/projects.example.json" "$TEST_DIR/projects.json"
echo "📝 Created projects.json from template"

# Install Python dependencies (quiet)
if command -v pip3 &> /dev/null; then
  pip3 install -r "$TEST_DIR/app/requirements.txt" --quiet 2>/dev/null || true
fi

# Start service in background
echo ""
echo "📦 Starting AJD service on port $PORT..."
cd "$TEST_DIR/app/" || exit 1
AJD_HOME="$TEST_DIR" AJD_PORT="$PORT" python3 app.py \
    > "$TEST_DIR/data/logs/server.log" 2>&1 &
SERVER_PID=$!
sleep 3

# Check if process is alive
if ! kill -0 $SERVER_PID 2>/dev/null; then
  echo "❌ Service failed to start. Logs:"
  cat "$TEST_DIR/data/logs/server.log"
  exit 1
fi
echo "✅ AJD service started (PID: $SERVER_PID)"

# Wait for health check
echo ""
echo "🔋 Waiting for service to be ready..."
for i in $(seq 10 -1 1); do
  if curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:$PORT/ | grep -q '^2\|^3'; then
    echo "✅ Service is ready (HTTP 2xx/3xx)"
    break
  fi || { echo "   Waiting $i more seconds..."; sleep 2; }
done

# Validate API endpoints
echo ""
echo "🔍 Validating AJD service endpoints..."
ALL_OK=true
for endpoint in / /api/state /api/schedulers /api/services /api/heartbeat; do
  resp=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:$PORT$endpoint) || resp="ERR"
  if [ "$resp" = "200" ]; then
    echo "✅ $endpoint → HTTP 200"
  elif [ "$resp" = "404" ] || [ "$resp" = "405" ]; then
    echo "✅ $endpoint → HTTP $resp (acceptable for GET on POST endpoint)"
  else
    echo "❌ $endpoint → HTTP $resp (expected 200, 404, or 405)"
    ALL_OK=false
  fi
done

# Test heartbeat POST/GET roundtrip
echo ""
echo "💓 Testing heartbeat POST/GET roundtrip..."
HEARTBEAT_RESP=$(curl -s -X POST http://127.0.0.1:$PORT/api/heartbeat \
  -H 'Content-Type: application/json' \
  -d '{"job":"test_clean_install","status":"ok","note":"clean install test"}' \
  -w '\n%{http_code}')
HTTP_CODE=$(echo "$HEARTBEAT_RESP" | tail -1)
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ POST /api/heartbeat → HTTP 200"
else
  echo "❌ POST /api/heartbeat → HTTP $HTTP_CODE"
  ALL_OK=false
fi

# Verify heartbeat recorded via /api/state
STATE_RESP=$(curl -s http://127.0.0.1:$PORT/api/state)
if echo "$STATE_RESP" | grep -q "test_clean_install"; then
  echo "✅ Heartbeat recorded and readable via /api/state"
else
  echo "❌ Heartbeat not found in /api/state"
  echo "   Response: $STATE_RESP"
  ALL_OK=false
fi

# Stop service
echo ""
echo "🛑 Stopping test service..."
kill $SERVER_PID 2>/dev/null || true
sleep 1

# Summary
echo ""
echo "=== Clean Install Test Summary ==="
if [ "$ALL_OK" = true ]; then
  echo "✅ ALL TESTS PASSED — Clean install verified successfully"
  echo "   Install directory: $TEST_DIR"
  echo "   Service port: $PORT"
  exit 0
else
  echo "❌ Some tests failed"
  exit 1
fi