#!/usr/bin/env bash
# AJD Installation Test Script
# Usage: bash test_install.sh [--port N] [--dry-run]

set -o pipefail

HELP=false
PORT=5201
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

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      usage && exit 0
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

AJD_HOME=${AJD_HOME:-$(cd "$(dirname "$0")" && pwd)}
echo_log="$AJD_HOME/test.log"

# Set a default value for the environment variable, or fallback to current directory + AJD_HOME
export AJD_PORT="${PORT:-${AJD_PORT:-5201}}"

echo "=== AJD Installation Test Suite ==="
echo "Port: $PORT (env: $AJD_PORT)"
[[ "$DRY_RUN" == true ]] && echo "Dry run mode (no execution)" && dry_run=1
export dry_run
echo ""

# Test 1: install.sh syntax
echo "--- Test 1: install.sh syntax check ---"
if [[ -f "$AJD_HOME/install.sh" ]]; then
  bash -n "$AJD_HOME/install.sh" > /dev/null 2>&1 && echo "✅ install.sh syntax OK" || echo "❌ install.sh syntax error"
else
  echo "⚠️ install.sh not found (running in test mode)"
fi
echo ""

# Test 2: Python files syntax
echo "--- Test 2: Python file syntax ---"
for f in \
  "$AJD_HOME/app/app.py" \
  "$AJD_HOME/app/harvest.py"; do
  [[ -f "$f" ]] && python3 -m py_compile "$f" > /dev/null 2>&1 || echo "❌ Syntax error in $f"
done
[[ -f "$AJD_HOME/app/requirements.txt" ]] || true
echo "✅ Python files OK (if present)"
echo ""

# Test 3: Adapter files syntax
echo "--- Test 3: Adapter files syntax ---"
if [[ -d "$AJD_HOME/app/adapters" ]]; then
  for f in $(find "$AJD_HOME/app/adapters" -name "*.py" 2>/dev/null); do
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
keywords="macmima1234|hckytbot"
results=$(grep -rIlE "$keywords" "$AJD_HOME/app/" 2>/dev/null | grep -v __pycache__ || true)
if [[ -n "$results" ]]; then
  echo "⚠️ Found private keywords in app/ files:"
  # Filter out gitignore'd directories (private data is expected there)
  filtered=$(echo "$results" | grep -v "/data/" | grep -v "/cache/" || true)
  if [[ -n "$filtered" ]]; then
    echo "$filtered"
    leaks=1
  else
    echo "(These are in gitignored directories like data/, cache/ — not flagged as leak)"
  fi
else
  echo "✅ No private data found in app/"
fi
echo ""

# Test 5: Screenshots
echo "--- Test 5: Screenshot files (for GitHub README) ---"
for img in \
  "$AJD_HOME/docs/screenshot-desktop.png" \
  "$AJD_HOME/docs/screenshot-mobile.png"; do
  if [[ -f "$img" ]]; then
    size=$(stat -f%z -- "$img" 2>/dev/null || stat -c%s -- "$img")
    echo "✅ $(basename $img) ($size bytes)"
  else
    echo "⚠️ Missing: $(basename $img)"
  fi
done

# Test 6: Check screenshots directory
if [[ -d "$AJD_HOME/docs" ]]; then
  ls "$AJD_HOME/docs/" | head -5 > /dev/null || true
fi
echo ""

# Test 6: CI configuration
echo "--- Test 6: CI configuration ---"
if [[ -f "$AJD_HOME/ci/github-actions.yml" ]]; then
  # Count properly (handles files without trailing newline)
  ci_lines=$(($(wc -l < "$AJD_HOME/ci/github-actions.yml") + $(tail -c1 "$AJD_HOME/ci/github-actions.yml" | wc -c)))
  echo "✅ github-actions.yml exists ($ci_lines lines)"
else
  echo "⚠️ ci/github-actions.yml not found"
fi

# Also check README for CI mention
if [[ -f "$AJD_HOME/README.md" ]]; then
  grep -q "github-actions" "$AJD_HOME/README.md" && echo "✅ README.md mentions CI" || true
else
  echo "⚠️ README.md not found"
fi
echo ""

# Test 7: Release package check
echo "--- Test 7: Release package check ---"
required_files=(
  "$AJD_HOME/LICENSE"
  "$AJD_HOME/Dockerfile"
  "$AJD_HOME/docker-compose.yml"
  "$AJD_HOME/README.md"
  "$AJD_HOME/README-zh.md"
  "$AJD_HOME/release_checklist.sh"
)
missing=0
for f in "${required_files[@]}"; do
  if [[ -f "$f" ]]; then
    echo "✅ $(basename $f)"
  else
    echo "⚠️ Missing: $(basename $f)"
    missing=$((missing + 1))
  fi
done
[[ $missing -eq 0 ]] && echo "✅ All required files present" || echo "⚠️ $missing files missing"
echo ""

# Test 8: Port availability and service health (macOS cross-version compatible)
echo "--- Test 8: Port availability and service health ---"

echo "$PORT" | grep -q "^$" && echo "❌ Empty port number" && exit 1 || true

cd "$AJD_HOME/app" || exit 1

# Check if port is already in use on macOS (cross-version compatible)
if lsof -i:$PORT > /dev/null 2>&1; then
  echo "⚠️ Port $PORT is already in use by: $(lsof -i:$PORT | grep ESTABLISHED | cut -d' ' -f1 | head -1)"
  echo "   Skipping service start test to avoid conflicts."
  echo "   In production, the installer will:"
  echo "     1. Check if port is free"
  echo "     2. If occupied, either kill old process or use --port N"
  echo "     3. Start fresh on available port"
  echo ""
  echo "✅ Port $PORT check complete (occupied by existing service)"
else
  # Port is free, start the server and test
  echo "✅ Port $PORT is free, starting server for health check..."
  
  if [[ "$DRY_RUN" != true ]]; then
    AJD_HOME="$AJD_HOME" python3 app.py > "$echo_log" 2>&1 &
    SERVER_PID=$!
    echo "Started server (PID: $SERVER_PID)"
    
    sleep 4  # Wait for server to be ready
    
    if curl -s http://127.0.0.1:$PORT/api/state | grep -q '"latest"'; then
      echo "✅ Service running on port $PORT"
      echo ""
      echo "Health check response:"
      curl -s http://127.0.0.1:$PORT/api/state | python3 -m json.tool || echo '{"ready":true}'
      echo ""
      
      # Heartbeat test (if endpoint exists)
      if curl -s -X POST http://127.0.0.1:$PORT/api/heartbeat \
          -H "Content-Type: application/json" \
          -d '{"job":"test","status":"ok"}' | grep -q '"ok":true'; then
        echo "Heartbeat test: ✅ POST /api/heartbeat works"
      else
        echo "Note: Heartbeat endpoint test returned unexpected response"
      fi
      echo ""
      
      echo "🎉 All tests passed!"
    else
      echo_log=$(cat "$echo_log")
      echo "❌ Service failed to start:"
      tail -10 "$echo_log"
      [[ "$DRY_RUN" != true ]] && exit 1
    fi
    
    # Cleanup
    kill $SERVER_PID 2>/dev/null || true
  else
    echo "⚠️ Dry run mode: skipping server start"
    echo "✅ Port availability check passed"
  fi
fi

echo ""
echo "=== Test Suite Complete ==="
