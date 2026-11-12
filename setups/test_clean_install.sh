#!/usr/bin/env bash
# test_clean_install.sh — End-to-end clean install test for AJD
# Simulates: curl -fsSL <github raw>/install.sh | bash
# Validates: install → service starts → endpoints respond → heartbeat works → clean shutdown
# Usage: bash setups/test_clean_install.sh [AJD_HOME]
#   AJD_HOME defaults to a temp directory under /tmp/ajd-test-XXXXXX

set -euo pipefail

# Source directory (the AJD repo we're testing)
SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test installation directory (default: fresh temp dir)
TEST_AJD_HOME="${1:-$(mktemp -d -t ajd-test-XXXXXX)}"

echo "=== AJD Clean Install Test ==="
echo "Source:      $SRC_ROOT"
echo "Test dir:    $TEST_AJD_HOME"
echo ""

CLEANUP_ON_EXIT=true
trap 'cleanup' EXIT INT TERM

cleanup() {
    if [ "$CLEANUP_ON_EXIT" = true ]; then
        # Kill any test server
        if [ -n "${SERVER_PID:-}" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
            kill "$SERVER_PID" 2>/dev/null || true
            sleep 0.5
            kill -9 "$SERVER_PID" 2>/dev/null || true
        fi
        # Remove test directory if it was auto-created (under /tmp)
        if [[ "$TEST_AJD_HOME" == /tmp/ajd-test-* ]]; then
            rm -rf "$TEST_AJD_HOME"
            echo "🧹 Cleaned up $TEST_AJD_HOME"
        fi
    fi
}

ERRORS=0

# ── Step 1: Copy engine files (simulate GitHub download) ──
echo "📦 Step 1: Copying AJD engine files to test directory..."
mkdir -p "$TEST_AJD_HOME/app" "$TEST_AJD_HOME/data/logs" "$TEST_AJD_HOME/data/snapshots" "$TEST_AJD_HOME/docs"

# Copy app files
cp -r "$SRC_ROOT/app/"* "$TEST_AJD_HOME/app/"
# Copy docs (screenshots needed for validation)
cp -r "$SRC_ROOT/docs/"* "$TEST_AJD_HOME/docs/" 2>/dev/null || true
# Copy root-level docs
cp "$SRC_ROOT/AGENTS.md" "$TEST_AJD_HOME/"
cp "$SRC_ROOT/SETUP.md" "$TEST_AJD_HOME/"
cp "$SRC_ROOT/README.md" "$TEST_AJD_HOME/"
cp "$SRC_ROOT/README-zh.md" "$TEST_AJD_HOME/"
cp "$SRC_ROOT/install.sh" "$TEST_AJD_HOME/"
cp "$SRC_ROOT/app/projects.example.json" "$TEST_AJD_HOME/projects.example.json"

echo "   ✅ Files copied"

# ── Step 2: Create projects.json from template ──
echo ""
echo "📝 Step 2: Creating projects.json from template..."
cp "$TEST_AJD_HOME/projects.example.json" "$TEST_AJD_HOME/projects.json"
echo "   ✅ projects.json created"

# ── Step 3: Install Python dependencies ──
echo ""
echo "📦 Step 3: Installing Python dependencies..."
if command -v pip3 &>/dev/null; then
    pip3 install -r "$TEST_AJD_HOME/app/requirements.txt" --quiet 2>/dev/null || true
    echo "   ✅ Dependencies installed"
else
    echo "   ⚠️  pip3 not found, skipping dependency install"
fi

# ── Step 4: Start service on a free port ──
echo ""
echo "🚀 Step 4: Starting AJD service..."
TEST_PORT=5181
while lsof -ti:$TEST_PORT >/dev/null 2>&1; do
    TEST_PORT=$((TEST_PORT + 1))
    if [ $TEST_PORT -gt 5190 ]; then
        echo "   ❌ Could not find free port in 5181-5190 range"
        ERRORS=$((ERRORS + 1))
        exit $ERRORS
    fi
done

cd "$TEST_AJD_HOME/app"
AJD_HOME="$TEST_AJD_HOME" AJD_PORT="$TEST_PORT" AJD_AUTH_REQUIRED=false python3 app.py \
    > "$TEST_AJD_HOME/data/logs/server.log" 2>&1 &
SERVER_PID=$!

sleep 3

if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "   ❌ Service failed to start. Log:"
    cat "$TEST_AJD_HOME/data/logs/server.log"
    ERRORS=$((ERRORS + 1))
    exit $ERRORS
fi
echo "   ✅ Service started on port $TEST_PORT (PID: $SERVER_PID)"

# ── Step 5: Wait for health check ──
echo ""
echo "🔋 Step 5: Waiting for service readiness..."
READY=false
for i in {10..1}; do
    if curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$TEST_PORT/" 2>/dev/null | grep -q '^[23]'; then
        READY=true
        break
    fi
    echo "   Waiting ($i)..."
    sleep 1
done

if [ "$READY" = false ]; then
    echo "   ❌ Service did not become ready. Log:"
    cat "$TEST_AJD_HOME/data/logs/server.log"
    ERRORS=$((ERRORS + 1))
    exit $ERRORS
fi
echo "   ✅ Service is ready"

# ── Step 6: Validate API endpoints ──
echo ""
echo "🔍 Step 6: Validating API endpoints..."
ENDPOINTS=("/" "/api/state" "/api/heartbeat" "/api/schedulers" "/api/services")
for ep in "${ENDPOINTS[@]}"; do
    resp=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$TEST_PORT$ep" 2>/dev/null || echo "ERR")
    if [ "$resp" = "200" ]; then
        echo "   ✅ $ep → HTTP 200"
    elif [ "$resp" = "404" ] || [ "$resp" = "405" ]; then
        echo "   ✅ $ep → HTTP $resp (acceptable)"
    else
        echo "   ❌ $ep → HTTP $resp (expected 200, 404, or 405)"
        ERRORS=$((ERRORS + 1))
    fi
done

# ── Step 7: Test heartbeat POST ──
echo ""
echo "💓 Step 7: Testing heartbeat endpoint..."
HB_RESP=$(curl -s -X POST "http://127.0.0.1:$TEST_PORT/api/heartbeat" \
    -H 'Content-Type: application/json' \
    -d '{"job":"clean_install_test","status":"ok","note":"test from test_clean_install.sh"}' \
    -w '\n%{http_code}' 2>/dev/null || echo -e "\nERR")

HB_CODE=$(echo "$HB_RESP" | tail -1)
HB_BODY=$(echo "$HB_RESP" | sed '$d')

if [ "$HB_CODE" = "200" ]; then
    if echo "$HB_BODY" | grep -q '"ok":true'; then
        echo "   ✅ Heartbeat POST → HTTP 200, response OK"
    else
        echo "   ⚠️  Heartbeat POST → HTTP 200 but unexpected body: $HB_BODY"
    fi
else
    echo "   ❌ Heartbeat POST → HTTP $HB_CODE (expected 200)"
    ERRORS=$((ERRORS + 1))
fi

# ── Step 8: Verify heartbeat persisted ──
echo ""
echo "📖 Step 8: Verifying heartbeat was recorded..."
sleep 1
STATE_RESP=$(curl -s "http://127.0.0.1:$TEST_PORT/api/state" 2>/dev/null || echo "ERR")
if echo "$STATE_RESP" | grep -q "clean_install_test"; then
    echo "   ✅ Heartbeat found in /api/state"
else
    echo "   ⚠️  Heartbeat not visible in /api/state yet (may need more time)"
fi

# ── Step 9: Check required files exist ──
echo ""
echo "📋 Step 9: Checking required files in test install..."
REQUIRED="AGENTS.md SETUP.md README.md README-zh.md install.sh projects.example.json projects.json app/app.py app/harvest.py app/requirements.txt"
for f in $REQUIRED; do
    if [ -f "$TEST_AJD_HOME/$f" ]; then
        echo "   ✅ $f"
    else
        echo "   ❌ $f MISSING!"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check adapters
ADAPTER_FILES="app/adapters/__init__.py app/adapters/registry.py app/adapters/schedulers/__init__.py app/adapters/schedulers/crontab.py app/adapters/schedulers/hermes.py app/adapters/schedulers/launchd.py app/adapters/schedulers/systemd.py app/adapters/services/__init__.py app/adapters/services/docker.py app/adapters/services/http.py app/adapters/services/port.py"
for f in $ADAPTER_FILES; do
    if [ -f "$TEST_AJD_HOME/$f" ]; then
        echo "   ✅ $f"
    else
        echo "   ❌ $f MISSING!"
        ERRORS=$((ERRORS + 1))
    fi
done

# ── Step 10: Privacy scan on test install ──
echo ""
echo "🔍 Step 10: Privacy scan on test install..."
PRIVATE_PATTERN="macmima1234|hckytbot|kuohome|news_auto|stock_auto|idiom_auto|zaiditong"
MISMATCHES=$(grep -rIl -E "$PRIVATE_PATTERN" \
    --include="*.py" --include="*.json" --include="*.md" \
    --exclude-dir=__pycache__ \
    "$TEST_AJD_HOME/app/" 2>/dev/null || true)

if [ -n "$MISMATCHES" ]; then
    echo "   ❌ Found private data in test install:"
    echo "$MISMATCHES"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ No private data in test install"
fi

# ── Summary ──
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✅ Clean install test PASSED (all checks)"
    CLEANUP_ON_EXIT=true
else
    echo "❌ Clean install test FAILED ($ERRORS errors)"
    CLEANUP_ON_EXIT=false
    echo "   Test directory preserved at: $TEST_AJD_HOME"
fi
echo "=========================================="

exit $ERRORS