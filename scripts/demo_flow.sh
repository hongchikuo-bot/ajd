#!/usr/bin/env bash
# AJD Demo Flow Script
# This script demonstrates the complete AJD flow from installation to heartbeat failure detection.
# Run this script to see AJD in action (no video recording needed - this IS the demo).

set -euo pipefail

# Determine source directory (where AJD source lives)
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DEMO_DIR="/tmp/ajd-demo-$(date +%s)"
PORT=5081

echo "=========================================="
echo "AJD Demo Flow: Install → Dashboard → Heartbeat"
echo "=========================================="
echo ""
echo "Demo directory: $DEMO_DIR"
echo "Port: $PORT"
echo ""

# 1. Simulate curl | bash installation (using local files)
echo ">>> STEP 1: Installation (simulating: curl -fsSL .../install.sh | bash)"
echo ""

mkdir -p "$DEMO_DIR/app" "$DEMO_DIR/data/logs" "$DEMO_DIR/data/snapshots"

# Copy engine files (simulating download from GitHub)
cp -r "$SOURCE_DIR/app/"* "$DEMO_DIR/app/"
cp "$SOURCE_DIR/AGENTS.md" "$SOURCE_DIR/SETUP.md" "$SOURCE_DIR/README.md" "$SOURCE_DIR/README-zh.md" "$DEMO_DIR/"
mkdir -p "$DEMO_DIR/docs"
cp "$SOURCE_DIR/docs/screenshot-desktop.png" "$SOURCE_DIR/docs/screenshot-mobile.png" "$DEMO_DIR/docs/"
cp "$SOURCE_DIR/app/projects.example.json" "$DEMO_DIR/projects.example.json"
cp "$DEMO_DIR/projects.example.json" "$DEMO_DIR/projects.json"

# Install dependencies
pip3 install -r "$DEMO_DIR/app/requirements.txt" --quiet 2>/dev/null || true

echo "✅ Installation complete"
echo ""

# 2. Start service
echo ">>> STEP 2: Starting AJD service on port $PORT"
cd "$DEMO_DIR/app"
AJD_HOME="$DEMO_DIR" AJD_PORT="$PORT" python3 app.py > "$DEMO_DIR/data/logs/server.log" 2>&1 &
SERVER_PID=$!
sleep 3

if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo "❌ Service failed to start"
    cat "$DEMO_DIR/data/logs/server.log"
    exit 1
fi

echo "✅ Service started (PID: $SERVER_PID)"
echo ""

# 3. Wait for readiness
echo ">>> STEP 3: Waiting for service readiness..."
for i in {10..1}; do
    if curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:$PORT/" | grep -q '^[23]'; then
        echo "✅ Service is ready (HTTP 2xx)"
        break
    fi
    [ $i -eq 1 ] && { echo "❌ Service not ready"; cat "$DEMO_DIR/data/logs/server.log"; exit 1; }
    sleep 1
done
echo ""

# 4. Test dashboard endpoints
echo ">>> STEP 4: Validating dashboard endpoints"
for endpoint in / /api/state /api/heartbeat /api/schedulers /api/services; do
    resp=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT$endpoint") || resp="ERR"
    if [ "$resp" = "200" ]; then
        echo "✅ $endpoint → HTTP 200"
    else
        echo "⚠️  $endpoint → HTTP $resp"
    fi
done
echo ""

# 5. Test successful heartbeat
echo ">>> STEP 5: Sending SUCCESS heartbeat (job completed OK)"
HB_RESP=$(curl -s -X POST "http://127.0.0.1:$PORT/api/heartbeat" \
    -H 'Content-Type: application/json' \
    -d '{"job":"daily-news-build","status":"ok","note":"3.2MB generated"}')
echo "Response: $HB_RESP"
echo ""

# 6. Test warning heartbeat
echo ">>> STEP 6: Sending WARNING heartbeat (job completed with warnings)"
HB_RESP=$(curl -s -X POST "http://127.0.0.1:$PORT/api/heartbeat" \
    -H 'Content-Type: application/json' \
    -d '{"job":"weekly-report","status":"warn","note":"partial data"}')
echo "Response: $HB_RESP"
echo ""

# 7. Test FAILED heartbeat (this is the key demo: detecting failure)
echo ">>> STEP 7: Sending FAILURE heartbeat (job FAILED - THIS IS THE KEY FEATURE)"
HB_RESP=$(curl -s -X POST "http://127.0.0.1:$PORT/api/heartbeat" \
    -H 'Content-Type: application/json' \
    -d '{"job":"model-training","status":"fail","note":"GPU OOM at epoch 42"}')
echo "Response: $HB_RESP"
echo ""

# 8. Check state - shows the failed job
echo ">>> STEP 8: Checking /api/state - see the FAILED job highlighted!"
STATE=$(curl -s "http://127.0.0.1:$PORT/api/state")
echo "$STATE" | python3 -m json.tool | head -80
echo ""

# 9. Demonstrate the key insight: missing heartbeat = silent failure
echo ">>> STEP 9: THE KEY INSIGHT - Missing heartbeat = silent failure"
echo ""
echo "   A job that runs but crashes halfway (no heartbeat sent) will show as:"
echo "   - No entry in heartbeats (if never started)"
echo "   - Stale entry (if last heartbeat was hours/days ago)"
echo ""
echo "   This is why heartbeat is better than checking file timestamps!"
echo ""

# 10. Show dashboard URL
echo ">>> STEP 10: Open dashboard in browser"
echo "   Dashboard URL: http://127.0.0.1:$PORT/"
echo "   - 總覽 (Overview): See all jobs with status badges"
echo "   - 專案 (Projects): Browse projects by bot/type"
echo "   - 歷史 (History): View heartbeat timeline"
echo ""

# Cleanup
echo ">>> Cleaning up demo..."
kill $SERVER_PID 2>/dev/null || true
rm -rf "$DEMO_DIR"
echo "✅ Demo complete!"
echo ""
echo "=========================================="
echo "AJD Demo Summary"
echo "=========================================="
echo "1. One-command install: curl | bash"
echo "2. Auto-starts dashboard on localhost:5080"
echo "3. Universal heartbeat API (any script can POST)"
echo "4. Detects SUCCESS / WARNING / FAILURE states"
echo "5. Detects SILENT FAILURES (missing heartbeat)"
echo "6. Works with ANY agent (Hermes, Claude, Cursor, etc.)"
echo "7. Zero private data - completely generic"
echo "=========================================="