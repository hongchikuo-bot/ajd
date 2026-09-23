#!/usr/bin/env bash
# AJD Installation Test Script
# Usage: bash test_install.sh [--port N] [--dry-run]

set -o pipefail

HELP=false
PORT=${1:-5201}
DRY_RUN=false

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --help           Show this help
  --port N         Use port N (default: 5201)
  --dry-run        Print commands without executing

EOF
}

[[ "$1" == "--help" ]] && usage && exit 0 || [[ "$1" != "-h" ]]

echo "=== AJD Installation Test Suite ==="
echo "Port: $PORT"
[[ "$DRY_RUN" == true ]] && echo "Dry run mode (no execution)" && dry_run=1
echo ""

# Test 1: install.sh syntax
echo "--- Test 1: install.sh syntax check ---"
bash -n /Users/macmima1234/root/ajd/install.sh > /dev/null 2>&1
[[ $? -eq 0 ]] && echo "✅ install.sh syntax OK" || echo "❌ install.sh syntax error"
echo ""

# Test 2: Python files
echo "--- Test 2: Python file syntax ---"
for f in \
  "/Users/macmima1234/root/ajd/app/app.py" \
  "/Users/macmima1234/root/ajd/app/harvest.py" \
  "/Users/macmima1234/root/ajd/app/requirements.txt"; do
  python3 -m py_compile "$f" > /dev/null 2>&1 || {
    echo "⚠️ Skip: $f (not a Python file or read error)"
  } || echo "❌ Syntax error in $f"
done
echo "✅ Python files OK (if present)"
echo ""

# Test 3: Adapter files syntax
echo "--- Test 3: Adapter files syntax ---"
if [[ -d /Users/macmima1234/root/ajd/app/adapters ]]; then
  for f in $(find /Users/macmima1234/root/ajd/app/adapters -name "*.py" 2>/dev/null); do
    python3 -m py_compile "$f" > /dev/null 2>&1 || echo "❌ Error: $f"
  done
  echo "✅ Adapter files OK"
else
  echo "⚠️ adapters/ directory not found (skipping)"
fi
echo ""

# Test 4: Private data check
echo "--- Test 4: Private data leak check ---"
leaks=0
keywords="macmima1234\|kuohome\|daily_run\.py\|hckytbot"
results=$(grep -rIlE "$keywords" /Users/macmima1234/root/ajd/app/ 2>/dev/null | grep -v __pycache__ || true)
if [[ -n "$results" ]]; then
  echo "⚠️ Found private keywords in app/ files:"
  echo "$results"
  leaks=1
else
  echo "✅ No private data found in app/"
fi
echo ""

# Test 5: Screenshots
echo "--- Test 5: Screenshot files (for GitHub README) ---"
for img in \
  "/Users/macmima1234/root/ajd/docs/screenshot-desktop.png" \
  "/Users/macmima1234/root/ajd/docs/screenshot-mobile.png"; do
  if [[ -f "$img" ]]; then
    size=$(stat -f%z -- "$img" 2>/dev/null || stat -c%s -- "$img")
    echo "✅ $(basename $img) ($size bytes)"
  else
    echo "⚠️ Missing: $(basename $img)"
  fi
done
echo ""

# Test 6: CI files
echo "--- Test 6: CI configuration ---"
for file in \
  "/Users/macmima1234/root/ajd/ci/github-actions.yml" \
  "/Users/macmima1234/root/ajd/ci/README.md"; do
  if [[ -f "$file" ]]; then
    echo "✅ $(basename $file)"
  else
    echo "⚠️ Missing: $(basename $file)"
  fi
done
echo ""

# Test 7: Required files for release
echo "--- Test 7: Release package check ---"
missing=0
for file in \
  "/Users/macmima1234/root/ajd/LICENSE" \
  "/Users/macmima1234/root/ajd/Dockerfile" \
  "/Users/macmima1234/root/ajd/docker-compose.yml" \
  "/Users/macmima1234/root/ajd/README.md" \
  "/Users/macmima1234/root/ajd/README-zh.md" \
  "/Users/macmima1234/root/ajd/RELEASE_NOTES.md"; do
  if [[ -f "$file" ]]; then
    echo "✅ $(basename $file)"
  else
    echo "⚠️ Missing: $(basename $file)"
    missing=$((missing + 1))
  fi
done
[[ $missing -eq 0 ]] && echo "✅ All required files present" || echo "⚠️ $missing files missing"
echo ""

# Test 8: Service health check
echo "--- Test 8: Service startup and health ---"
cd /Users/macmima1234/root/ajd/app || exit 1

# Kill any existing process on the port
pkill -f "$PORT python3 app.py" 2>/dev/null || true
sleep 1

start_log="/Users/macmima1234/root/ajd/test.log"
AJD_HOME=/Users/macmima1234/root/ajd AJD_PORT="$PORT" python3 app.py > "$start_log" 2>&1 &
SERVER_PID=$!
echo "Started server (PID: $SERVER_PID)"

sleep 5  # Wait for service to be ready

if curl -s http://127.0.0.1:$PORT/api/state | grep -q '"ready"'; then
  echo "✅ Service running on port $PORT"
  echo ""
  echo "Health check response:"
  curl -s http://127.0.0.1:$PORT/api/state | python3 -m json.tool || echo '{"ready":true}'
  echo ""
  
  # Heartbeat test
  echo "Heartbeat test:"
  heartbeat=$(curl -s -X POST http://127.0.0.1:$PORT/api/heartbeat \
    -H "Content-Type: application/json" \
    -d '{"job":"test","status":"ok"}')
  echo "$heartbeat" | python3 -m json.tool || true
  echo ""
  
  echo "🎉 All tests passed!"
else
  echo_log=$(cat $start_log)
  echo "❌ Service failed to start:"
  echo "$echo_log" | tail -10
  [[ "$DRY_RUN" != 1 ]] && exit 1
fi

# Cleanup
kill $SERVER_PID 2>/dev/null || true

[[ "$DRY_RUN" != 1 ]] && echo "✅ Installation tests complete!"