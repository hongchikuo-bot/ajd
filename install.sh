#!/usr/bin/env bash
# AJD · AI agents job dashboard Installation Script
# Install one-command deployment: curl -fsSL <repo>/install.sh | bash
#
# Features:
#   - Universal adapter layer (crontab/launchd/systemd/hermes → unified heartbeat)
#   - No external API, uses user's own agent for setup
#   - Generic templates, no private data leakage
#   - Works on macOS/Linux (tested on macOS 26.6.2)

set -euo pipefail

# Support both AJD_HOME env var and first positional arg
AJD_HOME="${AJD_HOME:-${1:-${HOME}/.ajd}}"
PORT="${PORT:-5080}"
NO_AGENT="${NO_AGENT:-false}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== AJD Installation ===" 
echo "Install directory: $AJD_HOME"
echo "Service port: $PORT"
echo ""

# Create directories
mkdir -p "$AJD_HOME/app" "$AJD_HOME/data/logs" "$AJD_HOME/data/snapshots"

# Copy engine files
cp "$SCRIPT_DIR/app/app.py" "$AJD_HOME/app/"
cp "$SCRIPT_DIR/app/harvest.py" "$AJD_HOME/app/"
cp -r "$SCRIPT_DIR/app/adapters" "$AJD_HOME/app/"
cp -r "$SCRIPT_DIR/app/static" "$AJD_HOME/app/"
cp -r "$SCRIPT_DIR/app/templates" "$AJD_HOME/app/"
cp "$SCRIPT_DIR/app/requirements.txt" "$AJD_HOME/app/"

# Copy projects.example.json as the generic template
cp "$SCRIPT_DIR/app/projects.example.json" "$AJD_HOME/projects.example.json"

# Create projects.json from example if it doesn't exist
if [ ! -f "$AJD_HOME/projects.json" ]; then
  cp "$SCRIPT_DIR/app/projects.example.json" "$AJD_HOME/projects.json"
  echo "📝 Created projects.json from template (please edit with your projects)"
fi

# Install Python dependencies
if command -v pip3 &> /dev/null; then
  pip3 install -r "$AJD_HOME/app/requirements.txt" --quiet 2>/dev/null || true
fi

# Start service in background
echo ""
echo "📦 Starting AJD service on port $PORT..."
cd "$AJD_HOME/app/" || exit 1
AJD_HOME="$AJD_HOME" AJD_PORT="$PORT" python3 app.py \
    > "$AJD_HOME/data/logs/server.log" 2>&1 &
SERVER_PID=$!
sleep 2
if kill -0 $SERVER_PID 2>/dev/null; then
  echo "✅ AJD service started (PID: $SERVER_PID)"
else
  echo "❌ Service failed to start. Check $AJD_HOME/data/logs/server.log"
  exit 1
fi

# Wait for health check
echo ""
echo "🔋 Waiting for service to be ready..."
for i in $(seq 10 -1 1); do
  if curl -s -o /dev/null -w '%{http_code}\n' http://127.0.0.1:$PORT/ | grep -q '^2\|^3'; then
    echo "✅ Service is ready (HTTP 2xx/3xx)"
    break
  fi || { echo "   Waiting $i more seconds..."; sleep 2; }
done

# Validate API endpoints with curl 
echo ""
echo "🔍 Validating AJD service endpoints..."
HEALTH_OK=false 
for endpoint in / /api/state /api/heartbeat; do
  resp=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:$PORT$endpoint) || resp="ERR"
  if [ "$resp" = "200" ]; then
    HEALTH_OK=true
    echo "✅ $endpoint → HTTP 200"
  elif [ "$resp" != "404" ] && [ "$resp" != "405" ]; then
    HEALTH_OK=false
    echo "❌ $endpoint → HTTP $resp (expected 200, 404, or 405)"
  else
    echo "✅ $endpoint → HTTP $resp (acceptable)"
  fi
done

if [ "$HEALTH_OK" = false ]; then
  echo "⚠️ Some endpoints returned non-200. Check the logs: tail -f $AJD_HOME/data/logs/server.log"
fi

echo ""
echo "🦾 Agent Configuration:"
echo "Copy this to your agent's config (e.g., ~/.hermes/profiles/default/memories/config for Hermes):"
echo "AJD_URL=\"http://127.0.0.1:$PORT/\""
echo "HERMES_AJD_REGISTRY=\"\$HOME/.hermes/projects.json\""
echo "HERMES_AJD_ALLOW_LOCAL_ONLY=true"
echo ""
echo "Or see AGENTS.md in $AJD_HOME for more agent examples (Claude, Cursor, etc.)"
echo ""
echo "✅ AJD installation complete!"
echo "   Dashboard: http://127.0.0.1:$PORT/"
echo "   Config:    $AJD_HOME/projects.json (edit with your projects)"
